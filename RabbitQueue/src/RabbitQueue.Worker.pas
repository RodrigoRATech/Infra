unit RabbitQueue.Worker;

{
  AUDITORIA: Corrigido deadlock em Start()
  - Problema: FLock.Acquire chamado duas vezes sem Release intermediário
  - Correção: uso de try/finally correto em Start()
  - Corrigido: acesso a FConnection.Config dentro do except
    (era feito fora do lock, potencial race condition)
}

interface

uses
  RabbitQueue.Interfaces,
  RabbitQueue.Types,
  System.Classes,
  System.SysUtils,
  System.SyncObjs,
  System.Generics.Collections;

type
  TRabbitQueueWorker = class(TInterfacedObject, IRabbitQueueWorker)
  strict private type
    TWorkerThread = class(TThread)
    strict private
      FOwner: TRabbitQueueWorker;
    protected
      procedure Execute; override;
    public
      constructor Create(AOwner: TRabbitQueueWorker);
    end;

  strict private
    FThread        : TWorkerThread;
    FConnection    : IRabbitConnection;
    FHandlers      : TList<IRabbitQueueHandler>;
    FQueueNames    : TList<string>;
    FLock          : TCriticalSection;
    FIsRunning     : Boolean;
    FPrefetchCount : Integer;
    FMaxRetries    : Integer;  // cacheado na construção — evita acesso ao Config em threads

    FOnBeforeProcess : TOnBeforeProcess;
    FOnAfterProcess  : TOnAfterProcess;
    FOnProcessError  : TOnProcessError;
    FOnDequeue       : TOnDequeue;
    FOnQueueEmpty    : TOnQueueEmpty;
    FOnQueueError    : TOnQueueError;

    procedure ProcessQueue(const AQueueName: string);
    function  FindHandler(const AQueueName: string): IRabbitQueueHandler;
    procedure DoProcess(const AItem: TQueueItemInfo);
    procedure SafeFireBeforeProcess(const AItem: TQueueItemInfo);
    procedure SafeFireAfterProcess(const AItem: TQueueItemInfo;
      const AResult: TProcessResult);
    procedure SafeFireQueueError(const AQueueName: string;
      const AError: Exception);
  public
    constructor Create(
      const AConnection  : IRabbitConnection;
      const AHandlers    : TList<IRabbitQueueHandler>;
      const AQueueNames  : TList<string>;
      const APrefetch    : Integer
    );
    destructor Destroy; override;

    function  GetIsRunning: Boolean;
    procedure Start;
    procedure Stop;
    procedure SetOnBeforeProcess(const AEvent: TOnBeforeProcess);
    procedure SetOnAfterProcess(const AEvent: TOnAfterProcess);
    procedure SetOnProcessError(const AEvent: TOnProcessError);
    procedure SetOnDequeue(const AEvent: TOnDequeue);
    procedure SetOnQueueEmpty(const AEvent: TOnQueueEmpty);
    procedure SetOnQueueError(const AEvent: TOnQueueError);
  end;

implementation

{ TRabbitQueueWorker.TWorkerThread }

constructor TRabbitQueueWorker.TWorkerThread.Create(AOwner: TRabbitQueueWorker);
begin
  inherited Create(True);
  FOwner          := AOwner;
  FreeOnTerminate := False;
end;

procedure TRabbitQueueWorker.TWorkerThread.Execute;
var
  LQueueName: string;
  LQueueSnapshot: TArray<string>;
  I: Integer;
begin
  while not Terminated do
  begin
    // Copia snapshot das filas para não manter o lock durante IO de rede
    FOwner.FLock.Acquire;
    try
      LQueueSnapshot := FOwner.FQueueNames.ToArray;
    finally
      FOwner.FLock.Release;
    end;

    if Length(LQueueSnapshot) = 0 then
    begin
      Sleep(100);
      Continue;
    end;

    for I := 0 to High(LQueueSnapshot) do
    begin
      if Terminated then
        Break;
      FOwner.ProcessQueue(LQueueSnapshot[I]);
    end;

    Sleep(10);
  end;
end;

{ TRabbitQueueWorker }

constructor TRabbitQueueWorker.Create(
  const AConnection : IRabbitConnection;
  const AHandlers   : TList<IRabbitQueueHandler>;
  const AQueueNames : TList<string>;
  const APrefetch   : Integer);
begin
  inherited Create;
  FConnection    := AConnection;
  FHandlers      := AHandlers;
  FQueueNames    := AQueueNames;
  FPrefetchCount := APrefetch;
  FMaxRetries    := AConnection.Config.MaxRetries; // cache — thread-safe
  FLock          := TCriticalSection.Create;
  FIsRunning     := False;
end;

destructor TRabbitQueueWorker.Destroy;
begin
  Stop;
  FLock.Free;
  inherited;
end;

procedure TRabbitQueueWorker.Start;
begin
  FLock.Acquire;
  try
    // ✅ CORREÇÃO: try/finally correto — lock liberado em qualquer saída.
    // Bug anterior: FLock.Acquire chamado 2x sem Release → deadlock garantido.
    if FIsRunning then
      Exit;

    FConnection.Connect;

    FThread := TWorkerThread.Create(Self);
    FThread.Start;
    FIsRunning := True;
  finally
    FLock.Release; // ← era FLock.Acquire no código original (BUG CRÍTICO)
  end;
