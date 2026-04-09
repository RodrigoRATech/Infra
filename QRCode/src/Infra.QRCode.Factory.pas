unit Infra.QRCode.Factory;

interface

uses
  Infra.QRCode.Types,
  Infra.QRCode.Contracts,
  Infra.QRCode.Content,
  Infra.QRCode.Builder;

type
  TQRCode = class sealed
  public
    // ── Gerador ───────────────────────────────────────────────────
    class function New: IQRCodeGenerator;

    // ── Conteúdos ─────────────────────────────────────────────────
    class function Text(const AText: string): IQRContentBuilder;
    class function URL(const AURL: string): IQRContentBuilder;
    class function Email(const AAddress: string;
                         const ASubject: string = '';
                         const ABody: string = ''): IQRContentBuilder;
    class function Phone(const APhone: string): IQRContentBuilder;
    class function SMS(const APhone: string;
                       const AMessage: string = ''): IQRContentBuilder;
    class function WhatsApp(const APhone: string;
                            const AMessage: string = ''): IQRContentBuilder;
    class function WiFi(const ASSID: string;
                        const APassword: string;
                        const AEncryption: TQRWiFiEncryption = weWPA;
                        const AHidden: Boolean = False): IQRContentBuilder;
    class function GeoLocation(const ALatitude, ALongitude: Double;
                               const AAltitude: Double = 0): IQRContentBuilder;
    class function VCard(const AName: string): TQRContentVCard;
    class function MeCard(const AName: string): TQRContentMeCard;
    class function PIX(const APixKey: string;
                       const AMerchantName: string;
                       const ACity: string;
                       const AAmount: Currency = 0;
                       const ADescription: string = '';
                       const ATXID: string = '***'): IQRContentBuilder;
  end;

implementation

uses
{$IFDEF VCL}
   Infra.QRCode.Renderer.VCL
{$ELSE}
   Infra.QRCode.Renderer.FMX
{$ENDIF}
;

{ TQRCode }

class function TQRCode.New: IQRCodeGenerator;
var
  LRenderer: IQRCodeRenderer;
begin
  //
  // Seleção automática do renderer em tempo de compilação.
  // Zero overhead em runtime — decisão 100% estática.
  //
  {$IFDEF VCL}
  LRenderer := TQRCodeRendererVCL.Create(TQRRenderOptions.Default);
  {$ELSE}
  LRenderer := TQRCodeRendererFMX.Create(TQRRenderOptions.Default);
  {$ENDIF}

  Result := TQRCodeGenerator.Create(LRenderer);
end;

class function TQRCode.Text(const AText: string): IQRContentBuilder;
begin
  Result := TQRContentText.Create(AText);
end;

class function TQRCode.URL(const AURL: string): IQRContentBuilder;
begin
  Result := TQRContentURL.Create(AURL);
end;

class function TQRCode.Email(const AAddress, ASubject,
  ABody: string): IQRContentBuilder;
begin
  Result := TQRContentEmail.Create(AAddress, ASubject, ABody);
end;

class function TQRCode.Phone(const APhone: string): IQRContentBuilder;
begin
  Result := TQRContentPhone.Create(APhone);
end;

class function TQRCode.SMS(const APhone,
  AMessage: string): IQRContentBuilder;
begin
  Result := TQRContentSMS.Create(APhone, AMessage);
end;

class function TQRCode.WhatsApp(const APhone,
  AMessage: string): IQRContentBuilder;
begin
  Result := TQRContentWhatsApp.Create(APhone, AMessage);
end;

class function TQRCode.WiFi(const ASSID, APassword: string;
  const AEncryption: TQRWiFiEncryption;
  const AHidden: Boolean): IQRContentBuilder;
begin
  Result := TQRContentWiFi.Create(ASSID, APassword, AEncryption, AHidden);
end;

class function TQRCode.GeoLocation(const ALatitude, ALongitude,
  AAltitude: Double): IQRContentBuilder;
begin
  Result := TQRContentGeoLocation.Create(ALatitude, ALongitude, AAltitude);
end;

class function TQRCode.VCard(const AName: string): TQRContentVCard;
begin
  Result := TQRContentVCard.Create(AName);
end;

class function TQRCode.MeCard(const AName: string): TQRContentMeCard;
begin
  Result := TQRContentMeCard.Create(AName);
end;

class function TQRCode.PIX(const APixKey, AMerchantName, ACity: string;
  const AAmount: Currency; const ADescription,
  ATXID: string): IQRContentBuilder;
begin
  Result := TQRContentPIX.Create(APixKey, AMerchantName, ACity,
                                  AAmount, ADescription, ATXID);
end;

end.
