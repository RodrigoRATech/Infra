unit RabbitMQ.Management.Startup;

interface

uses
  System.SysUtils,
  System.Diagnostics,
  System.Generics.Collections,
  RabbitMQ.Management.Types,
  RabbitMQ.Management.Service;

type
  /// <summary>
  /// Resultado do processo de startup.
  /// </summary>
  TStartupResult = record
    Available: Boolean;
    Queues: TArray<TRabbitQueueInfo>;
    QueueCount: Integer;
    ElapsedMs: Int64;
    ErrorMessage: string;
    function Success: Boolean;
    function Summary: string;
  end;

  /// <summary>
  /// Callback invocado para cada fila descoberta durante o startup.
  /// Retorne True para indicar que a fila foi processada, False para ignorar.
  /// </summary>
  TQueueStartupCallback = reference to function(
    const AQueue: TRabbitQueueInfo): Boolean;

  /// <summary>
  /// Responsável por carregar filas ativas do RabbitMQ na inicialização
  /// de um microserviço. Aguarda disponibilidade do broker com retry,
  /// descobre filas, aplica filtros e notifica via callback.
  ///
  /// Totalmente isolado — não depende de nenhuma outra unit do projeto.
  /// </summary>
  TRabbitMQStartup = class
  strict private
    FService: TRabbitMQManagementService;
    FOwnsService: Boolean;
    FFilter: TQueueDiscoveryFilter;
    FMaxRetries: Integer;
    FRetryDelayMs: Integer;
    FOnLog: TLogProc;

    procedure Log(const ALevel, AMessage: string;
      const AContext: string = 'STARTUP');
    function WaitForBroker: Boolean;
  public
    constructor Create(const AConfig: TRabbitManagementConfig); overload;
    constructor Create(AService: TRabbitMQManagementService;
      AOwnsService: Boolean = False); overload;
    destructor Destroy; override;

    /// <summary>Filtro a ser aplicado na descoberta. Default = TQueueDiscoveryFilter.Default.</summary>
    property Filter: TQueueDiscoveryFilter read FFilter write FFilter;
    /// <summary>Tentativas máximas de conexão ao broker. Default = 10.</summary>
    property MaxRetries: Integer read FMaxRetries write FMaxRetries;
    /// <summary>Delay entre tentativas em milissegundos. Default = 3000.</summary>
    property RetryDelayMs: Integer read FRetryDelayMs write FRetryDelayMs;
    /// <summary>Callback de log.</summary>
    property OnLog: TLogProc read FOnLog write FOnLog;

    /// <summary>
    /// Executa o startup completo:
    /// 1. Aguarda broker disponível
    /// 2. Descobre filas com filtro
    /// 3. Retorna resultado com lista de filas
    /// </summary>
    function Execute: TStartupResult;

    /// <summary>
    /// Executa o startup e invoca callback para cada fila descoberta.
    /// Útil para registrar consumers/handlers dinamicamente.
    /// </summary>
    function ExecuteWithCallback(
      ACallback: TQueueStartupCallback): TStartupResult;
  end;

implementation

{ TStartupResult }

function TStartupResult.Success: Boolean;
begin
  Result := Available and (ErrorMessage = '');
end;

function TStartupResult.Summary: string;
begin
  if Success then
    Result := Format('Startup OK em %dms: %d filas ativas',
      [ElapsedMs, QueueCount])
  else
    Result := Format('Startup FALHOU em %dms: %s',
      [ElapsedMs, ErrorMessage]);
end;

{ TRabbitMQStartup }

constructor TRabbitMQStartup.Create(
  const AConfig: TRabbitManagementConfig);
begin
  inherited Create;
  FService := TRabbitMQManagementService.Create(AConfig);
  FOwnsService := True;
  FFilter := TQueueDiscoveryFilter.Default;
  FMaxRetries := 10;
  FRetryDelayMs := 3000;
  FOnLog := nil;
end;

constructor TRabbitMQStartup.Create(
  AService: TRabbitMQManagementService; AOwnsService: Boolean);
begin
  inherited Create;
  FService := AService;
  FOwnsService := AOwnsService;
  FFilter := TQueueDiscoveryFilter.Default;
  FMaxRetries := 10;
  FRetryDelayMs := 3000;
  FOnLog := nil;
