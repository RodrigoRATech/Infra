unit Infra.RabbitMQ.Manager.Service;

interface

uses
  System.SysUtils,
  System.JSON,
  System.Diagnostics,
  System.Generics.Collections,
  Infra.RabbitMQ.Manager.Types,
  Infra.RabbitMQ.Manager.Client;

type
  /// <summary>
  /// Callback para log — permite injetar qualquer mecanismo de log
  /// sem depender de interfaces externas.
  /// </summary>
  TLogProc = reference to procedure(const ALevel, AMessage, AContext: string);

  /// <summary>
  /// Serviço de alto nível para operações sobre filas do RabbitMQ.
  /// Encapsula o client HTTP e adiciona lógica de negócio:
  ///   - Descoberta com filtros
  ///   - Purge individual e em lote
  ///   - Delete individual e em lote
  ///   - Logging opcional
  /// </summary>
  TRabbitMQManagementService = class
  strict private
    FClient: TRabbitMQApiClient;
    FOwnsClient: Boolean;
    FOnLog: TLogProc;

    procedure Log(const ALevel, AMessage: string;
      const AContext: string = 'RABBIT.MGMT');
    function ParseQueueState(const AValue: string): TRabbitQueueState;
    function ParseQueueInfo(const AJsonObj: TJSONObject): TRabbitQueueInfo;
  public
    constructor Create(const AConfig: TRabbitManagementConfig); overload;
    constructor Create(AClient: TRabbitMQApiClient;
      AOwnsClient: Boolean = False); overload;
    destructor Destroy; override;

    /// <summary>Callback de log — atribua para receber logs internos.</summary>
    property OnLog: TLogProc read FOnLog write FOnLog;

    // === Descoberta ===

    /// <summary>Testa se a Management API está acessível.</summary>
    function IsAvailable: Boolean;

    /// <summary>Retorna todas as filas do vhost, sem filtro.</summary>
    function FetchAllQueues: TRabbitQueueList;

    /// <summary>Retorna filas filtradas conforme critérios.</summary>
    function FetchQueues(const AFilter: TQueueDiscoveryFilter): TRabbitQueueList;

    /// <summary>Retorna apenas filas ativas (running/idle), sem exclusivas.</summary>
    function FetchActiveQueues: TRabbitQueueList;

    /// <summary>Retorna informações de uma fila específica.</summary>
    function FetchQueue(const AQueueName: string): TRabbitQueueInfo;

    /// <summary>Verifica se uma fila existe.</summary>
    function QueueExists(const AQueueName: string): Boolean;

    // === Purge (limpar mensagens sem remover a fila) ===

    /// <summary>Limpa todas as mensagens de uma fila.</summary>
    function PurgeQueue(const AQueueName: string): TQueueOperationResult;

    /// <summary>Limpa mensagens de múltiplas filas.</summary>
    function PurgeQueues(
      const AQueueNames: TArray<string>): TBatchOperationResult;

    /// <summary>Limpa todas as filas que correspondem ao filtro.</summary>
    function PurgeByFilter(
      const AFilter: TQueueDiscoveryFilter): TBatchOperationResult;

    // === Delete (remover a fila inteira do RabbitMQ) ===

    /// <summary>Remove uma fila do RabbitMQ.</summary>
    function DeleteQueue(const AQueueName: string): TQueueOperationResult;

    /// <summary>Remove múltiplas filas.</summary>
    function DeleteQueues(
      const AQueueNames: TArray<string>): TBatchOperationResult;

    /// <summary>Remove todas as filas que correspondem ao filtro.</summary>
    function DeleteByFilter(
      const AFilter: TQueueDiscoveryFilter): TBatchOperationResult;

    // === Utilitários ===

    /// <summary>Lista nomes de todas as filas ativas.</summary>
    function ListActiveQueueNames: TArray<string>;

    /// <summary>Exibe no log um relatório de todas as filas ativas.</summary>
    procedure PrintQueueReport;
  end;

implementation

