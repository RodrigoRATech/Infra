unit Infra.Auth2FA.QRCodeURIBuilder;

interface

uses
  System.SysUtils,
  System.NetEncoding,
  Infra.Auth2FA.Interfaces;

type
  /// <summary>
  ///   Constrói a URI otpauth:// para provisioning via QR Code
  ///   Formato: otpauth://totp/{issuer}:{account}?secret={secret}&issuer={issuer}&algorithm={algo}&digits={digits}&period={period}
  /// </summary>
  TQRCodeURIBuilder = class(TInterfacedObject, IQRCodeURIBuilder)
  private
    function URLEncode(const AValue: string): string;
    function AlgorithmToString(const AAlgorithm: TTOTPAlgorithm): string;
  public
    function Build(const ASecret: string; const AConfig: ITOTPConfig): string;
  end;

implementation

{ TQRCodeURIBuilder }

function TQRCodeURIBuilder.URLEncode(const AValue: string): string;
begin
  Result := TNetEncoding.URL.Encode(AValue);
end;

function TQRCodeURIBuilder.AlgorithmToString(const AAlgorithm: TTOTPAlgorithm): string;
begin
  case AAlgorithm of
    taSHA1:   Result := 'SHA1';
    taSHA256: Result := 'SHA256';
    taSHA512: Result := 'SHA512';
  else
    Result := 'SHA1';
  end;
end;

function TQRCodeURIBuilder.Build(const ASecret: string;
  const AConfig: ITOTPConfig): string;
var
  LLabel: string;
  LParams: string;
begin
  if ASecret.IsEmpty then
    raise EArgumentException.Create('Secret não pode ser vazio');

  if AConfig.Issuer.IsEmpty then
    raise EArgumentException.Create('Issuer é obrigatório para o QR Code');

  // Label: issuer:account
  LLabel := Format('%s:%s', [
    URLEncode(AConfig.Issuer),
    URLEncode(AConfig.AccountName)
  ]);

  // Parâmetros
  LParams := Format('secret=%s&issuer=%s&algorithm=%s&digits=%d&period=%d', [
    ASecret, // Base32 sem encoding adicional
    URLEncode(AConfig.Issuer),
    AlgorithmToString(AConfig.Algorithm),
    AConfig.Digits,
    AConfig.Period
  ]);

  Result := Format('otpauth://totp/%s?%s', [LLabel, LParams]);
end;

end.
