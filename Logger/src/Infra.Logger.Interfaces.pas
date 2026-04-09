unit Infra.Logger.Interfaces;

interface

uses
  System.Classes,
  System.JSON,
  Infra.Logger.Types;

type
  ILogEntry = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function GetTimestamp: TDateTime;
    function GetLevel: TLogLevel;
    function GetMessage: string;
    function GetCategory: string;
    function GetExtraData: TJSONObject;
    function ToJSON: TJSONObject;
    function ToJSONString: string;

    property Timestamp: TDateTime read GetTimestamp;
    property Level: TLogLevel read GetLevel;
    property Message: string read GetMessage;
    property Category: string read GetCategory;
    property ExtraData: TJSONObject read GetExtraData;
  end;

  ILogHandler = interface
    ['{B2C3D4E5-F6A7-8901-BCDE-F12345678901}']
    function GetName: string;
    function GetEnabledLevels: TLogLevels;
    procedure SetEnabledLevels(const Value: TLogLevels);
    procedure Handle(const AEntry: ILogEntry);
    function IsEnabled(ALevel: TLogLevel): Boolean;

    property Name: string read GetName;
    property EnabledLevels: TLogLevels read GetEnabledLevels write SetEnabledLevels;
  end;

  ILogDispatcher = interface
    ['{C3D4E5F6-A7B8-9012-CDEF-123456789012}']
    procedure RegisterHandler(const AHandler: ILogHandler);
    procedure UnregisterHandler(const AHandler: ILogHandler);
    procedure Dispatch(const AEntry: ILogEntry);
    procedure ClearHandlers;
  end;

  ILogQueue = interface
    ['{D4E5F6A7-B8C9-0123-DEF0-234567890123}']
    procedure Enqueue(const AEntry: ILogEntry);
    function Dequeue(out AEntry: ILogEntry): Boolean;
    function Count: Integer;
    procedure Clear;
  end;

  ILogger = interface
    ['{E5F6A7B8-C9D0-1234-EF01-345678901234}']
    procedure Log(ALevel: TLogLevel; const AMessage: string; 
      const ACategory: string = ''; AExtraData: TJSONObject = nil);
    procedure Debug(const AMessage: string; const ACategory: string = '');
    procedure Info(const AMessage: string; const ACategory: string = '');
    procedure Warning(const AMessage: string; const ACategory: string = '');
    procedure Error(const AMessage: string; const ACategory: string = '');
    procedure Flush;
    procedure Shutdown;

    procedure RegisterHandler(const AHandler: ILogHandler);
    procedure UnregisterHandler(const AHandler: ILogHandler);
  end;

  IEmailConfig = interface
    ['{F6A7B8C9-D0E1-2345-F012-456789012345}']
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

  IPushNotificationConfig = interface
    ['{A7B8C9D0-E1F2-3456-0123-567890123456}']
    function GetServerURL: string;
    function GetAPIKey: string;
    function GetTimeout: Integer;

    property ServerURL: string read GetServerURL;
    property APIKey: string read GetAPIKey;
    property Timeout: Integer read GetTimeout;
  end;

implementation

end.
