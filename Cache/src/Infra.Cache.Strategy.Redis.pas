unit Infra.Cache.Strategy.Redis;

interface

uses
  System.SysUtils, System.SyncObjs,
  System.Classes, System.DateUtils,

  Infra.Cache.Interfaces, Infra.Cache.Config,
  Infra.Cache.Fallback,

  Redis.Client, Redis.Commons, Redis.NetLib.INDY;

type
  /// <summary>
  ///   Implementação concreta da Strategy de cache utilizando Redis.
  ///   Inclui: thread-safety, fallback automático, watchdog de reconexão e self-purging.
  /// </summary>
  TRedisCacheStrategy = class(TInterfacedObject, ICacheStrategy)
  private
    FConfig: TCacheConfig;
    FOwnsConfig: Boolean;
    FRedis: IRedisClient;
    FLock: TCriticalSection;
    FFallback: TMemoryFallbackCache;
    FConnected: Boolean;
    FOnEvent: TCacheEventProc;
    FStartTime: TDateTime;

    // Estatísticas
    FHits: Int64;
    FMisses: Int64;
    FErrors: Int64;
    FFallbacks: Int64;
    FEvictions: Int64;
    FLastConnectionTime: TDateTime;
    FLastErrorTime: TDateTime;
    FLastErrorMessage: string;

    // Watchdog
    FWatchdogThread: TThread;
    FWatchdogRunning: Boolean;

    // Self-Purge (executado pelo Watchdog)
    FLastPurgeTime: TDateTime;

    procedure DoConnect;
    procedure DoDisconnect;
    function TryReconnect: Boolean;
    procedure StartWatchdog;
    procedure StopWatchdog;
    procedure FireEvent(AEvent: TCacheEvent; const AMessage: string);
    procedure HandleError(const AContext: string; E: Exception);
    procedure IncrementStat(var AStat: Int64);
  public
    constructor Create(AConfig: TCacheConfig; AOwnsConfig: Boolean = False);
    destructor Destroy; override;

    { ICacheStrategy }
    function Get(const AKey: string; out AValue: string): Boolean;
    procedure Put(const AKey, AValue: string; ATTLSeconds: Integer = 0);
    function Remove(const AKey: string): Boolean;
    function Exists(const AKey: string): Boolean;
    procedure Clear;
    function GetStats: TCacheStats;
    procedure SetOnEvent(AProc: TCacheEventProc);
  end;

implementation

{ TRedisCacheStrategy }

constructor TRedisCacheStrategy.Create(AConfig: TCacheConfig; AOwnsConfig: Boolean);
begin
  inherited Create;

  if not Assigned(AConfig) then
    raise EArgumentNilException.Create('TCacheConfig não pode ser nil.');
  if not AConfig.Validate then
    raise EArgumentException.Create('TCacheConfig inválido. Verifique Host, Port e TTL.');

  if AOwnsConfig then
    FConfig := AConfig
  else
    FConfig := AConfig.Clone;
  FOwnsConfig := True; // sempre dono do clone ou do original se AOwnsConfig

  FLock := TCriticalSection.Create;
  FFallback := TMemoryFallbackCache.Create;
  FStartTime := Now;
  FConnected := False;
  FHits := 0;
  FMisses := 0;
  FErrors := 0;
  FFallbacks := 0;
  FEvictions := 0;
  FLastPurgeTime := Now;

  DoConnect;
  StartWatchdog;
end;

destructor TRedisCacheStrategy.Destroy;
begin
  StopWatchdog;
  DoDisconnect;

  FLock.Enter;
  try
    FFallback.Free;
    FConfig.Free;
  finally
    FLock.Leave;
  end;
  FLock.Free;

  inherited;
end;

procedure TRedisCacheStrategy.DoConnect;
var
  LRetry: Integer;
begin
  FLock.Enter;
  try
    for LRetry := 0 to FConfig.MaxRetries - 1 do
    begin
      try
        FRedis := NewRedisClient(FConfig.Host, FConfig.Port);
        // Testa a conexão com um PING
        if SameText( FRedis.PING, 'PONG') then
        begin
          FConnected := True;
          FLastConnectionTime := Now;
          FireEvent(ceConnected, Format('Conectado ao Redis em %s:%d',
            [FConfig.Host, FConfig.Port]));
          Exit;
        end;
      except
        on E: Exception do
        begin
          FConnected := False;
          if LRetry < FConfig.MaxRetries - 1 then
            Sleep(FConfig.RetryIntervalMs)
          else
            HandleError('DoConnect', E);
        end;
      end;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TRedisCacheStrategy.DoDisconnect;
