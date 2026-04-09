unit Infra.Logger;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.SyncObjs,
  Infra.Logger.Types,
  Infra.Logger.Interfaces,
  Infra.Logger.Entry,
  Infra.Logger.Queue,
  Infra.Logger.Dispatcher,
  Infra.Logger.Worker;

type
  TLogger = class(TInterfacedObject, ILogger)
  private
    FQueue: TLogQueue;
    FDispatcher: ILogDispatcher;
    FWorker: TLogWorkerThread;
    FIsShutdown: Boolean;
    FLock: TCriticalSection;

    class var FInstance: ILogger;
    class var FInstanceLock: TCriticalSection;

    procedure CheckShutdown;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Log(ALevel: TLogLevel; const AMessage: string;
      const ACategory: string = ''; AExtraData: TJSONObject = nil);
    procedure Debug(const AMessage: string; const ACategory: string = '');
    procedure Info(const AMessage: string; const ACategory: string = '');
    procedure Warning(const AMessage: string; const ACategory: string = '');
    procedure Error(const AMessage: string; const ACategory: string = '');
    procedure Flush;
    procedure Shutdown;

    procedure RegisterHandler(const AHandler: ILogHandler);
    procedure UnregisterHandler(const AHandler: ILogHandler);

    // Singleton - opcional
    class function Instance: ILogger;
    class procedure ReleaseInstance;
    class constructor Create;
    class destructor Destroy;
  end;

implementation

{ TLogger }

class constructor TLogger.Create;
begin
  FInstanceLock := TCriticalSection.Create;
  FInstance := nil;
end;

class destructor TLogger.Destroy;
begin
  ReleaseInstance;
  FInstanceLock.Free;
end;

class function TLogger.Instance: ILogger;
begin
  if not Assigned(FInstance) then
  begin
    FInstanceLock.Acquire;
    try
      if not Assigned(FInstance) then
        FInstance := TLogger.Create;
    finally
      FInstanceLock.Release;
    end;
  end;
  Result := FInstance;
end;

class procedure TLogger.ReleaseInstance;
begin
  FInstanceLock.Acquire;
  try
    if Assigned(FInstance) then
    begin
      FInstance.Shutdown;
      FInstance := nil;
    end;
  finally
    FInstanceLock.Release;
  end;
end;

constructor TLogger.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FIsShutdown := False;
  FQueue := TLogQueue.Create;
  FDispatcher := TLogDispatcher.Create;
  FWorker := TLogWorkerThread.Create(FQueue, FDispatcher);
  FWorker.Start;
end;

destructor TLogger.Destroy;
begin
  Shutdown;
  FLock.Free;
  inherited;
end;

procedure TLogger.CheckShutdown;
begin
  if FIsShutdown then
    raise EInvalidOperation.Create('Logger has been shutdown');
end;

procedure TLogger.Log(ALevel: TLogLevel; const AMessage: string;
  const ACategory: string; AExtraData: TJSONObject);
var
  LEntry: ILogEntry;
begin
  FLock.Acquire;
  try
    CheckShutdown;
    LEntry := TLogEntry.Create(ALevel, AMessage, ACategory, AExtraData);
    FQueue.Enqueue(LEntry);
  finally
    FLock.Release;
  end;
end;

procedure TLogger.Debug(const AMessage: string; const ACategory: string);
begin
  Log(llDebug, AMessage, ACategory);
end;

procedure TLogger.Info(const AMessage: string; const ACategory: string);
begin
  Log(llInformation, AMessage, ACategory);
end;

procedure TLogger.Warning(const AMessage: string; const ACategory: string);
begin
  Log(llWarning, AMessage, ACategory);
end;

procedure TLogger.Error(const AMessage: string; const ACategory: string);
begin
  Log(llError, AMessage, ACategory);
end;

procedure TLogger.Flush;
begin
  FLock.Acquire;
  try
    CheckShutdown;
    FWorker.Flush;
  finally
    FLock.Release;
  end;
end;

procedure TLogger.Shutdown;
begin
  FLock.Acquire;
  try
    if FIsShutdown then
      Exit;

    FIsShutdown := True;

    if Assigned(FWorker) then
    begin
      FWorker.Stop;
      FreeAndNil(FWorker);
    end;

    if Assigned(FDispatcher) then
      FDispatcher.ClearHandlers;

    if Assigned(FQueue) then
      FreeAndNil(FQueue);
  finally
    FLock.Release;
  end;
end;

procedure TLogger.RegisterHandler(const AHandler: ILogHandler);
begin
  FLock.Acquire;
  try
    CheckShutdown;
    FDispatcher.RegisterHandler(AHandler);
  finally
    FLock.Release;
  end;
end;

procedure TLogger.UnregisterHandler(const AHandler: ILogHandler);
begin
  FLock.Acquire;
  try
    if not FIsShutdown then
      FDispatcher.UnregisterHandler(AHandler);
  finally
    FLock.Release;
  end;
end;

end.