{ TRabbitMQManagementService }

constructor TRabbitMQManagementService.Create(
  const AConfig: TRabbitManagementConfig);
begin
  inherited Create;
  FClient := TRabbitMQApiClient.Create(AConfig);
  FOwnsClient := True;
  FOnLog := nil;
end;

constructor TRabbitMQManagementService.Create(
  AClient: TRabbitMQApiClient; AOwnsClient: Boolean);
begin
  inherited Create;
  FClient := AClient;
  FOwnsClient := AOwnsClient;
  FOnLog := nil;
end;

destructor TRabbitMQManagementService.Destroy;
begin
  if FOwnsClient then
    FClient.Free;
  inherited;
end;

procedure TRabbitMQManagementService.Log(
  const ALevel, AMessage, AContext: string);
begin
  if Assigned(FOnLog) then
    FOnLog(ALevel, AMessage, AContext);
end;

function TRabbitMQManagementService.ParseQueueState(
  const AValue: string): TRabbitQueueState;
begin
  if AValue = 'running' then
    Result := rqsRunning
  else if AValue = 'idle' then
    Result := rqsIdle
  else if AValue = 'down' then
    Result := rqsDown
  else
    Result := rqsUnknown;
end;

function TRabbitMQManagementService.ParseQueueInfo(
  const AJsonObj: TJSONObject): TRabbitQueueInfo;
begin
  Result := Default(TRabbitQueueInfo);
  Result.Name := AJsonObj.GetValue<string>('name', '');
  Result.VHost := AJsonObj.GetValue<string>('vhost', '/');
  Result.State := ParseQueueState(AJsonObj.GetValue<string>('state', 'unknown'));
  Result.ConsumerCount := AJsonObj.GetValue<Integer>('consumers', 0);
  Result.MessageReady := AJsonObj.GetValue<Integer>('messages_ready', 0);
  Result.MessageUnacked := AJsonObj.GetValue<Integer>('messages_unacknowledged', 0);
  Result.MessageTotal := AJsonObj.GetValue<Integer>('messages', 0);
  Result.Durable := AJsonObj.GetValue<Boolean>('durable', False);
  Result.AutoDelete := AJsonObj.GetValue<Boolean>('auto_delete', False);
  Result.Exclusive := AJsonObj.GetValue<Boolean>('exclusive', False);
end;

// === Descoberta ===

function TRabbitMQManagementService.IsAvailable: Boolean;
begin
  Result := FClient.TestConnection;
end;

function TRabbitMQManagementService.FetchAllQueues: TRabbitQueueList;
var
  LJsonArray: TJSONArray;
  I: Integer;
begin
  Result := TRabbitQueueList.Create;
  LJsonArray := FClient.FetchQueuesJSON;
  try
    for I := 0 to LJsonArray.Count - 1 do
      Result.Add(ParseQueueInfo(LJsonArray.Items[I] as TJSONObject));

    Log('INFO', Format('%d filas carregadas do RabbitMQ', [Result.Count]));
  finally
    LJsonArray.Free;
  end;
end;

function TRabbitMQManagementService.FetchQueues(
  const AFilter: TQueueDiscoveryFilter): TRabbitQueueList;
var
  LAll: TRabbitQueueList;
  LQueue: TRabbitQueueInfo;
begin
  Result := TRabbitQueueList.Create;
  LAll := FetchAllQueues;
  try
    for LQueue in LAll do
      if AFilter.Matches(LQueue) then
        Result.Add(LQueue);

    Log('INFO', Format('%d filas após filtro (de %d total)',
      [Result.Count, LAll.Count]));
  finally
    LAll.Free;
  end;
end;

function TRabbitMQManagementService.FetchActiveQueues: TRabbitQueueList;
var
  LFilter: TQueueDiscoveryFilter;
begin
  LFilter := TQueueDiscoveryFilter.Default;
  Result := FetchQueues(LFilter);
end;

function TRabbitMQManagementService.FetchQueue(
  const AQueueName: string): TRabbitQueueInfo;
