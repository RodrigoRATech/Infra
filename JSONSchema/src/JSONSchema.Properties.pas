unit JsonSchema.Properties;

interface

uses
  System.SysUtils, System.JSON, System.Generics.Collections,
  JsonSchema.Types, JsonSchema.Validators;

type
  TJsonSchemaProperty = class;
  TJsonSchemaObject = class;
  TJsonSchemaArray = class;
  
  /// <summary>
  /// Interface base para propriedades do schema
  /// </summary>
  IJsonSchemaProperty = interface
    ['{B2C3D4E5-F6A7-8901-BCDE-F23456789012}']
    function GetName: string;
    function GetSchemaType: TJsonSchemaType;
    function IsRequired: Boolean;
    function ToJSON: TJSONObject;
    function Validate(const AValue: TJSONValue; out AError: string): Boolean;
  end;

  /// <summary>
  /// Classe base abstrata para todas as propriedades
  /// </summary>
  TJsonSchemaProperty = class(TInterfacedObject, IJsonSchemaProperty)
  protected
    FName: string;
    FDescription: string;
    FRequired: Boolean;
    FNullable: Boolean;
    FDefault: TJSONValue;
    FSchemaType: TJsonSchemaType;
    FValidators: TList<IJsonValidator>;
    FParent: TObject;
    
    procedure AddBaseProperties(AJson: TJSONObject); virtual;
  public
    constructor Create(const AName: string; AParent: TObject);
    destructor Destroy; override;
    
    function GetName: string;
    function GetSchemaType: TJsonSchemaType;
    function IsRequired: Boolean;
    function ToJSON: TJSONObject; virtual;
    function Validate(const AValue: TJSONValue; out AError: string): Boolean; virtual;
    
    // Fluent interface comum
    function Description(const AValue: string): TJsonSchemaProperty;
    function Required: TJsonSchemaProperty;
    function Nullable: TJsonSchemaProperty;
    function &End: TObject;
  end;

  /// <summary>
  /// Propriedade do tipo String
  /// </summary>
  TJsonSchemaString = class(TJsonSchemaProperty)
  private
    FMinLength: Integer;
    FMaxLength: Integer;
    FPattern: string;
    FFormat: TJsonSchemaFormat;
    FEnumValues: TArray<string>;
    FHasMinLength: Boolean;
    FHasMaxLength: Boolean;
  public
    constructor Create(const AName: string; AParent: TObject);
    
    function ToJSON: TJSONObject; override;
    function Validate(const AValue: TJSONValue; out AError: string): Boolean; override;
    
    // Fluent interface específica
    function MinLength(AValue: Integer): TJsonSchemaString;
    function MaxLength(AValue: Integer): TJsonSchemaString;
    function Pattern(const AValue: string): TJsonSchemaString;
    function Format(AValue: TJsonSchemaFormat): TJsonSchemaString;
    function Enum(const AValues: TArray<string>): TJsonSchemaString;
    function DefaultValue(const AValue: string): TJsonSchemaString;
    
    // Atalhos para formatos comuns
    function AsEmail: TJsonSchemaString;
    function AsUUID: TJsonSchemaString;
    function AsURI: TJsonSchemaString;
    function AsDate: TJsonSchemaString;
    function AsTime: TJsonSchemaString;
    function AsDateTime: TJsonSchemaString;
    function AsZipCodeBR: TJsonSchemaString;
    function AsPhoneBR: TJsonSchemaString;
    function AsCPF: TJsonSchemaString;
    function AsCNPJ: TJsonSchemaString;
    
    // Re-declaração para manter tipo correto
    function Description(const AValue: string): TJsonSchemaString;
    function Required: TJsonSchemaString;
    function Nullable: TJsonSchemaString;
    function &End: TObject;
  end;

  /// <summary>
  /// Propriedade do tipo Number/Integer
  /// </summary>
  TJsonSchemaNumber = class(TJsonSchemaProperty)
  private
    FMinimum: Double;
    FMaximum: Double;
    FExclusiveMinimum: Double;
    FExclusiveMaximum: Double;
    FMultipleOf: Double;
    FHasMinimum: Boolean;
    FHasMaximum: Boolean;
    FHasExclusiveMinimum: Boolean;
    FHasExclusiveMaximum: Boolean;
    FHasMultipleOf: Boolean;
    FIsInteger: Boolean;
  public
    constructor Create(const AName: string; AParent: TObject; AIsInteger: Boolean = False);
    
    function ToJSON: TJSONObject; override;
    function Validate(const AValue: TJSONValue; out AError: string): Boolean; override;
    
    // Fluent interface específica
    function Minimum(AValue: Double): TJsonSchemaNumber;
    function Maximum(AValue: Double): TJsonSchemaNumber;
    function ExclusiveMinimum(AValue: Double): TJsonSchemaNumber;
    function ExclusiveMaximum(AValue: Double): TJsonSchemaNumber;
    function MultipleOf(AValue: Double): TJsonSchemaNumber;
    function Range(AMin, AMax: Double): TJsonSchemaNumber;
    function DefaultValue(AValue: Double): TJsonSchemaNumber;
    
    // Re-declaração para manter tipo correto
    function Description(const AValue: string): TJsonSchemaNumber;
    function Required: TJsonSchemaNumber;
    function Nullable: TJsonSchemaNumber;
    function &End: TObject;
  end;

  /// <summary>
  /// Propriedade do tipo Boolean
  /// </summary>
  TJsonSchemaBoolean = class(TJsonSchemaProperty)
  public
    constructor Create(const AName: string; AParent: TObject);
    
    function DefaultValue(AValue: Boolean): TJsonSchemaBoolean;
    
    // Re-declaração para manter tipo correto
    function Description(const AValue: string): TJsonSchemaBoolean;
    function Required: TJsonSchemaBoolean;
    function Nullable: TJsonSchemaBoolean;
    function &End: TObject;
  end;

  /// <summary>
  /// Propriedade do tipo Array
  /// </summary>
  TJsonSchemaArray = class(TJsonSchemaProperty)
  private
    FMinItems: Integer;
    FMaxItems: Integer;
    FUniqueItems: Boolean;
    FHasMinItems: Boolean;
    FHasMaxItems: Boolean;
    FItemsSchema: TJsonSchemaProperty;
  public
    constructor Create(const AName: string; AParent: TObject);
    destructor Destroy; override;
    
    function ToJSON: TJSONObject; override;
    function Validate(const AValue: TJSONValue; out AError: string): Boolean; override;
    
    // Fluent interface específica
    function MinItems(AValue: Integer): TJsonSchemaArray;
    function MaxItems(AValue: Integer): TJsonSchemaArray;
    function UniqueItems: TJsonSchemaArray;
    
    // Items do array
    function ItemsString: TJsonSchemaString;
    function ItemsNumber(AIsInteger: Boolean = False): TJsonSchemaNumber;
    function ItemsBoolean: TJsonSchemaBoolean;
    function ItemsObject: TJsonSchemaObject;
    
    // Re-declaração para manter tipo correto
    function Description(const AValue: string): TJsonSchemaArray;
    function Required: TJsonSchemaArray;
    function Nullable: TJsonSchemaArray;
    function &End: TObject;
  end;

  /// <summary>
  /// Propriedade do tipo Object (aninhado)
  /// </summary>
  TJsonSchemaObject = class(TJsonSchemaProperty)
  private
    FProperties: TObjectList<TJsonSchemaProperty>;
    FAdditionalProperties: Boolean;
    FMinProperties: Integer;
    FMaxProperties: Integer;
    FHasMinProperties: Boolean;
    FHasMaxProperties: Boolean;
  public
    constructor Create(const AName: string; AParent: TObject);
    destructor Destroy; override;
    
    function ToJSON: TJSONObject; override;
    function Validate(const AValue: TJSONValue; out AError: string): Boolean; override;
    
    // Fluent interface para adicionar propriedades
    function AddString(const AName: string): TJsonSchemaString;
    function AddInteger(const AName: string): TJsonSchemaNumber;
    function AddNumber(const AName: string): TJsonSchemaNumber;
    function AddBoolean(const AName: string): TJsonSchemaBoolean;
    function AddArray(const AName: string): TJsonSchemaArray;
    function AddObject(const AName: string): TJsonSchemaObject;
    
    // Configurações do objeto
    function AdditionalProperties(AValue: Boolean): TJsonSchemaObject;
    function MinProperties(AValue: Integer): TJsonSchemaObject;
    function MaxProperties(AValue: Integer): TJsonSchemaObject;
    
    // Re-declaração para manter tipo correto
    function Description(const AValue: string): TJsonSchemaObject;
    function Required: TJsonSchemaObject;
    function Nullable: TJsonSchemaObject;
    function &End: TObject;
  end;

  /// <summary>
  /// Propriedade para timestamps com validações específicas
  /// </summary>
  TJsonSchemaTimestamp = class(TJsonSchemaString)
  private
    FValidationType: TDateTimeValidator.TDateTimeValidationType;
  public
    function ToJSON: TJSONObject; override;
    function Validate(const AValue: TJSONValue; out AError: string): Boolean; override;
    
    function AsDateOnly: TJsonSchemaTimestamp;
    function AsTimeOnly: TJsonSchemaTimestamp;
    function AsDateTimeLocal: TJsonSchemaTimestamp;
    function AsDateTimeGMT: TJsonSchemaTimestamp;
    
    // Re-declaração para manter tipo correto
    function Description(const AValue: string): TJsonSchemaTimestamp;
    function Required: TJsonSchemaTimestamp;
    function Nullable: TJsonSchemaTimestamp;
    function &End: TObject;
  end;

