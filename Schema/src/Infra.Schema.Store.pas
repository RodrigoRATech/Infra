unit Infra.Schema.Store;

interface

uses
  System.SysUtils,
  System.IOUtils,
  Infra.Schema.Config,
  Infra.Schema.Exceptions;

type
  ISchemaStore = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    { Retorna o conteúdo JSON do schema. Lança ESchemaNotFound ou ESchemaLoadError. }
    function Load(const ASchemaName: string): string;
    { Remove o schema da cache (invalida entrada). }
    procedure Invalidate(const ASchemaName: string);
    { Remove todos os schemas da cache. }
    procedure InvalidateAll;
  end;

  TSchemaStore = class(TInterfacedObject, ISchemaStore)
  private
    FConfig: TSchemaConfig;

    function BuildFilePath(const ASchemaName: string): string;
    function BuildCacheKey(const ASchemaName: string): string;

    { Tenta recuperar da cache Redis — retorna True se encontrou }
    function TryLoadFromCache(const ASchemaName: string; out AContent: string): Boolean;
    { Lê schema do disco }
    function LoadFromDisk(const ASchemaName: string): string;
    { Persiste schema na cache Redis }
    procedure SaveToCache(const ASchemaName, AContent: string);
  public
    constructor Create(AConfig: TSchemaConfig);
    destructor Destroy; override;

    function Load(const ASchemaName: string): string;
    procedure Invalidate(const ASchemaName: string);
    procedure InvalidateAll;
  end;

implementation

uses
  Infra.Logger,
  Infra.Logger.Types,
  Infra.Cache.Manager;

{ TSchemaStore }

constructor TSchemaStore.Create(AConfig: TSchemaConfig);
begin
  inherited Create;

  if not Assigned(AConfig) then
    raise ESchemaConfigError.Create('TSchemaConfig não pode ser nil.');

  FConfig := AConfig;
end;

destructor TSchemaStore.Destroy;
begin
  // FConfig é de propriedade do chamador (Manager), não liberar aqui
  inherited Destroy;
end;

function TSchemaStore.BuildFilePath(const ASchemaName: string): string;
begin
  Result := TPath.Combine(FConfig.SchemaBasePath,
                          ASchemaName + FConfig.SchemaExtension);
end;

function TSchemaStore.BuildCacheKey(const ASchemaName: string): string;
begin
  Result := FConfig.CacheKeyPrefix + ASchemaName;
end;

function TSchemaStore.TryLoadFromCache(const ASchemaName: string;
  out AContent: string): Boolean;
var
  LCacheKey: string;
begin
  Result := False;
  AContent := EmptyStr;

  if not FConfig.CacheEnabled then
    Exit;

  LCacheKey := BuildCacheKey(ASchemaName);

  { ╔══════════════════════════════════════════════════════╗
    ║  PONTO DE INTEGRAÇÃO: Infra.Cache.Manager            ║
    ║  Chame aqui o método Get da sua classe de cache.     ║
    ║                                                      ║
    ║  Exemplo:                                            ║
    ║    AContent := TCacheManager.Instance.Get(LCacheKey) ║
    ║    Result   := AContent <> EmptyStr;                 ║
    ╚══════════════════════════════════════════════════════╝ }

  // TODO: substituir pelo uso real da classe de cache
  // AContent := TCacheManager.Instance.Get(LCacheKey);
  // Result   := AContent <> EmptyStr;
end;

function TSchemaStore.LoadFromDisk(const ASchemaName: string): string;
var
  LFilePath: string;
begin
  LFilePath := BuildFilePath(ASchemaName);

  if not TFile.Exists(LFilePath) then
    raise ESchemaNotFound.Create(ASchemaName);

  try
    Result := TFile.ReadAllText(LFilePath, TEncoding.UTF8);
  except
    on E: Exception do
      raise ESchemaLoadError.Create(ASchemaName, E.Message);
  end;
end;

procedure TSchemaStore.SaveToCache(const ASchemaName, AContent: string);
var
  LCacheKey: string;
begin
  if not FConfig.CacheEnabled then
    Exit;

  LCacheKey := BuildCacheKey(ASchemaName);

  { ╔══════════════════════════════════════════════════════╗
    ║  PONTO DE INTEGRAÇÃO: Infra.Cache.Manager            ║
    ║  Chame aqui o método Set/Put da sua classe de cache. ║
    ║                                                      ║
    ║  Exemplo:                                            ║
    ║    TCacheManager.Instance.Put(                       ║
    ║      LCacheKey,                                      ║
    ║      AContent,                                       ║
    ║      FConfig.CacheTTLSeconds                         ║
    ║    );                                                ║
    ╚══════════════════════════════════════════════════════╝ }

  // TODO: substituir pelo uso real da classe de cache
  // TCacheManager.Instance.Put(LCacheKey, AContent, FConfig.CacheTTLSeconds);
end;

function TSchemaStore.Load(const ASchemaName: string): string;
var
  LContent: string;
begin
  if TryLoadFromCache(ASchemaName, LContent) then
  begin
    TLogger.Instance.Log( llDebug, Format('[Schema.Store] Cache HIT para schema: %s', [ASchemaName]));
    Exit(LContent);
  end;

  TLogger.Instance.Log( llDebug, Format('[Schema.Store] Cache MISS para schema: %s — lendo disco', [ASchemaName]));
  LContent := LoadFromDisk(ASchemaName);
  SaveToCache(ASchemaName, LContent);

  Result := LContent;
end;

procedure TSchemaStore.Invalidate(const ASchemaName: string);
var
  LCacheKey: string;
begin
  if not FConfig.CacheEnabled then
    Exit;

  LCacheKey := BuildCacheKey(ASchemaName);

  { ╔══════════════════════════════════════════════════════╗
    ║  PONTO DE INTEGRAÇÃO: Infra.Cache.Manager            ║
    ║  TCacheManager.Instance.Delete(LCacheKey);           ║
    ╚══════════════════════════════════════════════════════╝ }

  TLogger.Instance.Log( llInformation, Format('[Schema.Store] Cache invalidado para schema: %s', [ASchemaName]));
end;

procedure TSchemaStore.InvalidateAll;
begin
  if not FConfig.CacheEnabled then
    Exit;

  { ╔══════════════════════════════════════════════════════╗
    ║  PONTO DE INTEGRAÇÃO: Infra.Cache.Manager            ║
    ║  TCacheManager.Instance.DeleteByPrefix(              ║
    ║    FConfig.CacheKeyPrefix                            ║
    ║  );                                                  ║
    ╚══════════════════════════════════════════════════════╝ }

  TLogger.Instance.Log( llInformation, '[Schema.Store] Cache de schemas totalmente invalidado.');
end;

end.
