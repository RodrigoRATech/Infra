unit Infra.QRCode.Content;

interface

uses
  SysUtils,
  Infra.QRCode.Types,
  Infra.QRCode.Contracts;

type
  // -------------------------------------------------------------------------
  // Base abstrata — Open/Closed Principle
  // -------------------------------------------------------------------------
  TQRContentBase = class abstract(TInterfacedObject, IQRContentBuilder)
  public
    function Build: string; virtual; abstract;
    function ContentType: TQRContentType; virtual; abstract;
  end;

  // -------------------------------------------------------------------------
  // Texto simples
  // -------------------------------------------------------------------------
  TQRContentText = class(TQRContentBase)
  private
    FText: string;
  public
    constructor Create(const AText: string);
    function Build: string; override;
    function ContentType: TQRContentType; override;
  end;

  // -------------------------------------------------------------------------
  // URL
  // -------------------------------------------------------------------------
  TQRContentURL = class(TQRContentBase)
  private
    FURL: string;
  public
    constructor Create(const AURL: string);
    function Build: string; override;
    function ContentType: TQRContentType; override;
  end;

  // -------------------------------------------------------------------------
  // E-mail
  // -------------------------------------------------------------------------
  TQRContentEmail = class(TQRContentBase)
  private
    FAddress : string;
    FSubject : string;
    FBody    : string;
  public
    constructor Create(const AAddress: string;
                       const ASubject: string = '';
                       const ABody: string = '');
    function Build: string; override;
    function ContentType: TQRContentType; override;
  end;

  // -------------------------------------------------------------------------
  // Telefone
  // -------------------------------------------------------------------------
  TQRContentPhone = class(TQRContentBase)
  private
    FPhone: string;
  public
    constructor Create(const APhone: string);
    function Build: string; override;
    function ContentType: TQRContentType; override;
  end;

  // -------------------------------------------------------------------------
  // SMS
  // -------------------------------------------------------------------------
  TQRContentSMS = class(TQRContentBase)
  private
    FPhone   : string;
    FMessage : string;
  public
    constructor Create(const APhone: string; const AMessage: string = '');
    function Build: string; override;
    function ContentType: TQRContentType; override;
  end;

  // -------------------------------------------------------------------------
  // WhatsApp
  // -------------------------------------------------------------------------
  TQRContentWhatsApp = class(TQRContentBase)
  private
    FPhone   : string;
    FMessage : string;
  public
    constructor Create(const APhone: string; const AMessage: string = '');
    function Build: string; override;
    function ContentType: TQRContentType; override;
  end;

  // -------------------------------------------------------------------------
  // Wi-Fi
  // -------------------------------------------------------------------------
  TQRContentWiFi = class(TQRContentBase)
  private
    FSSID       : string;
    FPassword   : string;
    FEncryption : TQRWiFiEncryption;
    FHidden     : Boolean;
    function EncryptionToStr: string;
  public
    constructor Create(const ASSID: string;
                       const APassword: string;
                       const AEncryption: TQRWiFiEncryption = weWPA;
                       const AHidden: Boolean = False);
    function Build: string; override;
    function ContentType: TQRContentType; override;
  end;

  // -------------------------------------------------------------------------
  // Geolocalização
  // -------------------------------------------------------------------------
  TQRContentGeoLocation = class(TQRContentBase)
  private
    FLatitude  : Double;
    FLongitude : Double;
    FAltitude  : Double;
  public
    constructor Create(const ALatitude, ALongitude: Double;
                       const AAltitude: Double = 0);
    function Build: string; override;
    function ContentType: TQRContentType; override;
  end;

  // -------------------------------------------------------------------------
  // vCard 3.0
  // -------------------------------------------------------------------------
  TQRContentVCard = class(TQRContentBase)
  private
    FName         : string;
    FOrganization : string;
    FTitle        : string;
    FPhone        : string;
    FEmail        : string;
    FAddress      : string;
    FWebsite      : string;
    FNote         : string;
  public
    constructor Create(const AName: string);
    function SetOrganization(const AValue: string): TQRContentVCard;
    function SetTitle(const AValue: string): TQRContentVCard;
    function SetPhone(const AValue: string): TQRContentVCard;
    function SetEmail(const AValue: string): TQRContentVCard;
    function SetAddress(const AValue: string): TQRContentVCard;
    function SetWebsite(const AValue: string): TQRContentVCard;
    function SetNote(const AValue: string): TQRContentVCard;
    function Build: string; override;
    function ContentType: TQRContentType; override;
  end;

  // -------------------------------------------------------------------------
  // MeCard (padrão NTT DoCoMo — mais compacto que vCard)
  // -------------------------------------------------------------------------
  TQRContentMeCard = class(TQRContentBase)
  private
    FName    : string;
    FPhone   : string;
    FEmail   : string;
    FAddress : string;
    FNote    : string;
  public
    constructor Create(const AName: string);
    function SetPhone(const AValue: string): TQRContentMeCard;
    function SetEmail(const AValue: string): TQRContentMeCard;
    function SetAddress(const AValue: string): TQRContentMeCard;
    function SetNote(const AValue: string): TQRContentMeCard;
    function Build: string; override;
    function ContentType: TQRContentType; override;
  end;

  // -------------------------------------------------------------------------
  // PIX (Padrão Brasileiro de Pagamento Instantâneo — EMV/QRCode)
  // -------------------------------------------------------------------------
  TQRContentPIX = class(TQRContentBase)
  private
    FPixKey       : string;
    FMerchantName : string;
    FCity         : string;
    FAmount       : Currency;
    FDescription  : string;
    FTXID         : string;
    function BuildEMV: string;
    function CRC16(const AData: string): string;
    function FormatField(const AID: string; const AValue: string): string;
  public
    constructor Create(const APixKey: string;
                       const AMerchantName: string;
                       const ACity: string;
                       const AAmount: Currency = 0;
                       const ADescription: string = '';
                       const ATXID: string = '***');
    function Build: string; override;
    function ContentType: TQRContentType; override;
  end;