implementation

uses
  System.RegularExpressions;

{ TJsonSchemaProperty }

constructor TJsonSchemaProperty.Create(const AName: string; AParent: TObject);
begin
  inherited Create;
  FName := AName;
  FParent := AParent;
  FRequired := False;
  FNullable := False;
  FDefault := nil;
  FValidators := TList<IJsonValidator>.Create;
end;

destructor TJsonSchemaProperty.Destroy;
begin
  FValidators.Free;
  if Assigned(FDefault) then
    FDefault.Free;
  inherited;
end;

function TJsonSchemaProperty.GetName: string;
begin
  Result := FName;
end;

function TJsonSchemaProperty.GetSchemaType: TJsonSchemaType;
begin
  Result := FSchemaType;
end;

function TJsonSchemaProperty.IsRequired: Boolean;
begin
  Result := FRequired;
end;

procedure TJsonSchemaProperty.AddBaseProperties(AJson: TJSONObject);
begin
  AJson.AddPair('type', FSchemaType.ToString);
  
  if FDescription <> '' then
    AJson.AddPair('description', FDescription);
    
  if FNullable then
    AJson.AddPair('nullable', TJSONBool.Create(True));
end;

function TJsonSchemaProperty.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  AddBaseProperties(Result);
end;

function TJsonSchemaProperty.Validate(const AValue: TJSONValue; out AError: string): Boolean;
var
  LValidator: IJsonValidator;
