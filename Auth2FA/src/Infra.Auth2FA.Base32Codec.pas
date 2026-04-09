unit Infra.Auth2FA.Base32Codec;

interface

uses
  System.SysUtils,
  Infra.Auth2FA.Interfaces;

type
  TBase32Codec = class(TInterfacedObject, IBase32Codec)
  strict private
    const
      ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
      PAD_CHAR = '=';
  private
    function CharToValue(const AChar: Char): Byte;
  public
    function Encode(const AData: TBytes): string;
    function Decode(const AEncoded: string): TBytes;
  end;

implementation

{ TBase32Codec }

function TBase32Codec.CharToValue(const AChar: Char): Byte;
var
  LUpper: Char;
begin
  LUpper := UpCase(AChar);

  if (LUpper >= 'A') and (LUpper <= 'Z') then
    Result := Ord(LUpper) - Ord('A')
  else if (LUpper >= '2') and (LUpper <= '7') then
    Result := Ord(LUpper) - Ord('2') + 26
  else
    raise EArgumentException.CreateFmt('Caractere Base32 inválido: "%s"', [AChar]);
end;

function TBase32Codec.Encode(const AData: TBytes): string;
var
  LBuffer: Cardinal;
  LBitsLeft: Integer;
  I: Integer;
  LResult: TStringBuilder;
begin
  LResult := TStringBuilder.Create;
  try
    LBuffer := 0;
    LBitsLeft := 0;

    for I := 0 to Length(AData) - 1 do
    begin
      LBuffer := (LBuffer shl 8) or AData[I];
      Inc(LBitsLeft, 8);

      while LBitsLeft >= 5 do
      begin
        Dec(LBitsLeft, 5);
        LResult.Append(ALPHABET[((LBuffer shr LBitsLeft) and $1F) + 1]);
      end;
    end;

    // Bits restantes
    if LBitsLeft > 0 then
      LResult.Append(ALPHABET[((LBuffer shl (5 - LBitsLeft)) and $1F) + 1]);

    // Padding (opcional, Google Authenticator não exige)
    while (LResult.Length mod 8) <> 0 do
      LResult.Append(PAD_CHAR);

    Result := LResult.ToString;
  finally
    LResult.Free;
  end;
end;

function TBase32Codec.Decode(const AEncoded: string): TBytes;
var
  LClean: string;
  LBuffer: Cardinal;
  LBitsLeft: Integer;
  I: Integer;
  LOutput: TBytes;
  LIndex: Integer;
begin
  // Remove padding e espaços
  LClean := AEncoded.Replace(PAD_CHAR, '').Replace(' ', '').Trim;

  if LClean.IsEmpty then
    Exit(nil);

  // Tamanho máximo estimado de saída
  SetLength(LOutput, (Length(LClean) * 5) div 8);
  LBuffer := 0;
  LBitsLeft := 0;
  LIndex := 0;

  for I := 1 to Length(LClean) do
  begin
    LBuffer := (LBuffer shl 5) or CharToValue(LClean[I]);
    Inc(LBitsLeft, 5);

    if LBitsLeft >= 8 then
    begin
      Dec(LBitsLeft, 8);
      LOutput[LIndex] := Byte((LBuffer shr LBitsLeft) and $FF);
      Inc(LIndex);
    end;
  end;

  SetLength(LOutput, LIndex);
  Result := LOutput;
end;

end.