end;

procedure TRabbitQueueWorker.Stop;
begin
  FLock.Acquire;
  try
    if not FIsRunning then
      Exit;

    if Assigned(FThread) then
    begin
      FThread.Terminate;
      FThread.WaitFor;
      FreeAndNil(FThread);
    end;

    FConnection.Disconnect;
    FIsRunning := False;
  finally
    FLock.Release;
  end;
end;

function TRabbitQueueWorker.GetIsRunning: Boolean;
begin
  FLock.Acquire;
  try
    Result := FIsRunning;
  finally
    FLock.Release;
  end;
end;

procedure TRabbitQueueWorker.SetOnBeforeProcess(const AEvent: TOnBeforeProcess);
begin
  FOnBeforeProcess := AEvent;
end;

procedure TRabbitQueueWorker.SetOnAfterProcess(const AEvent: TOnAfterProcess);
begin
  FOnAfterProcess := AEvent;
end;

procedure TRabbitQueueWorker.SetOnProcessError(const AEvent: TOnProcessError);
begin
  FOnProcessError := AEvent;
end;

procedure TRabbitQueueWorker.SetOnDequeue(const AEvent: TOnDequeue);
begin
  FOnDequeue := AEvent;
end;

procedure TRabbitQueueWorker.SetOnQueueEmpty(const AEvent: TOnQueueEmpty);
begin
  FOnQueueEmpty := AEvent;
end;

procedure TRabbitQueueWorker.SetOnQueueError(const AEvent: TOnQueueError);
begin
  FOnQueueError := AEvent;
end;

function TRabbitQueueWorker.FindHandler(
  const AQueueName: string): IRabbitQueueHandler;
var
  LHandler: IRabbitQueueHandler;
begin
  Result := nil;
  // Acesso read-only à lista — lock não necessário aqui pois
  // FHandlers só é modificado pelo Core quando o worker está parado
  for LHandler in FHandlers do
    if LHandler.CanHandle(AQueueName) then
      Exit(LHandler);
end;

procedure TRabbitQueueWorker.SafeFireBeforeProcess(
  const AItem: TQueueItemInfo);
begin
  if Assigned(FOnBeforeProcess) then
    TThread.Synchronize(nil, procedure
    begin
      FOnBeforeProcess(AItem);
    end);
end;

procedure TRabbitQueueWorker.SafeFireAfterProcess(
  const AItem: TQueueItemInfo; const AResult: TProcessResult);
begin
  if Assigned(FOnAfterProcess) then
    TThread.Synchronize(nil, procedure
    begin
      FOnAfterProcess(AItem, AResult);
    end);
end;

procedure TRabbitQueueWorker.SafeFireQueueError(const AQueueName: string;
  const AError: Exception);
begin
  if Assigned(FOnQueueError) then
    TThread.Synchronize(nil, procedure
    begin
      FOnQueueError(AQueueName, AError);
    end);
end;

procedure TRabbitQueueWorker.DoProcess(const AItem: TQueueItemInfo);
var
  LHandler   : IRabbitQueueHandler;
  LResult    : TProcessResult;
  LShouldReq : Boolean;
begin
  LHandler := FindHandler(AItem.Queue);

  if not Assigned(LHandler) then
  begin
    // Sem handler registrado: ACK para não bloquear a fila indefinidamente
    FConnection.Ack(AItem.MessageId);
    Exit;
  end;

  SafeFireBeforeProcess(AItem);

  try
    LResult := LHandler.Execute(AItem);
    SafeFireAfterProcess(AItem, LResult);

    case LResult of
      prSuccess : FConnection.Ack(AItem.MessageId);
      prFailure : FConnection.Nack(AItem.MessageId, False); // descarta
      prRequeue : FConnection.Nack(AItem.MessageId, True);  // recoloca
    end;

    if Assigned(FOnDequeue) then
      TThread.Synchronize(nil, procedure
      begin
        FOnDequeue(AItem);
      end);

  except
    on E: Exception do
    begin
      // Usa MaxRetries cacheado — thread-safe, sem acesso a Config em runtime
      LShouldReq := AItem.RetryCount < FMaxRetries;

      if Assigned(FOnProcessError) then
        TThread.Synchronize(nil, procedure
        begin
          FOnProcessError(AItem, E, LShouldReq);
        end);

      FConnection.Nack(AItem.MessageId, LShouldReq);
      SafeFireQueueError(AItem.Queue, E);
    end;
  end;
end;

procedure TRabbitQueueWorker.ProcessQueue(const AQueueName: string);
var
  LItem: TQueueItemInfo;
begin
  try
    LItem := FConnection.Receive(AQueueName);

    if LItem.MessageId.IsEmpty then
    begin
      if Assigned(FOnQueueEmpty) then
        TThread.Synchronize(nil, procedure
        begin
          FOnQueueEmpty(AQueueName);
        end);
      Exit;
    end;

    DoProcess(LItem);
  except
    on E: Exception do
      SafeFireQueueError(AQueueName, E);
  end;
end;

end.