begin
  Result := True;
  AError := '';
  
  // Verifica nullable
  if (AValue = nil) or (AValue is TJSONNull) then
  begin
    if FRequired and not FNullable then
    begin
      AError := Format('Property "%s" is required', [FName]);
      Result := False;
    end;
    Exit;
  end;
  
  // Executa validadores
  for LValidator in FValidators do
  begin
    if not LValidator.Validate(AValue) then
    begin
      AError := LValidator.GetErrorMessage;
      Result := False;
      Exit;
    end;
  end;
end;

function TJsonSchemaProperty.Description(const AValue: string): TJsonSchemaProperty;
begin
  FDescription := AValue;
  Result := Self;
end;

function TJsonSchemaProperty.Required: TJsonSchemaProperty;
begin
  FRequired := True;
  Result := Self;
end;

function TJsonSchemaProperty.Nullable: TJsonSchemaProperty;
begin
  FNullable := True;
  Result := Self;
end;

function TJsonSchemaProperty.&End: TObject;
begin
  Result := FParent;
end;

{ TJsonSchemaString }

constructor TJsonSchemaString.Create(const AName: string; AParent: TObject);
begin
  inherited Create(AName, AParent);
  FSchemaType := jstString;
  FFormat := jsfNone;
  FHasMinLength := False;
  FHasMaxLength := False;
end;

function TJsonSchemaString.ToJSON: TJSONObject;
var
  LEnumArray: TJSONArray;
  LValue: string;
begin
  Result := inherited ToJSON;
  
  if FHasMinLength then
    Result.AddPair('minLength', TJSONNumber.Create(FMinLength));
    
  if FHasMaxLength then
    Result.AddPair('maxLength', TJSONNumber.Create(FMaxLength));
    
  if FPattern <> '' then
    Result.AddPair('pattern', FPattern);
    
  if FFormat <> jsfNone then
    Result.AddPair('format', FFormat.ToString);
    
  if Length(FEnumValues) > 0 then
  begin
    LEnumArray := TJSONArray.Create;
    for LValue in FEnumValues do
      LEnumArray.Add(LValue);
    Result.AddPair('enum', LEnumArray);
  end;
  
  if Assigned(FDefault) then
    Result.AddPair('default', FDefault.Clone as TJSONValue);
end;

function TJsonSchemaString.Validate(const AValue: TJSONValue; out AError: string): Boolean;
var
  LStr: string;
  LAllowed: string;
  LFound: Boolean;