implementation

uses
  StrUtils;

{ TQRContentText }

constructor TQRContentText.Create(const AText: string);
begin
  inherited Create;
  FText := AText;
end;

function TQRContentText.Build: string;
begin
  Result := FText;
end;

function TQRContentText.ContentType: TQRContentType;
begin
  Result := ctText;
end;

{ TQRContentURL }

constructor TQRContentURL.Create(const AURL: string);
begin
  inherited Create;
  FURL := AURL;
end;

function TQRContentURL.Build: string;
begin
  Result := FURL;
end;

function TQRContentURL.ContentType: TQRContentType;
begin
  Result := ctURL;
end;

{ TQRContentEmail }

constructor TQRContentEmail.Create(const AAddress, ASubject, ABody: string);
begin
  inherited Create;
  FAddress := AAddress;
  FSubject := ASubject;
  FBody    := ABody;
end;

function TQRContentEmail.Build: string;
var
  LParams: string;
begin
  LParams := '';

  if FSubject <> '' then
    LParams := 'subject=' + FSubject;

  if FBody <> '' then
  begin
    if LParams <> '' then
      LParams := LParams + '&';
    LParams := LParams + 'body=' + FBody;
  end;

  if LParams <> '' then
    Result := Format('mailto:%s?%s', [FAddress, LParams])
  else
    Result := Format('mailto:%s', [FAddress]);
end;

function TQRContentEmail.ContentType: TQRContentType;
begin
  Result := ctEmail;
end;

{ TQRContentPhone }

constructor TQRContentPhone.Create(const APhone: string);
begin
  inherited Create;
  FPhone := APhone;
end;

function TQRContentPhone.Build: string;
begin
  Result := 'tel:' + FPhone;
end;

function TQRContentPhone.ContentType: TQRContentType;
begin
  Result := ctPhone;
end;

{ TQRContentSMS }

constructor TQRContentSMS.Create(const APhone: string; const AMessage: string);
begin
  inherited Create;
  FPhone   := APhone;
  FMessage := AMessage;
end;

function TQRContentSMS.Build: string;
begin
  if FMessage <> '' then
    Result := Format('SMSTO:%s:%s', [FPhone, FMessage])
  else
    Result := Format('SMSTO:%s', [FPhone]);
end;

function TQRContentSMS.ContentType: TQRContentType;
begin
  Result := ctSMS;
end;

{ TQRContentWhatsApp }

constructor TQRContentWhatsApp.Create(const APhone: string; const AMessage: string);
begin
  inherited Create;
  FPhone   := APhone;
  FMessage := AMessage;
end;

function TQRContentWhatsApp.Build: string;
begin
  if FMessage <> '' then
    Result := Format('https://wa.me/%s?text=%s', [FPhone, FMessage])
  else
    Result := Format('https://wa.me/%s', [FPhone]);
end;

function TQRContentWhatsApp.ContentType: TQRContentType;
begin
  Result := ctWhatsApp;
