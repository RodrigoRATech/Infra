unit Infra.Cache.Factory;

interface

uses
  System.Classes, System.SysUtils,
  Infra.Cache.Interfaces, Infra.Cache.Config,
  Infra.Cache.Serializer, Infra.Cache.Manager;

type
  /// <summary>
  ///   Factory centralizada para criação de instâncias do módulo de cache.
  ///   Retorna TCacheManager (classe concreta) para acesso aos generics.
  /// </summary>
  TCacheFactory = class
  private
    class var FDefaultConfig: TCacheConfig;
    class var FDefaultStrategy: ICacheStrategy;
    class var FDefaultSerializer: TCacheSerializer;
    class var FDefaultSerializerIntf: ICacheSerializer;
    class var FDefaultManager: TCacheManager;
    class var FDefaultManagerIntf: ICacheManager;
    class var FDefaultMonitor: ICacheMonitor;
  public
    class procedure Initialize(AConfig: TCacheConfig); overload;
    class procedure Initialize(const AHost: string; APort: Integer); overload;
    class procedure Finalize;

    class function Config: TCacheConfig;
    class function Strategy: ICacheStrategy;
    class function Serializer: TCacheSerializer;
    class function Manager: TCacheManager;
    class function ManagerIntf: ICacheManager;
    class function Monitor: ICacheMonitor;

    class function CreateStrategy(AConfig: TCacheConfig): ICacheStrategy;
    class function CreateManager(AStrategy: ICacheStrategy;
      ASerializer: TCacheSerializer): TCacheManager;
    class function CreateMonitor(AStrategy: ICacheStrategy): ICacheMonitor;
  end;

implementation

uses
  Infra.Cache.Strategy.Redis,
  Infra.Cache.Monitor;

{ TCacheFactory }

class procedure TCacheFactory.Initialize(AConfig: TCacheConfig);
begin
  Finalize;
  FDefaultConfig := AConfig.Clone;
end;

class procedure TCacheFactory.Initialize(const AHost: string; APort: Integer);
var
  LConfig: TCacheConfig;
begin
  LConfig := TCacheConfig.Create;
  try
    LConfig.Host := AHost;
    LConfig.Port := APort;
    Initialize(LConfig);
  finally
    LConfig.Free;
  end;
end;

class procedure TCacheFactory.Finalize;
begin
  FDefaultMonitor := nil;
  FDefaultManagerIntf := nil;
  FDefaultManager := nil;
  FDefaultSerializerIntf := nil;
  FDefaultSerializer := nil;
  FDefaultStrategy := nil;
  FreeAndNil(FDefaultConfig);
end;

class function TCacheFactory.Config: TCacheConfig;
begin
  if not Assigned(FDefaultConfig) then
    raise EInvalidOperation.Create(
      'TCacheFactory não foi inicializada. Chame TCacheFactory.Initialize primeiro.');
  Result := FDefaultConfig;
end;

class function TCacheFactory.Strategy: ICacheStrategy;
begin
  if not Assigned(FDefaultStrategy) then
    FDefaultStrategy := CreateStrategy(Config);
  Result := FDefaultStrategy;
end;

class function TCacheFactory.Serializer: TCacheSerializer;
var
  LSerializer: TCacheSerializer;
begin
  if not Assigned(FDefaultSerializer) then
  begin
    LSerializer := TCacheSerializer.Create;
    // Primeiro armazena a referência de classe
    FDefaultSerializer := LSerializer;
    // Depois armazena a interface para manter a contagem de referência
    // Usa cast explícito para evitar incompatibilidade
    Supports(LSerializer, ICacheSerializer, FDefaultSerializerIntf);
  end;
  Result := FDefaultSerializer;
end;

class function TCacheFactory.Manager: TCacheManager;
var
  LManager: TCacheManager;
begin
  if not Assigned(FDefaultManager) then
  begin
    LManager := CreateManager(Strategy, Serializer);
    FDefaultManager := LManager;
    Supports(LManager, ICacheManager, FDefaultManagerIntf);
  end;
  Result := FDefaultManager;
end;

class function TCacheFactory.ManagerIntf: ICacheManager;
begin
  Manager; // força criação se necessário
  Result := FDefaultManagerIntf;
end;

class function TCacheFactory.Monitor: ICacheMonitor;
begin
  if not Assigned(FDefaultMonitor) then
    FDefaultMonitor := CreateMonitor(Strategy);
  Result := FDefaultMonitor;
end;

class function TCacheFactory.CreateStrategy(AConfig: TCacheConfig): ICacheStrategy;
begin
  Result := TRedisCacheStrategy.Create(AConfig);
end;

class function TCacheFactory.CreateManager(AStrategy: ICacheStrategy;
  ASerializer: TCacheSerializer): TCacheManager;
begin
  Result := TCacheManager.Create(AStrategy, ASerializer);
end;

class function TCacheFactory.CreateMonitor(AStrategy: ICacheStrategy): ICacheMonitor;
begin
  Result := TCacheMonitor.Create(AStrategy);
end;

initialization

finalization
  TCacheFactory.Finalize;

end.
