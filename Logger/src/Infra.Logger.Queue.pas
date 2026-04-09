unit Infra.Logger.Queue;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  Infra.Logger.Interfaces;

type
  TLogQueue = class(TInterfacedObject, ILogQueue)
  private
    FQueue: TQueue<ILogEntry>;
    FLock: TCriticalSection;
    FEvent: TEvent;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Enqueue(const AEntry: ILogEntry);
    function Dequeue(out AEntry: ILogEntry): Boolean;
    function Count: Integer;
    procedure Clear;

    function WaitForEntry(ATimeout: Cardinal = INFINITE): Boolean;
    procedure Signal;
  end;

implementation

{ TLogQueue }

constructor TLogQueue.Create;
begin
  inherited Create;
  FQueue := TQueue<ILogEntry>.Create;
  FLock := TCriticalSection.Create;
  FEvent := TEvent.Create(nil, False, False, '');
end;

destructor TLogQueue.Destroy;
begin
  Clear;
  FQueue.Free;
  FLock.Free;
  FEvent.Free;
  inherited;
end;

procedure TLogQueue.Enqueue(const AEntry: ILogEntry);
begin
  FLock.Acquire;
  try
    FQueue.Enqueue(AEntry);
    FEvent.SetEvent;
  finally
    FLock.Release;
  end;
end;

function TLogQueue.Dequeue(out AEntry: ILogEntry): Boolean;
begin
  FLock.Acquire;
  try
    Result := FQueue.Count > 0;
    if Result then
      AEntry := FQueue.Dequeue
    else
      AEntry := nil;
  finally
    FLock.Release;
  end;
end;

function TLogQueue.Count: Integer;
begin
  FLock.Acquire;
  try
    Result := FQueue.Count;
  finally
    FLock.Release;
  end;
end;

procedure TLogQueue.Clear;
begin
  FLock.Acquire;
  try
    FQueue.Clear;
  finally
    FLock.Release;
  end;
end;

function TLogQueue.WaitForEntry(ATimeout: Cardinal): Boolean;
begin
  Result := FEvent.WaitFor(ATimeout) = wrSignaled;
end;

procedure TLogQueue.Signal;
begin
  FEvent.SetEvent;
end;

end.
