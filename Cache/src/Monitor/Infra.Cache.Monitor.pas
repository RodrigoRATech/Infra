unit Infra.Cache.Monitor;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.SyncObjs,
  System.Generics.Collections, System.DateUtils,
  Infra.Cache.Interfaces;

type
  TStatsSnapshot = record
    Timestamp: TDateTime;
    Stats: TCacheStats;
  end;

  /// <summary>
  ///   Monitor de cache: coleta periódica de métricas, histórico e diagnóstico.
  /// </summary>
  TCacheMonitor = class(TInterfacedObject, ICacheMonitor)
  private
    FStrategy: ICacheStrategy;
    FLock: TCriticalSection;
    FHistory: TList<TStatsSnapshot>;
    FMaxHistoryEntries: Integer;
    FCollectorThread: TThread;
    FCollecting: Boolean;
  public
    constructor Create(AStrategy: ICacheStrategy; AMaxHistory: Integer = 720);
    destructor Destroy; override;

    { ICacheMonitor }
    function GetStats: TCacheStats;
    function GetStatsJSON: TJSONObject;
    function IsHealthy: Boolean;
    procedure ResetStats;
    function GetHistoricalStats(ALastMinutes: Integer): TJSONArray;
    procedure StartCollecting(AIntervalMs: Integer = 5000);
    procedure StopCollecting;
  end;

implementation

{ TCacheMonitor }

constructor TCacheMonitor.Create(AStrategy: ICacheStrategy; AMaxHistory: Integer);
begin
  inherited Create;
  if not Assigned(AStrategy) then
    raise EArgumentNilException.Create('ICacheStrategy não pode ser nil.');
  FStrategy := AStrategy;
  FLock := TCriticalSection.Create;
  FHistory := TList<TStatsSnapshot>.Create;
  FMaxHistoryEntries := AMaxHistory;
  FCollecting := False;
end;

destructor TCacheMonitor.Destroy;
begin
  StopCollecting;
  FLock.Enter;
  try
    FHistory.Free;
  finally
    FLock.Leave;
  end;
  FLock.Free;
  inherited;
end;

function TCacheMonitor.GetStats: TCacheStats;
begin
  Result := FStrategy.GetStats;
end;

function TCacheMonitor.GetStatsJSON: TJSONObject;
var
  LStats: TCacheStats;
begin
  LStats := GetStats;
  Result := LStats.ToJSON;
end;

function TCacheMonitor.IsHealthy: Boolean;
var
  LStats: TCacheStats;
begin
  LStats := GetStats;
  Result := LStats.IsConnected and (LStats.TotalErrors < 100);
end;

procedure TCacheMonitor.ResetStats;
begin
  FLock.Enter;
  try
    FHistory.Clear;
  finally
    FLock.Leave;
  end;
end;

function TCacheMonitor.GetHistoricalStats(ALastMinutes: Integer): TJSONArray;
var
  LSnapshot: TStatsSnapshot;
  LCutoff: TDateTime;
  LObj: TJSONObject;
begin
  Result := TJSONArray.Create;
  LCutoff := IncMinute(Now, -ALastMinutes);

  FLock.Enter;
  try
    for LSnapshot in FHistory do
    begin
      if LSnapshot.Timestamp >= LCutoff then
      begin
        LObj := LSnapshot.Stats.ToJSON;
        LObj.AddPair('timestamp', DateTimeToStr(LSnapshot.Timestamp));
        Result.AddElement(LObj);
      end;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TCacheMonitor.StartCollecting(AIntervalMs: Integer);
begin
  if FCollecting then
    Exit;

  FCollecting := True;
  FCollectorThread := TThread.CreateAnonymousThread(
    procedure
    var
      LSnapshot: TStatsSnapshot;
    begin
      while FCollecting do
      begin
        Sleep(AIntervalMs);
        if not FCollecting then
          Break;

        LSnapshot.Timestamp := Now;
        LSnapshot.Stats := FStrategy.GetStats;

        FLock.Enter;
        try
          FHistory.Add(LSnapshot);
          // Limita o tamanho do histórico
          while FHistory.Count > FMaxHistoryEntries do
            FHistory.Delete(0);
        finally
          FLock.Leave;
        end;
      end;
    end
  );
  FCollectorThread.FreeOnTerminate := False;
  FCollectorThread.Start;
end;

procedure TCacheMonitor.StopCollecting;
begin
  FCollecting := False;
  if Assigned(FCollectorThread) then
  begin
    FCollectorThread.WaitFor;
    FCollectorThread.Free;
    FCollectorThread := nil;
  end;
end;

end.
