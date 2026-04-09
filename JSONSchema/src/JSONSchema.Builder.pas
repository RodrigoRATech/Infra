unit JsonSchema.Builder;

interface

uses
  System.SysUtils, System.JSON, System.Generics.Collections,
  JsonSchema.Types, JsonSchema.Properties;

type
  /// <summary>
  /// Builder principal para construção de JSON Schemas
  /// </summary>
  TJsonSchemaBuilder = class
  private
    FId: string;
    FSchema: string;
    FTitle: string;
    FDescription: string;
    FProperties: TObjectList<TJsonSchemaProperty>;
    FAdditionalProperties: Boolean;
    FDefinitions: TObjectDictionary<string, TJsonSchemaObject>;
    
    function GetRequiredArray: TJSONArray;
  public
    constructor Create;
    destructor Destroy; override;
    
    /// <summary>
    /// Define o $id do schema
    /// </summary>
    function Id(const AValue: string): TJsonSchemaBuilder;
    
    /// <summary>
    /// Define o título do schema
    /// </summary>
    function Title(const AValue: string): TJsonSchemaBuilder;
    
    /// <summary>
    /// Define a descrição do schema
    /// </summary>
    function Description(const AValue: string): TJsonSchemaBuilder;
    
    /// <summary>
    /// Define se propriedades adicionais são permitidas
    /// </summary>
    function AdditionalProperties(AValue: Boolean): TJsonSchemaBuilder;
    
    /// <summary>
    /// Adiciona uma propriedade do tipo string
    /// </summary>
    function AddString(const AName: string): TJsonSchemaString;
    
    /// <summary>
    /// Adiciona uma propriedade do tipo integer
    /// </summary>
    function AddInteger(const AName: string): TJsonSchemaNumber;
    
    /// <summary>
    /// Adiciona uma propriedade do tipo number
    /// </summary>
    function AddNumber(const AName: string): TJsonSchemaNumber;
    
    /// <summary>
    /// Adiciona uma propriedade do tipo boolean
    /// </summary>
    function AddBoolean(const AName: string): TJsonSchemaBoolean;
    
    /// <summary>
    /// Adiciona uma propriedade do tipo array
    /// </summary>
    function AddArray(const AName: string): TJsonSchemaArray;
    
    /// <summary>
    /// Adiciona uma propriedade do tipo object
    /// </summary>
    function AddObject(const AName: string): TJsonSchemaObject;
    
    /// <summary>
    /// Adiciona uma propriedade do tipo timestamp
    /// </summary>
    function AddTimestamp(const AName: string): TJsonSchemaTimestamp;
    
    /// <summary>
    /// Adiciona uma definição reutilizável ($defs)
    /// </summary>
    function AddDefinition(const AName: string): TJsonSchemaObject;
    
    /// <summary>
    /// Gera o JSON Schema como TJSONObject
    /// </summary>
    function Build: TJSONObject;
    
    /// <summary>
    /// Gera o JSON Schema como string formatada
    /// </summary>
    function ToJSON(AIndent: Boolean = True): string;
    
    /// <summary>
    /// Valida um JSON contra o schema
    /// </summary>
    function Validate(const AJson: string): Boolean; overload;
    function Validate(const AJson: string; out AErrors: TArray<string>): Boolean; overload;
    function Validate(AJsonObject: TJSONObject; out AErrors: TArray<string>): Boolean; overload;
    
    /// <summary>
    /// Cria uma nova instância do builder
    /// </summary>
    class function New: TJsonSchemaBuilder;
  end;

implementation

{ TJsonSchemaBuilder }

constructor TJsonSchemaBuilder.Create;
begin
  inherited Create;
  FSchema := JSON_SCHEMA_DRAFT;
  FProperties := TObjectList<TJsonSchemaProperty>.Create(True);
  FDefinitions := TObjectDictionary<string, TJsonSchemaObject>.Create([doOwnsValues]);
  FAdditionalProperties := True;
end;

destructor TJsonSchemaBuilder.Destroy;
begin
  FProperties.Free;
  FDefinitions.Free;
  inherited;
end;

class function TJsonSchemaBuilder.New: TJsonSchemaBuilder;
begin
  Result := TJsonSchemaBuilder.Create;
end;

function TJsonSchemaBuilder.Id(const AValue: string): TJsonSchemaBuilder;
begin
  FId := AValue;
  Result := Self;
end;

function TJsonSchemaBuilder.Title(const AValue: string): TJsonSchemaBuilder;
begin
  FTitle := AValue;
  Result := Self;
end;

function TJsonSchemaBuilder.Description(const AValue: string): TJsonSchemaBuilder;
begin
  FDescription := AValue;
  Result := Self;
end;

function TJsonSchemaBuilder.AdditionalProperties(AValue: Boolean): TJsonSchemaBuilder;
begin
  FAdditionalProperties := AValue;
  Result := Self;
end;

function TJsonSchemaBuilder.AddString(const AName: string): TJsonSchemaString;
begin
  Result := TJsonSchemaString.Create(AName, Self);
  FProperties.Add(Result);
end;

function TJsonSchemaBuilder.AddInteger(const AName: string): TJsonSchemaNumber;
begin
  Result := TJsonSchemaNumber.Create(AName, Self, True);
  FProperties.Add(Result);
