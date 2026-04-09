unit Infra.Logger.Handlers.Base;

interface

uses
  System.SysUtils,
  Infra.Logger.Types,
  Infra.Logger.Interfaces;

type
  TBaseLogHandler = class(TInterfacedObject, ILogHandler)
  private
    FName: string;
    FEnabledLevels: TLogLevels;
  protected
    function GetName: string;
    function GetEnabledLevels: TLogLevels;
    procedure SetEnabledLevels(const Value: TLogLevels);
    procedure DoHandle(const AEntry: ILogEntry); virtual; abstract;
  public
    constructor Create(const AName: string; AEnabledLevels: TLogLevels = ALL_LOG_LEVELS);

    procedure Handle(const AEntry: ILogEntry);
    function IsEnabled(ALevel: TLogLevel): Boolean;

    property Name: string read GetName;
    property EnabledLevels: TLogLevels read GetEnabledLevels write SetEnabledLevels;
  end;

implementation

{ TBaseLogHandler }

constructor TBaseLogHandler.Create(const AName: string; AEnabledLevels: TLogLevels);
begin
  inherited Create;
  FName := AName;
  FEnabledLevels := AEnabledLevels;
end;

function TBaseLogHandler.GetName: string;
begin
  Result := FName;
end;

function TBaseLogHandler.GetEnabledLevels: TLogLevels;
begin
  Result := FEnabledLevels;
end;

procedure TBaseLogHandler.SetEnabledLevels(const Value: TLogLevels);
begin
  FEnabledLevels := Value;
end;

function TBaseLogHandler.IsEnabled(ALevel: TLogLevel): Boolean;
begin
  Result := ALevel in FEnabledLevels;
end;

procedure TBaseLogHandler.Handle(const AEntry: ILogEntry);
begin
  if IsEnabled(AEntry.Level) then
    DoHandle(AEntry);
end;

end.
