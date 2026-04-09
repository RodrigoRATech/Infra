unit Infra.Schema.Middleware;

interface

uses
  Horse;

type
  { Middleware global de validação de schema JSON.

    - Aplicado via THorse.Use (uma única vez no bootstrap da API).
    - Ignora automaticamente requisições sem body (GET, HEAD, OPTIONS).
    - Deriva o nome do schema a partir do path da rota.
    - Requisições cujo schema não existe em disco são liberadas
      (comportamento configurável via ARequireSchema). }
  TSchemaMiddleware = class sealed
  public
    { Retorna o callback para uso em THorse.Use.

      ARequireSchema:
        True  → lança ESchemaNotFound se o arquivo não existir (padrão)
        False → libera a requisição sem validar se o schema não existir }
    class function Build(ARequireSchema: Boolean = False): THorseCallback;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  Horse.HandleException,
  Infra.Schema.Manager,
  Infra.Schema.RouteResolver,
  Infra.Schema.Exceptions;

{ ── Métodos HTTP que nunca possuem body ──────────────────────────────────── }

function IsBodylessMethod(const AMethod: string): Boolean;
const
  BODYLESS_METHODS: array[0..2] of string = ('GET', 'HEAD', 'OPTIONS');
var
  LMethod: string;
begin
  LMethod := AMethod.ToUpper;
  Result  := MatchStr(LMethod, BODYLESS_METHODS);
end;

{ ── TSchemaMiddleware ─────────────────────────────────────────────────────── }

class function TSchemaMiddleware.Build(ARequireSchema: Boolean): THorseCallback;
var
  LResolver: ISchemaRouteResolver;
begin
  LResolver := TSchemaRouteResolver.Create;

  Result :=
    procedure(ARequest: THorseRequest; AResponse: THorseResponse; ANext: TProc)
    var
      LSchemaName: string;
    begin
      { Guard Clause: métodos sem body são ignorados }
      if IsBodylessMethod(ARequest.MethodType.ToString) then
      begin
        ANext;
        Exit;
      end;

      { Deriva o nome do schema a partir da rota atual }
      LSchemaName := LResolver.Resolve(ARequest.RawWebRequest.PathInfo);

      if LSchemaName = EmptyStr then
      begin
        Log('WARN', '[Schema.Middleware] Não foi possível resolver o schema para a rota: '
          + ARequest.RawWebRequest.PathInfo);
        ANext;
        Exit;
      end;

      Log('INFO', Format('[Schema.Middleware] Rota: %s → Schema: %s',
        [ARequest.RawWebRequest.PathInfo, LSchemaName]));

      try
        TSchemaManager.Instance.Validate(LSchemaName, ARequest.Body);

        Log('INFO', Format('[Schema.Middleware] Body válido. Schema: %s', [LSchemaName]));
        ANext;

      except
        on E: ESchemaNotFound do
        begin
          Log('WARN', Format('[Schema.Middleware] Schema não encontrado: %s', [E.Message]));

          { Schema ausente e não obrigatório → libera a requisição }
          if not ARequireSchema then
          begin
            ANext;
            Exit;
          end;

          { ╔════════════════════════════════════════════════════════╗
            ║  INTEGRAÇÃO: Horse.HandleException                     ║
            ║  ESchemaNotFound → HTTP 404                            ║
            ╚════════════════════════════════════════════════════════╝ }
          raise;
        end;

        on E: ESchemaValidationError do
        begin
          Log('WARN', Format('[Schema.Middleware] Validação falhou. Schema: %s | Erros: %s',
            [LSchemaName, E.Errors]));

          { ╔════════════════════════════════════════════════════════╗
            ║  INTEGRAÇÃO: Horse.HandleException                     ║
            ║  ESchemaValidationError → HTTP 422                     ║
            ╚════════════════════════════════════════════════════════╝ }
          raise;
        end;

        on E: ESchemaLoadError do
        begin
          Log('ERROR', Format('[Schema.Middleware] Erro ao carregar schema: %s', [E.Message]));

          { ╔════════════════════════════════════════════════════════╗
            ║  INTEGRAÇÃO: Horse.HandleException                     ║
            ║  ESchemaLoadError → HTTP 500                           ║
            ╚════════════════════════════════════════════════════════╝ }
          raise;
        end;

        on E: Exception do
        begin
          Log('ERROR', Format('[Schema.Middleware] Erro inesperado: %s', [E.Message]));
          raise;
        end;
      end;
    end;
end;

end.
