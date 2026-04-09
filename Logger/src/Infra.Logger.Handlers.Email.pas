unit Infra.Logger.Handlers.Email;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.NetEncoding,
  System.Generics.Collections,
  IdSMTP,
  IdSSLOpenSSL,
  IdMessage,
  IdText,
  Infra.Logger.Types,
  Infra.Logger.Interfaces,
  Infra.Logger.Handlers.Base;

type
  TEmailConfig = class(TInterfacedObject, IEmailConfig)
  private
    FSMTPHost: string;
    FSMTPPort: Integer;
    FUsername: string;
    FPassword: string;
    FFromAddress: string;
    FToAddresses: TArray<string>;
    FUseSSL: Boolean;
  public
    constructor Create(const ASMTPHost: string; ASMTPPort: Integer;
      const AUsername, APassword, AFromAddress: string;
      const AToAddresses: TArray<string>; AUseSSL: Boolean = True);

    function GetSMTPHost: string;
    function GetSMTPPort: Integer;
    function GetUsername: string;
    function GetPassword: string;
    function GetFromAddress: string;
    function GetToAddresses: TArray<string>;
    function GetUseSSL: Boolean;

    property SMTPHost: string read GetSMTPHost;
    property SMTPPort: Integer read GetSMTPPort;
    property Username: string read GetUsername;
    property Password: string read GetPassword;
    property FromAddress: string read GetFromAddress;
    property ToAddresses: TArray<string> read GetToAddresses;
    property UseSSL: Boolean read GetUseSSL;
  end;

  TEmailLogHandler = class(TBaseLogHandler)
  private
    FConfig: IEmailConfig;
    FSubjectPrefix: string;

    procedure SendEmail(const ASubject, ABody: string);
  protected
    procedure DoHandle(const AEntry: ILogEntry); override;
  public
    constructor Create(const AConfig: IEmailConfig;
      const ASubjectPrefix: string = '[LOG]';
      AEnabledLevels: TLogLevels = [llWarning, llError]);
    
    property Config: IEmailConfig read FConfig;
    property SubjectPrefix: string read FSubjectPrefix write FSubjectPrefix;
  end;

implementation

uses
  IdExplicitTLSClientServerBase;
{ TEmailConfig }

constructor TEmailConfig.Create(const ASMTPHost: string; ASMTPPort: Integer;
  const AUsername, APassword, AFromAddress: string;
  const AToAddresses: TArray<string>; AUseSSL: Boolean);
begin
  inherited Create;
  FSMTPHost := ASMTPHost;
  FSMTPPort := ASMTPPort;
  FUsername := AUsername;
  FPassword := APassword;
  FFromAddress := AFromAddress;
  FToAddresses := AToAddresses;
  FUseSSL := AUseSSL;
end;

function TEmailConfig.GetSMTPHost: string;
begin
  Result := FSMTPHost;
end;

function TEmailConfig.GetSMTPPort: Integer;
begin
  Result := FSMTPPort;
end;

function TEmailConfig.GetUsername: string;
begin
  Result := FUsername;
end;

function TEmailConfig.GetPassword: string;
begin
  Result := FPassword;
end;

function TEmailConfig.GetFromAddress: string;
begin
  Result := FFromAddress;
end;

function TEmailConfig.GetToAddresses: TArray<string>;
begin
  Result := FToAddresses;
end;

function TEmailConfig.GetUseSSL: Boolean;
begin
  Result := FUseSSL;
end;

{ TEmailLogHandler }

constructor TEmailLogHandler.Create(const AConfig: IEmailConfig;
  const ASubjectPrefix: string; AEnabledLevels: TLogLevels);
begin
  inherited Create('EmailHandler', AEnabledLevels);
  FConfig := AConfig;
  FSubjectPrefix := ASubjectPrefix;
end;

procedure TEmailLogHandler.SendEmail(const ASubject, ABody: string);
var
  LSMTP: TIdSMTP;
  LSSL: TIdSSLIOHandlerSocketOpenSSL;
  LMessage: TIdMessage;
  LTextPart: TIdText;
  LAddress: string;
begin
  LSMTP := TIdSMTP.Create(nil);
  LSSL := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  LMessage := TIdMessage.Create(nil);
  try
    // Configuração SSL
    if FConfig.UseSSL then
    begin
      LSSL.SSLOptions.Method := sslvTLSv1_2;
      LSSL.SSLOptions.Mode := sslmClient;
      LSMTP.IOHandler := LSSL;
      LSMTP.UseTLS := utUseExplicitTLS;
    end;

    // Configuração SMTP
    LSMTP.Host := FConfig.SMTPHost;
    LSMTP.Port := FConfig.SMTPPort;
    LSMTP.Username := FConfig.Username;
    LSMTP.Password := FConfig.Password;
    LSMTP.AuthType := satDefault;

    // Configuração da mensagem
    LMessage.From.Address := FConfig.FromAddress;
    LMessage.Subject := ASubject;
    
    for LAddress in FConfig.ToAddresses do
      LMessage.Recipients.Add.Address := LAddress;

    // Corpo da mensagem em texto plano
    LMessage.Body.Text := ABody;
    LMessage.ContentType := 'text/plain; charset=utf-8';

    // Envio
    LSMTP.Connect;
    try
      LSMTP.Send(LMessage);
    finally
      LSMTP.Disconnect;
    end;
  finally
    LMessage.Free;
    LSSL.Free;
    LSMTP.Free;
  end;
end;

procedure TEmailLogHandler.DoHandle(const AEntry: ILogEntry);
var
  LSubject, LBody: string;
begin
  LSubject := Format('%s %s - %s', [
    FSubjectPrefix,
    LOG_LEVEL_NAMES[AEntry.Level],
    AEntry.Category
  ]);

  LBody := Format(
    'Timestamp: %s' + sLineBreak +
    'Level: %s' + sLineBreak +
    'Category: %s' + sLineBreak +
    'Message: %s' + sLineBreak +
    sLineBreak +
    'JSON:' + sLineBreak +
    '%s',
    [
      DateTimeToStr(AEntry.Timestamp),
      LOG_LEVEL_NAMES[AEntry.Level],
      AEntry.Category,
      AEntry.Message,
      AEntry.ToJSONString
    ]
  );

  try
    SendEmail(LSubject, LBody);
  except
    on E: Exception do
    begin
      {$IFDEF DEBUG}
      //OutputDebugString(PChar('Email send failed: ' + E.Message));
      {$ENDIF}
    end;
  end;
end;

end.
