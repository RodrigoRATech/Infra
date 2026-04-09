unit Infra.Cache.Interfaces;

interface

uses
  System.SysUtils, System.Generics.Collections, System.JSON;

type
  /// <summary>
  ///   Estatísticas de uso do cache para monitoramento.
  /// </summary>
  TCacheStats = record
    TotalHits: Int64;
    TotalMisses: Int64;
    TotalErrors: Int64;
    TotalFallbacks: Int64;
    TotalEvictions: Int64;
    CurrentKeys: Int64;
    IsConnected: Boolean;
    LastConnectionTime: TDateTime;
    LastErrorTime: TDateTime;
    LastErrorMessage: string;
    UptimeSeconds: Int64;
    function HitRatio: Double;
    function ToJSON: TJSONObject;
  end;

  /// <summary>
  ///   Evento disparado quando ocorrem mudanças relevantes no cache.
  /// </summary>
  TCacheEvent = (ceConnected, ceDisconnected, ceReconnected,
                 ceError, ceFallbackActivated, cePurgeCompleted);

  TCacheEventProc = reference to procedure(AEvent: TCacheEvent; const AMessage: string);

  /// <summary>
  ///   Strategy: contrato principal de cache (desacoplado de Redis).
  /// </summary>
  ICacheStrategy = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function Get(const AKey: string; out AValue: string): Boolean;
    procedure Put(const AKey, AValue: string; ATTLSeconds: Integer = 0);
    function Remove(const AKey: string): Boolean;
    function Exists(const AKey: string): Boolean;
    procedure Clear;
    function GetStats: TCacheStats;
    procedure SetOnEvent(AProc: TCacheEventProc);
  end;

  /// <summary>
  ///   Serializador genérico para objetos.
  /// </summary>
  ICacheSerializer = interface
    ['{B2C3D4E5-F6A7-8901-BCDE-F12345678901}']
    function SerializeJSON(AValue: TJSONValue): string;
    function DeserializeJSON(const AData: string): TJSONValue;
  end;

  /// <summary>
  ///   Cache manager: contrato de alto nível para operações string e JSON.
  ///   Métodos genéricos (GetObject<T>, PutObject<T>, GetOrAdd<T>) ficam
  ///   exclusivamente na classe concreta TCacheManager, pois interfaces
  ///   Delphi não suportam métodos parameterizados.
  /// </summary>
  ICacheManager = interface
    ['{C3D4E5F6-A7B8-9012-CDEF-123456789012}']
    function GetString(const AKey: string; out AValue: string): Boolean;
    procedure PutString(const AKey, AValue: string; ATTLSeconds: Integer = 0);

    function GetJSON(const AKey: string; out AValue: TJSONValue): Boolean;
    procedure PutJSON(const AKey: string; AValue: TJSONValue; ATTLSeconds: Integer = 0);

    function Remove(const AKey: string): Boolean;
    function Exists(const AKey: string): Boolean;
    procedure Clear;
    function GetStats: TCacheStats;
    procedure SetOnEvent(AProc: TCacheEventProc);
  end;

  /// <summary>
  ///   Monitor de cache para métricas e diagnóstico.
  /// </summary>
  ICacheMonitor = interface
    ['{D4E5F6A7-B8C9-0123-DEFA-234567890123}']
    function GetStats: TCacheStats;
    function GetStatsJSON: TJSONObject;
    function IsHealthy: Boolean;
    procedure ResetStats;
    function GetHistoricalStats(ALastMinutes: Integer): TJSONArray;
    procedure StartCollecting(AIntervalMs: Integer = 5000);
    procedure StopCollecting;
  end;

implementation

{ TCacheStats }

function TCacheStats.HitRatio: Double;
var
  LTotal: Int64;
begin
  LTotal := TotalHits + TotalMisses;
  if LTotal = 0 then
    Result := 0
  else
    Result := TotalHits / LTotal;
end;

function TCacheStats.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('totalHits', TJSONNumber.Create(TotalHits));
  Result.AddPair('totalMisses', TJSONNumber.Create(TotalMisses));
  Result.AddPair('totalErrors', TJSONNumber.Create(TotalErrors));
  Result.AddPair('totalFallbacks', TJSONNumber.Create(TotalFallbacks));
  Result.AddPair('totalEvictions', TJSONNumber.Create(TotalEvictions));
  Result.AddPair('currentKeys', TJSONNumber.Create(CurrentKeys));
  Result.AddPair('isConnected', TJSONBool.Create(IsConnected));
  Result.AddPair('hitRatio', TJSONNumber.Create(HitRatio));
  Result.AddPair('uptimeSeconds', TJSONNumber.Create(UptimeSeconds));
  if not LastErrorMessage.IsEmpty then
    Result.AddPair('lastErrorMessage', LastErrorMessage);
end;

end.