begin
  FLock.Enter;
  try
    FRedis := nil;
    FConnected := False;
  finally
    FLock.Leave;
  end;
end;

function TRedisCacheStrategy.TryReconnect: Boolean;
begin
  Result := False;
  FLock.Enter;
  try
    try
      FRedis := NewRedisClient(FConfig.Host, FConfig.Port);
      if SameText( FRedis.PING, 'PONG') then
      begin
        FConnected := True;
        FLastConnectionTime := Now;
        FireEvent(ceReconnected, 'Reconexão com Redis bem-sucedida.');
        Result := True;
      end;
    except
      on E: Exception do
      begin
        FConnected := False;
        // Silencioso no watchdog, apenas loga
      end;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TRedisCacheStrategy.StartWatchdog;
begin
  FWatchdogRunning := True;
  FWatchdogThread := TThread.CreateAnonymousThread(
    procedure
    begin
      while FWatchdogRunning do
      begin
        Sleep(FConfig.WatchdogIntervalMs);
        if not FWatchdogRunning then
          Break;

        // Verificação de conexão
        FLock.Enter;
        try
          if FConnected and Assigned(FRedis) then
          begin
            try
              if not SameText( FRedis.PING, 'PONG') then
              begin
                FConnected := False;
                FireEvent(ceDisconnected, 'Redis não respondeu ao PING.');
              end;
            except
              FConnected := False;
              FireEvent(ceDisconnected, 'Erro ao enviar PING ao Redis.');
            end;
          end;
        finally
          FLock.Leave;
        end;

        // Tentativa de reconexão se desconectado
        if not FConnected then
          TryReconnect;

        // Self-Purge: limpeza periódica
        if FConnected and (MilliSecondsBetween(Now, FLastPurgeTime) >= FConfig.PurgeIntervalMs) then
        begin
          FLastPurgeTime := Now;
          // Redis gerencia TTLs nativamente, mas notificamos
          FireEvent(cePurgeCompleted, 'Ciclo de purge executado (Redis gerencia TTL nativamente).');
        end;
      end;
    end
  );
  FWatchdogThread.FreeOnTerminate := False;
  FWatchdogThread.Start;
end;

procedure TRedisCacheStrategy.StopWatchdog;
begin
  FWatchdogRunning := False;
  if Assigned(FWatchdogThread) then
  begin
    FWatchdogThread.WaitFor;
    FWatchdogThread.Free;
    FWatchdogThread := nil;
  end;
end;

procedure TRedisCacheStrategy.FireEvent(AEvent: TCacheEvent; const AMessage: string);
begin
  if Assigned(FOnEvent) then
  begin
    try
      FOnEvent(AEvent, AMessage);
    except
      // Evento não deve derrubar o cache
    end;
  end;
end;

procedure TRedisCacheStrategy.HandleError(const AContext: string; E: Exception);
begin
  IncrementStat(FErrors);
  FLastErrorTime := Now;
  FLastErrorMessage := Format('[%s] %s: %s', [AContext, E.ClassName, E.Message]);
  FireEvent(ceError, FLastErrorMessage);
end;

procedure TRedisCacheStrategy.IncrementStat(var AStat: Int64);
begin
  TInterlocked.Increment(AStat);
end;

{ ICacheStrategy }

function TRedisCacheStrategy.Get(const AKey: string; out AValue: string): Boolean;
var
  LFullKey: string;
  LValue: string;