var
  LJson: TJSONObject;
begin
  LJson := FClient.FetchQueueJSON(AQueueName);
  try
    Result := ParseQueueInfo(LJson);
  finally
    LJson.Free;
  end;
end;

function TRabbitMQManagementService.QueueExists(
  const AQueueName: string): Boolean;
begin
  try
    FetchQueue(AQueueName);
    Result := True;
  except
    Result := False;
  end;
end;

// === Purge ===

function TRabbitMQManagementService.PurgeQueue(
  const AQueueName: string): TQueueOperationResult;
var
  LInfo: TRabbitQueueInfo;
  LMsgCount: Integer;
begin
  try
    LInfo := FetchQueue(AQueueName);
    LMsgCount := LInfo.MessageTotal;

    if FClient.PurgeQueue(AQueueName) then
    begin
      Result := TQueueOperationResult.OK(AQueueName, LMsgCount);
      Log('INFO', Format('Purge OK: %s (%d mensagens removidas)',
        [AQueueName, LMsgCount]));
    end
    else
    begin
      Result := TQueueOperationResult.Fail(AQueueName,
        'API retornou status inesperado');
      Log('ERROR', Format('Purge FALHOU: %s', [AQueueName]));
    end;
  except
    on E: Exception do
    begin
      Result := TQueueOperationResult.Fail(AQueueName, E.Message);
      Log('ERROR', Format('Purge ERRO: %s - %s', [AQueueName, E.Message]));
    end;
  end;
end;

function TRabbitMQManagementService.PurgeQueues(
  const AQueueNames: TArray<string>): TBatchOperationResult;
var
  LStopwatch: TStopwatch;
  LResults: TList<TQueueOperationResult>;
  LName: string;
  LOpResult: TQueueOperationResult;
begin
  LStopwatch := TStopwatch.StartNew;
  LResults := TList<TQueueOperationResult>.Create;
  try
    Result.TotalSuccess := 0;
    Result.TotalFailed := 0;

    for LName in AQueueNames do
    begin
      LOpResult := PurgeQueue(LName);
      LResults.Add(LOpResult);

      if LOpResult.Success then
        Inc(Result.TotalSuccess)
      else
        Inc(Result.TotalFailed);
    end;

    Result.Results := LResults.ToArray;
    Result.TotalProcessed := Length(AQueueNames);
    LStopwatch.Stop;
    Result.ElapsedMs := LStopwatch.ElapsedMilliseconds;

    Log('INFO', Result.Summary);
  finally
    LResults.Free;
  end;
end;

function TRabbitMQManagementService.PurgeByFilter(
  const AFilter: TQueueDiscoveryFilter): TBatchOperationResult;
var
  LQueues: TRabbitQueueList;
  LNames: TList<string>;
  LQueue: TRabbitQueueInfo;
begin
  LQueues := FetchQueues(AFilter);
  LNames := TList<string>.Create;
  try
    for LQueue in LQueues do
      LNames.Add(LQueue.Name);

    Log('INFO', Format('Purge por filtro: %d filas selecionadas',
      [LNames.Count]));

    Result := PurgeQueues(LNames.ToArray);
  finally
    LNames.Free;
    LQueues.Free;
  end;
end;

// === Delete ===

function TRabbitMQManagementService.DeleteQueue(
  const AQueueName: string): TQueueOperationResult;
begin
  try
    if FClient.DeleteQueue(AQueueName) then
    begin
      Result := TQueueOperationResult.OK(AQueueName);
      Log('INFO', Format('Delete OK: %s', [AQueueName]));
    end
    else
    begin
      Result := TQueueOperationResult.Fail(AQueueName,
        'API retornou status inesperado');
      Log('ERROR', Format('Delete FALHOU: %s', [AQueueName]));
    end;
  except
    on E: Exception do
    begin
      Result := TQueueOperationResult.Fail(AQueueName, E.Message);
      Log('ERROR', Format('Delete ERRO: %s - %s', [AQueueName, E.Message]));
    end;
  end;
