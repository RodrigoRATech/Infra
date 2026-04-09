unit Infra.QRCode.Types;

{$IFDEF FMX}
  {$DEFINE IS_FMX}
{$ENDIF}

interface

{$IFDEF IS_FMX}
uses
  FMX.Types,
  FMX.Graphics;
{$ELSE}
uses
  Vcl.Graphics;
{$ENDIF}

type
  TQRErrorLevel = (
    elLow,
    elMedium,
    elQuartile,
    elHigh
  );

  TQRContentType = (
    ctText, ctURL, ctEmail, ctPhone, ctSMS,
    ctWhatsApp, ctWiFi, ctGeoLocation, ctVCard, ctMeCard, ctPIX
  );

  TQRWiFiEncryption = (
    weNone, weWEP, weWPA
  );

  TQROutputFormat = (
    ofBitmap,
    ofPNG,
    ofStream,
    ofPNGStream
  );

  {$IFDEF IS_FMX}
  /// <summary>Em FMX usamos TAlphaColor (ARGB 32-bit).</summary>
  TQRColor = TAlphaColor;
  {$ELSE}
  /// <summary>Em VCL usamos TColor (BGR Windows GDI).</summary>
  TQRColor = TColor;
  {$ENDIF}

  /// <summary>
  ///   Opções de renderização unificadas para VCL e FMX.
  ///   TQRColor é resolvido em tempo de compilação por plataforma.
  /// </summary>
  TQRRenderOptions = record
    PixelSize : Integer;
    QuietZone : Integer;
    ForeColor : TQRColor;
    BackColor : TQRColor;
    class function Default: TQRRenderOptions; static;
  end;

const
  QR_DEFAULT_PIXEL_SIZE = 4;
  QR_DEFAULT_QUIET_ZONE = 4;

  {$IFDEF IS_FMX}
  QR_DEFAULT_FORE : TQRColor = $FF000000; // TAlphaColors.Black
  QR_DEFAULT_BACK : TQRColor = $FFFFFFFF; // TAlphaColors.White
  {$ELSE}
  QR_DEFAULT_FORE : TQRColor = clBlack;
  QR_DEFAULT_BACK : TQRColor = clWhite;
  {$ENDIF}

implementation

class function TQRRenderOptions.Default: TQRRenderOptions;
begin
  Result.PixelSize := QR_DEFAULT_PIXEL_SIZE;
  Result.QuietZone := QR_DEFAULT_QUIET_ZONE;
  Result.ForeColor := QR_DEFAULT_FORE;
  Result.BackColor := QR_DEFAULT_BACK;
end;

end.
