unit RabbitQueue.Core;

interface

uses
  RabbitQueue.Interfaces,
  RabbitQueue.Types,
  RabbitQueue.Connection,
  RabbitQueue.Worker,
  System.SysUtils,
  System.SyncObjs,
  System.Generics.Collections;

type
  TRabbitQueue = class(TInterfacedObject, IRabbitQueue)
  strict private
    FConnection  : IRabbitConnection;
    FWorker      : IRabbitQueueWorker;  // ✅ Interface — enxerga IsRunning e gerencia memória
    FHandlers    : TList<IRabbitQueueHandler>;
    FQueueNames  : TList<string>;
    FLock        : TCriticalSection;
    FPrefetch    : Integer;

    // Eventos de fila
    FOnEnqueue    : TOnEnqueue;
    FOnDequeue    : TOnDequeue;
    FOnQueueEmpty : TOnQueueEmpty;
    FOnQueueError : TOnQueueError;

    // Eventos de processamento
    FOnBeforeProcess : TOnBeforeProcess;
    FOnAfterProcess  : TOnAfterProcess;
    FOnProcessError  : TOnProcessError;

    procedure EnsureWorkerStopped(const AOperation: string);
    procedure SyncWorkerEvents;
  public
    constructor Create(const AConfig: TRabbitConnectionConfig);
    destructor Destroy; override;

    // IRabbitQueue — Handlers
    function RegisterHandler(
      const AHandler: IRabbitQueueHandler): IRabbitQueue;
    function UnregisterHandler(
      const AHandlerName: string): IRabbitQueue;

    // IRabbitQueue — Operações
    function Enqueue(const AQueueName, ABody: string;
      const APriority: TQueuePriority = qpNormal): IRabbitQueue;
    procedure Dequeue(const AQueueName: string);
    procedure Purge(const AQueueName: string);

    // IRabbitQueue — Ciclo de vida
    procedure Start;
    procedure Stop;

    // IRabbitQueue — Eventos de fila
    procedure SetOnEnqueue(const AEvent: TOnEnqueue);
    procedure SetOnDequeue(const AEvent: TOnDequeue);
    procedure SetOnQueueEmpty(const AEvent: TOnQueueEmpty);
    procedure SetOnQueueError(const AEvent: TOnQueueError);

    // IRabbitQueue — Eventos de processamento
    procedure SetOnBeforeProcess(const AEvent: TOnBeforeProcess);
    procedure SetOnAfterProcess(const AEvent: TOnAfterProcess);
    procedure SetOnProcessError(const AEvent: TOnProcessError);

    // IRabbitQueue — Fluent Config
    function WithQueue(const AQueueName: string): IRabbitQueue;
    function WithPrefetch(const ACount: Integer): IRabbitQueue;
  end;

implementation

{ TRabbitQueue }

constructor TRabbitQueue.Create(const AConfig: TRabbitConnectionConfig);
begin
  inherited Create;
  FHandlers   := TList<IRabbitQueueHandler>.Create;
  FQueueNames := TList<string>.Create;
  FLock       := TCriticalSection.Create;
  FPrefetch   := 1;
  FWorker     := nil;
  FConnection := TRabbitConnection.Create(AConfig);
end;

destructor TRabbitQueue.Destroy;
begin
  Stop;
  // ✅ Interface: basta atribuir nil — ref count libera automaticamente
  FWorker := nil;
  FHandlers.Free;
  FQueueNames.Free;
  FLock.Free;
  // FConnection é interface — liberada por ref count
  inherited;
end;

procedure TRabbitQueue.EnsureWorkerStopped(const AOperation: string);
begin
  if Assigned(FWorker) and FWorker.IsRunning then
    raise EQueueException.CreateFmt(
      'Operação "%s" não permitida com o worker em execução. ' +
      'Chame Stop() antes.', [AOperation]);
end;

procedure TRabbitQueue.SyncWorkerEvents;
begin
  if not Assigned(FWorker) then
    Exit;

  FWorker.SetOnBeforeProcess(FOnBeforeProcess);
  FWorker.SetOnAfterProcess(FOnAfterProcess);
  FWorker.SetOnProcessError(FOnProcessError);

  // Eventos internos do worker (callbacks do Core)
  // Cast para acessar os métodos extras não expostos na IRabbitQueueWorker
  (FWorker as TRabbitQueueWorker).SetOnDequeue(FOnDequeue);
  (FWorker as TRabbitQueueWorker).SetOnQueueEmpty(FOnQueueEmpty);
  (FWorker as TRabbitQueueWorker).SetOnQueueError(FOnQueueError);