begin
  Result := inherited Validate(AValue, AError);
  if not Result or (AValue = nil) or (AValue is TJSONNull) then
    Exit;
    
  if not (AValue is TJSONString) then
  begin
    AError := Format('Property "%s" must be a string', [FName]);
    Exit(False);
  end;
  
  LStr := TJSONString(AValue).Value;
  
  // Valida comprimento mínimo
  if FHasMinLength and (Length(LStr) < FMinLength) then
  begin
    AError := Format('Property "%s" must have at least %d characters', [FName, FMinLength]);
    Exit(False);
  end;
  
  // Valida comprimento máximo
  if FHasMaxLength and (Length(LStr) > FMaxLength) then
  begin
    AError := Format('Property "%s" must have at most %d characters', [FName, FMaxLength]);
    Exit(False);
  end;
  
  // Valida pattern
  if (FPattern <> '') and not TRegEx.IsMatch(LStr, FPattern) then
  begin
    AError := Format('Property "%s" does not match required pattern', [FName]);
    Exit(False);
  end;
  
  // Valida formato
  if (FFormat <> jsfNone) and (FFormat.GetPattern <> '') then
  begin
    if not TRegEx.IsMatch(LStr, FFormat.GetPattern) then
    begin
      AError := Format('Property "%s" is not a valid %s', [FName, FFormat.ToString]);
      Exit(False);
    end;
  end;
  
  // Valida enum
  if Length(FEnumValues) > 0 then
  begin
    LFound := False;
    for LAllowed in FEnumValues do
    begin
      if SameText(LStr, LAllowed) then
      begin
        LFound := True;
        Break;
      end;
    end;
    
    if not LFound then
    begin
      AError := Format('Property "%s" must be one of: [%s]', [FName, string.Join(', ', FEnumValues)]);
      Exit(False);
    end;
  end;
  
  Result := True;
end;

function TJsonSchemaString.MinLength(AValue: Integer): TJsonSchemaString;
begin
  FMinLength := AValue;
  FHasMinLength := True;
  Result := Self;
end;

function TJsonSchemaString.MaxLength(AValue: Integer): TJsonSchemaString;
begin
  FMaxLength := AValue;
  FHasMaxLength := True;
  Result := Self;
end;

function TJsonSchemaString.Pattern(const AValue: string): TJsonSchemaString;
begin
  FPattern := AValue;
  Result := Self;
end;

function TJsonSchemaString.Format(AValue: TJsonSchemaFormat): TJsonSchemaString;
begin
  FFormat := AValue;
  Result := Self;
end;

function TJsonSchemaString.Enum(const AValues: TArray<string>): TJsonSchemaString;
begin
  FEnumValues := AValues;
  Result := Self;
end;

function TJsonSchemaString.DefaultValue(const AValue: string): TJsonSchemaString;
begin
  if Assigned(FDefault) then
    FDefault.Free;
  FDefault := TJSONString.Create(AValue);
  Result := Self;
end;

function TJsonSchemaString.AsEmail: TJsonSchemaString;
begin
  Result := Format(jsfEmail);
end;

function TJsonSchemaString.AsUUID: TJsonSchemaString;
begin
  Result := Format(jsfUUID);
end;

function TJsonSchemaString.AsURI: TJsonSchemaString;
begin
  Result := Format(jsfURI);
end;

function TJsonSchemaString.AsDate: TJsonSchemaString;
begin
  Result := Format(jsfDate);
end;

function TJsonSchemaString.AsTime: TJsonSchemaString;
begin
  Result := Format(jsfTime);
end;

function TJsonSchemaString.AsDateTime: TJsonSchemaString;
begin
  Result := Format(jsfDateTime);
end;

function TJsonSchemaString.AsZipCodeBR: TJsonSchemaString;
begin
  Result := Format(jsfZipCodeBR);
end;

function TJsonSchemaString.AsPhoneBR: TJsonSchemaString;
begin
  Result := Format(jsfPhoneBR);
end;

function TJsonSchemaString.AsCPF: TJsonSchemaString;
begin
  Result := Format(jsfCPF);
end;

function TJsonSchemaString.AsCNPJ: TJsonSchemaString;
begin
  Result := Format(jsfCNPJ);
end;

function TJsonSchemaString.Description(const AValue: string): TJsonSchemaString;
begin
  inherited Description(AValue);
  Result := Self;
end;

function TJsonSchemaString.Required: TJsonSchemaString;
begin
  inherited Required;
  Result := Self;
end;

function TJsonSchemaString.Nullable: TJsonSchemaString;
begin
  inherited Nullable;
  Result := Self;
end;

function TJsonSchemaString.&End: TObject;
begin
  Result := inherited &End;
end;

{ TJsonSchemaNumber }

constructor TJsonSchemaNumber.Create(const AName: string; AParent: TObject; AIsInteger: Boolean);
begin
  inherited Create(AName, AParent);
  FIsInteger := AIsInteger;
  if AIsInteger then
    FSchemaType := jstInteger
  else
    FSchemaType := jstNumber;
    
  FHasMinimum := False;
  FHasMaximum := False;
  FHasExclusiveMinimum := False;
  FHasExclusiveMaximum := False;
  FHasMultipleOf := False;
