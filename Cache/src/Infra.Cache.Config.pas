unit Infra.Cache.Config;

interface

type
  TCacheConfig = class
  private
    FHost: string;
    FPort: Integer;
    FConnectionTimeout: Integer;
    FReadTimeout: Integer;
    FDefaultTTLSeconds: Integer;
    FMaxRetries: Integer;
    FRetryIntervalMs: Integer;
    FWatchdogIntervalMs: Integer;
    FPurgeIntervalMs: Integer;
    FKeyPrefix: string;
    FFallbackEnabled: Boolean;
  public
    constructor Create;

    property Host: string read FHost write FHost;
    property Port: Integer read FPort write FPort;
    property ConnectionTimeout: Integer read FConnectionTimeout write FConnectionTimeout;
    property ReadTimeout: Integer read FReadTimeout write FReadTimeout;
    property DefaultTTLSeconds: Integer read FDefaultTTLSeconds write FDefaultTTLSeconds;
    property MaxRetries: Integer read FMaxRetries write FMaxRetries;
    property RetryIntervalMs: Integer read FRetryIntervalMs write FRetryIntervalMs;
    property WatchdogIntervalMs: Integer read FWatchdogIntervalMs write FWatchdogIntervalMs;
    property PurgeIntervalMs: Integer read FPurgeIntervalMs write FPurgeIntervalMs;
    property KeyPrefix: string read FKeyPrefix write FKeyPrefix;
    property FallbackEnabled: Boolean read FFallbackEnabled write FFallbackEnabled;

    function Clone: TCacheConfig;
    function Validate: Boolean;
    function GetFullKey(const AKey: string): string;
  end;

implementation

uses
  System.SysUtils;

{ TCacheConfig }

constructor TCacheConfig.Create;
begin
  inherited Create;
  FHost := '127.0.0.1';
  FPort := 6379;
  FConnectionTimeout := 3000;
  FReadTimeout := 3000;
  FDefaultTTLSeconds := 300; // 5 minutos
  FMaxRetries := 3;
  FRetryIntervalMs := 1000;
  FWatchdogIntervalMs := 10000; // 10 segundos
  FPurgeIntervalMs := 60000;   // 1 minuto
  FKeyPrefix := 'app:cache:';
  FFallbackEnabled := True;
end;

function TCacheConfig.Clone: TCacheConfig;
begin
  Result := TCacheConfig.Create;
  Result.FHost := FHost;
  Result.FPort := FPort;
  Result.FConnectionTimeout := FConnectionTimeout;
  Result.FReadTimeout := FReadTimeout;
  Result.FDefaultTTLSeconds := FDefaultTTLSeconds;
  Result.FMaxRetries := FMaxRetries;
  Result.FRetryIntervalMs := FRetryIntervalMs;
  Result.FWatchdogIntervalMs := FWatchdogIntervalMs;
  Result.FPurgeIntervalMs := FPurgeIntervalMs;
  Result.FKeyPrefix := FKeyPrefix;
  Result.FFallbackEnabled := FFallbackEnabled;
end;

function TCacheConfig.Validate: Boolean;
begin
  Result := (not FHost.IsEmpty) and (FPort > 0) and (FPort < 65536)
    and (FDefaultTTLSeconds > 0) and (FMaxRetries >= 0);
end;

function TCacheConfig.GetFullKey(const AKey: string): string;
begin
  Result := FKeyPrefix + AKey;
end;

end.