end;

function TRabbitQueue.RegisterHandler(
  const AHandler: IRabbitQueueHandler): IRabbitQueue;
begin
  FLock.Acquire;
  try
    FHandlers.Add(AHandler);
  finally
    FLock.Release;
  end;
  Result := Self;
end;

function TRabbitQueue.UnregisterHandler(
  const AHandlerName: string): IRabbitQueue;
var
  I: Integer;
begin
  FLock.Acquire;
  try
    for I := FHandlers.Count - 1 downto 0 do
      if SameText(FHandlers[I].HandlerName, AHandlerName) then
      begin
        FHandlers.Delete(I);
        Break;
      end;
  finally
    FLock.Release;
  end;
  Result := Self;
end;

function TRabbitQueue.Enqueue(const AQueueName, ABody: string;
  const APriority: TQueuePriority): IRabbitQueue;
var
  LItem: TQueueItemInfo;
begin
  FConnection.Send(AQueueName, ABody, APriority);

  if Assigned(FOnEnqueue) then
  begin
    LItem.MessageId  := '';
    LItem.Queue      := AQueueName;
    LItem.Body       := ABody;
    LItem.Priority   := APriority;
    LItem.RetryCount := 0;
    LItem.EnqueuedAt := Now;
    LItem.Status     := qisWaiting;
    FOnEnqueue(LItem);
  end;

  Result := Self;
end;

procedure TRabbitQueue.Dequeue(const AQueueName: string);
var
  LItem: TQueueItemInfo;
begin
  LItem := FConnection.Receive(AQueueName);

  if not LItem.MessageId.IsEmpty then
  begin
    if Assigned(FOnDequeue) then
      FOnDequeue(LItem);
  end;
end;

procedure TRabbitQueue.Purge(const AQueueName: string);
var
  LItem: TQueueItemInfo;
begin
  repeat
    LItem := FConnection.Receive(AQueueName, 200);
    if not LItem.MessageId.IsEmpty then
      FConnection.Ack(LItem.MessageId);
  until LItem.MessageId.IsEmpty;
end;

procedure TRabbitQueue.Start;
begin
  FLock.Acquire;
  try
    if Assigned(FWorker) and FWorker.IsRunning then
      Exit;

    // ✅ Atribuição nil via interface — ref count destrói instância anterior
    FWorker := nil;

    FWorker := TRabbitQueueWorker.Create(
      FConnection,
      FHandlers,
      FQueueNames,
      FPrefetch
    );

    SyncWorkerEvents;
    FWorker.Start;
  finally
    FLock.Release;
  end;
end;

procedure TRabbitQueue.Stop;
begin
  FLock.Acquire;
  try
    if Assigned(FWorker) then
      FWorker.Stop;
  finally
    FLock.Release;
  end;
end;

procedure TRabbitQueue.SetOnEnqueue(const AEvent: TOnEnqueue);
begin
  FOnEnqueue := AEvent;
end;

procedure TRabbitQueue.SetOnDequeue(const AEvent: TOnDequeue);
begin
  FOnDequeue := AEvent;
  SyncWorkerEvents;
end;

procedure TRabbitQueue.SetOnQueueEmpty(const AEvent: TOnQueueEmpty);
begin
  FOnQueueEmpty := AEvent;
  SyncWorkerEvents;
end;

procedure TRabbitQueue.SetOnQueueError(const AEvent: TOnQueueError);
begin
  FOnQueueError := AEvent;
  SyncWorkerEvents;
end;

procedure TRabbitQueue.SetOnBeforeProcess(const AEvent: TOnBeforeProcess);
begin
  FOnBeforeProcess := AEvent;
  SyncWorkerEvents;
end;

procedure TRabbitQueue.SetOnAfterProcess(const AEvent: TOnAfterProcess);
begin
  FOnAfterProcess := AEvent;
  SyncWorkerEvents;
end;

procedure TRabbitQueue.SetOnProcessError(const AEvent: TOnProcessError);
begin
  FOnProcessError := AEvent;
  SyncWorkerEvents;
end;

function TRabbitQueue.WithQueue(const AQueueName: string): IRabbitQueue;
begin
  FLock.Acquire;
  try
    if not FQueueNames.Contains(AQueueName) then
      FQueueNames.Add(AQueueName);
  finally
    FLock.Release;
  end;
  Result := Self;
end;

function TRabbitQueue.WithPrefetch(const ACount: Integer): IRabbitQueue;
begin
  FPrefetch := ACount;
  Result    := Self;
end;

end.