end;

destructor TRabbitMQStartup.Destroy;
begin
  if FOwnsService then
    FService.Free;
  inherited;
end;

procedure TRabbitMQStartup.Log(
  const ALevel, AMessage, AContext: string);
begin
  if Assigned(FOnLog) then
    FOnLog(ALevel, AMessage, AContext);
end;

function TRabbitMQStartup.WaitForBroker: Boolean;
var
  I: Integer;
begin
  Result := False;
  Log('INFO', Format('Aguardando RabbitMQ (max %d tentativas, delay %dms)...',
    [FMaxRetries, FRetryDelayMs]));

  for I := 1 to FMaxRetries do
  begin
    if FService.IsAvailable then
    begin
      Log('INFO', Format('RabbitMQ disponível (tentativa %d/%d)',
        [I, FMaxRetries]));
      Exit(True);
    end;

    Log('WARN', Format('RabbitMQ indisponível (%d/%d), aguardando...',
      [I, FMaxRetries]));

    if I < FMaxRetries then
      Sleep(FRetryDelayMs);
  end;

  Log('ERROR', Format('RabbitMQ não respondeu após %d tentativas',
    [FMaxRetries]));
end;

function TRabbitMQStartup.Execute: TStartupResult;
var
  LStopwatch: TStopwatch;
  LQueues: TRabbitQueueList;
  I: Integer;
begin
  Result := Default(TStartupResult);
  LStopwatch := TStopwatch.StartNew;

  try
    Log('INFO', '════════════════════════════════════════════');
    Log('INFO', '  RABBITMQ STARTUP - DESCOBERTA DE FILAS   ');
    Log('INFO', '════════════════════════════════════════════');

    { 1. Aguarda broker }
    Result.Available := WaitForBroker;
    if not Result.Available then
    begin
      Result.ErrorMessage := 'RabbitMQ Management API indisponível';
      LStopwatch.Stop;
      Result.ElapsedMs := LStopwatch.ElapsedMilliseconds;
      Exit;
    end;

    { 2. Descobre filas }
    LQueues := FService.FetchQueues(FFilter);
    try
      Result.QueueCount := LQueues.Count;
      SetLength(Result.Queues, LQueues.Count);
      for I := 0 to LQueues.Count - 1 do
        Result.Queues[I] := LQueues[I];

      { 3. Exibe relatório }
      FService.OnLog := FOnLog;
      FService.PrintQueueReport;

      Log('INFO', Format('%d filas ativas descobertas', [LQueues.Count]));
    finally
      LQueues.Free;
    end;

    LStopwatch.Stop;
    Result.ElapsedMs := LStopwatch.ElapsedMilliseconds;
    Log('INFO', Result.Summary);
    Log('INFO', '════════════════════════════════════════════');

  except
    on E: Exception do
    begin
      LStopwatch.Stop;
      Result.ElapsedMs := LStopwatch.ElapsedMilliseconds;
      Result.ErrorMessage := E.Message;
      Log('ERROR', 'Startup falhou: ' + E.Message);
    end;
  end;
end;

function TRabbitMQStartup.ExecuteWithCallback(
  ACallback: TQueueStartupCallback): TStartupResult;
var
  LQueue: TRabbitQueueInfo;
  LProcessed, LIgnored: Integer;
begin
  Result := Execute;

  if not Result.Success then
    Exit;

  LProcessed := 0;
  LIgnored := 0;

  Log('INFO', 'Processando filas via callback...');

  for LQueue in Result.Queues do
  begin
    try
      if ACallback(LQueue) then
      begin
        Inc(LProcessed);
        Log('INFO', Format('  [OK] %s', [LQueue.Name]));
      end
      else
      begin
        Inc(LIgnored);
        Log('INFO', Format('  [SKIP] %s', [LQueue.Name]));
      end;
    except
      on E: Exception do
      begin
        Inc(LIgnored);
        Log('ERROR', Format('  [ERRO] %s: %s', [LQueue.Name, E.Message]));
      end;
    end;
  end;

  Log('INFO', Format('Callback concluído: %d processadas, %d ignoradas',
    [LProcessed, LIgnored]));
end;

end.