end;

function TRabbitMQManagementService.DeleteQueues(
  const AQueueNames: TArray<string>): TBatchOperationResult;
var
  LStopwatch: TStopwatch;
  LResults: TList<TQueueOperationResult>;
  LName: string;
  LOpResult: TQueueOperationResult;
begin
  LStopwatch := TStopwatch.StartNew;
  LResults := TList<TQueueOperationResult>.Create;
  try
    Result.TotalSuccess := 0;
    Result.TotalFailed := 0;

    for LName in AQueueNames do
    begin
      LOpResult := DeleteQueue(LName);
      LResults.Add(LOpResult);

      if LOpResult.Success then
        Inc(Result.TotalSuccess)
      else
        Inc(Result.TotalFailed);
    end;

    Result.Results := LResults.ToArray;
    Result.TotalProcessed := Length(AQueueNames);
    LStopwatch.Stop;
    Result.ElapsedMs := LStopwatch.ElapsedMilliseconds;

    Log('INFO', Result.Summary);
  finally
    LResults.Free;
  end;
end;

function TRabbitMQManagementService.DeleteByFilter(
  const AFilter: TQueueDiscoveryFilter): TBatchOperationResult;
var
  LQueues: TRabbitQueueList;
  LNames: TList<string>;
  LQueue: TRabbitQueueInfo;
begin
  LQueues := FetchQueues(AFilter);
  LNames := TList<string>.Create;
  try
    for LQueue in LQueues do
      LNames.Add(LQueue.Name);

    Log('INFO', Format('Delete por filtro: %d filas selecionadas',
      [LNames.Count]));

    Result := DeleteQueues(LNames.ToArray);
  finally
    LNames.Free;
    LQueues.Free;
  end;
end;

// === Utilitários ===

function TRabbitMQManagementService.ListActiveQueueNames: TArray<string>;
var
  LQueues: TRabbitQueueList;
  LNames: TList<string>;
  LQueue: TRabbitQueueInfo;
begin
  LQueues := FetchActiveQueues;
  LNames := TList<string>.Create;
  try
    for LQueue in LQueues do
      LNames.Add(LQueue.Name);
    Result := LNames.ToArray;
  finally
    LNames.Free;
    LQueues.Free;
  end;
end;

procedure TRabbitMQManagementService.PrintQueueReport;
var
  LQueues: TRabbitQueueList;
  LQueue: TRabbitQueueInfo;
  LTotalMsgs: Integer;
begin
  LQueues := FetchActiveQueues;
  try
    LTotalMsgs := 0;

    Log('INFO', '');
    Log('INFO', '╔══════════════════════════════════════════════════════════════════════════════════╗');
    Log('INFO', '║                         RABBITMQ QUEUE REPORT                                   ║');
    Log('INFO', '╠══════════════════════════════════════════════════════════════════════════════════╣');
    Log('INFO', Format('║ %-40s │ %-8s │ %-5s │ %-7s │ %-7s ║',
      ['QUEUE', 'STATE', 'CONS', 'READY', 'UNACKED']));
    Log('INFO', '╠══════════════════════════════════════════════════════════════════════════════════╣');

    for LQueue in LQueues do
    begin
      Log('INFO', Format('║ %-40s │ %-8s │ %5d │ %7d │ %7d ║',
        [LQueue.Name, LQueue.StateAsString, LQueue.ConsumerCount,
         LQueue.MessageReady, LQueue.MessageUnacked]));
      Inc(LTotalMsgs, LQueue.MessageTotal);
    end;

    Log('INFO', '╠══════════════════════════════════════════════════════════════════════════════════╣');
    Log('INFO', Format('║ TOTAL: %d filas | %d mensagens                                              ║',
      [LQueues.Count, LTotalMsgs]));
    Log('INFO', '╚══════════════════════════════════════════════════════════════════════════════════╝');
    Log('INFO', '');
  finally
    LQueues.Free;
  end;
end;

end.
