unit Infra.Logger.Worker;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  Infra.Logger.Interfaces,
  Infra.Logger.Queue;

type
  TLogWorkerThread = class(TThread)
  private
    FQueue: TLogQueue;
    FDispatcher: ILogDispatcher;
    FStopEvent: TEvent;
    FFlushEvent: TEvent;
    FFlushCompleteEvent: TEvent;
  protected
    procedure Execute; override;
    procedure ProcessQueue;
  public
    constructor Create(AQueue: TLogQueue; const ADispatcher: ILogDispatcher);
    destructor Destroy; override;

    procedure Flush;
    procedure Stop;
  end;

implementation

{ TLogWorkerThread }

constructor TLogWorkerThread.Create(AQueue: TLogQueue;
  const ADispatcher: ILogDispatcher);
begin
  inherited Create(True); // Criado suspenso
  FreeOnTerminate := False;
  FQueue := AQueue;
  FDispatcher := ADispatcher;
  FStopEvent := TEvent.Create(nil, True, False, '');
  FFlushEvent := TEvent.Create(nil, False, False, '');
  FFlushCompleteEvent := TEvent.Create(nil, False, False, '');
end;

destructor TLogWorkerThread.Destroy;
begin
  Stop;
  FStopEvent.Free;
  FFlushEvent.Free;
  FFlushCompleteEvent.Free;
  inherited;
end;

procedure TLogWorkerThread.Execute;
var
  LWaitResult: TWaitResult;
  LEvents: array[0..1] of THandle;
begin
  NameThreadForDebugging('LogWorkerThread');

  while not Terminated do
  begin
    // Aguarda entrada na fila ou sinal de flush/stop
    if FQueue.WaitForEntry(100) then
      ProcessQueue;

    // Verifica se foi solicitado flush
    if FFlushEvent.WaitFor(0) = wrSignaled then
    begin
      ProcessQueue;
      FFlushCompleteEvent.SetEvent;
    end;

    // Verifica se deve parar
    if FStopEvent.WaitFor(0) = wrSignaled then
      Break;
  end;

  // Processa itens restantes antes de finalizar
  ProcessQueue;
end;

procedure TLogWorkerThread.ProcessQueue;
var
  LEntry: ILogEntry;
begin
  while FQueue.Dequeue(LEntry) do
  begin
    if Assigned(LEntry) and Assigned(FDispatcher) then
      FDispatcher.Dispatch(LEntry);
  end;
end;

procedure TLogWorkerThread.Flush;
begin
  FFlushEvent.SetEvent;
  FFlushCompleteEvent.WaitFor(5000); // Timeout de 5 segundos
end;

procedure TLogWorkerThread.Stop;
begin
  FStopEvent.SetEvent;
  FQueue.Signal; // Libera wait da fila
  
  if not Terminated then
  begin
    Terminate;
    WaitFor;
  end;
end;

end.