end;

function TJsonSchemaNumber.ToJSON: TJSONObject;
begin
  Result := inherited ToJSON;
  
  if FHasMinimum then
    Result.AddPair('minimum', TJSONNumber.Create(FMinimum));
    
  if FHasMaximum then
    Result.AddPair('maximum', TJSONNumber.Create(FMaximum));
    
  if FHasExclusiveMinimum then
    Result.AddPair('exclusiveMinimum', TJSONNumber.Create(FExclusiveMinimum));
    
  if FHasExclusiveMaximum then
    Result.AddPair('exclusiveMaximum', TJSONNumber.Create(FExclusiveMaximum));
    
  if FHasMultipleOf then
    Result.AddPair('multipleOf', TJSONNumber.Create(FMultipleOf));
    
  if Assigned(FDefault) then
    Result.AddPair('default', FDefault.Clone as TJSONValue);
end;

function TJsonSchemaNumber.Validate(const AValue: TJSONValue; out AError: string): Boolean;
var
  LNum: Double;
begin
  Result := inherited Validate(AValue, AError);
  if not Result or (AValue = nil) or (AValue is TJSONNull) then
    Exit;
    
  if not (AValue is TJSONNumber) then
  begin
    AError := Format('Property "%s" must be a number', [FName]);
    Exit(False);
  end;
  
  LNum := TJSONNumber(AValue).AsDouble;
  
  // Valida se é inteiro
  if FIsInteger and (Frac(LNum) <> 0) then
  begin
    AError := Format('Property "%s" must be an integer', [FName]);
    Exit(False);
  end;
  
  // Valida mínimo
  if FHasMinimum and (LNum < FMinimum) then
  begin
    AError := Format('Property "%s" must be >= %g', [FName, FMinimum]);
    Exit(False);
  end;
  
  // Valida máximo
  if FHasMaximum and (LNum > FMaximum) then
  begin
    AError := Format('Property "%s" must be <= %g', [FName, FMaximum]);
    Exit(False);
  end;
  
  // Valida exclusiveMinimum
  if FHasExclusiveMinimum and (LNum <= FExclusiveMinimum) then
  begin
    AError := Format('Property "%s" must be > %g', [FName, FExclusiveMinimum]);
    Exit(False);
  end;
  
  // Valida exclusiveMaximum
  if FHasExclusiveMaximum and (LNum >= FExclusiveMaximum) then
  begin
    AError := Format('Property "%s" must be < %g', [FName, FExclusiveMaximum]);
    Exit(False);
  end;
  
  // Valida multipleOf
  if FHasMultipleOf and (FMultipleOf <> 0) then
  begin
    if Abs(Frac(LNum / FMultipleOf)) > 1E-10 then
    begin
      AError := Format('Property "%s" must be a multiple of %g', [FName, FMultipleOf]);
      Exit(False);
    end;
  end;
  
  Result := True;
end;

function TJsonSchemaNumber.Minimum(AValue: Double): TJsonSchemaNumber;
begin
  FMinimum := AValue;
  FHasMinimum := True;
  Result := Self;
end;

function TJsonSchemaNumber.Maximum(AValue: Double): TJsonSchemaNumber;
begin
  FMaximum := AValue;
  FHasMaximum := True;
  Result := Self;
end;

function TJsonSchemaNumber.ExclusiveMinimum(AValue: Double): TJsonSchemaNumber;
begin
  FExclusiveMinimum := AValue;
  FHasExclusiveMinimum := True;
  Result := Self;
end;

function TJsonSchemaNumber.ExclusiveMaximum(AValue: Double): TJsonSchemaNumber;
begin
  FExclusiveMaximum := AValue;
  FHasExclusiveMaximum := True;
  Result := Self;
end;

function TJsonSchemaNumber.MultipleOf(AValue: Double): TJsonSchemaNumber;
begin
  FMultipleOf := AValue;
  FHasMultipleOf := True;
  Result := Self;
end;

function TJsonSchemaNumber.Range(AMin, AMax: Double): TJsonSchemaNumber;
begin
  Minimum(AMin);
  Maximum(AMax);
  Result := Self;
end;

function TJsonSchemaNumber.DefaultValue(AValue: Double): TJsonSchemaNumber;
begin
  if Assigned(FDefault) then
    FDefault.Free;
  FDefault := TJSONNumber.Create(AValue);
  Result := Self;
end;

function TJsonSchemaNumber.Description(const AValue: string): TJsonSchemaNumber;
begin
  inherited Description(AValue);
  Result := Self;
end;

