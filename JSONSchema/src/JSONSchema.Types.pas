unit JsonSchema.Types;

interface

uses
  System.SysUtils, System.Generics.Collections, System.JSON, System.RegularExpressions;

type
  /// <summary>
  /// Tipos de dados suportados pelo JSON Schema
  /// </summary>
  TJsonSchemaType = (
    jstString,
    jstInteger,
    jstNumber,
    jstBoolean,
    jstArray,
    jstObject,
    jstNull
  );

  /// <summary>
  /// Formatos pré-definidos para strings
  /// </summary>
  TJsonSchemaFormat = (
    jsfNone,
    jsfDateTime,
    jsfDate,
    jsfTime,
    jsfDuration,
    jsfEmail,
    jsfHostname,
    jsfIPv4,
    jsfIPv6,
    jsfURI,
    jsfUUID,
    jsfRegex,
    // Formatos customizados brasileiros
    jsfZipCodeBR,
    jsfPhoneBR,
    jsfCPF,
    jsfCNPJ
  );

  TJsonSchemaTypeHelper = record helper for TJsonSchemaType
    function ToString: string;
    class function FromString(const AValue: string): TJsonSchemaType; static;
  end;

  TJsonSchemaFormatHelper = record helper for TJsonSchemaFormat
    function ToString: string;
    function GetPattern: string;
  end;

  /// <summary>
  /// Exceção base para erros de JSON Schema
  /// </summary>
  EJsonSchemaException = class(Exception);
  EJsonSchemaValidationException = class(EJsonSchemaException);
  EJsonSchemaBuildException = class(EJsonSchemaException);

const
  JSON_SCHEMA_DRAFT = 'https://json-schema.org/draft/2020-12/schema';

implementation

{ TJsonSchemaTypeHelper }

function TJsonSchemaTypeHelper.ToString: string;
begin
  case Self of
    jstString:  Result := 'string';
    jstInteger: Result := 'integer';
    jstNumber:  Result := 'number';
    jstBoolean: Result := 'boolean';
    jstArray:   Result := 'array';
    jstObject:  Result := 'object';
    jstNull:    Result := 'null';
  else
    Result := 'string';
  end;
end;

class function TJsonSchemaTypeHelper.FromString(const AValue: string): TJsonSchemaType;
begin
  if AValue = 'string' then Result := jstString
  else if AValue = 'integer' then Result := jstInteger
  else if AValue = 'number' then Result := jstNumber
  else if AValue = 'boolean' then Result := jstBoolean
  else if AValue = 'array' then Result := jstArray
  else if AValue = 'object' then Result := jstObject
  else if AValue = 'null' then Result := jstNull
  else Result := jstString;
end;

{ TJsonSchemaFormatHelper }

function TJsonSchemaFormatHelper.ToString: string;
begin
  case Self of
    jsfDateTime:   Result := 'date-time';
    jsfDate:       Result := 'date';
    jsfTime:       Result := 'time';
    jsfDuration:   Result := 'duration';
    jsfEmail:      Result := 'email';
    jsfHostname:   Result := 'hostname';
    jsfIPv4:       Result := 'ipv4';
    jsfIPv6:       Result := 'ipv6';
    jsfURI:        Result := 'uri';
    jsfUUID:       Result := 'uuid';
    jsfRegex:      Result := 'regex';
    jsfZipCodeBR:  Result := 'zipcode-br';
    jsfPhoneBR:    Result := 'phone-br';
    jsfCPF:        Result := 'cpf';
    jsfCNPJ:       Result := 'cnpj';
  else
    Result := '';
  end;
end;

function TJsonSchemaFormatHelper.GetPattern: string;
begin
  case Self of
    jsfEmail:
      Result := '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    jsfIPv4:
      Result := '^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$';
    jsfUUID:
      Result := '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';
    jsfZipCodeBR:
      Result := '^\d{5}-?\d{3}$';
    jsfPhoneBR:
      Result := '^(\+55\s?)?(\(?\d{2}\)?[\s-]?)?(9?\d{4}[\s-]?\d{4})$';
    jsfCPF:
      Result := '^\d{3}\.?\d{3}\.?\d{3}-?\d{2}$';
    jsfCNPJ:
      Result := '^\d{2}\.?\d{3}\.?\d{3}/?\d{4}-?\d{2}$';
    jsfDate:
      Result := '^\d{4}-\d{2}-\d{2}$';
    jsfTime:
      Result := '^\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})?$';
    jsfDateTime:
      Result := '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})?$';
  else
    Result := '';
  end;
end;

end.
