unit Infra.QRCode.Contracts;

interface

uses
  Classes,
  DelphiZXingQRCode,
  Infra.QRCode.Types

{$IFDEF VCL}
, VCL.Graphics
{$ELSE}
, FMX.Graphics
{$ENDIF}
;

type
  // ── Contrato do Renderer (Strategy Pattern) ───────────────────────────────
  /// <summary>
  ///   Abstração do renderer de QRCode.
  ///   Permite trocar implementação VCL ↔ FMX sem alterar o Builder.
  ///   GoF: Strategy Pattern.
  /// </summary>
  IQRCodeRenderer = interface
    ['{C3D4E5F6-A7B8-9012-CDEF-123456789012}']
    function  RenderBitmap(const AQRCode: TDelphiZXingQRCode): TBitmap;
    procedure RenderBitmapToStream(const AQRCode: TDelphiZXingQRCode;
                                   const AStream: TStream);
    procedure RenderPNGToStream(const AQRCode: TDelphiZXingQRCode;
                                const AStream: TStream);
    procedure RenderPNGToFile(const AQRCode: TDelphiZXingQRCode;
                              const AFilePath: string);
  end;

  // ── Contrato do Content Builder ───────────────────────────────────────────
  IQRContentBuilder = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function Build: string;
    function ContentType: TQRContentType;
  end;

  // ── Contrato do Generator ─────────────────────────────────────────────────
  IQRCodeGenerator = interface
    ['{B2C3D4E5-F6A7-8901-BCDE-F12345678901}']
    function SetContent(const ABuilder: IQRContentBuilder): IQRCodeGenerator;
    function SetErrorLevel(const ALevel: TQRErrorLevel): IQRCodeGenerator;
    function SetRenderOptions(const AOptions: TQRRenderOptions): IQRCodeGenerator;

    function GenerateBitmap: TBitmap;
    function GeneratePNGFile(const AFilePath: string): IQRCodeGenerator;
    function GenerateBitmapStream(const AStream: TStream): IQRCodeGenerator;
    function GeneratePNGStream(const AStream: TStream): IQRCodeGenerator;
    function GenerateBase64: string;
    function GenerateDataURI: string;
    function GetRawData: string;
  end;

implementation

end.
