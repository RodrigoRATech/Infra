unit JsonSchema;

interface

uses
  JsonSchema.Types,
  JsonSchema.Validators,
  JsonSchema.Properties,
  JsonSchema.Builder;

type
  // Re-exporta tipos principais
  TJsonSchemaBuilder = JsonSchema.Builder.TJsonSchemaBuilder;
  TJsonSchemaType = JsonSchema.Types.TJsonSchemaType;
  TJsonSchemaFormat = JsonSchema.Types.TJsonSchemaFormat;
  
  EJsonSchemaException = JsonSchema.Types.EJsonSchemaException;
  EJsonSchemaValidationException = JsonSchema.Types.EJsonSchemaValidationException;

/// <summary>
/// Factory function para criar um novo schema builder
/// </summary>
function NewJsonSchema: TJsonSchemaBuilder;

implementation

function NewJsonSchema: TJsonSchemaBuilder;
begin
  Result := TJsonSchemaBuilder.New;
end;

end.
