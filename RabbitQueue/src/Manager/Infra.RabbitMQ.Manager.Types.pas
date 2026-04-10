unit Infra.RabbitMQ.Manager.Types;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  /// <summary>
  /// Estado de uma fila reportado pelo RabbitMQ Management API.
  /// </summary>
  TRabbitQueueState = (rqsRunning, rqsIdle, rqsDown, rqsUnknown);

  /// <summary>
  /// Snapshot de uma fila descoberta via Management API.
  /// Record imutável — sem lógica de negócio.
  /// </summary>
  TRabbitQueueInfo = record
    Name: string;
    VHost: string;
    State: TRabbitQueueState;
    ConsumerCount: Integer;
    MessageReady: Integer;
    MessageUnacked: Integer;
    MessageTotal: Integer;
    Durable: Boolean;
    AutoDelete: Boolean;
    Exclusive: Boolean;
    function IsActive: Boolean;
    function HasMessages: Boolean;
    function StateAsString: string;
    function Summary: string;
  end;

  /// <summary>
  /// Lista tipada de filas descobertas.
  /// </summary>
  TRabbitQueueList = TList<TRabbitQueueInfo>;

  /// <summary>
  /// Resultado de uma operação sobre uma fila (purge, delete).
  /// </summary>
  TQueueOperationResult = record
    QueueName: string;
    Success: Boolean;
    ErrorMessage: string;
    MessagesPurged: Integer;
    class function OK(const AQueueName: string;
      AMessagesPurged: Integer = 0): TQueueOperationResult; static;
    class function Fail(const AQueueName, AError: string): TQueueOperationResult; static;
    function ToString: string;
  end;

  /// <summary>
  /// Resultado em lote para operações sobre múltiplas filas.
  /// </summary>
  TBatchOperationResult = record
    Results: TArray<TQueueOperationResult>;
    TotalProcessed: Integer;
    TotalSuccess: Integer;
    TotalFailed: Integer;
    ElapsedMs: Int64;
    function AllSucceeded: Boolean;
    function FailedQueues: TArray<string>;
    function Summary: string;
  end;

  /// <summary>
  /// Configuração de conexão com a RabbitMQ Management API.
  /// </summary>
  TRabbitManagementConfig = record
    Host: string;
    Port: Integer;
    User: string;
    Password: string;
    VHost: string;
    UseSSL: Boolean;
    TimeoutMs: Integer;
    function BaseURL: string;
    function ApiQueuesURL: string;
    function ApiQueueURL(const AQueueName: string): string;
    function ApiQueuePurgeURL(const AQueueName: string): string;
    class function Default: TRabbitManagementConfig; static;
  end;

  /// <summary>
  /// Filtro aplicável à descoberta de filas.
  /// </summary>
  TQueueDiscoveryFilter = record
    Prefix: string;
    ExcludeEmpty: Boolean;
    ExcludeExclusive: Boolean;
    OnlyDurable: Boolean;
    MinConsumers: Integer;
    class function Default: TQueueDiscoveryFilter; static;
    class function None: TQueueDiscoveryFilter; static;
    function Matches(const AQueue: TRabbitQueueInfo): Boolean;
  end;

implementation

uses
  System.Net.URLClient, System.NetEncoding;

{ TRabbitQueueInfo }

function TRabbitQueueInfo.IsActive: Boolean;
begin
  Result := State in [rqsRunning, rqsIdle];
end;

function TRabbitQueueInfo.HasMessages: Boolean;
begin
  Result := MessageTotal > 0;
end;

function TRabbitQueueInfo.StateAsString: string;
begin
  case State of
    rqsRunning: Result := 'running';
    rqsIdle:    Result := 'idle';
    rqsDown:    Result := 'down';
  else
    Result := 'unknown';
  end;
end;

function TRabbitQueueInfo.Summary: string;
begin
  Result := Format('%s [%s] consumers=%d ready=%d unacked=%d total=%d',
    [Name, StateAsString, ConsumerCount, MessageReady,
     MessageUnacked, MessageTotal]);
end;

{ TQueueOperationResult }