end;

{ TQRContentWiFi }

constructor TQRContentWiFi.Create(const ASSID, APassword: string;
  const AEncryption: TQRWiFiEncryption; const AHidden: Boolean);
begin
  inherited Create;
  FSSID       := ASSID;
  FPassword   := APassword;
  FEncryption := AEncryption;
  FHidden     := AHidden;
end;

function TQRContentWiFi.EncryptionToStr: string;
begin
  case FEncryption of
    weWEP : Result := 'WEP';
    weWPA : Result := 'WPA';
  else
    Result := 'nopass';
  end;
end;

function TQRContentWiFi.Build: string;
var
  LHidden: string;
begin
  LHidden := IfThen(FHidden, 'true', 'false');
  Result := Format('WIFI:T:%s;S:%s;P:%s;H:%s;;',
    [EncryptionToStr, FSSID, FPassword, LHidden]);
end;

function TQRContentWiFi.ContentType: TQRContentType;
begin
  Result := ctWiFi;
end;

{ TQRContentGeoLocation }

constructor TQRContentGeoLocation.Create(const ALatitude, ALongitude,
  AAltitude: Double);
begin
  inherited Create;
  FLatitude  := ALatitude;
  FLongitude := ALongitude;
  FAltitude  := AAltitude;
end;

function TQRContentGeoLocation.Build: string;
var
  LFormatSettings: TFormatSettings;
begin
  LFormatSettings := TFormatSettings.Create('en-US');

  if FAltitude <> 0 then
    Result := Format('geo:%s,%s,%s',
      [FloatToStr(FLatitude, LFormatSettings),
       FloatToStr(FLongitude, LFormatSettings),
       FloatToStr(FAltitude, LFormatSettings)])
  else
    Result := Format('geo:%s,%s',
      [FloatToStr(FLatitude, LFormatSettings),
       FloatToStr(FLongitude, LFormatSettings)]);
end;

function TQRContentGeoLocation.ContentType: TQRContentType;
begin
  Result := ctGeoLocation;
end;

{ TQRContentVCard }

constructor TQRContentVCard.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

function TQRContentVCard.SetOrganization(const AValue: string): TQRContentVCard;
begin
  FOrganization := AValue;
  Result := Self;
end;

function TQRContentVCard.SetTitle(const AValue: string): TQRContentVCard;
begin
  FTitle := AValue;
  Result := Self;
end;

function TQRContentVCard.SetPhone(const AValue: string): TQRContentVCard;
begin
  FPhone := AValue;
  Result := Self;
end;

function TQRContentVCard.SetEmail(const AValue: string): TQRContentVCard;
begin
  FEmail := AValue;
  Result := Self;
end;

function TQRContentVCard.SetAddress(const AValue: string): TQRContentVCard;
begin
  FAddress := AValue;
  Result := Self;
end;

function TQRContentVCard.SetWebsite(const AValue: string): TQRContentVCard;
begin
  FWebsite := AValue;
  Result := Self;
end;

function TQRContentVCard.SetNote(const AValue: string): TQRContentVCard;
begin
  FNote := AValue;
  Result := Self;
end;

function TQRContentVCard.Build: string;
const
  CRLF = #13#10;
begin
  Result := 'BEGIN:VCARD' + CRLF;
  Result := Result + 'VERSION:3.0' + CRLF;
  Result := Result + 'N:' + FName + CRLF;
  Result := Result + 'FN:' + FName + CRLF;

  if FOrganization <> '' then
    Result := Result + 'ORG:' + FOrganization + CRLF;

  if FTitle <> '' then
    Result := Result + 'TITLE:' + FTitle + CRLF;

  if FPhone <> '' then
    Result := Result + 'TEL;TYPE=CELL:' + FPhone + CRLF;

  if FEmail <> '' then
    Result := Result + 'EMAIL:' + FEmail + CRLF;

  if FAddress <> '' then
    Result := Result + 'ADR:;;' + FAddress + CRLF;

  if FWebsite <> '' then
    Result := Result + 'URL:' + FWebsite + CRLF;

  if FNote <> '' then
    Result := Result + 'NOTE:' + FNote + CRLF;

  Result := Result + 'END:VCARD';
end;

function TQRContentVCard.ContentType: TQRContentType;
begin
  Result := ctVCard;
end;

{ TQRContentMeCard }

constructor TQRContentMeCard.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

