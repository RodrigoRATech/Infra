unit Infra.Auth2FA.Config;

interface

uses
  Infra.Auth2FA.Interfaces;

type
  TTOTPConfig = class(TInterfacedObject, ITOTPConfig)
  strict private
    FDigits: Integer;
    FPeriod: Integer;
    FAlgorithm: TTOTPAlgorithm;
    FToleranceSteps: Integer;
    FIssuer: string;
    FAccountName: string;
  private
    function GetDigits: Integer;
    function GetPeriod: Integer;
    function GetAlgorithm: TTOTPAlgorithm;
    function GetToleranceSteps: Integer;
    function GetIssuer: string;
    function GetAccountName: string;
    procedure SetDigits(const AValue: Integer);
    procedure SetPeriod(const AValue: Integer);
    procedure SetAlgorithm(const AValue: TTOTPAlgorithm);
    procedure SetToleranceSteps(const AValue: Integer);
    procedure SetIssuer(const AValue: string);
    procedure SetAccountName(const AValue: string);
  public
    constructor Create;

    /// <summary>
    ///   Cria configuração padrão compatível com Google Authenticator
    /// </summary>
    class function CreateDefault(const AIssuer, AAccountName: string): ITOTPConfig;

    property Digits: Integer read GetDigits write SetDigits;
    property Period: Integer read GetPeriod write SetPeriod;
    property Algorithm: TTOTPAlgorithm read GetAlgorithm write SetAlgorithm;
    property ToleranceSteps: Integer read GetToleranceSteps write SetToleranceSteps;
    property Issuer: string read GetIssuer write SetIssuer;
    property AccountName: string read GetAccountName write SetAccountName;
  end;

implementation

uses
  System.SysUtils;

{ TTOTPConfig }

constructor TTOTPConfig.Create;
begin
  inherited Create;
  FDigits := 6;           // Google Authenticator padrão
  FPeriod := 30;          // 30 segundos (padrão RFC 6238)
  FAlgorithm := taSHA1;   // SHA-1 (padrão Google Authenticator)
  FToleranceSteps := 1;   // ±1 janela de tolerância (±30s)
  FIssuer := '';
  FAccountName := '';
end;

class function TTOTPConfig.CreateDefault(const AIssuer, AAccountName: string): ITOTPConfig;
var
  LConfig: TTOTPConfig;
begin
  LConfig := TTOTPConfig.Create;
  LConfig.Issuer := AIssuer;
  LConfig.AccountName := AAccountName;
  Result := LConfig;
end;

function TTOTPConfig.GetDigits: Integer;
begin
  Result := FDigits;
end;

function TTOTPConfig.GetPeriod: Integer;
begin
  Result := FPeriod;
end;

function TTOTPConfig.GetAlgorithm: TTOTPAlgorithm;
begin
  Result := FAlgorithm;
end;

function TTOTPConfig.GetToleranceSteps: Integer;
begin
  Result := FToleranceSteps;
end;

function TTOTPConfig.GetIssuer: string;
begin
  Result := FIssuer;
end;

function TTOTPConfig.GetAccountName: string;
begin
  Result := FAccountName;
end;

procedure TTOTPConfig.SetDigits(const AValue: Integer);
begin
  if not (AValue in [6, 7, 8]) then
    raise EArgumentOutOfRangeException.Create('Digits deve ser 6, 7 ou 8');
  FDigits := AValue;
end;

procedure TTOTPConfig.SetPeriod(const AValue: Integer);
begin
  if AValue <= 0 then
    raise EArgumentOutOfRangeException.Create('Period deve ser maior que zero');
  FPeriod := AValue;
end;

procedure TTOTPConfig.SetAlgorithm(const AValue: TTOTPAlgorithm);
begin
  FAlgorithm := AValue;
end;

procedure TTOTPConfig.SetToleranceSteps(const AValue: Integer);
begin
  if AValue < 0 then
    raise EArgumentOutOfRangeException.Create('ToleranceSteps não pode ser negativo');
  FToleranceSteps := AValue;
end;

procedure TTOTPConfig.SetIssuer(const AValue: string);
begin
  FIssuer := AValue;
end;

procedure TTOTPConfig.SetAccountName(const AValue: string);
begin
  FAccountName := AValue;
end;

end.
