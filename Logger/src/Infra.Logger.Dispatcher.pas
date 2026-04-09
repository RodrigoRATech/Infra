unit Infra.Logger.Dispatcher;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  Infra.Logger.Types,
  Infra.Logger.Interfaces;

type
  TLogDispatcher = class(TInterfacedObject, ILogDispatcher)
  private
    FHandlers: TList<ILogHandler>;
    FLock: TMultiReadExclusiveWriteSynchronizer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure RegisterHandler(const AHandler: ILogHandler);
    procedure UnregisterHandler(const AHandler: ILogHandler);
    procedure Dispatch(const AEntry: ILogEntry);
    procedure ClearHandlers;
  end;

implementation

{ TLogDispatcher }

constructor TLogDispatcher.Create;
begin
  inherited Create;
  FHandlers := TList<ILogHandler>.Create;
  FLock := TMultiReadExclusiveWriteSynchronizer.Create;
end;

destructor TLogDispatcher.Destroy;
begin
  ClearHandlers;
  FHandlers.Free;
  FLock.Free;
  inherited;
end;

procedure TLogDispatcher.RegisterHandler(const AHandler: ILogHandler);
begin
  FLock.BeginWrite;
  try
    if not FHandlers.Contains(AHandler) then
      FHandlers.Add(AHandler);
  finally
    FLock.EndWrite;
  end;
end;

procedure TLogDispatcher.UnregisterHandler(const AHandler: ILogHandler);
begin
  FLock.BeginWrite;
  try
    FHandlers.Remove(AHandler);
  finally
    FLock.EndWrite;
  end;
end;

procedure TLogDispatcher.Dispatch(const AEntry: ILogEntry);
var
  LHandler: ILogHandler;
  LHandlersCopy: TArray<ILogHandler>;
  I: Integer;
begin
  // Cria cópia thread-safe dos handlers
  FLock.BeginRead;
  try
    SetLength(LHandlersCopy, FHandlers.Count);
    for I := 0 to FHandlers.Count - 1 do
      LHandlersCopy[I] := FHandlers[I];
  finally
    FLock.EndRead;
  end;

  // Processa fora do lock
  for LHandler in LHandlersCopy do
  begin
    if LHandler.IsEnabled(AEntry.Level) then
    begin
      try
        LHandler.Handle(AEntry);
      except
        on E: Exception do
        begin
          // Log interno de erro - evita loop infinito
          {$IFDEF DEBUG}
          //OutputDebugString(PChar(Format('Logger Handler Error [%s]: %s', [LHandler.Name, E.Message])));
          {$ENDIF}
        end;
      end;
    end;
  end;
end;

procedure TLogDispatcher.ClearHandlers;
begin
  FLock.BeginWrite;
  try
    FHandlers.Clear;
  finally
    FLock.EndWrite;
  end;
end;

end.