function TJsonSchemaNumber.Required: TJsonSchemaNumber;
begin
  inherited Required;
  Result := Self;
end;

function TJsonSchemaNumber.Nullable: TJsonSchemaNumber;
begin
  inherited Nullable;
  Result := Self;
end;

function TJsonSchemaNumber.&End: TObject;
begin
  Result := inherited &End;
end;

{ TJsonSchemaBoolean }

constructor TJsonSchemaBoolean.Create(const AName: string; AParent: TObject);
begin
  inherited Create(AName, AParent);
  FSchemaType := jstBoolean;
end;

function TJsonSchemaBoolean.DefaultValue(AValue: Boolean): TJsonSchemaBoolean;
begin
  if Assigned(FDefault) then
    FDefault.Free;
  FDefault := TJSONBool.Create(AValue);
  Result := Self;
end;

function TJsonSchemaBoolean.Description(const AValue: string): TJsonSchemaBoolean;
begin
  inherited Description(AValue);
  Result := Self;
end;

function TJsonSchemaBoolean.Required: TJsonSchemaBoolean;
begin
  inherited Required;
  Result := Self;
end;

function TJsonSchemaBoolean.Nullable: TJsonSchemaBoolean;
begin
  inherited Nullable;
  Result := Self;
end;

function TJsonSchemaBoolean.&End: TObject;
begin
  Result := inherited &End;
end;

{ TJsonSchemaArray }

constructor TJsonSchemaArray.Create(const AName: string; AParent: TObject);
begin
  inherited Create(AName, AParent);
  FSchemaType := jstArray;
  FUniqueItems := False;
  FHasMinItems := False;
  FHasMaxItems := False;
  FItemsSchema := nil;
end;

destructor TJsonSchemaArray.Destroy;
begin
  if Assigned(FItemsSchema) then
    FItemsSchema.Free;
  inherited;
end;

function TJsonSchemaArray.ToJSON: TJSONObject;
begin
  Result := inherited ToJSON;
  
  if FHasMinItems then
    Result.AddPair('minItems', TJSONNumber.Create(FMinItems));
    
  if FHasMaxItems then
    Result.AddPair('maxItems', TJSONNumber.Create(FMaxItems));
    
  if FUniqueItems then
    Result.AddPair('uniqueItems', TJSONBool.Create(True));
    
  if Assigned(FItemsSchema) then
    Result.AddPair('items', FItemsSchema.ToJSON);
end;

function TJsonSchemaArray.Validate(const AValue: TJSONValue; out AError: string): Boolean;
var
  LArray: TJSONArray;
  LItem: TJSONValue;
  I: Integer;
  LItemError: string;
begin
  Result := inherited Validate(AValue, AError);
  if not Result or (AValue = nil) or (AValue is TJSONNull) then
    Exit;
    
  if not (AValue is TJSONArray) then
  begin
    AError := Format('Property "%s" must be an array', [FName]);
    Exit(False);
  end;
  
  LArray := TJSONArray(AValue);
  
  // Valida quantidade mínima
  if FHasMinItems and (LArray.Count < FMinItems) then
  begin
    AError := Format('Property "%s" must have at least %d items', [FName, FMinItems]);
    Exit(False);
  end;
  
  // Valida quantidade máxima
  if FHasMaxItems and (LArray.Count > FMaxItems) then
  begin
    AError := Format('Property "%s" must have at most %d items', [FName, FMaxItems]);
    Exit(False);
  end;
  
  // Valida cada item
  if Assigned(FItemsSchema) then
  begin
    for I := 0 to LArray.Count - 1 do
    begin
      LItem := LArray.Items[I];
      if not FItemsSchema.Validate(LItem, LItemError) then
      begin
        AError := Format('Property "%s"[%d]: %s', [FName, I, LItemError]);
        Exit(False);
      end;
    end;
  end;
  
  Result := True;
end;

function TJsonSchemaArray.MinItems(AValue: Integer): TJsonSchemaArray;
begin
  FMinItems := AValue;
  FHasMinItems := True;
  Result := Self;
end;

function TJsonSchemaArray.MaxItems(AValue: Integer): TJsonSchemaArray;
begin
  FMaxItems := AValue;
  FHasMaxItems := True;
  Result := Self;
end;

function TJsonSchemaArray.UniqueItems: TJsonSchemaArray;
begin
  FUniqueItems := True;
  Result := Self;
end;

function TJsonSchemaArray.ItemsString: TJsonSchemaString;
begin
  if Assigned(FItemsSchema) then
    FItemsSchema.Free;
  FItemsSchema := TJsonSchemaString.Create('items', Self);
  Result := TJsonSchemaString(FItemsSchema);
end;

