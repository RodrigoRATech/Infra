unit Infra.Schema.RouteResolver;

interface

uses
  System.SysUtils,
  System.RegularExpressions;

type
  { Converte o path da requisição no nome do arquivo de schema correspondente.

    Regras:
      1. Remove o prefixo de versionamento  → /sgq/v1/documento/incluir
                                                       ↓
      2. Descarta segmentos de versão (vN)  → documento/incluir
      3. Remove parâmetros dinâmicos (:id)  → segmentos fixos apenas
      4. Une com hífen e coloca em lowercase → documento-incluir  }
  ISchemaRouteResolver = interface
    ['{C3D4E5F6-A7B8-9012-CDEF-234567890123}']
    function Resolve(const ARoutePath: string): string;
  end;

  TSchemaRouteResolver = class(TInterfacedObject, ISchemaRouteResolver)
  private
    { Remove segmentos que representam versão: v1, v2, v10... }
    class function IsVersionSegment(const ASegment: string): Boolean; static;

    { Remove segmentos que são parâmetros dinâmicos do Horse: :id, :codigo... }
    class function IsDynamicSegment(const ASegment: string): Boolean; static;
  public
    { Exemplos:
        /sgq/v1/documento/incluir  → documento-incluir
        /api/v2/cliente/:id/editar → cliente-editar
        /sgq/v1/nao-conformidade/incluir → nao-conformidade-incluir  }
    function Resolve(const ARoutePath: string): string;
  end;

implementation

uses
  System.Classes,
  System.StrUtils;

{ TSchemaRouteResolver }

class function TSchemaRouteResolver.IsVersionSegment(const ASegment: string): Boolean;
begin
  // Segmentos como v1, v2, v12 (vN onde N é numérico)
  Result := TRegEx.IsMatch(ASegment, '^v\d+$', [roIgnoreCase]);
end;

class function TSchemaRouteResolver.IsDynamicSegment(const ASegment: string): Boolean;
begin
  // Horse usa :parametro para segmentos dinâmicos
  Result := ASegment.StartsWith(':');
end;

function TSchemaRouteResolver.Resolve(const ARoutePath: string): string;
var
  LParts    : TArray<string>;
  LSegment  : string;
  LSegments : TStringList;
begin
  Result := EmptyStr;

  if Trim(ARoutePath) = EmptyStr then
    Exit;

  // Divide o path pelo separador '/'
  LParts := ARoutePath.ToLower.Split(['/']);

  LSegments := TStringList.Create;
  try
    for LSegment in LParts do
    begin
      { Ignora: vazio (barras duplas ou barra inicial), versões e parâmetros }
      if (Trim(LSegment) = EmptyStr)   then Continue;
      if IsVersionSegment(LSegment)    then Continue;
      if IsDynamicSegment(LSegment)    then Continue;

      LSegments.Add(LSegment);
    end;

    // Une os segmentos úteis com hífen → documento-incluir
    Result := string.Join('-', LSegments.ToStringArray);
  finally
    LSegments.Free;
  end;
end;

end.
