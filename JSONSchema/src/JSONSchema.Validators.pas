unit JsonSchema.Validators;

interface

uses
  System.SysUtils, System.JSON, System.RegularExpressions, System.Generics.Collections,
  JsonSchema.Types;

type
  IJsonValidator = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function Validate(const AValue: TJSONValue): Boolean;
    function GetErrorMessage: string;
  end;

  TBaseValidator = class(TInterfacedObject, IJsonValidator)
  protected
    FErrorMessage: string;
  public
    function Validate(const AValue: TJSONValue): Boolean; virtual; abstract;
    function GetErrorMessage: string;
  end;

  TPatternValidator = class(TBaseValidator)
  private
    FPattern: string;
  public
    constructor Create(const APattern: string);
    function Validate(const AValue: TJSONValue): Boolean; override;
  end;

  TEnumValidator = class(TBaseValidator)
  private
    FAllowedValues: TArray<string>;
  public
    constructor Create(const AAllowedValues: TArray<string>);
    function Validate(const AValue: TJSONValue): Boolean; override;
  end;

  TRangeValidator = class(TBaseValidator)
  private
    FMinValue: Double;
    FMaxValue: Double;
    FHasMin: Boolean;
    FHasMax: Boolean;
    FExclusiveMin: Boolean;
    FExclusiveMax: Boolean;
  public
    constructor Create;
    function SetMinimum(AValue: Double; AExclusive: Boolean = False): TRangeValidator;
    function SetMaximum(AValue: Double; AExclusive: Boolean = False): TRangeValidator;
    function Validate(const AValue: TJSONValue): Boolean; override;
  end;

  TArrayLengthValidator = class(TBaseValidator)
  private
    FMinItems: Integer;
    FMaxItems: Integer;
    FHasMin: Boolean;
    FHasMax: Boolean;
  public
    constructor Create;
    function SetMinItems(AValue: Integer): TArrayLengthValidator;
    function SetMaxItems(AValue: Integer): TArrayLengthValidator;
    function Validate(const AValue: TJSONValue): Boolean; override;
  end;

  TStringLengthValidator = class(TBaseValidator)
  private
    FMinLength: Integer;
    FMaxLength: Integer;
    FHasMin: Boolean;
    FHasMax: Boolean;
  public
    constructor Create;
    function SetMinLength(AValue: Integer): TStringLengthValidator;
    function SetMaxLength(AValue: Integer): TStringLengthValidator;
    function Validate(const AValue: TJSONValue): Boolean; override;
  end;

  TDateTimeValidator = class(TBaseValidator)
  public
    type
      TDateTimeValidationType = (dtvDate, dtvTime, dtvDateTime, dtvDateTimeGMT);
  private
    FValidationType: TDateTimeValidationType;
  public
    constructor Create(AValidationType: TDateTimeValidationType);
    function Validate(const AValue: TJSONValue): Boolean; override;
  end;

implementation

{ TBaseValidator }

function TBaseValidator.GetErrorMessage: string;
begin
  Result := FErrorMessage;
end;

{ TPatternValidator }

constructor TPatternValidator.Create(const APattern: string);
begin
  inherited Create;
  FPattern := APattern;
end;

function TPatternValidator.Validate(const AValue: TJSONValue): Boolean;
var
  LValue: string;
begin
  Result := False;
  if not (AValue is TJSONString) then
  begin
    FErrorMessage := 'Value must be a string';
    Exit;
  end;

  LValue := TJSONString(AValue).Value;
  Result := TRegEx.IsMatch(LValue, FPattern);
  
  if not Result then
    FErrorMessage := Format('Value "%s" does not match pattern "%s"', [LValue, FPattern]);
end;

{ TEnumValidator }

constructor TEnumValidator.Create(const AAllowedValues: TArray<string>);
begin
  inherited Create;
  FAllowedValues := AAllowedValues;
end;

function TEnumValidator.Validate(const AValue: TJSONValue): Boolean;
var
  LValue: string;
  LAllowed: string;
begin
  Result := False;
  if not (AValue is TJSONString) then
  begin
    FErrorMessage := 'Value must be a string';
    Exit;
  end;

  LValue := TJSONString(AValue).Value;
  
  for LAllowed in FAllowedValues do
  begin
    if SameText(LValue, LAllowed) then
      Exit(True);
  end;

  FErrorMessage := Format('Value "%s" is not in allowed values: [%s]', 
    [LValue, string.Join(', ', FAllowedValues)]);
end;

{ TRangeValidator }

constructor TRangeValidator.Create;
begin
  inherited Create;
  FHasMin := False;
  FHasMax := False;
  FExclusiveMin := False;
  FExclusiveMax := False;
end;

function TRangeValidator.SetMinimum(AValue: Double; AExclusive: Boolean): TRangeValidator;
begin
  FMinValue := AValue;
  FHasMin := True;
  FExclusiveMin := AExclusive;
  Result := Self;
end;

function TRangeValidator.SetMaximum(AValue: Double; AExclusive: Boolean): TRangeValidator;
begin
  FMaxValue := AValue;
  FHasMax := True;
  FExclusiveMax := AExclusive;
  Result := Self;
