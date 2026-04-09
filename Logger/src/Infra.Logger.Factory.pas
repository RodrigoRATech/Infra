unit Infra.Logger.Factory;

interface

uses
  System.SysUtils,
  Infra.Logger.Types,
  Infra.Logger.Interfaces,
  Infra.Logger,
  Infra.Logger.Handlers.Files,
  Infra.Logger.Handlers.Email,
  Infra.Logger.Handlers.PushNotification;

type
  TLoggerFactory = class
  public
    // Cria logger com handler de arquivo padrão
    class function CreateDefaultLogger(const ALogFilePath: string = ''): ILogger;

    // Cria handlers individuais
    class function CreateFileHandler(const AFilePath: string = '';
      AEnabledLevels: TLogLevels = ALL_LOG_LEVELS): ILogHandler;

    class function CreateEmailHandler(
      const ASMTPHost: string;
      ASMTPPort: Integer;
      const AUsername, APassword, AFromAddress: string;
      const AToAddresses: TArray<string>;
      AUseSSL: Boolean = True;
      AEnabledLevels: TLogLevels = [llWarning, llError]): ILogHandler;

    class function CreatePushHandler(
      const AServerURL, AAPIKey: string;
      const AAppName: string = 'Application';
      ATimeout: Integer = 30000;
      AEnabledLevels: TLogLevels = [llWarning, llError]): ILogHandler;
  end;

implementation

{ TLoggerFactory }

class function TLoggerFactory.CreateDefaultLogger(const ALogFilePath: string): ILogger;
var
  LFileHandler: ILogHandler;
begin
  Result := TLogger.Create;
  LFileHandler := CreateFileHandler(ALogFilePath);
  Result.RegisterHandler(LFileHandler);
end;

class function TLoggerFactory.CreateFileHandler(const AFilePath: string;
  AEnabledLevels: TLogLevels): ILogHandler;
begin
  Result := TFileLogHandler.Create(AFilePath, AEnabledLevels);
end;

class function TLoggerFactory.CreateEmailHandler(
  const ASMTPHost: string;
  ASMTPPort: Integer;
  const AUsername, APassword, AFromAddress: string;
  const AToAddresses: TArray<string>;
  AUseSSL: Boolean;
  AEnabledLevels: TLogLevels): ILogHandler;
var
  LConfig: IEmailConfig;
begin
  LConfig := TEmailConfig.Create(ASMTPHost, ASMTPPort, AUsername, APassword,
    AFromAddress, AToAddresses, AUseSSL);
  Result := TEmailLogHandler.Create(LConfig, '[LOG]', AEnabledLevels);
end;

class function TLoggerFactory.CreatePushHandler(
  const AServerURL, AAPIKey: string;
  const AAppName: string;
  ATimeout: Integer;
  AEnabledLevels: TLogLevels): ILogHandler;
var
  LConfig: IPushNotificationConfig;
begin
  LConfig := TPushNotificationConfig.Create(AServerURL, AAPIKey, ATimeout);
  Result := TPushNotificationLogHandler.Create(LConfig, AAppName, AEnabledLevels);
end;

end.