begin
  Result := False;
  AValue := '';
  LFullKey := FConfig.GetFullKey(AKey);

  FLock.Enter;
  try
    if FConnected and Assigned(FRedis) then
    begin
      try
        LValue := FRedis.GET(LFullKey);
        if not LValue.IsEmpty then
        begin
          AValue := LValue;
          IncrementStat(FHits);
          // Atualiza fallback local
          if FConfig.FallbackEnabled then
            FFallback.Put(LFullKey, LValue, FConfig.DefaultTTLSeconds);
          Result := True;
          Exit;
        end;
      except
        on E: Exception do
        begin
          HandleError('Get', E);
          FConnected := False;
        end;
      end;
    end;
  finally
    FLock.Leave;
  end;

  // Fallback
  if (not Result) and FConfig.FallbackEnabled then
  begin
    if FFallback.Get(LFullKey, LValue) then
    begin
      AValue := LValue;
      IncrementStat(FFallbacks);
      FireEvent(ceFallbackActivated, Format('Fallback ativado para chave: %s', [AKey]));
      Result := True;
      Exit;
    end;
  end;

  if not Result then
    IncrementStat(FMisses);
end;

procedure TRedisCacheStrategy.Put(const AKey, AValue: string; ATTLSeconds: Integer);
var
  LFullKey: string;
  LTTL: Integer;
begin
  LFullKey := FConfig.GetFullKey(AKey);
  LTTL := ATTLSeconds;
  if LTTL <= 0 then
    LTTL := FConfig.DefaultTTLSeconds;

  FLock.Enter;
  try
    if FConnected and Assigned(FRedis) then
    begin
      try
        FRedis.&SET(LFullKey, AValue, LTTL);
      except
        on E: Exception do
        begin
          HandleError('Put', E);
          FConnected := False;
        end;
      end;
    end;
  finally
    FLock.Leave;
  end;

  // Sempre atualiza o fallback
  if FConfig.FallbackEnabled then
    FFallback.Put(LFullKey, AValue, LTTL);
end;

function TRedisCacheStrategy.Remove(const AKey: string): Boolean;
var
  LFullKey: string;
begin
  Result := False;
  LFullKey := FConfig.GetFullKey(AKey);

  FLock.Enter;
  try
    if FConnected and Assigned(FRedis) then
    begin
      try
        Result := FRedis.DEL([LFullKey]) > 0;
        IncrementStat(FEvictions);
      except
        on E: Exception do
        begin
          HandleError('Remove', E);
          FConnected := False;
        end;
      end;
    end;
  finally
    FLock.Leave;
  end;

  if FConfig.FallbackEnabled then
    FFallback.Remove(LFullKey);
end;

function TRedisCacheStrategy.Exists(const AKey: string): Boolean;
var
  LFullKey: string;
begin
  Result := False;
  LFullKey := FConfig.GetFullKey(AKey);

  FLock.Enter;
  try
    if FConnected and Assigned(FRedis) then
    begin
      try
        Result := FRedis.EXISTS(LFullKey);
      except
        on E: Exception do
        begin
          HandleError('Exists', E);
          FConnected := False;
        end;
      end;
    end;
  finally
    FLock.Leave;
  end;

  if (not Result) and FConfig.FallbackEnabled then
    Result := FFallback.Exists(LFullKey);
end;

procedure TRedisCacheStrategy.Clear;
begin
  FLock.Enter;
  try
    if FConnected and Assigned(FRedis) then
    begin
      try
        FRedis.FLUSHDB;
      except
        on E: Exception do
        begin
          HandleError('Clear', E);
          FConnected := False;
        end;
      end;
    end;
  finally
    FLock.Leave;
  end;

  if FConfig.FallbackEnabled then
    FFallback.Clear;
end;

function TRedisCacheStrategy.GetStats: TCacheStats;
begin
  FLock.Enter;
  try
    Result.TotalHits := FHits;
    Result.TotalMisses := FMisses;
    Result.TotalErrors := FErrors;
    Result.TotalFallbacks := FFallbacks;
    Result.TotalEvictions := FEvictions;
    Result.CurrentKeys := FFallback.Count; // aproximação
    Result.IsConnected := FConnected;
    Result.LastConnectionTime := FLastConnectionTime;
    Result.LastErrorTime := FLastErrorTime;
    Result.LastErrorMessage := FLastErrorMessage;
    Result.UptimeSeconds := SecondsBetween(Now, FStartTime);
  finally
    FLock.Leave;
  end;
end;

procedure TRedisCacheStrategy.SetOnEvent(AProc: TCacheEventProc);
begin
  FLock.Enter;
  try
    FOnEvent := AProc;
  finally
    FLock.Leave;
  end;
end;

end.
