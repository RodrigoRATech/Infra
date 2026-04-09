unit Infra.Logger.Handlers.PushNotification;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.Net.HttpClientComponent,
  Infra.Logger.Types,
  Infra.Logger.Interfaces,
  Infra.Logger.Handlers.Base;

type
  TPushNotificationConfig = class(TInterfacedObject, IPushNotificationConfig)
  private
    FServerURL: string;
    FAPIKey: string;
    FTimeout: Integer;
  public
    constructor Create(const AServerURL, AAPIKey: string; ATimeout: Integer = 30000);

    function GetServerURL: string;
    function GetAPIKey: string;
    function GetTimeout: Integer;

    property ServerURL: string read GetServerURL;
    property APIKey: string read GetAPIKey;
    property Timeout: Integer read GetTimeout;
  end;

  TPushNotificationLogHandler = class(TBaseLogHandler)
  private
    FConfig: IPushNotificationConfig;
    FAppName: string;

    procedure SendPushNotification(const AEntry: ILogEntry);
  protected
    procedure DoHandle(const AEntry: ILogEntry); override;
  public
    constructor Create(const AConfig: IPushNotificationConfig;
      const AAppName: string = 'Application';
      AEnabledLevels: TLogLevels = [llWarning, llError]);

    property Config: IPushNotificationConfig read FConfig;
    property AppName: string read FAppName write FAppName;
  end;

implementation

{ TPushNotificationConfig }

constructor TPushNotificationConfig.Create(const AServerURL, AAPIKey: string;
  ATimeout: Integer);
begin
  inherited Create;
  FServerURL := AServerURL;
  FAPIKey := AAPIKey;
  FTimeout := ATimeout;
end;

function TPushNotificationConfig.GetServerURL: string;
begin
  Result := FServerURL;
end;

function TPushNotificationConfig.GetAPIKey: string;
begin
  Result := FAPIKey;
end;

function TPushNotificationConfig.GetTimeout: Integer;
begin
  Result := FTimeout;
end;

{ TPushNotificationLogHandler }

constructor TPushNotificationLogHandler.Create(
  const AConfig: IPushNotificationConfig;
  const AAppName: string;
  AEnabledLevels: TLogLevels);
begin
  inherited Create('PushNotificationHandler', AEnabledLevels);
  FConfig := AConfig;
  FAppName := AAppName;
end;

procedure TPushNotificationLogHandler.SendPushNotification(const AEntry: ILogEntry);
var
  LHttpClient: TNetHTTPClient;
  LRequest: TNetHTTPRequest;
  LResponse: IHTTPResponse;
  LPayload: TJSONObject;
  LNotification: TJSONObject;
  LContent: TStringStream;
begin
  LHttpClient := TNetHTTPClient.Create(nil);
  LRequest := TNetHTTPRequest.Create(nil);
  LPayload := TJSONObject.Create;
  LContent := nil;
  try
    LRequest.Client := LHttpClient;
    LHttpClient.ConnectionTimeout := FConfig.Timeout;
    LHttpClient.ResponseTimeout := FConfig.Timeout;

    // Monta payload genérico para push notification
    // Adapte conforme seu servidor de push (Firebase, OneSignal, etc.)
    LNotification := TJSONObject.Create;
    LNotification.AddPair('title', Format('[%s] %s', [
      LOG_LEVEL_NAMES[AEntry.Level],
      FAppName
    ]));
    LNotification.AddPair('body', AEntry.Message);
    LNotification.AddPair('priority', 'high');

    LPayload.AddPair('notification', LNotification);
    LPayload.AddPair('data', AEntry.ToJSON);

    LContent := TStringStream.Create(LPayload.ToJSON, TEncoding.UTF8);

    LRequest.CustomHeaders['Authorization'] := 'Bearer ' + FConfig.APIKey;
    LRequest.CustomHeaders['Content-Type'] := 'application/json';

    LResponse := LRequest.Post(FConfig.ServerURL, LContent);

    if LResponse.StatusCode >= 400 then
    begin
      {$IFDEF DEBUG}
      //OutputDebugString(PChar(Format('Push notification failed: %d - %s', [LResponse.StatusCode, LResponse.StatusText])));
      {$ENDIF}
    end;
  finally
    LContent.Free;
    LPayload.Free;
    LRequest.Free;
    LHttpClient.Free;
  end;
end;

procedure TPushNotificationLogHandler.DoHandle(const AEntry: ILogEntry);
begin
  try
    SendPushNotification(AEntry);
  except
    on E: Exception do
    begin
      {$IFDEF DEBUG}
      //OutputDebugString(PChar('Push notification failed: ' + E.Message));
      {$ENDIF}
    end;
  end;
end;

end.
