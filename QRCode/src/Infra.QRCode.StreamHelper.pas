unit Infra.QRCode.StreamHelper;

interface

uses
  Classes,
  SysUtils,
  System.NetEncoding,
  Data.DB

{$IFDEF VCL}
  , VCL.Graphics
  , VCL.Imaging.PNGImage
{$ELSE}
  , FMX.Graphics
  , FMX.Surfaces
{$ENDIF}

;

type
  TQRStreamHelper = class sealed
  public
    class function  StreamToBase64(const AStream: TStream): string; static;
    class function  Base64ToStream(const ABase64: string): TMemoryStream; static;
    class function  StreamToDataURI(const AStream: TStream): string; static;
    class procedure SaveStreamToBlob(const AField: TField;
                                     const AStream: TStream); static;
    class function  LoadStreamFromBlob(const AField: TField): TMemoryStream; static;
    class function  LoadBase64FromBlob(const AField: TField): string; static;
    class procedure SaveStreamToFile(const AStream: TStream;
                                     const AFilePath: string); static;
    class function  LoadStreamFromFile(const AFilePath: string): TMemoryStream; static;
    class function  IsValidPNGStream(const AStream: TStream): Boolean; static;

    {$IFDEF FMX}
    /// <summary>
    ///   FMX exclusivo: carrega stream PNG diretamente em TBitmap FMX.
    ///   Usa TBitmapCodecManager — funciona em todas as plataformas.
    ///   Caller é responsável por liberar o TBitmap retornado.
    /// </summary>
    class function StreamToFMXBitmap(const AStream: TStream): TBitmap; static;

    /// <summary>
    ///   FMX exclusivo: converte TBitmap FMX em stream PNG.
    ///   Caller é responsável por criar e liberar o AStream.
    /// </summary>
    class procedure FMXBitmapToStream(const ABitmap: TBitmap;
                                      const AStream: TStream); static;
    {$ENDIF}
  end;

implementation

{ TQRStreamHelper }

class function TQRStreamHelper.StreamToBase64(const AStream: TStream): string;
var
  LEncoded: TStringStream;
begin
  if not Assigned(AStream) then
    raise EArgumentNilException.Create('AStream não pode ser nulo.');

  AStream.Position := 0;
  LEncoded := TStringStream.Create('', TEncoding.ASCII);
  try
    TNetEncoding.Base64.Encode(AStream, LEncoded);
    Result := LEncoded.DataString;
  finally
    LEncoded.Free;
  end;
end;

class function TQRStreamHelper.Base64ToStream(
  const ABase64: string): TMemoryStream;
var
  LEncoded: TStringStream;
begin
  if ABase64.Trim = '' then
    raise EArgumentException.Create('Base64 não pode ser vazio.');

  Result := TMemoryStream.Create;
  try
    LEncoded := TStringStream.Create(ABase64, TEncoding.ASCII);
    try
      TNetEncoding.Base64.Decode(LEncoded, Result);
      Result.Position := 0;
    finally
      LEncoded.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

class function TQRStreamHelper.StreamToDataURI(const AStream: TStream): string;
begin
  Result := 'data:image/png;base64,' + StreamToBase64(AStream);
end;

class procedure TQRStreamHelper.SaveStreamToBlob(const AField: TField;
  const AStream: TStream);
var
  LBlobStream: TStream;
begin
  if not Assigned(AField) then
    raise EArgumentNilException.Create('AField não pode ser nulo.');
  if not Assigned(AStream) then
    raise EArgumentNilException.Create('AStream não pode ser nulo.');
  if not (AField is TBlobField) then
    raise EInvalidCast.CreateFmt(
      'Campo "%s" não é um campo BLOB.', [AField.FieldName]);

  AStream.Position := 0;
  LBlobStream := TBlobField(AField).DataSet.CreateBlobStream(
    TBlobField(AField), bmWrite);
  try
    LBlobStream.CopyFrom(AStream, AStream.Size);
  finally
    LBlobStream.Free;
  end;
end;

class function TQRStreamHelper.LoadStreamFromBlob(
  const AField: TField): TMemoryStream;
var
  LBlobStream: TStream;