end;

function TRangeValidator.Validate(const AValue: TJSONValue): Boolean;
var
  LValue: Double;
begin
  Result := False;
  
  if AValue is TJSONNumber then
    LValue := TJSONNumber(AValue).AsDouble
  else
  begin
    FErrorMessage := 'Value must be a number';
    Exit;
  end;

  if FHasMin then
  begin
    if FExclusiveMin then
    begin
      if LValue <= FMinValue then
      begin
        FErrorMessage := Format('Value must be greater than %g', [FMinValue]);
        Exit;
      end;
    end
    else
    begin
      if LValue < FMinValue then
      begin
        FErrorMessage := Format('Value must be greater than or equal to %g', [FMinValue]);
        Exit;
      end;
    end;
  end;

  if FHasMax then
  begin
    if FExclusiveMax then
    begin
      if LValue >= FMaxValue then
      begin
        FErrorMessage := Format('Value must be less than %g', [FMaxValue]);
        Exit;
      end;
    end
    else
    begin
      if LValue > FMaxValue then
      begin
        FErrorMessage := Format('Value must be less than or equal to %g', [FMaxValue]);
        Exit;
      end;
    end;
  end;

  Result := True;
end;

{ TArrayLengthValidator }

constructor TArrayLengthValidator.Create;
begin
  inherited Create;
  FHasMin := False;
  FHasMax := False;
end;

function TArrayLengthValidator.SetMinItems(AValue: Integer): TArrayLengthValidator;
begin
  FMinItems := AValue;
  FHasMin := True;
  Result := Self;
end;

function TArrayLengthValidator.SetMaxItems(AValue: Integer): TArrayLengthValidator;
begin
  FMaxItems := AValue;
  FHasMax := True;
  Result := Self;
end;

function TArrayLengthValidator.Validate(const AValue: TJSONValue): Boolean;
var
  LArray: TJSONArray;
begin
  Result := False;
  
  if not (AValue is TJSONArray) then
  begin
    FErrorMessage := 'Value must be an array';
    Exit;
  end;

  LArray := TJSONArray(AValue);

  if FHasMin and (LArray.Count < FMinItems) then
  begin
    FErrorMessage := Format('Array must have at least %d items', [FMinItems]);
    Exit;
  end;

  if FHasMax and (LArray.Count > FMaxItems) then
  begin
    FErrorMessage := Format('Array must have at most %d items', [FMaxItems]);
    Exit;
  end;

  Result := True;
end;

{ TStringLengthValidator }

constructor TStringLengthValidator.Create;
begin
  inherited Create;
  FHasMin := False;
  FHasMax := False;
end;

function TStringLengthValidator.SetMinLength(AValue: Integer): TStringLengthValidator;
begin
  FMinLength := AValue;
  FHasMin := True;
  Result := Self;
end;

function TStringLengthValidator.SetMaxLength(AValue: Integer): TStringLengthValidator;
begin
  FMaxLength := AValue;
  FHasMax := True;
  Result := Self;
end;

function TStringLengthValidator.Validate(const AValue: TJSONValue): Boolean;
var
  LValue: string;
begin
  Result := False;
  
  if not (AValue is TJSONString) then
  begin
    FErrorMessage := 'Value must be a string';
    Exit;
  end;

  LValue := TJSONString(AValue).Value;

  if FHasMin and (Length(LValue) < FMinLength) then
  begin
    FErrorMessage := Format('String must have at least %d characters', [FMinLength]);
    Exit;
  end;

  if FHasMax and (Length(LValue) > FMaxLength) then
  begin
    FErrorMessage := Format('String must have at most %d characters', [FMaxLength]);
    Exit;
  end;

  Result := True;
end;

{ TDateTimeValidator }

constructor TDateTimeValidator.Create(AValidationType: TDateTimeValidationType);
begin
  inherited Create;
  FValidationType := AValidationType;
end;

function TDateTimeValidator.Validate(const AValue: TJSONValue): Boolean;
var
  LValue: string;
  LPattern: string;
begin
  Result := False;
  
  if not (AValue is TJSONString) then
  begin
    FErrorMessage := 'Value must be a string';
    Exit;
  end;

  LValue := TJSONString(AValue).Value;

  case FValidationType of
    dtvDate:
      LPattern := '^\d{4}-\d{2}-\d{2}$';
    dtvTime:
      LPattern := '^\d{2}:\d{2}:\d{2}(\.\d+)?$';
    dtvDateTime:
      LPattern := '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?([+-]\d{2}:\d{2}|Z)?$';
    dtvDateTimeGMT:
      LPattern := '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$';
  end;

  Result := TRegEx.IsMatch(LValue, LPattern);
  
  if not Result then
  begin
    case FValidationType of
      dtvDate:       FErrorMessage := 'Value must be a valid date (YYYY-MM-DD)';
      dtvTime:       FErrorMessage := 'Value must be a valid time (HH:MM:SS)';
      dtvDateTime:   FErrorMessage := 'Value must be a valid datetime (ISO 8601)';
      dtvDateTimeGMT: FErrorMessage := 'Value must be a valid GMT datetime (ends with Z)';
    end;
  end;
end;

end.
