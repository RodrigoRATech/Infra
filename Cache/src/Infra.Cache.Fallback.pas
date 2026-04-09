unit Infra.Cache.Fallback;

interface

uses
  System.SysUtils, System.Generics.Collections, System.SyncObjs;

type
  TFallbackEntry = record
    Value: string;
    ExpiresAt: TDateTime;
  end;

  /// <summary>
  ///   Cache local em memória (fallback) thread-safe. Usado quando Redis está indisponível.
  /// </summary>
  TMemoryFallbackCache = class
  private
    FLock: TCriticalSection;
    FStore: TDictionary<string, TFallbackEntry>;
    FMaxEntries: Integer;
    procedure EvictExpired;
  public
    constructor Create(AMaxEntries: Integer = 10000);
    destructor Destroy; override;

    function Get(const AKey: string; out AValue: string): Boolean;
    procedure Put(const AKey, AValue: string; ATTLSeconds: Integer);
    function Remove(const AKey: string): Boolean;
    function Exists(const AKey: string): Boolean;
    procedure Clear;
    function Count: Integer;
  end;

implementation

uses
  System.DateUtils;

{ TMemoryFallbackCache }

constructor TMemoryFallbackCache.Create(AMaxEntries: Integer);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FStore := TDictionary<string, TFallbackEntry>.Create;
  FMaxEntries := AMaxEntries;
end;

destructor TMemoryFallbackCache.Destroy;
begin
  FLock.Enter;
  try
    FStore.Free;
  finally
    FLock.Leave;
  end;
  FLock.Free;
  inherited;
end;

procedure TMemoryFallbackCache.EvictExpired;
var
  LKeysToRemove: TList<string>;
  LPair: TPair<string, TFallbackEntry>;
begin
  // Chamado internamente, já dentro do Lock
  LKeysToRemove := TList<string>.Create;
  try
    for LPair in FStore do
    begin
      if (LPair.Value.ExpiresAt > 0) and (Now > LPair.Value.ExpiresAt) then
        LKeysToRemove.Add(LPair.Key);
    end;
    for var LKey in LKeysToRemove do
      FStore.Remove(LKey);
  finally
    LKeysToRemove.Free;
  end;
end;

function TMemoryFallbackCache.Get(const AKey: string; out AValue: string): Boolean;
var
  LEntry: TFallbackEntry;
begin
  Result := False;
  AValue := '';
  FLock.Enter;
  try
    if FStore.TryGetValue(AKey, LEntry) then
    begin
      if (LEntry.ExpiresAt > 0) and (Now > LEntry.ExpiresAt) then
      begin
        FStore.Remove(AKey);
        Exit(False);
      end;
      AValue := LEntry.Value;
      Result := True;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TMemoryFallbackCache.Put(const AKey, AValue: string; ATTLSeconds: Integer);
var
  LEntry: TFallbackEntry;
begin
  FLock.Enter;
  try
    if (FStore.Count >= FMaxEntries) and (not FStore.ContainsKey(AKey)) then
      EvictExpired;

    // Se ainda está cheio após evict, remove o primeiro item (FIFO simplificado)
    if (FStore.Count >= FMaxEntries) and (not FStore.ContainsKey(AKey)) then
    begin
      for var LKey in FStore.Keys do
      begin
        FStore.Remove(LKey);
        Break;
      end;
    end;

    LEntry.Value := AValue;
    if ATTLSeconds > 0 then
      LEntry.ExpiresAt := IncSecond(Now, ATTLSeconds)
    else
      LEntry.ExpiresAt := 0; // sem expiração

    FStore.AddOrSetValue(AKey, LEntry);
  finally
    FLock.Leave;
  end;
end;

function TMemoryFallbackCache.Remove(const AKey: string): Boolean;
begin
  FLock.Enter;
  try
    Result := FStore.ContainsKey(AKey);
    if Result then
      FStore.Remove(AKey);
  finally
    FLock.Leave;
  end;
end;

function TMemoryFallbackCache.Exists(const AKey: string): Boolean;
var
  LEntry: TFallbackEntry;
begin
  FLock.Enter;
  try
    Result := FStore.TryGetValue(AKey, LEntry);
    if Result and (LEntry.ExpiresAt > 0) and (Now > LEntry.ExpiresAt) then
    begin
      FStore.Remove(AKey);
      Result := False;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TMemoryFallbackCache.Clear;
begin
  FLock.Enter;
  try
    FStore.Clear;
  finally
    FLock.Leave;
  end;
end;

function TMemoryFallbackCache.Count: Integer;
begin
  FLock.Enter;
  try
    Result := FStore.Count;
  finally
    FLock.Leave;
  end;
end;

end.
