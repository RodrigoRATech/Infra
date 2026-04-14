unit Infra.ORM.Core.Metadata.Cache;

{
  Responsabilidade:
    Cache singleton thread-safe de metadados de entidades.

    Estratégia de concorrência:
      - Leitura:  múltiplos leitores simultâneos (TMREWSync.BeginRead)
      - Escrita:  exclusiva (TMREWSync.BeginWrite)
      - Double-checked locking para evitar resolução duplicada

    Regra: o cache possui ownership das instâncias de IOrmMetadadoEntidade.
    O resolvedor é instanciado internamente e não é exposto.
}

interface

uses
  System.SysUtils,
  System.SyncObjs,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions,
  Infra.ORM.Core.Logging.Contrato,
  Infra.ORM.Core.Metadata.Entidade,
  Infra.ORM.Core.Metadata.Resolvedor;

type

  // ---------------------------------------------------------------------------
  // Cache thread-safe de metadados
  //
  // Uso:
  //   TCacheMetadados.Instancia.Resolver(TCliente)
  //
  // A instância singleton é inicializada de forma lazy e thread-safe.
  // ---------------------------------------------------------------------------
  TCacheMetadados = class(TInterfacedObject, IOrmCacheMetadados)
  strict private
    // Lock multi-reader / single-writer
    FLock: TMREWSync;

    // Dicionário principal: TClass → IOrmMetadadoEntidade
    // Usamos interface para que o lifetime seja controlado por refcount
    FCache: TDictionary<TClass, IOrmMetadadoEntidade>;

    // Resolvedor interno — stateless, compartilhado com segurança
    FResolvedor: TResolvedorMetadados;

    // Logger opcional
    FLogger: IOrmLogger;

    // Singleton
    class var FInstancia: IOrmCacheMetadados;
    class var FLockSingleton: TCriticalSection;
    class constructor Create;
    class destructor Destroy;

  strict private
    // Resolve sem lock — deve ser chamado dentro de seção de escrita
    function ResolverInterno(AClasse: TClass): IOrmMetadadoEntidade;

  public
    constructor Create(ALogger: IOrmLogger = nil);
    destructor Destroy; override;

    // Acesso ao singleton global
    class function Instancia: IOrmCacheMetadados;

    // Inicializa o singleton com logger externo (chamar no bootstrap)
    class procedure Inicializar(ALogger: IOrmLogger = nil);

    // IOrmCacheMetadados
    function Resolver(AClasse: TClass): IOrmMetadadoEntidade;
    function ResolverPorNome(
      const ANomeClasse: string): IOrmMetadadoEntidade;
    function EstaEmCache(AClasse: TClass): Boolean;
    procedure Invalidar(AClasse: TClass);
    procedure InvalidarTudo;
    function TotalEmCache: Integer;
  end;

implementation

uses
  Infra.ORM.Core.Logging.Contrato;

{ TCacheMetadados }

class constructor TCacheMetadados.Create;
begin
  FLockSingleton := TCriticalSection.Create;
  FInstancia     := nil;
end;

class destructor TCacheMetadados.Destroy;
begin
  FInstancia := nil;
  FLockSingleton.Free;
end;

class function TCacheMetadados.Instancia: IOrmCacheMetadados;
begin
  // Double-checked locking para inicialização lazy do singleton
  if not Assigned(FInstancia) then
  begin
    FLockSingleton.Acquire;
    try
      if not Assigned(FInstancia) then
        FInstancia := TCacheMetadados.Create;
    finally
      FLockSingleton.Release;
    end;
  end;
  Result := FInstancia;
end;

class procedure TCacheMetadados.Inicializar(ALogger: IOrmLogger);
begin
  FLockSingleton.Acquire;
  try
    // Reinicializa com logger — permite setup no bootstrap da aplicação
    FInstancia := TCacheMetadados.Create(ALogger);
  finally
    FLockSingleton.Release;
  end;
end;

constructor TCacheMetadados.Create(ALogger: IOrmLogger);
begin
  inherited Create;

  FLock       := TMREWSync.Create;
  FResolvedor := TResolvedorMetadados.Create;
  FCache      := TDictionary<TClass, IOrmMetadadoEntidade>.Create;

  if Assigned(ALogger) then
    FLogger := ALogger
  else
    FLogger := TLoggerNulo.Create;