function TJsonSchemaArray.ItemsNumber(AIsInteger: Boolean): TJsonSchemaNumber;
begin
  if Assigned(FItemsSchema) then
    FItemsSchema.Free;
  FItemsSchema := TJsonSchemaNumber.Create('items', Self, AIsInteger);
  Result := TJsonSchemaNumber(FItemsSchema);
end;

function TJsonSchemaArray.ItemsBoolean: TJsonSchemaBoolean;
begin
  if Assigned(FItemsSchema) then
    FItemsSchema.Free;
  FItemsSchema := TJsonSchemaBoolean.Create('items', Self);
  Result := TJsonSchemaBoolean(FItemsSchema);
end;

function TJsonSchemaArray.ItemsObject: TJsonSchemaObject;
begin
  if Assigned(FItemsSchema) then
    FItemsSchema.Free;
  FItemsSchema := TJsonSchemaObject.Create('items', Self);
  Result := TJsonSchemaObject(FItemsSchema);
end;

function TJsonSchemaArray.Description(const AValue: string): TJsonSchemaArray;
begin
  inherited Description(AValue);
  Result := Self;
end;

function TJsonSchemaArray.Required: TJsonSchemaArray;
begin
  inherited Required;
  Result := Self;
end;

function TJsonSchemaArray.Nullable: TJsonSchemaArray;
begin
  inherited Nullable;
  Result := Self;
end;

function TJsonSchemaArray.&End: TObject;
begin
  Result := inherited &End;
end;

{ TJsonSchemaObject }

constructor TJsonSchemaObject.Create(const AName: string; AParent: TObject);
begin
  inherited Create(AName, AParent);
  FSchemaType := jstObject;
  FProperties := TObjectList<TJsonSchemaProperty>.Create(True);
  FAdditionalProperties := True;
  FHasMinProperties := False;
  FHasMaxProperties := False;
end;

destructor TJsonSchemaObject.Destroy;
begin
  FProperties.Free;
  inherited;
end;

function TJsonSchemaObject.ToJSON: TJSONObject;
var
  LProperties: TJSONObject;
  LRequired: TJSONArray;
  LProp: TJsonSchemaProperty;
begin
  Result := inherited ToJSON;
  
  if FProperties.Count > 0 then
  begin
    LProperties := TJSONObject.Create;
    LRequired := TJSONArray.Create;
    
    for LProp in FProperties do
    begin
      LProperties.AddPair(LProp.FName, LProp.ToJSON);
      if LProp.FRequired then
        LRequired.Add(LProp.FName);
    end;
    
    Result.AddPair('properties', LProperties);
    
    if LRequired.Count > 0 then
      Result.AddPair('required', LRequired)
    else
      LRequired.Free;
  end;
  
  if not FAdditionalProperties then
    Result.AddPair('additionalProperties', TJSONBool.Create(False));
    
  if FHasMinProperties then
    Result.AddPair('minProperties', TJSONNumber.Create(FMinProperties));
    
  if FHasMaxProperties then
    Result.AddPair('maxProperties', TJSONNumber.Create(FMaxProperties));
end;

function TJsonSchemaObject.Validate(const AValue: TJSONValue; out AError: string): Boolean;
var
  LObj: TJSONObject;
  LProp: TJsonSchemaProperty;
  LPropValue: TJSONValue;
  LPropError: string;
begin
  Result := inherited Validate(AValue, AError);
  if not Result or (AValue = nil) or (AValue is TJSONNull) then
    Exit;
    
  if not (AValue is TJSONObject) then
  begin
    AError := Format('Property "%s" must be an object', [FName]);
    Exit(False);
  end;
  
  LObj := TJSONObject(AValue);
  
  // Valida quantidade de propriedades
  if FHasMinProperties and (LObj.Count < FMinProperties) then
  begin
    AError := Format('Property "%s" must have at least %d properties', [FName, FMinProperties]);
    Exit(False);
  end;
  
  if FHasMaxProperties and (LObj.Count > FMaxProperties) then
  begin
    AError := Format('Property "%s" must have at most %d properties', [FName, FMaxProperties]);
    Exit(False);
  end;
  
  // Valida cada propriedade definida
  for LProp in FProperties do
  begin
    LPropValue := LObj.GetValue(LProp.FName);
    
    // Verifica se propriedade requerida existe
    if LProp.FRequired and (LPropValue = nil) then
    begin
      AError := Format('Property "%s.%s" is required', [FName, LProp.FName]);
      Exit(False);
    end;
    
    // Valida o valor se existir
    if LPropValue <> nil then
    begin
      if not LProp.Validate(LPropValue, LPropError) then
      begin
        AError := Format('%s.%s', [FName, LPropError]);
        Exit(False);
      end;
    end;
  end;
  
  Result := True;
