unit Infra.Auth2FA.TOTP.Engine;

interface

uses
  System.SysUtils,
  System.DateUtils,
  Infra.Auth2FA.Interfaces;

type
  /// <summary>
  ///   Motor de cálculo TOTP conforme RFC 6238
  ///   Responsabilidade única: calcular tokens baseados em tempo
  /// </summary>
  TTOTPEngine = class
  strict private
    FHMACStrategy: IHMACStrategy;
    FBase32Codec: IBase32Codec;
    FDigits: Integer;
    FPeriod: Integer;
  private
    /// <summary>
    ///   Converte o contador (Int64) em array de 8 bytes Big-Endian
    /// </summary>
    function CounterToBytes(const ACounter: Int64): TBytes;

    /// <summary>
    ///   Aplica truncamento dinâmico conforme RFC 4226 §5.4
    /// </summary>
    function DynamicTruncation(const AHMACSummary: TBytes): UInt32;

    /// <summary>
    ///   Retorna o contador TOTP para um dado momento Unix (UTC)
    /// </summary>
    function GetTimeCounter(const AUnixTime: Int64): Int64;
  public
    constructor Create(
      const AHMACStrategy: IHMACStrategy;
      const ABase32Codec: IBase32Codec;
      const ADigits: Integer = 6;
      const APeriod: Integer = 30
    );

    /// <summary>
    ///   Gera o token TOTP para um determinado segredo e instante
    /// </summary>
    function GenerateToken(const ASecretBase32: string; const AUnixTime: Int64): string;

    /// <summary>
    ///   Retorna o Unix timestamp UTC atual
    /// </summary>
    class function GetCurrentUnixTime: Int64; static;

    /// <summary>
    ///   Segundos restantes na janela atual
    /// </summary>
    function GetRemainingSeconds: Integer;

    property Period: Integer read FPeriod;
    property Digits: Integer read FDigits;
  end;

implementation

{ TTOTPEngine }

constructor TTOTPEngine.Create(
  const AHMACStrategy: IHMACStrategy;
  const ABase32Codec: IBase32Codec;
  const ADigits: Integer;
  const APeriod: Integer);
begin
  inherited Create;

  if not Assigned(AHMACStrategy) then
    raise EArgumentNilException.Create('HMACStrategy não pode ser nulo');
  if not Assigned(ABase32Codec) then
    raise EArgumentNilException.Create('Base32Codec não pode ser nulo');

  FHMACStrategy := AHMACStrategy;
  FBase32Codec := ABase32Codec;
  FDigits := ADigits;
  FPeriod := APeriod;
end;

function TTOTPEngine.CounterToBytes(const ACounter: Int64): TBytes;
var
  I: Integer;
  LValue: Int64;
begin
  SetLength(Result, 8);
  LValue := ACounter;

  // Big-Endian encoding
  for I := 7 downto 0 do
  begin
    Result[I] := Byte(LValue and $FF);
    LValue := LValue shr 8;
  end;
end;

function TTOTPEngine.DynamicTruncation(const AHMACSummary: TBytes): UInt32;
var
  LOffset: Integer;
  LBinaryCode: UInt32;
  LModulo: UInt32;
begin
  // RFC 4226 §5.4: Dynamic Truncation
  // Offset = últimos 4 bits do último byte
  LOffset := AHMACSummary[Length(AHMACSummary) - 1] and $0F;

  // Extrai 4 bytes a partir do offset
  LBinaryCode :=
    ((UInt32(AHMACSummary[LOffset])     and $7F) shl 24) or
    ((UInt32(AHMACSummary[LOffset + 1]) and $FF) shl 16) or
    ((UInt32(AHMACSummary[LOffset + 2]) and $FF) shl  8) or
     (UInt32(AHMACSummary[LOffset + 3]) and $FF);

  // Módulo para obter N dígitos
  LModulo := 1;
  var I: Integer;
  for I := 1 to FDigits do
    LModulo := LModulo * 10;

  Result := LBinaryCode mod LModulo;
end;

function TTOTPEngine.GetTimeCounter(const AUnixTime: Int64): Int64;
begin
  Result := AUnixTime div FPeriod;
end;

function TTOTPEngine.GenerateToken(const ASecretBase32: string;
  const AUnixTime: Int64): string;
var
  LSecretBytes: TBytes;
  LCounterBytes: TBytes;
  LHMACResult: TBytes;
  LToken: UInt32;
  LCounter: Int64;
begin
  // 1. Decodifica o segredo de Base32 para bytes
  LSecretBytes := FBase32Codec.Decode(ASecretBase32);
  try
    // 2. Calcula o contador baseado no tempo
    LCounter := GetTimeCounter(AUnixTime);
    LCounterBytes := CounterToBytes(LCounter);

    // 3. Calcula HMAC(segredo, contador)
    LHMACResult := FHMACStrategy.ComputeHMAC(LSecretBytes, LCounterBytes);

    // 4. Aplica truncamento dinâmico
    LToken := DynamicTruncation(LHMACResult);

    // 5. Formata com zeros à esquerda
    Result := Format('%.*d', [FDigits, LToken]);
  finally
    // Limpa dados sensíveis da memória
    if Length(LSecretBytes) > 0 then
      FillChar(LSecretBytes[0], Length(LSecretBytes), 0);
  end;
end;

class function TTOTPEngine.GetCurrentUnixTime: Int64;
begin
  Result := DateTimeToUnix(TTimeZone.Local.ToUniversalTime(Now), {AInputIsUTC=}True);
end;

function TTOTPEngine.GetRemainingSeconds: Integer;
var
  LCurrentUnix: Int64;
begin
  LCurrentUnix := GetCurrentUnixTime;
  Result := FPeriod - (LCurrentUnix mod FPeriod);
end;

end.