end;

destructor TCacheMetadados.Destroy;
begin
  FCache.Free;
  FResolvedor.Free;
  FLock.Free;
  FLogger := nil;
  inherited Destroy;
end;

function TCacheMetadados.ResolverInterno(
  AClasse: TClass): IOrmMetadadoEntidade;
var
  LMetadado: TMetadadoEntidade;
begin
  // Chamado sempre dentro de seção de escrita (BeginWrite)
  LMetadado := FResolvedor.Resolver(AClasse);
  Result    := LMetadado as IOrmMetadadoEntidade;
  FCache.AddOrSetValue(AClasse, Result);
end;

function TCacheMetadados.Resolver(AClasse: TClass): IOrmMetadadoEntidade;
var
  LResultado: IOrmMetadadoEntidade;
begin
  if not Assigned(AClasse) then
    raise EOrmMetadadoExcecao.Create(
      'TCacheMetadados',
      'Classe não pode ser nil ao resolver metadados.');

  // ── Tentativa de leitura (rápida) ────────────────────────────────────────
  FLock.BeginRead;
  try
    if FCache.TryGetValue(AClasse, LResultado) then
    begin
      Result := LResultado;
      Exit;
    end;
  finally
    FLock.EndRead;
  end;

  // ── Cache miss — adquire escrita e resolve ───────────────────────────────
  FLock.BeginWrite;
  try
    // Double-check: outra thread pode ter resolvido enquanto aguardávamos
    if FCache.TryGetValue(AClasse, LResultado) then
    begin
      Result := LResultado;
      Exit;
    end;

    FLogger.Debug(
      'Resolvendo metadados via RTTI',
      TContextoLog.Novo
        .Add('classe', AClasse.ClassName)
        .Construir);

    Result := ResolverInterno(AClasse);

    FLogger.Debug(
      'Metadados resolvidos e cacheados',
      TContextoLog.Novo
        .Add('classe', AClasse.ClassName)
        .Add('tabela', Result.NomeQualificado)
        .Add('propriedades', Result.Propriedades.Length)
        .Add('chaves', Result.Chaves.Length)
        .Construir);
  except
    on E: Exception do
    begin
      FLogger.Erro(
        'Falha ao resolver metadados',
        E,
        TContextoLog.Novo
          .Add('classe', AClasse.ClassName)
          .Construir);
      raise;
    end;
  end;
  FLock.EndWrite;
end;

function TCacheMetadados.ResolverPorNome(
  const ANomeClasse: string): IOrmMetadadoEntidade;
var
  LPar: TPair<TClass, IOrmMetadadoEntidade>;
begin
  Result := nil;

  if ANomeClasse.IsEmpty then
    Exit;

  FLock.BeginRead;
  try
    for LPar in FCache do
    begin
      if SameText(LPar.Key.ClassName, ANomeClasse) then
      begin
        Result := LPar.Value;
        Exit;
      end;
    end;
  finally
    FLock.EndRead;
  end;
end;

function TCacheMetadados.EstaEmCache(AClasse: TClass): Boolean;
begin
  FLock.BeginRead;
  try
    Result := FCache.ContainsKey(AClasse);
  finally
    FLock.EndRead;
  end;
end;

procedure TCacheMetadados.Invalidar(AClasse: TClass);
begin
  FLock.BeginWrite;
  try
    FCache.Remove(AClasse);

    FLogger.Aviso(
      'Metadado invalidado no cache',
      TContextoLog.Novo
        .Add('classe', AClasse.ClassName)
        .Construir);
  finally
    FLock.EndWrite;
  end;
end;

procedure TCacheMetadados.InvalidarTudo;
begin
  FLock.BeginWrite;
  try
    FCache.Clear;
    FLogger.Aviso('Cache de metadados invalidado completamente.');
  finally
    FLock.EndWrite;
  end;
end;

function TCacheMetadados.TotalEmCache: Integer;
begin
  FLock.BeginRead;
  try
    Result := FCache.Count;
  finally
    FLock.EndRead;
  end;
end;

end.
