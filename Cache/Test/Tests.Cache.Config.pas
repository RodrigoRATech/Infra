unit Tests.Cache.Config;

interface

uses
  DUnitX.TestFramework,
  Cache.Config;

type
  [TestFixture]
  TCacheConfigTest = class
  public
    [Test]
    procedure Test_Default_Values;
    [Test]
    procedure Test_Validate_OK;
    [Test]
    procedure Test_Validate_Empty_Host;
    [Test]
    procedure Test_Validate_Invalid_Port;
    [Test]
    procedure Test_Clone;
    [Test]
    procedure Test_GetFullKey;
  end;

implementation

uses
  System.SysUtils;

{ TCacheConfigTest }

procedure TCacheConfigTest.Test_Default_Values;
var
  LConfig: TCacheConfig;
begin
  LConfig := TCacheConfig.Create;
  try
    Assert.AreEqual('127.0.0.1', LConfig.Host);
    Assert.AreEqual(6379, LConfig.Port);
    Assert.AreEqual(300, LConfig.DefaultTTLSeconds);
    Assert.IsTrue(LConfig.FallbackEnabled);
  finally
    LConfig.Free;
  end;
end;

procedure TCacheConfigTest.Test_Validate_OK;
var
  LConfig: TCacheConfig;
begin
  LConfig := TCacheConfig.Create;
  try
    Assert.IsTrue(LConfig.Validate);
  finally
    LConfig.Free;
  end;
end;

procedure TCacheConfigTest.Test_Validate_Empty_Host;
var
  LConfig: TCacheConfig;
begin
  LConfig := TCacheConfig.Create;
  try
    LConfig.Host := '';
    Assert.IsFalse(LConfig.Validate);
  finally
    LConfig.Free;
  end;
end;

procedure TCacheConfigTest.Test_Validate_Invalid_Port;
var
  LConfig: TCacheConfig;
begin
  LConfig := TCacheConfig.Create;
  try
    LConfig.Port := 0;
    Assert.IsFalse(LConfig.Validate);
  finally
    LConfig.Free;
  end;
end;

procedure TCacheConfigTest.Test_Clone;
var
  LOriginal, LClone: TCacheConfig;
begin
  LOriginal := TCacheConfig.Create;
  try
    LOriginal.Host := '10.0.0.1';
    LOriginal.Port := 6380;
    LClone := LOriginal.Clone;
    try
      Assert.AreEqual('10.0.0.1', LClone.Host);
      Assert.AreEqual(6380, LClone.Port);
      // Garante que são objetos diferentes
      LClone.Host := '192.168.0.1';
      Assert.AreNotEqual(LOriginal.Host, LClone.Host);
    finally
      LClone.Free;
    end;
  finally
    LOriginal.Free;
  end;
end;

procedure TCacheConfigTest.Test_GetFullKey;
var
  LConfig: TCacheConfig;
begin
  LConfig := TCacheConfig.Create;
  try
    Assert.AreEqual('app:cache:mykey', LConfig.GetFullKey('mykey'));
  finally
    LConfig.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TCacheConfigTest);

end.
