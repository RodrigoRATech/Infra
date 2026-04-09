unit Infra.Auth2FA.Service;

interface

uses
  System.SysUtils,
  Infra.Auth2FA.Interfaces,
  Infra.Auth2FA.TOTP.Engine;

type
  /// <summary>
  ///   Serviço de autenticação de dois fatores.
  ///   Orquestra todos os componentes respeitando DIP (Dependency Inversion).
  /// </summary>
  TAuth2FAService = class(TInterfacedObject, IAuth2FAService)
  strict private
    FConfig: ITOTPConfig;
    FEngine: TTOTPEngine;
    FSecretGenerator: ISecretGenerator;
    FQRCodeURIBuilder: IQRCodeURIBuilder;
  public
    constructor Create(
      const AConfig: ITOTPConfig;
      const ASecretGenerator: ISecretGenerator;
      const AHMACStrategy: IHMACStrategy;
      const ABase32Codec: IBase32Codec;
      const AQRCodeURIBuilder: IQRCodeURIBuilder
    );
    destructor Destroy; override;

    /// <summary>
    ///   Gera um novo segredo Base32 (para cadastro do usuário)
    /// </summary>
    function GenerateSecret: string;

    /// <summary>
    ///   Gera o token TOTP atual para um segredo
    /// </summary>
    function GenerateToken(const ASecretBase32: string): string;

    /// <summary>
    ///   Valida o token informado pelo usuário com tolerância de janela
    /// </summary>
    function ValidateToken(const ASecretBase32, AToken: string): TTOTPValidationResult;

    /// <summary>
    ///   Retorna a URI otpauth:// para geração do QR Code
    /// </summary>
    function GetProvisioningURI(const ASecretBase32: string): string;

    /// <summary>
    ///   Segundos restantes na janela de tempo atual
    /// </summary>
    function GetRemainingSeconds: Integer;

    function GetConfig: ITOTPConfig;
    property Config: ITOTPConfig read GetConfig;
  end;

implementation

{ TAuth2FAService }

constructor TAuth2FAService.Create(
  const AConfig: ITOTPConfig;
  const ASecretGenerator: ISecretGenerator;
  const AHMACStrategy: IHMACStrategy;
  const ABase32Codec: IBase32Codec;
  const AQRCodeURIBuilder: IQRCodeURIBuilder);
begin
  inherited Create;

  if not Assigned(AConfig) then
    raise EArgumentNilException.Create('Config não pode ser nulo');
  if not Assigned(ASecretGenerator) then
    raise EArgumentNilException.Create('SecretGenerator não pode ser nulo');
  if not Assigned(AHMACStrategy) then
    raise EArgumentNilException.Create('HMACStrategy não pode ser nulo');
  if not Assigned(ABase32Codec) then
    raise EArgumentNilException.Create('Base32Codec não pode ser nulo');
  if not Assigned(AQRCodeURIBuilder) then
    raise EArgumentNilException.Create('QRCodeURIBuilder não pode ser nulo');

  FConfig := AConfig;
  FSecretGenerator := ASecretGenerator;
  FQRCodeURIBuilder := AQRCodeURIBuilder;

  FEngine := TTOTPEngine.Create(
    AHMACStrategy,
    ABase32Codec,
    AConfig.Digits,
    AConfig.Period
  );
end;

destructor TAuth2FAService.Destroy;
begin
  FEngine.Free;
  inherited;
end;

function TAuth2FAService.GenerateSecret: string;
begin
  Result := FSecretGenerator.GenerateBase32(20); // 160 bits (RFC recomendado)
end;

function TAuth2FAService.GenerateToken(const ASecretBase32: string): string;
begin
  if ASecretBase32.IsEmpty then
    raise EArgumentException.Create('Secret Base32 não pode ser vazio');

  Result := FEngine.GenerateToken(ASecretBase32, TTOTPEngine.GetCurrentUnixTime);
end;

function TAuth2FAService.ValidateToken(
  const ASecretBase32, AToken: string): TTOTPValidationResult;
var
  LCurrentTime: Int64;
  LStep: Integer;
  LGeneratedToken: string;
begin
  if ASecretBase32.IsEmpty then
    raise EArgumentException.Create('Secret Base32 não pode ser vazio');
  if AToken.IsEmpty then
    raise EArgumentException.Create('Token não pode ser vazio');

  LCurrentTime := TTOTPEngine.GetCurrentUnixTime;

  // Verifica o token na janela de tolerância (passado, presente, futuro)
  for LStep := -FConfig.ToleranceSteps to FConfig.ToleranceSteps do
  begin
    LGeneratedToken := FEngine.GenerateToken(
      ASecretBase32,
      LCurrentTime + (LStep * FConfig.Period)
    );

    if LGeneratedToken = AToken then
      Exit(TTOTPValidationResult.Success(LStep));
  end;

  Result := TTOTPValidationResult.Failure;
end;

function TAuth2FAService.GetProvisioningURI(const ASecretBase32: string): string;
begin
  Result := FQRCodeURIBuilder.Build(ASecretBase32, FConfig);
end;

function TAuth2FAService.GetRemainingSeconds: Integer;
begin
  Result := FEngine.GetRemainingSeconds;
end;

function TAuth2FAService.GetConfig: ITOTPConfig;
begin
  Result := FConfig;
end;

end.
