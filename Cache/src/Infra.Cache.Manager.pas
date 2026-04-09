unit Infra.Cache.Manager;

interface

uses
  System.SysUtils, System.JSON,
  Infra.Cache.Interfaces,
  Infra.Cache.Serializer;

type
  /// <summary>
  ///   Gerenciador de cache de alto nível.
  ///   Implementa ICacheManager (string e JSON) e expõe métodos genéricos
  ///   (GetObject<T>, PutObject<T>, GetOrAdd<T>) como membros da classe.
  /// </summary>
  TCacheManager = class(TInterfacedObject, ICacheManager)
  private
    FStrategy: ICacheStrategy;
    FSerializer: ICacheSerializer;
    FConcreteSerializer: TCacheSerializer;
  public
    constructor Create(AStrategy: ICacheStrategy; ASerializer: TCacheSerializer);

    { ICacheManager }
    function GetString(const AKey: string; out AValue: string): Boolean;
    procedure PutString(const AKey, AValue: string; ATTLSeconds: Integer = 0);

    function GetJSON(const AKey: string; out AValue: TJSONValue): Boolean;
    procedure PutJSON(const AKey: string; AValue: TJSONValue; ATTLSeconds: Integer = 0);

    function Remove(const AKey: string): Boolean;
    function Exists(const AKey: string): Boolean;
    procedure Clear;
    function GetStats: TCacheStats;
    procedure SetOnEvent(AProc: TCacheEventProc);

    { Métodos genéricos — acessíveis via TCacheManager (não via ICacheManager) }
    function GetObject<T: class, constructor>(const AKey: string; out AValue: T): Boolean;
    procedure PutObject<T: class>(const AKey: string; AValue: T; ATTLSeconds: Integer = 0);
    function GetOrAdd<T: class, constructor>(const AKey: string;
      AFactory: TFunc<T>; ATTLSeconds: Integer = 0): T;
  end;

implementation

{ TCacheManager }

constructor TCacheManager.Create(AStrategy: ICacheStrategy; ASerializer: TCacheSerializer);
begin
  inherited Create;
  if not Assigned(AStrategy) then
    raise EArgumentNilException.Create('ICacheStrategy não pode ser nil.');
  if not Assigned(ASerializer) then
    raise EArgumentNilException.Create('TCacheSerializer não pode ser nil.');
  FStrategy := AStrategy;
  FConcreteSerializer := ASerializer;
  // A interface mantém a referência contada, evitando leak
  FSerializer := ASerializer;
end;

function TCacheManager.GetString(const AKey: string; out AValue: string): Boolean;
begin
  Result := FStrategy.Get(AKey, AValue);
end;

procedure TCacheManager.PutString(const AKey, AValue: string; ATTLSeconds: Integer);
begin
  FStrategy.Put(AKey, AValue, ATTLSeconds);
end;

function TCacheManager.GetObject<T>(const AKey: string; out AValue: T): Boolean;
var
  LData: string;
begin
  Result := False;
  AValue := nil;
  if FStrategy.Get(AKey, LData) then
  begin
    try
      AValue := FConcreteSerializer.Deserialize<T>(LData);
      Result := Assigned(AValue);
    except
      Result := False;
      AValue := nil;
    end;
  end;
end;

procedure TCacheManager.PutObject<T>(const AKey: string; AValue: T; ATTLSeconds: Integer);
var
  LData: string;
begin
  LData := FConcreteSerializer.Serialize<T>(AValue);
  FStrategy.Put(AKey, LData, ATTLSeconds);
end;

function TCacheManager.GetJSON(const AKey: string; out AValue: TJSONValue): Boolean;
var
  LData: string;
begin
  Result := False;
  AValue := nil;
  if FStrategy.Get(AKey, LData) then
  begin
    try
      AValue := FSerializer.DeserializeJSON(LData);
      Result := Assigned(AValue);
    except
      Result := False;
      AValue := nil;
    end;
  end;
end;

procedure TCacheManager.PutJSON(const AKey: string; AValue: TJSONValue; ATTLSeconds: Integer);
var
  LData: string;
begin
  LData := FSerializer.SerializeJSON(AValue);
  FStrategy.Put(AKey, LData, ATTLSeconds);
end;

function TCacheManager.GetOrAdd<T>(const AKey: string; AFactory: TFunc<T>;
  ATTLSeconds: Integer): T;
var
  LData: string;
begin
  if FStrategy.Get(AKey, LData) then
  begin
    try
      Result := FConcreteSerializer.Deserialize<T>(LData);
      if Assigned(Result) then
        Exit;
    except
      // fallthrough para factory
    end;
  end;

  Result := AFactory();
  if Assigned(Result) then
  begin
    LData := FConcreteSerializer.Serialize<T>(Result);
    FStrategy.Put(AKey, LData, ATTLSeconds);
  end;
end;

function TCacheManager.Remove(const AKey: string): Boolean;
begin
  Result := FStrategy.Remove(AKey);
end;

function TCacheManager.Exists(const AKey: string): Boolean;
begin
  Result := FStrategy.Exists(AKey);
end;

procedure TCacheManager.Clear;
begin
  FStrategy.Clear;
end;

function TCacheManager.GetStats: TCacheStats;
begin
  Result := FStrategy.GetStats;
end;

procedure TCacheManager.SetOnEvent(AProc: TCacheEventProc);
begin
  FStrategy.SetOnEvent(AProc);
end;

end.