end;

function TJsonSchemaBuilder.AddNumber(const AName: string): TJsonSchemaNumber;
begin
  Result := TJsonSchemaNumber.Create(AName, Self, False);
  FProperties.Add(Result);
end;

function TJsonSchemaBuilder.AddBoolean(const AName: string): TJsonSchemaBoolean;
begin
  Result := TJsonSchemaBoolean.Create(AName, Self);
  FProperties.Add(Result);
end;

function TJsonSchemaBuilder.AddArray(const AName: string): TJsonSchemaArray;
begin
  Result := TJsonSchemaArray.Create(AName, Self);
  FProperties.Add(Result);
end;

function TJsonSchemaBuilder.AddObject(const AName: string): TJsonSchemaObject;
begin
  Result := TJsonSchemaObject.Create(AName, Self);
  FProperties.Add(Result);
end;

function TJsonSchemaBuilder.AddTimestamp(const AName: string): TJsonSchemaTimestamp;
begin
  Result := TJsonSchemaTimestamp.Create(AName, Self);
  FProperties.Add(Result);
end;

function TJsonSchemaBuilder.AddDefinition(const AName: string): TJsonSchemaObject;
begin
  Result := TJsonSchemaObject.Create(AName, Self);
  FDefinitions.Add(AName, Result);
end;

function TJsonSchemaBuilder.GetRequiredArray: TJSONArray;
var
  LProp: TJsonSchemaProperty;
begin
  Result := TJSONArray.Create;
  for LProp in FProperties do
  begin
    if LProp.IsRequired then
      Result.Add(LProp.GetName);
  end;
end;

function TJsonSchemaBuilder.Build: TJSONObject;
var
  LProperties: TJSONObject;
  LRequired: TJSONArray;
  LDefs: TJSONObject;
  LProp: TJsonSchemaProperty;
  LDefPair: TPair<string, TJsonSchemaObject>;
begin
  Result := TJSONObject.Create;
  
  // Metadados do schema
  Result.AddPair('$schema', FSchema);
  
  if FId <> '' then
    Result.AddPair('$id', FId);
    
  if FTitle <> '' then
    Result.AddPair('title', FTitle);
    
  if FDescription <> '' then
    Result.AddPair('description', FDescription);
    
  Result.AddPair('type', 'object');
  
  // Propriedades
  if FProperties.Count > 0 then
  begin
    LProperties := TJSONObject.Create;
    for LProp in FProperties do
      LProperties.AddPair(LProp.GetName, LProp.ToJSON);
    Result.AddPair('properties', LProperties);
    
    // Required
    LRequired := GetRequiredArray;
    if LRequired.Count > 0 then
      Result.AddPair('required', LRequired)
    else
      LRequired.Free;
  end;
  
  // Additional properties
  if not FAdditionalProperties then
    Result.AddPair('additionalProperties', TJSONBool.Create(False));
    
  // Definitions ($defs)
  if FDefinitions.Count > 0 then
  begin
    LDefs := TJSONObject.Create;
    for LDefPair in FDefinitions do
      LDefs.AddPair(LDefPair.Key, LDefPair.Value.ToJSON);
    Result.AddPair('$defs', LDefs);
  end;
end;

function TJsonSchemaBuilder.ToJSON(AIndent: Boolean): string;
var
  LJson: TJSONObject;
begin
  LJson := Build;
  try
    if AIndent then
      Result := LJson.Format(2)
    else
      Result := LJson.ToJSON;
  finally
    LJson.Free;
  end;
end;

function TJsonSchemaBuilder.Validate(const AJson: string): Boolean;
var
  LErrors: TArray<string>;
begin
  Result := Validate(AJson, LErrors);
end;

function TJsonSchemaBuilder.Validate(const AJson: string; out AErrors: TArray<string>): Boolean;
var
  LJsonObj: TJSONObject;
begin
  LJsonObj := TJSONObject.ParseJSONValue(AJson) as TJSONObject;
  if LJsonObj = nil then
  begin
    SetLength(AErrors, 1);
    AErrors[0] := 'Invalid JSON format';
    Exit(False);
  end;
  
  try
    Result := Validate(LJsonObj, AErrors);
  finally
    LJsonObj.Free;
  end;
end;

function TJsonSchemaBuilder.Validate(AJsonObject: TJSONObject; out AErrors: TArray<string>): Boolean;
var
  LProp: TJsonSchemaProperty;
  LPropValue: TJSONValue;
  LError: string;
  LErrorList: TList<string>;
begin
  LErrorList := TList<string>.Create;
  try
    for LProp in FProperties do
    begin
      LPropValue := AJsonObject.GetValue(LProp.GetName);
      
      // Verifica se propriedade requerida existe
      if LProp.IsRequired and (LPropValue = nil) then
      begin
        LErrorList.Add(Format('Property "%s" is required', [LProp.GetName]));
        Continue;
      end;
      
      // Valida o valor se existir
      if LPropValue <> nil then
      begin
        if not LProp.Validate(LPropValue, LError) then
          LErrorList.Add(LError);
      end;
    end;
    
    AErrors := LErrorList.ToArray;
    Result := Length(AErrors) = 0;
  finally
    LErrorList.Free;
  end;
end;

end.
