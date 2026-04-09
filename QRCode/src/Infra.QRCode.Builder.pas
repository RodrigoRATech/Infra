unit Infra.QRCode.Builder;

interface

uses
  SysUtils,
  Classes,
  System.NetEncoding,
  DelphiZXingQRCode,
  Infra.QRCode.Types,
  Infra.QRCode.Contracts,
  Infra.QRCode.StreamHelper

{$IFDEF VCL}
, VCL.Graphics
{$ELSE}
, FMX.Graphics
{$ENDIF}
;

type
  /// <summary>
  ///   Gerador de QRCode — agnóstico de plataforma.
  ///   Recebe IQRCodeRenderer via injeção de dependência (DIP).
  ///   Não conhece VCL nem FMX — apenas orquestra.
  /// </summary>
  TQRCodeGenerator = class(TInterfacedObject, IQRCodeGenerator)
  private
    FContent       : IQRContentBuilder;
    FErrorLevel    : TQRErrorLevel;
    FRenderOptions : TQRRenderOptions;
    FRenderer      : IQRCodeRenderer;  // <- Injetado externamente
    function BuildInternalQRCode: TDelphiZXingQRCode;
    procedure UpdateRenderer;
  public
    constructor Create(const ARenderer: IQRCodeRenderer);

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

uses
{$IFDEF VCL}
   Infra.QRCode.Renderer.VCL
{$ELSE}
   Infra.QRCode.Renderer.FMX
{$ENDIF}
;

{ TQRCodeGenerator }

constructor TQRCodeGenerator.Create(const ARenderer: IQRCodeRenderer);
begin
  inherited Create;
  if not Assigned(ARenderer) then
    raise EArgumentNilException.Create('ARenderer não pode ser nulo.');
  FRenderer      := ARenderer;
  FErrorLevel    := elMedium;
  FRenderOptions := TQRRenderOptions.Default;
end;

procedure TQRCodeGenerator.UpdateRenderer;
begin
  //
  // Quando o usuário chama SetRenderOptions(), recriamos o renderer
  // com as novas opções, preservando o tipo correto de plataforma.
  //
  {$IFDEF VCL}
  FRenderer := TQRCodeRendererVCL.Create(FRenderOptions);
  {$ELSE}
  FRenderer := TQRCodeRendererFMX.Create(FRenderOptions);
  {$ENDIF}
end;

function TQRCodeGenerator.SetContent(
  const ABuilder: IQRContentBuilder): IQRCodeGenerator;
begin
  if not Assigned(ABuilder) then
    raise EArgumentNilException.Create('Content builder não pode ser nulo.');
  FContent := ABuilder;
  Result := Self;
end;

function TQRCodeGenerator.SetErrorLevel(
  const ALevel: TQRErrorLevel): IQRCodeGenerator;
begin
  FErrorLevel := ALevel;
  Result := Self;
end;

function TQRCodeGenerator.SetRenderOptions(
  const AOptions: TQRRenderOptions): IQRCodeGenerator;
begin
  FRenderOptions := AOptions;
  UpdateRenderer;
  Result := Self;
end;

function TQRCodeGenerator.BuildInternalQRCode: TDelphiZXingQRCode;
begin
  if not Assigned(FContent) then
    raise EInvalidOpException.Create(
      'Nenhum conteúdo definido. Chame SetContent() antes de gerar o QRCode.');

  Result := TDelphiZXingQRCode.Create;
  try
    Result.QuietZone := 0;
    Result.Encoding  := TQRCodeEncoding(0);
    Result.Data      := FContent.Build;
  except
    Result.Free;
    raise;
  end;
end;

function TQRCodeGenerator.GetRawData: string;
begin
  if not Assigned(FContent) then
    raise EInvalidOpException.Create('Nenhum conteúdo definido.');
  Result := FContent.Build;
end;

function TQRCodeGenerator.GenerateBitmap: TBitmap;
var
  LQR: TDelphiZXingQRCode;
begin
  LQR := BuildInternalQRCode;
  try
    Result := FRenderer.RenderBitmap(LQR);
  finally
    LQR.Free;
  end;
end;

function TQRCodeGenerator.GeneratePNGFile(
  const AFilePath: string): IQRCodeGenerator;
var
  LQR: TDelphiZXingQRCode;
begin
  if AFilePath.Trim = '' then
    raise EArgumentException.Create('Caminho do arquivo não pode ser vazio.');
  LQR := BuildInternalQRCode;
  try
    FRenderer.RenderPNGToFile(LQR, AFilePath);
  finally
    LQR.Free;
  end;
  Result := Self;
end;

function TQRCodeGenerator.GenerateBitmapStream(
  const AStream: TStream): IQRCodeGenerator;
var
  LQR: TDelphiZXingQRCode;
begin
  if not Assigned(AStream) then
    raise EArgumentNilException.Create('AStream não pode ser nulo.');
  LQR := BuildInternalQRCode;
  try
    FRenderer.RenderBitmapToStream(LQR, AStream);
  finally
    LQR.Free;
  end;
  Result := Self;
end;

function TQRCodeGenerator.GeneratePNGStream(
  const AStream: TStream): IQRCodeGenerator;
var
  LQR: TDelphiZXingQRCode;
begin
  if not Assigned(AStream) then
    raise EArgumentNilException.Create('AStream não pode ser nulo.');
  LQR := BuildInternalQRCode;
  try
    FRenderer.RenderPNGToStream(LQR, AStream);
  finally
    LQR.Free;
  end;
  Result := Self;
end;

function TQRCodeGenerator.GenerateBase64: string;
var
  LStream: TMemoryStream;
begin
  LStream := TMemoryStream.Create;
  try
    GeneratePNGStream(LStream);
    Result := TQRStreamHelper.StreamToBase64(LStream);
  finally
    LStream.Free;
  end;
end;

function TQRCodeGenerator.GenerateDataURI: string;
begin
  Result := 'data:image/png;base64,' + GenerateBase64;
end;

end.