end;

function TJsonSchemaObject.AddString(const AName: string): TJsonSchemaString;
begin
  Result := TJsonSchemaString.Create(AName, Self);
  FProperties.Add(Result);
end;

function TJsonSchemaObject.AddInteger(const AName: string): TJsonSchemaNumber;
begin
  Result := TJsonSchemaNumber.Create(AName, Self, True);
  FProperties.Add(Result);
end;

function TJsonSchemaObject.AddNumber(const AName: string): TJsonSchemaNumber;
begin
  Result := TJsonSchemaNumber.Create(AName, Self, False);
  FProperties.Add(Result);
end;

function TJsonSchemaObject.AddBoolean(const AName: string): TJsonSchemaBoolean;
begin
  Result := TJsonSchemaBoolean.Create(AName, Self);
  FProperties.Add(Result);
end;

function TJsonSchemaObject.AddArray(const AName: string): TJsonSchemaArray;
begin
  Result := TJsonSchemaArray.Create(AName, Self);
  FProperties.Add(Result);
end;

function TJsonSchemaObject.AddObject(const AName: string): TJsonSchemaObject;
begin
  Result := TJsonSchemaObject.Create(AName, Self);
  FProperties.Add(Result);
end;

function TJsonSchemaObject.AdditionalProperties(AValue: Boolean): TJsonSchemaObject;
begin
  FAdditionalProperties := AValue;
  Result := Self;
end;

function TJsonSchemaObject.MinProperties(AValue: Integer): TJsonSchemaObject;
begin
  FMinProperties := AValue;
  FHasMinProperties := True;
  Result := Self;
end;

function TJsonSchemaObject.MaxProperties(AValue: Integer): TJsonSchemaObject;
begin
  FMaxProperties := AValue;
  FHasMaxProperties := True;
  Result := Self;
end;

function TJsonSchemaObject.Description(const AValue: string): TJsonSchemaObject;
begin
  inherited Description(AValue);
  Result := Self;
end;

function TJsonSchemaObject.Required: TJsonSchemaObject;
begin
  inherited Required;
  Result := Self;
end;

function TJsonSchemaObject.Nullable: TJsonSchemaObject;
begin
  inherited Nullable;
  Result := Self;
end;

function TJsonSchemaObject.&End: TObject;
begin
  Result := inherited &End;
end;

{ TJsonSchemaTimestamp }

function TJsonSchemaTimestamp.ToJSON: TJSONObject;
begin
  Result := inherited ToJSON;
  
  case FValidationType of
    dtvDate:       Result.AddPair('format', 'date');
    dtvTime:       Result.AddPair('format', 'time');
    dtvDateTime:   Result.AddPair('format', 'date-time');
    dtvDateTimeGMT: Result.AddPair('format', 'date-time');
  end;
end;

function TJsonSchemaTimestamp.Validate(const AValue: TJSONValue; out AError: string): Boolean;
var
  LValidator: TDateTimeValidator;
begin
  Result := inherited Validate(AValue, AError);
  if not Result or (AValue = nil) or (AValue is TJSONNull) then
    Exit;
    
  LValidator := TDateTimeValidator.Create(FValidationType);
  try
    Result := LValidator.Validate(AValue);
    if not Result then
      AError := Format('Property "%s": %s', [FName, LValidator.GetErrorMessage]);
  finally
    LValidator.Free;
  end;
end;

function TJsonSchemaTimestamp.AsDateOnly: TJsonSchemaTimestamp;
begin
  FValidationType := dtvDate;
  Result := Self;
end;

function TJsonSchemaTimestamp.AsTimeOnly: TJsonSchemaTimestamp;
begin
  FValidationType := dtvTime;
  Result := Self;
end;

function TJsonSchemaTimestamp.AsDateTimeLocal: TJsonSchemaTimestamp;
begin
  FValidationType := dtvDateTime;
  Result := Self;
end;

function TJsonSchemaTimestamp.AsDateTimeGMT: TJsonSchemaTimestamp;
begin
  FValidationType := dtvDateTimeGMT;
  Result := Self;
end;

function TJsonSchemaTimestamp.Description(const AValue: string): TJsonSchemaTimestamp;
begin
  inherited Description(AValue);
  Result := Self;
end;

function TJsonSchemaTimestamp.Required: TJsonSchemaTimestamp;
begin
  inherited Required;
  Result := Self;
end;

function TJsonSchemaTimestamp.Nullable: TJsonSchemaTimestamp;
begin
  inherited Nullable;
  Result := Self;
end;

function TJsonSchemaTimestamp.&End: TObject;
begin
  Result := inherited &End;
end;

end.