begin
  if not Assigned(AField) then
    raise EArgumentNilException.Create('AField não pode ser nulo.');
  if not (AField is TBlobField) then
    raise EInvalidCast.CreateFmt(
      'Campo "%s" não é um campo BLOB.', [AField.FieldName]);

  Result := TMemoryStream.Create;
  try
    LBlobStream := TBlobField(AField).DataSet.CreateBlobStream(
      TBlobField(AField), bmRead);
    try
      Result.CopyFrom(LBlobStream, LBlobStream.Size);
      Result.Position := 0;
    finally
      LBlobStream.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

class function TQRStreamHelper.LoadBase64FromBlob(
  const AField: TField): string;
var
  LStream: TMemoryStream;
begin
  LStream := LoadStreamFromBlob(AField);
  try
    Result := StreamToBase64(LStream);
  finally
    LStream.Free;
  end;
end;

class procedure TQRStreamHelper.SaveStreamToFile(const AStream: TStream;
  const AFilePath: string);
var
  LDir: string;
begin
  if not Assigned(AStream) then
    raise EArgumentNilException.Create('AStream não pode ser nulo.');
  if AFilePath.Trim = '' then
    raise EArgumentException.Create('AFilePath não pode ser vazio.');

  LDir := ExtractFileDir(AFilePath);
  if (LDir <> '') and not DirectoryExists(LDir) then
    ForceDirectories(LDir);

  AStream.Position := 0;
  with TFileStream.Create(AFilePath, fmCreate) do
  try
    CopyFrom(AStream, AStream.Size);
  finally
    Free;
  end;
end;

class function TQRStreamHelper.LoadStreamFromFile(
  const AFilePath: string): TMemoryStream;
begin
  if not FileExists(AFilePath) then
    raise EFileNotFoundException.CreateFmt(
      'Arquivo não encontrado: "%s"', [AFilePath]);

  Result := TMemoryStream.Create;
  try
    Result.LoadFromFile(AFilePath);
    Result.Position := 0;
  except
    Result.Free;
    raise;
  end;
end;

class function TQRStreamHelper.IsValidPNGStream(
  const AStream: TStream): Boolean;
const
  PNG_SIGNATURE: array[0..7] of Byte = ($89,$50,$4E,$47,$0D,$0A,$1A,$0A);
var
  LHeader   : array[0..7] of Byte;
  LSavedPos : Int64;
  I         : Integer;
begin
  Result := False;
  if not Assigned(AStream) or (AStream.Size < 8) then
    Exit;

  LSavedPos := AStream.Position;
  try
    AStream.Position := 0;
    AStream.ReadBuffer(LHeader, SizeOf(LHeader));
    Result := True;
    for I := 0 to 7 do
      if LHeader[I] <> PNG_SIGNATURE[I] then
      begin
        Result := False;
        Break;
      end;
  finally
    AStream.Position := LSavedPos;
  end;
end;

{$IFDEF FMX}
class function TQRStreamHelper.StreamToFMXBitmap(
  const AStream: TStream): TBitmap;
var
  LSurface: TBitmapSurface;
begin
  if not Assigned(AStream) then
    raise EArgumentNilException.Create('AStream não pode ser nulo.');

  AStream.Position := 0;
  LSurface := TBitmapSurface.Create;
  try
    if not TBitmapCodecManager.LoadFromStream(AStream, LSurface) then
      raise EInvalidOpException.Create(
        'Falha ao decodificar stream como imagem (TBitmapCodecManager).');

    Result := TBitmap.Create;
    try
      Result.Assign(LSurface);
    except
      Result.Free;
      raise;
    end;
  finally
    LSurface.Free;
  end;
end;

class procedure TQRStreamHelper.FMXBitmapToStream(const ABitmap: TBitmap;
  const AStream: TStream);
var
  LSurface: TBitmapSurface;
begin
  if not Assigned(ABitmap) then
    raise EArgumentNilException.Create('ABitmap não pode ser nulo.');
  if not Assigned(AStream) then
    raise EArgumentNilException.Create('AStream não pode ser nulo.');

  LSurface := TBitmapSurface.Create;
  try
    LSurface.Assign(ABitmap);
    if not TBitmapCodecManager.SaveToStream(AStream, LSurface, '.png') then
      raise EInvalidOpException.Create(
        'Falha ao codificar TBitmap FMX como PNG.');
    AStream.Position := 0;
  finally
    LSurface.Free;
  end;
end;
{$ENDIF}

end.
