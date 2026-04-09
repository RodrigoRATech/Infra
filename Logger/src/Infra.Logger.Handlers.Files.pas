unit Infra.Logger.Handlers.Files;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.SyncObjs,
  Infra.Logger.Types,
  Infra.Logger.Interfaces,
  Infra.Logger.Handlers.Base;

type
  TFileLogHandler = class(TBaseLogHandler)
  private
    FFilePath: string;
    FLock: TCriticalSection;
    FMaxFileSize: Int64;
    FMaxBackupFiles: Integer;

    procedure EnsureDirectoryExists;
    procedure RotateFiles;
    function GetCurrentFileSize: Int64;
    function GenerateFileName: string;
  protected
    procedure DoHandle(const AEntry: ILogEntry); override;
  public
    constructor Create(const AFilePath: string = '';
      AEnabledLevels: TLogLevels = ALL_LOG_LEVELS;
      AMaxFileSize: Int64 = 10485760; // 10 MB
      AMaxBackupFiles: Integer = 5);
    destructor Destroy; override;

    property FilePath: string read FFilePath;
    property MaxFileSize: Int64 read FMaxFileSize write FMaxFileSize;
    property MaxBackupFiles: Integer read FMaxBackupFiles write FMaxBackupFiles;
  end;

implementation

{ TFileLogHandler }

constructor TFileLogHandler.Create(const AFilePath: string;
  AEnabledLevels: TLogLevels; AMaxFileSize: Int64; AMaxBackupFiles: Integer);
begin
  inherited Create('FileHandler', AEnabledLevels);
  FLock := TCriticalSection.Create;
  FMaxFileSize := AMaxFileSize;
  FMaxBackupFiles := AMaxBackupFiles;

  if AFilePath.IsEmpty then
    FFilePath := GenerateFileName
  else
    FFilePath := AFilePath;

  EnsureDirectoryExists;
end;

destructor TFileLogHandler.Destroy;
begin
  FLock.Free;
  inherited;
end;

function TFileLogHandler.GenerateFileName: string;
var
  LAppPath: string;
begin
  LAppPath := TPath.GetDirectoryName(ParamStr(0));
  Result := TPath.Combine(LAppPath, 'Logs');
  Result := TPath.Combine(Result, 'application.log');
end;

procedure TFileLogHandler.EnsureDirectoryExists;
var
  LDir: string;
begin
  LDir := TPath.GetDirectoryName(FFilePath);
  if not TDirectory.Exists(LDir) then
    TDirectory.CreateDirectory(LDir);
end;

function TFileLogHandler.GetCurrentFileSize: Int64;
begin
  if TFile.Exists(FFilePath) then
    Result := TFile.GetSize(FFilePath)
  else
    Result := 0;
end;

procedure TFileLogHandler.RotateFiles;
var
  I: Integer;
  LOldFile, LNewFile: string;
  LDir, LBaseName, LExt: string;
begin
  if GetCurrentFileSize < FMaxFileSize then
    Exit;

  LDir := TPath.GetDirectoryName(FFilePath);
  LBaseName := TPath.GetFileNameWithoutExtension(FFilePath);
  LExt := TPath.GetExtension(FFilePath);

  // Remove o arquivo mais antigo
  LOldFile := TPath.Combine(LDir, Format('%s.%d%s', [LBaseName, FMaxBackupFiles, LExt]));
  if TFile.Exists(LOldFile) then
    TFile.Delete(LOldFile);

  // Renomeia arquivos existentes
  for I := FMaxBackupFiles - 1 downto 1 do
  begin
    LOldFile := TPath.Combine(LDir, Format('%s.%d%s', [LBaseName, I, LExt]));
    LNewFile := TPath.Combine(LDir, Format('%s.%d%s', [LBaseName, I + 1, LExt]));
    if TFile.Exists(LOldFile) then
      TFile.Move(LOldFile, LNewFile);
  end;

  // Renomeia arquivo atual
  LNewFile := TPath.Combine(LDir, Format('%s.1%s', [LBaseName, LExt]));
  if TFile.Exists(FFilePath) then
    TFile.Move(FFilePath, LNewFile);
end;

procedure TFileLogHandler.DoHandle(const AEntry: ILogEntry);
var
  LStream: TStreamWriter;
  LJSONLine: string;
begin
  FLock.Acquire;
  try
    RotateFiles;

    LJSONLine := AEntry.ToJSONString;
    
    LStream := TStreamWriter.Create(FFilePath, True, TEncoding.UTF8);
    try
      LStream.WriteLine(LJSONLine);
    finally
      LStream.Free;
    end;
  finally
    FLock.Release;
  end;
end;

end.
