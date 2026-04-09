unit Infra.QRCode.Renderer.FMX;

// Este unit só deve ser incluído em projetos FMX.
// Em projetos VCL, use QRCode.Renderer.VCL.pas

interface

uses
  SysUtils,
  Classes,
  FMX.Graphics,
  FMX.Surfaces,
  FMX.Types,
  DelphiZXingQRCode,
  Infra.QRCode.Types,
  Infra.QRCode.Contracts;

type
  /// <summary>
  ///   Renderer para projetos FireMonkey (FMX).
  ///
  ///   DIFERENÇAS CHAVE em relação ao VCL:
  ///
  ///   1. TBitmap é FMX.Graphics.TBitmap — não tem PixelFormat configurável.
  ///      Sempre opera em BGRA 32-bit internamente.
  ///
  ///   2. Canvas.Pixels[] NÃO existe em FMX.
  ///      Renderização via TBitmapData.SetPixel (acesso direto à memória).
  ///      É SIGNIFICATIVAMENTE mais rápido que pixel-a-pixel via Canvas.
  ///
  ///   3. TPNGImage NÃO existe em FMX.
  ///      PNG é gerado via TBitmapCodecManager + TBitmapSurface.
  ///      Funciona em todas as plataformas: Windows, macOS, iOS, Android.
  ///
  ///   4. TAlphaColor em vez de TColor.
  ///      Formato ARGB: $AARRGGBB.
  ///
  ///   5. Canvas.BeginScene / EndScene são obrigatórios em FMX para
  ///      operações de desenho via Canvas. O uso direto de TBitmapData
  ///      (Map/Unmap) é preferível para fill de regiões e é thread-safe.
  /// </summary>
  TQRCodeRendererFMX = class(TInterfacedObject, IQRCodeRenderer)
  private
    FOptions: TQRRenderOptions;

    /// <summary>
    ///   Renderiza a matriz ZXing diretamente em memória via TBitmapData.
    ///   Não usa Canvas — evita BeginScene/EndScene e é multiplataforma.
    ///   Preenche regiões de PixelSize × PixelSize pixels por módulo.
    /// </summary>
    function BuildBitmap(const AQRCode: TDelphiZXingQRCode): TBitmap;

    /// <summary>
    ///   Salva TBitmap FMX como PNG em stream usando TBitmapCodecManager.
    ///   Este é o método correto em FMX — TPNGImage não existe.
    /// </summary>
    procedure SaveBitmapAsPNG(const ABitmap: TBitmap; const AStream: TStream);
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

uses
  System.UITypes; // TAlphaColorRec

{ TQRCodeRendererFMX }

constructor TQRCodeRendererFMX.Create(const AOptions: TQRRenderOptions);
begin
  inherited Create;
  FOptions := AOptions;
end;

function TQRCodeRendererFMX.BuildBitmap(
  const AQRCode: TDelphiZXingQRCode): TBitmap;
var
  LBmpData   : TBitmapData;
  LOffset    : Integer;
  LTotalSize : Integer;
  LRow, LCol : Integer;
  LPxRow, LPxCol : Integer;
  LX, LY     : Integer;
  LColor     : TAlphaColor;
