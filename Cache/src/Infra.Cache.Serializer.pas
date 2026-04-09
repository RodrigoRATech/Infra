unit Infra.Cache.Serializer;

interface

uses
  Infra.Cache.Interfaces, System.JSON;

type
  /// <summary>
  ///   Serialização/deserialização genérica de objetos usando RTTI e JSON.
  ///   Métodos genéricos (Serialize<T>, Deserialize<T>) são acessíveis
  ///   via referência à classe concreta.
  ///   Métodos de interface (SerializeJSON, DeserializeJSON) são acessíveis via ICacheSerializer.
  /// </summary>
  TCacheSerializer = class(TInterfacedObject, ICacheSerializer)
  public
    { Métodos genéricos — acessíveis apenas via referência à classe }
    function Serialize<T: class>(AObject: T): string;
    function Deserialize<T: class, constructor>(const AData: string): T;

    { ICacheSerializer }
    function SerializeJSON(AValue: TJSONValue): string;
    function DeserializeJSON(const AData: string): TJSONValue;
  end;

implementation

uses
  System.SysUtils, REST.Json;

{ TCacheSerializer }

function TCacheSerializer.Serialize<T>(AObject: T): string;
begin
  if not Assigned(AObject) then
    raise EArgumentNilException.Create('Objeto nulo não pode ser serializado.');
  Result := TJson.ObjectToJsonString(AObject);
end;

function TCacheSerializer.Deserialize<T>(const AData: string): T;
begin
  if AData.IsEmpty then
    raise EArgumentException.Create('Dados vazios não podem ser deserializados.');
  Result := TJson.JsonToObject<T>(AData);
end;

function TCacheSerializer.SerializeJSON(AValue: TJSONValue): string;
begin
  if not Assigned(AValue) then
    raise EArgumentNilException.Create('JSON nulo não pode ser serializado.');
  Result := AValue.ToJSON;
end;

function TCacheSerializer.DeserializeJSON(const AData: string): TJSONValue;
begin
  if AData.IsEmpty then
    raise EArgumentException.Create('Dados vazios não podem ser deserializados para JSON.');
  Result := TJSONObject.ParseJSONValue(AData);
  if not Assigned(Result) then
    raise EArgumentException.Create('Falha ao fazer parse do JSON: ' + AData);
end;

end.