function TQRContentMeCard.SetPhone(const AValue: string): TQRContentMeCard;
begin
  FPhone := AValue;
  Result := Self;
end;

function TQRContentMeCard.SetEmail(const AValue: string): TQRContentMeCard;
begin
  FEmail := AValue;
  Result := Self;
end;

function TQRContentMeCard.SetAddress(const AValue: string): TQRContentMeCard;
begin
  FAddress := AValue;
  Result := Self;
end;

function TQRContentMeCard.SetNote(const AValue: string): TQRContentMeCard;
begin
  FNote := AValue;
  Result := Self;
end;

function TQRContentMeCard.Build: string;
begin
  Result := 'MECARD:N:' + FName + ';';

  if FPhone <> '' then
    Result := Result + 'TEL:' + FPhone + ';';

  if FEmail <> '' then
    Result := Result + 'EMAIL:' + FEmail + ';';

  if FAddress <> '' then
    Result := Result + 'ADR:' + FAddress + ';';

  if FNote <> '' then
    Result := Result + 'NOTE:' + FNote + ';';

  Result := Result + ';';
end;

function TQRContentMeCard.ContentType: TQRContentType;
begin
  Result := ctMeCard;
end;

{ TQRContentPIX }

constructor TQRContentPIX.Create(const APixKey, AMerchantName, ACity: string;
  const AAmount: Currency; const ADescription: string; const ATXID: string);
begin
  inherited Create;
  FPixKey       := APixKey;
  FMerchantName := AMerchantName;
  FCity         := ACity;
  FAmount       := AAmount;
  FDescription  := ADescription;
  FTXID         := ATXID;
end;

function TQRContentPIX.FormatField(const AID: string; const AValue: string): string;
begin
  Result := AID + Format('%.2d', [Length(AValue)]) + AValue;
end;

function TQRContentPIX.CRC16(const AData: string): string;
const
  POLYNOMIAL = $1021;
var
  LCrc : Word;
  I, J : Integer;
  LByte: Byte;
begin
  LCrc := $FFFF;

  for I := 1 to Length(AData) do
  begin
    LByte := Ord(AData[I]);
    LCrc := LCrc xor (Word(LByte) shl 8);

    for J := 0 to 7 do
    begin
      if (LCrc and $8000) <> 0 then
        LCrc := (LCrc shl 1) xor POLYNOMIAL
      else
        LCrc := LCrc shl 1;
    end;
  end;

  Result := IntToHex(LCrc, 4);
end;

function TQRContentPIX.BuildEMV: string;
var
  LGUI        : string;
  LMerchInfo  : string;
  LAmount     : string;
  LAddInfo    : string;
  LPayload    : string;
  LFormatSets : TFormatSettings;
begin
  // Merchant Account Information (ID 26)
  LGUI       := FormatField('00', 'BR.GOV.BCB.PIX');
  LGUI       := LGUI + FormatField('01', FPixKey);

  if FDescription <> '' then
    LGUI := LGUI + FormatField('02', FDescription);

  LMerchInfo := FormatField('26', LGUI);

  // Merchant Category Code (ID 52)
  LPayload := FormatField('00', '01');          // Payload Format Indicator
  LPayload := LPayload + LMerchInfo;
  LPayload := LPayload + FormatField('52', '0000');  // MCC
  LPayload := LPayload + FormatField('53', '986');   // Moeda BRL

  // Amount (ID 54) — opcional
  if FAmount > 0 then
  begin
    LFormatSets        := TFormatSettings.Create('en-US');
    LFormatSets.DecimalSeparator := '.';
    LAmount := Format('%.2f', [FAmount], LFormatSets);
    LPayload := LPayload + FormatField('54', LAmount);
  end;

  LPayload := LPayload + FormatField('58', 'BR');         // Country Code
  LPayload := LPayload + FormatField('59', Copy(FMerchantName, 1, 25)); // Merchant Name
  LPayload := LPayload + FormatField('60', Copy(FCity, 1, 15));         // Merchant City

  // Additional Data Field Template (ID 62)
  LAddInfo := FormatField('05', FTXID);  // Reference Label
  LPayload := LPayload + FormatField('62', LAddInfo);

  // CRC16 (ID 63) — calculado sobre todo payload + '6304'
  LPayload := LPayload + '6304';
  Result   := LPayload + CRC16(LPayload);
end;

function TQRContentPIX.Build: string;
begin
  Result := BuildEMV;
end;

function TQRContentPIX.ContentType: TQRContentType;
begin
  Result := ctPIX;
end;

end.
