unit Infra.Auth2FA.Interfaces;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Algoritmos de hash suportados pelo TOTP/HOTP (RFC 6238)
  /// </summary>
  TTOTPAlgorithm = (taSHA1, taSHA256, taSHA512);

  /// <summary>
  ///   Resultado da validação do token
  /// </summary>
  TTOTPValidationResult = record
    IsValid: Boolean;
    MatchedStep: Integer; // Janela de tolerância onde o match ocorreu
    class function Success(const AStep: Integer): TTOTPValidationResult; static;
    class function Failure: TTOTPValidationResult; static;
  end;

  /// <summary>
  ///   Configurações do TOTP
  /// </summary>
  ITOTPConfig = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
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

    property Digits: Integer read GetDigits write SetDigits;
    property Period: Integer read GetPeriod write SetPeriod;
    property Algorithm: TTOTPAlgorithm read GetAlgorithm write SetAlgorithm;
    property ToleranceSteps: Integer read GetToleranceSteps write SetToleranceSteps;
    property Issuer: string read GetIssuer write SetIssuer;
    property AccountName: string read GetAccountName write SetAccountName;
  end;

  /// <summary>
  ///   Encoder/Decoder Base32 conforme RFC 4648
  /// </summary>
  IBase32Codec = interface
    ['{B2C3D4E5-F6A7-8901-BCDE-F12345678901}']
    function Encode(const AData: TBytes): string;
    function Decode(const AEncoded: string): TBytes;
  end;

  /// <summary>
  ///   Estratégia de cálculo HMAC (Strategy Pattern)
  /// </summary>
  IHMACStrategy = interface
    ['{C3D4E5F6-A7B8-9012-CDEF-123456789012}']
    function ComputeHMAC(const AKey, AMessage: TBytes): TBytes;
    function GetAlgorithmName: string;
    property AlgorithmName: string read GetAlgorithmName;
  end;

  /// <summary>
  ///   Gerador de segredos criptograficamente seguros
  /// </summary>
  ISecretGenerator = interface
    ['{D4E5F6A7-B8C9-0123-DEF0-123456789ABC}']
    function Generate(const ALength: Integer = 20): TBytes;
    function GenerateBase32(const ALength: Integer = 20): string;
  end;

  /// <summary>
  ///   Gerador de URI para QR Code (otpauth://)
  /// </summary>
  IQRCodeURIBuilder = interface
    ['{E5F6A7B8-C9D0-1234-EF01-23456789ABCD}']
    function Build(const ASecret: string; const AConfig: ITOTPConfig): string;
  end;

  /// <summary>
  ///   Serviço principal de autenticação 2FA
  /// </summary>
  IAuth2FAService = interface
    ['{F6A7B8C9-D0E1-2345-F012-3456789ABCDE}']
    function GenerateSecret: string;
    function GenerateToken(const ASecretBase32: string): string;
    function ValidateToken(const ASecretBase32, AToken: string): TTOTPValidationResult;
    function GetProvisioningURI(const ASecretBase32: string): string;
    function GetRemainingSeconds: Integer;
    function GetConfig: ITOTPConfig;
    property Config: ITOTPConfig read GetConfig;
  end;

implementation

{ TTOTPValidationResult }

class function TTOTPValidationResult.Success(const AStep: Integer): TTOTPValidationResult;
begin
  Result.IsValid := True;
  Result.MatchedStep := AStep;
end;

class function TTOTPValidationResult.Failure: TTOTPValidationResult;
begin
  Result.IsValid := False;
  Result.MatchedStep := 0;
end;

end.