class function TQueueOperationResult.OK(const AQueueName: string;
  AMessagesPurged: Integer): TQueueOperationResult;
begin
  Result.QueueName := AQueueName;
  Result.Success := True;
  Result.ErrorMessage := '';
  Result.MessagesPurged := AMessagesPurged;
end;

class function TQueueOperationResult.Fail(
  const AQueueName, AError: string): TQueueOperationResult;
begin
  Result.QueueName := AQueueName;
  Result.Success := False;
  Result.ErrorMessage := AError;
  Result.MessagesPurged := 0;
end;

function TQueueOperationResult.ToString: string;
begin
  if Success then
    Result := Format('[OK] %s (purged=%d)', [QueueName, MessagesPurged])
  else
    Result := Format('[FAIL] %s: %s', [QueueName, ErrorMessage]);
end;

{ TBatchOperationResult }

function TBatchOperationResult.AllSucceeded: Boolean;
begin
  Result := TotalFailed = 0;
end;

function TBatchOperationResult.FailedQueues: TArray<string>;
var
  LList: TList<string>;
  LItem: TQueueOperationResult;
begin
  LList := TList<string>.Create;
  try
    for LItem in Results do
      if not LItem.Success then
        LList.Add(LItem.QueueName);
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TBatchOperationResult.Summary: string;
begin
  Result := Format('Batch em %dms: total=%d success=%d failed=%d',
    [ElapsedMs, TotalProcessed, TotalSuccess, TotalFailed]);
end;

{ TRabbitManagementConfig }

function TRabbitManagementConfig.BaseURL: string;
var
  LScheme: string;
begin
  if UseSSL then
    LScheme := 'https'
  else
    LScheme := 'http';
  Result := Format('%s://%s:%d', [LScheme, Host, Port]);
end;

function TRabbitManagementConfig.ApiQueuesURL: string;
begin
  Result := Format('%s/api/queues/%s',
    [BaseURL, TNetEncoding.URL.Encode(VHost)]);
end;

function TRabbitManagementConfig.ApiQueueURL(
  const AQueueName: string): string;
begin
  Result := Format('%s/api/queues/%s/%s',
    [BaseURL, TNetEncoding.URL.Encode(VHost),
     TNetEncoding.URL.Encode(AQueueName)]);
end;

function TRabbitManagementConfig.ApiQueuePurgeURL(
  const AQueueName: string): string;
begin
  Result := Format('%s/api/queues/%s/%s/contents',
    [BaseURL, TNetEncoding.URL.Encode(VHost),
     TNetEncoding.URL.Encode(AQueueName)]);
end;

class function TRabbitManagementConfig.Default: TRabbitManagementConfig;
begin
  Result.Host := 'localhost';
  Result.Port := 15672;
  Result.User := 'guest';
  Result.Password := 'guest';
  Result.VHost := '/';
  Result.UseSSL := False;
  Result.TimeoutMs := 5000;
end;

{ TQueueDiscoveryFilter }

class function TQueueDiscoveryFilter.Default: TQueueDiscoveryFilter;
begin
  Result.Prefix := '';
  Result.ExcludeEmpty := False;
  Result.ExcludeExclusive := True;
  Result.OnlyDurable := True;
  Result.MinConsumers := 0;
end;

class function TQueueDiscoveryFilter.None: TQueueDiscoveryFilter;
begin
  Result.Prefix := '';
  Result.ExcludeEmpty := False;
  Result.ExcludeExclusive := False;
  Result.OnlyDurable := False;
  Result.MinConsumers := 0;
end;

function TQueueDiscoveryFilter.Matches(
  const AQueue: TRabbitQueueInfo): Boolean;
begin
  Result := True;

  if (Prefix <> '') and (not AQueue.Name.StartsWith(Prefix, True)) then
    Exit(False);

  if ExcludeEmpty and (not AQueue.HasMessages) and (AQueue.ConsumerCount = 0) then
    Exit(False);

  if ExcludeExclusive and AQueue.Exclusive then
    Exit(False);

  if OnlyDurable and (not AQueue.Durable) then
    Exit(False);

  if AQueue.ConsumerCount < MinConsumers then
    Exit(False);
end;

end.