begin
  LOffset    := FOptions.QuietZone * FOptions.PixelSize;
  LTotalSize := (AQRCode.Rows * FOptions.PixelSize) + (LOffset * 2);

  Result := TBitmap.Create(LTotalSize, LTotalSize);
  try
    //
    // PONTO CRÍTICO FMX:
    // Map() bloqueia o bitmap para acesso direto à memória (read/write).
    // É OBRIGATÓRIO chamar Unmap() ao final, mesmo
    // PONTO CRÍTICO FMX:
    // Map() bloqueia o bitmap para acesso direto à memória (read/write).
    // É OBRIGATÓRIO chamar Unmap() ao final, mesmo em caso de exceção.
    // Isso é equivalente ao ScanLine[] do VCL, porém multiplataforma.
    //
    if not Result.Map(TMapAccess.Write, LBmpData) then
      raise EInvalidOpException.Create(
        'Falha ao mapear TBitmapData para escrita (FMX).');
    try
      // Preenche fundo completo com BackColor
      for LPxRow := 0 to LTotalSize - 1 do
        for LPxCol := 0 to LTotalSize - 1 do
          LBmpData.SetPixel(LPxCol, LPxRow, FOptions.BackColor);

      // Renderiza cada módulo como bloco PixelSize × PixelSize
      for LRow := 0 to AQRCode.Rows - 1 do
      begin
        for LCol := 0 to AQRCode.Columns - 1 do
        begin
          LX := LOffset + (LCol * FOptions.PixelSize);
          LY := LOffset + (LRow * FOptions.PixelSize);

          if AQRCode.IsBlack[LRow, LCol] then
            LColor := FOptions.ForeColor
          else
            LColor := FOptions.BackColor;

          // Preenche o bloco do módulo pixel a pixel via BitmapData
          for LPxRow := 0 to FOptions.PixelSize - 1 do
            for LPxCol := 0 to FOptions.PixelSize - 1 do
              LBmpData.SetPixel(LX + LPxCol, LY + LPxRow, LColor);
        end;
      end;
    finally
      Result.Unmap(LBmpData);
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure TQRCodeRendererFMX.SaveBitmapAsPNG(const ABitmap: TBitmap;
  const AStream: TStream);
var
  LSurface: TBitmapSurface;
begin
  //
  // PONTO CRÍTICO FMX:
  // TPNGImage NÃO existe em FMX.
  // O caminho correto é: TBitmap → TBitmapSurface → TBitmapCodecManager.
  // TBitmapCodecManager detecta o formato pelo MIME type informado
  // e funciona em Windows, macOS, iOS e Android sem alteração de código.
  //
  LSurface := TBitmapSurface.Create;
  try
    LSurface.Assign(ABitmap);
    if not TBitmapCodecManager.SaveToStream(AStream, LSurface, '.png') then
      raise EInvalidOpException.Create(
        'Falha ao codificar QRCode como PNG via TBitmapCodecManager.');
    AStream.Position := 0;
  finally
    LSurface.Free;
  end;
end;

function TQRCodeRendererFMX.RenderBitmap(
  const AQRCode: TDelphiZXingQRCode): TBitmap;
begin
  Result := BuildBitmap(AQRCode);
end;

procedure TQRCodeRendererFMX.RenderBitmapToStream(
  const AQRCode: TDelphiZXingQRCode; const AStream: TStream);
var
  LBitmap: TBitmap;
begin
  LBitmap := BuildBitmap(AQRCode);
  try
    //
    // Em FMX, TBitmap.SaveToStream salva como BMP nativo da plataforma.
    // Para stream BMP explícito, usamos SaveToStream diretamente.
    //
    LBitmap.SaveToStream(AStream);
    AStream.Position := 0;
  finally
    LBitmap.Free;
  end;
end;

procedure TQRCodeRendererFMX.RenderPNGToStream(
  const AQRCode: TDelphiZXingQRCode; const AStream: TStream);
var
  LBitmap: TBitmap;
begin
  LBitmap := BuildBitmap(AQRCode);
  try
    SaveBitmapAsPNG(LBitmap, AStream);
  finally
    LBitmap.Free;
  end;
end;

procedure TQRCodeRendererFMX.RenderPNGToFile(
  const AQRCode: TDelphiZXingQRCode; const AFilePath: string);
var
  LBitmap  : TBitmap;
  LSurface : TBitmapSurface;
  LDir     : string;
begin
  LDir := ExtractFileDir(AFilePath);
  if (LDir <> '') and not DirectoryExists(LDir) then
    ForceDirectories(LDir);

  LBitmap := BuildBitmap(AQRCode);
  try
    //
    // Em FMX, TBitmap.SaveToFile detecta o formato pela extensão.
    // '.png' → codec PNG nativo da plataforma. Sem TPNGImage necessário.
    //
    LSurface := TBitmapSurface.Create;
    try
      LSurface.Assign(LBitmap);
      if not TBitmapCodecManager.SaveToFile(AFilePath, LSurface) then
        raise EInvalidOpException.Create(
          Format('Falha ao salvar PNG em: "%s"', [AFilePath]));
    finally
      LSurface.Free;
    end;
  finally
    LBitmap.Free;
  end;
end;

end.
