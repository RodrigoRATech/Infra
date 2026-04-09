unit Tests.Cache.Serializer;

interface

uses
  DUnitX.TestFramework, System.JSON,
  Cache.Interfaces, Cache.Serializer, Cache.Fallback;

type
  TTestPerson = class
  private
    FName: string;
    FAge: Integer;
  public
    property Name: string read FName write FName;
    property Age: Integer read FAge write FAge;
  end;

  [TestFixture]
  TSerializerTest = class
  private
    FSerializer: ICacheSerializer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Test_Serialize_Object;
    [Test]
    procedure Test_Deserialize_Object;
    [Test]
    procedure Test_Roundtrip_Object;
    [Test]
    procedure Test_Serialize_Nil_Raises;
    [Test]
    procedure Test_Deserialize_Empty_Raises;
    [Test]
    procedure Test_SerializeJSON;
    [Test]
    procedure Test_DeserializeJSON;
    [Test]
    procedure Test_DeserializeJSON_Invalid_Raises;
  end;

  [TestFixture]
  TFallbackCacheTest = class
  private
    FFallback: TMemoryFallbackCache;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Test_Put_And_Get;
    [Test]
    procedure Test_Get_NonExistent;
    [Test]
    procedure Test_Remove;
    [Test]
    procedure Test_Exists;
    [Test]
    procedure Test_Clear;
    [Test]
    procedure Test_TTL_Expiration;
    [Test]
    procedure Test_MaxEntries_Eviction;
  end;

implementation

uses
  System.SysUtils, System.DateUtils;

{ TSerializerTest }

procedure TSerializerTest.Setup;
begin
  FSerializer := TCacheSerializer.Create;
end;

procedure TSerializerTest.TearDown;
begin
  FSerializer := nil;
end;

procedure TSerializerTest.Test_Serialize_Object;
var
  LPerson: TTestPerson;
  LJson: string;
begin
  LPerson := TTestPerson.Create;
  try
    LPerson.Name := 'Rodrigo';
    LPerson.Age := 30;
    LJson := FSerializer.Serialize<TTestPerson>(LPerson);
    Assert.IsNotEmpty(LJson);
    Assert.Contains(LJson, 'Rodrigo');
  finally
    LPerson.Free;
  end;
end;

procedure TSerializerTest.Test_Deserialize_Object;
var
  LPerson: TTestPerson;
begin
  LPerson := FSerializer.Deserialize<TTestPerson>('{"name":"Ana","age":25}');
  try
    Assert.IsNotNull(LPerson);
    Assert.AreEqual('Ana', LPerson.Name);
    Assert.AreEqual(25, LPerson.Age);
  finally
    LPerson.Free;
  end;
end;

procedure TSerializerTest.Test_Roundtrip_Object;
var
  LOriginal, LRestored: TTestPerson;
  LJson: string;
begin
  LOriginal := TTestPerson.Create;
  try
    LOriginal.Name := 'Carlos';
    LOriginal.Age := 40;
    LJson := FSerializer.Serialize<TTestPerson>(LOriginal);
  finally
    LOriginal.Free;
  end;

  LRestored := FSerializer.Deserialize<TTestPerson>(LJson);
  try
    Assert.AreEqual('Carlos', LRestored.Name);
    Assert.AreEqual(40, LRestored.Age);
  finally
    LRestored.Free;
  end;
end;

procedure TSerializerTest.Test_Serialize_Nil_Raises;
begin
  Assert.WillRaise(
    procedure
    begin
      FSerializer.Serialize<TTestPerson>(nil);
    end,
    EArgumentNilException
  );
end;

procedure TSerializerTest.Test_Deserialize_Empty_Raises;
begin
  Assert.WillRaise(
    procedure
    begin
      FSerializer.Deserialize<TTestPerson>('');
    end,
    EArgumentException
  );
end;

procedure TSerializerTest.Test_SerializeJSON;
var
  LObj: TJSONObject;
  LResult: string;
begin
  LObj := TJSONObject.Create;
  try
    LObj.AddPair('key', 'value');
    LResult := FSerializer.SerializeJSON(LObj);
    Assert.Contains(LResult, 'key');
    Assert.Contains(LResult, 'value');
  finally
    LObj.Free;
  end;
end;

procedure TSerializerTest.Test_DeserializeJSON;
var
  LValue: TJSONValue;
begin
  LValue := FSerializer.DeserializeJSON('{"a":1}');
  try
    Assert.IsNotNull(LValue);
    Assert.IsTrue(LValue is TJSONObject);
  finally
    LValue.Free;
  end;
end;

procedure TSerializerTest.Test_DeserializeJSON_Invalid_Raises;
begin
  Assert.WillRaise(
    procedure
    begin
      FSerializer.DeserializeJSON('isso nao eh json {{{');
    end,
    EArgumentException
  );
end;

{ TFallbackCacheTest }

procedure TFallbackCacheTest.Setup;
begin
  FFallback := TMemoryFallbackCache.Create(100);
end;

procedure TFallbackCacheTest.TearDown;
begin
  FFallback.Free;
end;

procedure TFallbackCacheTest.Test_Put_And_Get;
var
  LValue: string;
begin
  FFallback.Put('key1', 'value1', 60);
  Assert.IsTrue(FFallback.Get('key1', LValue));
  Assert.AreEqual('value1', LValue);
end;

procedure TFallbackCacheTest.Test_Get_NonExistent;
var
  LValue: string;
begin
  Assert.IsFalse(FFallback.Get('nonexistent', LValue));
  Assert.IsEmpty(LValue);
end;

procedure TFallbackCacheTest.Test_Remove;
begin
  FFallback.Put('key2', 'val2', 60);
  Assert.IsTrue(FFallback.Remove('key2'));
  Assert.IsFalse(FFallback.Exists('key2'));
end;

procedure TFallbackCacheTest.Test_Exists;
begin
  FFallback.Put('key3', 'val3', 60);
  Assert.IsTrue(FFallback.Exists('key3'));
  Assert.IsFalse(FFallback.Exists('key_nope'));
end;

procedure TFallbackCacheTest.Test_Clear;
begin
  FFallback.Put('a', '1', 60);
  FFallback.Put('b', '2', 60);
  FFallback.Clear;
  Assert.AreEqual(0, FFallback.Count);
end;

procedure TFallbackCacheTest.Test_TTL_Expiration;
var
  LValue: string;
begin
  FFallback.Put('expire_key', 'data', 1); // 1 segundo TTL
  Assert.IsTrue(FFallback.Get('expire_key', LValue));
  Sleep(1500); // espera expirar
  Assert.IsFalse(FFallback.Get('expire_key', LValue));
end;

procedure TFallbackCacheTest.Test_MaxEntries_Eviction;
var
  I: Integer;
  LValue: string;
begin
  // MaxEntries = 100; inserir 110
  for I := 1 to 110 do
    FFallback.Put('k' + I.ToString, 'v' + I.ToString, 300);

  Assert.IsTrue(FFallback.Count <= 100);
  // Último deve existir
  Assert.IsTrue(FFallback.Get('k110', LValue));
end;

initialization
  TDUnitX.RegisterTestFixture(TSerializerTest);
  TDUnitX.RegisterTestFixture(TFallbackCacheTest);

end.
