unit Infra.QRCode.Renderer.VCL;

// Este unit só deve ser incluído em projetos VCL.
// Em projetos FMX, use QRCode.Renderer.FMX.pas

interface

uses
  SysUtils,
  Classes,
  Graphics,
  Vcl.Imaging.PNGImage,
  DelphiZXingQRCode,
  Infra.QRCode.Types,
  Infra.QRCode.Contracts;

type
  /// <summary>
  ///   Renderer para projetos VCL.
  ///   Usa GDI (Canvas.FillRect) para renderização dos módulos.
  ///   Usa TPNGImage para exportação PNG.
  /// </summary>
  TQRCodeRendererVCL = class(TInterfacedObject, IQRCodeRenderer)
  private
    FOptions: TQRRenderOptions;
    function BuildBitmap(const AQRCode: TDelphiZXingQRCode): TBitmap;
    function BitmapToPNG(const ABitmap: TBitmap): TPNGImage;
  public
    constructor Create(const AOptions: TQRRenderOptions);
    function  RenderBitmap(const AQRCode: TDelphiZXingQRCode): TBitmap;
    procedure RenderBitmapToStream(const AQRCode: TDelphiZXingQRCode;
                                   const AStream: TStream);
    procedure RenderPNGToStream(const AQRCode: TDelphiZXingQRCode;
                                const AStream: TStream);
    procedure RenderPNGToFile(const AQRCode: TDelphiZXingQRCode;
                              const AFilePath: string);
  end;

implementation

{ TQRCodeRendererVCL }

constructor TQRCodeRendererVCL.Create(const AOptions: TQRRenderOptions);
begin
  inherited Create;
  FOptions := AOptions;
end;

function TQRCodeRendererVCL.BuildBitmap(
  const AQRCode: TDelphiZXingQRCode): TBitmap;
var
  LOffset    : Integer;
  LTotalSize : Integer;
  LRow, LCol : Integer;
  LX, LY     : Integer;
begin
  LOffset    := FOptions.QuietZone * FOptions.PixelSize;
  LTotalSize := (AQRCode.Rows * FOptions.PixelSize) + (LOffset * 2);

  Result := TBitmap.Create;
  try
    Result.Width       := LTotalSize;
    Result.Height      := LTotalSize;
    Result.PixelFormat := pf24bit;

    // Fundo
    Result.Canvas.Brush.Color := FOptions.BackColor;
    Result.Canvas.Brush.Style := bsSolid;
    Result.Canvas.FillRect(Rect(0, 0, LTotalSize, LTotalSize));

    // Módulos
    for LRow := 0 to AQRCode.Rows - 1 do
    begin
      for LCol := 0 to AQRCode.Columns - 1 do
      begin
        LX := LOffset + (LCol * FOptions.PixelSize);
        LY := LOffset + (LRow * FOptions.PixelSize);

        if AQRCode.IsBlack[LRow, LCol] then
          Result.Canvas.Brush.Color := FOptions.ForeColor
        else
          Result.Canvas.Brush.Color := FOptions.BackColor;

        Result.Canvas.FillRect(
          Rect(LX, LY, LX + FOptions.PixelSize, LY + FOptions.PixelSize));
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TQRCodeRendererVCL.BitmapToPNG(const ABitmap: TBitmap): TPNGImage;
begin
  Result := TPNGImage.Create;
  try
    Result.Assign(ABitmap);
  except
    Result.Free;
    raise;
  end;
end;

function TQRCodeRendererVCL.RenderBitmap(
  const AQRCode: TDelphiZXingQRCode): TBitmap;
begin
  Result := BuildBitmap(AQRCode);
end;

procedure TQRCodeRendererVCL.RenderBitmapToStream(
  const AQRCode: TDelphiZXingQRCode; const AStream: TStream);
var
  LBitmap: TBitmap;
begin
  LBitmap := BuildBitmap(AQRCode);
  try
    LBitmap.SaveToStream(AStream);
    AStream.Position := 0;
  finally
    LBitmap.Free;
  end;
end;

procedure TQRCodeRendererVCL.RenderPNGToStream(
  const AQRCode: TDelphiZXingQRCode; const AStream: TStream);
var
  LBitmap : TBitmap;
  LPNG    : TPNGImage;
begin
  LBitmap := BuildBitmap(AQRCode);
  try
    LPNG := BitmapToPNG(LBitmap);
    try
      LPNG.SaveToStream(AStream);
      AStream.Position := 0;
    finally
      LPNG.Free;
    end;
  finally
    LBitmap.Free;
  end;
end;

procedure TQRCodeRendererVCL.RenderPNGToFile(
  const AQRCode: TDelphiZXingQRCode; const AFilePath: string);
var
  LBitmap : TBitmap;
  LPNG    : TPNGImage;
  LDir    : string;
begin
  LDir := ExtractFileDir(AFilePath);
  if (LDir <> '') and not DirectoryExists(LDir) then
    ForceDirectories(LDir);

  LBitmap := BuildBitmap(AQRCode);
  try
    LPNG := BitmapToPNG(LBitmap);
    try
      LPNG.SaveToFile(AFilePath);
    finally
      LPNG.Free;
    end;
  finally
    LBitmap.Free;
  end;
end;

end.
