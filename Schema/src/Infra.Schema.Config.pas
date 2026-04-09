unit Infra.Schema.Config;

interface

uses
  System.SysUtils,
  System.IOUtils;

type
  TSchemaConfig = class sealed
  private
    FSchemaBasePath  : string;
    FSchemaExtension : string;
    FCacheEnabled    : Boolean;
    FCacheTTLSeconds : Integer;
    FCacheKeyPrefix  : string;

    constructor Create;
  public
    class function Default: TSchemaConfig;

    { Fluent setters }
    function WithBasePath(const APath: string)        : TSchemaConfig;
    function WithExtension(const AExt: string)        : TSchemaConfig;
    function WithCacheEnabled(AEnabled: Boolean)      : TSchemaConfig;
    function WithCacheTTL(ASeconds: Integer)          : TSchemaConfig;
    function WithCacheKeyPrefix(const APrefix: string): TSchemaConfig;

    { Getters }
    property SchemaBasePath  : string  read FSchemaBasePath;
    property SchemaExtension : string  read FSchemaExtension;
    property CacheEnabled    : Boolean read FCacheEnabled;
    property CacheTTLSeconds : Integer read FCacheTTLSeconds;
    property CacheKeyPrefix  : string  read FCacheKeyPrefix;
  end;

implementation

{ TSchemaConfig }

constructor TSchemaConfig.Create;
begin
  inherited Create;
  FSchemaBasePath  := TPath.Combine(ExtractFilePath(ParamStr(0)), 'schemas');
  FSchemaExtension := '.jsonschema'; // ← ajustado
  FCacheEnabled    := True;
  FCacheTTLSeconds := 300;
  FCacheKeyPrefix  := 'sgq:schema:';
end;

class function TSchemaConfig.Default: TSchemaConfig;
begin
  Result := TSchemaConfig.Create;
end;

function TSchemaConfig.WithBasePath(const APath: string): TSchemaConfig;
begin
  FSchemaBasePath := APath;
  Result := Self;
end;

function TSchemaConfig.WithExtension(const AExt: string): TSchemaConfig;
begin
  FSchemaExtension := AExt;
  Result := Self;
end;

function TSchemaConfig.WithCacheEnabled(AEnabled: Boolean): TSchemaConfig;
begin
  FCacheEnabled := AEnabled;
  Result := Self;
end;

function TSchemaConfig.WithCacheTTL(ASeconds: Integer): TSchemaConfig;
begin
  FCacheTTLSeconds := ASeconds;
  Result := Self;
end;

function TSchemaConfig.WithCacheKeyPrefix(const APrefix: string): TSchemaConfig;
begin
  FCacheKeyPrefix := APrefix;
  Result := Self;
end;

end.
