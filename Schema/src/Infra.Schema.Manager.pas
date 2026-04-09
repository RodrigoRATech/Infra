unit Infra.Schema.Manager;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.SyncObjs,
  Infra.Schema.Config,
  Infra.Schema.Store,
  Infra.Schema.Exceptions;

type
  { Contrato público exposto ao resto da aplicação }
  ISchemaManager = interface
    ['{F0E1D2C3-B4A5-6789-CDEF-012345678901}']
    function  GetSchemaContent(const ASchemaName: string): string;
    procedure Validate(const ASchemaName, AJsonBody: string);
    procedure InvalidateCache(const ASchemaName: string);
    procedure InvalidateAllCaches;
    procedure ReloadConfig(AConfig: TSchemaConfig);
  end;

  TSchemaManager = class(TInterfacedObject, ISchemaManager)
  private
    FConfig   : TSchemaConfig;
    FStore    : ISchemaStore;
    FLock     : TCriticalSection;
    { Flyweight: schemas já parseados ficam vivos na memória }
    FParsedCache: TDictionary<string, TObject>; // TObject = tipo do seu parser

    class var FInstance : ISchemaManager;
    class var FInitLock : TCriticalSection;

    constructor Create(AConfig: TSchemaConfig);

    { Retorna schema parseado (do flyweight ou faz parse novo) }
    function GetOrParsedSchema(const ASchemaName: string): TObject;
  public
    destructor Destroy; override;

    { Singleton thread-safe com double-checked locking }
    class function Instance: ISchemaManager; overload;
    class function Instance(AConfig: TSchemaConfig): ISchemaManager; overload;
    class procedure ReleaseInstance;

    { ISchemaManager }
    function  GetSchemaContent(const ASchemaName: string): string;
    procedure Validate(const ASchemaName, AJsonBody: string);
    procedure InvalidateCache(const ASchemaName: string);
    procedure InvalidateAllCaches;
    procedure ReloadConfig(AConfig: TSchemaConfig);
  end;

implementation

uses
  Infra.Logger.Types,
  Infra.Logger,
  Infra.JSONSchema.Parser;

{ TSchemaManager }

constructor TSchemaManager.Create(AConfig: TSchemaConfig);
begin
  inherited Create;
  FConfig      := AConfig;
  FStore       := TSchemaStore.Create(FConfig);
  FLock        := TCriticalSection.Create;
  FParsedCache := TDictionary<string, TObject>.Create;

  TLogger.Instance.Log( llInformation, '[Schema.Manager] Inicializado. BasePath: ' + FConfig.SchemaBasePath);
end;

destructor TSchemaManager.Destroy;
begin
  FParsedCache.Free;
  FLock.Free;
  FConfig.Free;
  inherited Destroy;
end;

class function TSchemaManager.Instance: ISchemaManager;
begin
  if not Assigned(FInstance) then
  begin
    FInitLock.Enter;
    try
      if not Assigned(FInstance) then
        FInstance := TSchemaManager.Create(TSchemaConfig.Default);
    finally
      FInitLock.Leave;
    end;
  end;
  Result := FInstance;
end;

class function TSchemaManager.Instance(AConfig: TSchemaConfig): ISchemaManager;
begin
  FInitLock.Enter;
  try
    { Permite re-inicializar com configuração customizada }
    FInstance := TSchemaManager.Create(AConfig);
  finally
    FInitLock.Leave;
  end;
  Result := FInstance;
end;

class procedure TSchemaManager.ReleaseInstance;
begin
  FInitLock.Enter;
  try
    FInstance := nil; // interface libera automaticamente via refcount
  finally
    FInitLock.Leave;
  end;
end;

function TSchemaManager.GetOrParsedSchema(const ASchemaName: string): TObject;
var
  LContent: string;
  LParsed : TObject;
begin
  { Leitura com lock — protege o FParsedCache (Flyweight) }
  FLock.Enter;
  try
    if FParsedCache.TryGetValue(ASchemaName, Result) then
      Exit; // Flyweight: reutiliza schema já parseado

    LContent := FStore.Load(ASchemaName);

    { ╔══════════════════════════════════════════════════════════╗
      ║  PONTO DE INTEGRAÇÃO: Infra.JSONSchema.Parser            ║
      ║  Instancie e chame o parser JSONSchema existente.        ║
      ║                                                          ║
      ║  Exemplo:                                                ║
      ║    LParsed := TJSONSchemaParser.Parse(LContent);         ║
      ╚══════════════════════════════════════════════════════════╝ }

    // TODO: substituir pelo parse real
    // LParsed := TJSONSchemaParser.Parse(LContent);

    LParsed := nil; // placeholder até integração real
    FParsedCache.AddOrSetValue(ASchemaName, LParsed);
    Result := LParsed;
  finally
    FLock.Leave;
  end;
end;

function TSchemaManager.GetSchemaContent(const ASchemaName: string): string;
begin
  FLock.Enter;
  try
    Result := FStore.Load(ASchemaName);
  finally
    FLock.Leave;
  end;
end;

procedure TSchemaManager.Validate(const ASchemaName, AJsonBody: string);
var
  LSchema: TObject;
begin
  TLogger.Instance.Log( llDebug, Format('[Schema.Manager] Iniciando validação. Schema: %s', [ASchemaName]));

  LSchema := GetOrParsedSchema(ASchemaName);

  { ╔══════════════════════════════════════════════════════════╗
    ║  PONTO DE INTEGRAÇÃO: Infra.JSONSchema.Parser            ║
    ║  Chame o método de validação do parser existente.        ║
    ║                                                          ║
    ║  Exemplo:                                                ║
    ║    var LResult: TSchemaValidationResult;                 ║
    ║    LResult := TJSONSchemaParser.Validate(                ║
    ║                 LSchema as TJSONSchema,                  ║
    ║                 AJsonBody                                ║
    ║               );                                         ║
    ║    if not LResult.IsValid then                           ║
    ║      raise ESchemaValidationError.Create(                ║
    ║              ASchemaName, LResult.ErrorsAsString         ║
    ║            );                                            ║
    ╚══════════════════════════════════════════════════════════╝ }

  TLogger.Instance.Log( llDebug, Format('[Schema.Manager] Validação concluída OK. Schema: %s', [ASchemaName]));
end;

procedure TSchemaManager.InvalidateCache(const ASchemaName: string);
begin
  FLock.Enter;
  try
    FParsedCache.Remove(ASchemaName);
    FStore.Invalidate(ASchemaName);
    TLogger.Instance.Log( llInformation, Format('[Schema.Manager] Cache invalidado: %s', [ASchemaName]));
  finally
    FLock.Leave;
  end;
end;

procedure TSchemaManager.InvalidateAllCaches;
begin
  FLock.Enter;
  try
    FParsedCache.Clear;
    FStore.InvalidateAll;
    TLogger.Instance.Log( llInformation, '[Schema.Manager] Todos os caches de schema invalidados.');
  finally
    FLock.Leave;
  end;
end;

procedure TSchemaManager.ReloadConfig(AConfig: TSchemaConfig);
begin
  FLock.Enter;
  try
    FConfig.Free;
    FConfig := AConfig;
    FStore   := TSchemaStore.Create(FConfig);
    FParsedCache.Clear;
    TLogger.Instance.Log( llInformation, '[Schema.Manager] Configuração recarregada.');
  finally
    FLock.Leave;
  end;
end;

initialization
  TSchemaManager.FInitLock := TCriticalSection.Create;

finalization
  TSchemaManager.ReleaseInstance;
  TSchemaManager.FInitLock.Free;

end.
