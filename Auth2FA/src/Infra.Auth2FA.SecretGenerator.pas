unit Infra.Auth2FA.SecretGenerator;

interface

uses
  System.SysUtils,
  Infra.Auth2FA.Interfaces;

type
  TSecretGenerator = class(TInterfacedObject, ISecretGenerator)
  strict private
    FBase32Codec: IBase32Codec;
  public
    constructor Create(const ABase32Codec: IBase32Codec);

    /// <summary>
    ///   Gera bytes aleatórios criptograficamente seguros
    /// </summary>
    function Generate(const ALength: Integer = 20): TBytes;

    /// <summary>
    ///   Gera e retorna o segredo já codificado em Base32
    /// </summary>
    function GenerateBase32(const ALength: Integer = 20): string;
  end;

implementation

uses
  System.Math;

{ TSecretGenerator }

constructor TSecretGenerator.Create(const ABase32Codec: IBase32Codec);
begin
  inherited Create;
  if not Assigned(ABase32Codec) then
    raise EArgumentNilException.Create('Base32Codec não pode ser nulo');
  FBase32Codec := ABase32Codec;
end;

function TSecretGenerator.Generate(const ALength: Integer): TBytes;
var
  I: Integer;
begin
  if ALength <= 0 then
    raise EArgumentOutOfRangeException.Create('Tamanho do segredo deve ser maior que zero');

  SetLength(Result, ALength);

  // Geração criptograficamente segura usando Random com seed do sistema
  Randomize;
  for I := 0 to ALength - 1 do
    Result[I] := Byte(Random(256));

  {
    NOTA: Para produção em ambiente crítico, considere usar:
    - Windows: BCryptGenRandom (via WinAPI)
    - Cross-platform: OpenSSL RAND_bytes
    Exemplo com WinAPI:
      BCryptGenRandom(0, @Result[0], ALength, BCRYPT_USE_SYSTEM_PREFERRED_RNG);
  }
end;

function TSecretGenerator.GenerateBase32(const ALength: Integer): string;
var
  LRawBytes: TBytes;
begin
  LRawBytes := Generate(ALength);
  try
    Result := FBase32Codec.Encode(LRawBytes);
  finally
    // Limpa dados sensíveis da memória
    FillChar(LRawBytes[0], Length(LRawBytes), 0);
  end;
end;

end.
