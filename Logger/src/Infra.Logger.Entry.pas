unit Infra.Logger.Entry;

interface

uses
  System.SysUtils,
  System.JSON,
  System.DateUtils,
  Infra.Logger.Types,
  Infra.Logger.Interfaces;

type
  TLogEntry = class(TInterfacedObject, ILogEntry)
  private
    FTimestamp: TDateTime;
    FLevel: TLogLevel;
    FMessage: string;
    FCategory: string;
    FExtraData: TJSONObject;
    FOwnsExtraData: Boolean;
  protected
    function GetTimestamp: TDateTime;
    function GetLevel: TLogLevel;
    function GetMessage: string;
    function GetCategory: string;
    function GetExtraData: TJSONObject;
  public
    constructor Create(ALevel: TLogLevel; const AMessage: string;
      const ACategory: string = ''; AExtraData: TJSONObject = nil);
    destructor Destroy; override;

    function ToJSON: TJSONObject;
    function ToJSONString: string;

    property Timestamp: TDateTime read GetTimestamp;
    property Level: TLogLevel read GetLevel;
    property Message: string read GetMessage;
    property Category: string read GetCategory;
    property ExtraData: TJSONObject read GetExtraData;
  end;

implementation

{ TLogEntry }

constructor TLogEntry.Create(ALevel: TLogLevel; const AMessage: string;
  const ACategory: string; AExtraData: TJSONObject);
begin
  inherited Create;
  FTimestamp := Now;
  FLevel := ALevel;
  FMessage := AMessage;
  FCategory := ACategory;

  if Assigned(AExtraData) then
  begin
    // Cria uma cópia para evitar problemas de ownership
    FExtraData := TJSONObject.ParseJSONValue(AExtraData.ToJSON) as TJSONObject;
    FOwnsExtraData := True;
  end
  else
  begin
    FExtraData := nil;
    FOwnsExtraData := False;
  end;
end;

destructor TLogEntry.Destroy;
begin
  if FOwnsExtraData and Assigned(FExtraData) then
    FExtraData.Free;
  inherited;
end;

function TLogEntry.GetTimestamp: TDateTime;
begin
  Result := FTimestamp;
end;

function TLogEntry.GetLevel: TLogLevel;
begin
  Result := FLevel;
end;

function TLogEntry.GetMessage: string;
begin
  Result := FMessage;
end;

function TLogEntry.GetCategory: string;
begin
  Result := FCategory;
end;

function TLogEntry.GetExtraData: TJSONObject;
begin
  Result := FExtraData;
end;

function TLogEntry.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    Result.AddPair('timestamp', DateToISO8601(FTimestamp));
    Result.AddPair('level', LOG_LEVEL_NAMES[FLevel]);
    Result.AddPair('message', FMessage);
    Result.AddPair('category', FCategory);

    if Assigned(FExtraData) then
      Result.AddPair('extra', TJSONObject.ParseJSONValue(FExtraData.ToJSON) as TJSONObject)
    else
      Result.AddPair('extra', TJSONNull.Create);
  except
    Result.Free;
    raise;
  end;
end;

function TLogEntry.ToJSONString: string;
var
  LJSON: TJSONObject;
begin
  LJSON := ToJSON;
  try
    Result := LJSON.ToJSON;
  finally
    LJSON.Free;
  end;
end;

end.
