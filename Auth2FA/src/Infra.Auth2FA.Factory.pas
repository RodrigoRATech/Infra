unit Infra.Auth2FA.Factory;

interface

uses
  Infra.Auth2FA.Interfaces;

type
  /// <summary>
  ///   Factory para criação simplificada do serviço 2FA.
  ///   Encapsula a montagem de todas as dependências.
  /// </summary>
  TAuth2FAFactory = class
  public
    /// <summary>
    ///   Cria o serviço com configuração padrão do Google Authenticator
    /// </summary>
    class function CreateDefault(
      const AIssuer: string;
      const AAccountName: string
    ): IAuth2FAService;

    /// <summary>
    ///   Cria o serviço com configuração customizada
    /// </summary>
    class function CreateCustom(
      const AConfig: ITOTPConfig
    ): IAuth2FAService;
  end;

implementation

uses
  Infra.Auth2FA.Config,
  Infra.Auth2FA.Base32Codec,
  Infra.Auth2FA.HMAC.Strategy,
  Infra.Auth2FA.SecretGenerator,
  Infra.Auth2FA.QRCodeURIBuilder,
  Infra.Auth2FA.Service;

{ TAuth2FAFactory }

class function TAuth2FAFactory.CreateDefault(
  const AIssuer, AAccountName: string): IAuth2FAService;
var
  LConfig: ITOTPConfig;
begin
  LConfig := TTOTPConfig.CreateDefault(AIssuer, AAccountName);
  Result := CreateCustom(LConfig);
end;

class function TAuth2FAFactory.CreateCustom(
  const AConfig: ITOTPConfig): IAuth2FAService;
var
  LBase32Codec: IBase32Codec;
  LHMACStrategy: IHMACStrategy;
  LSecretGenerator: ISecretGenerator;
  LURIBuilder: IQRCodeURIBuilder;
begin
  LBase32Codec := TBase32Codec.Create;
  LHMACStrategy := THMACStrategyFactory.CreateStrategy(AConfig.Algorithm);
  LSecretGenerator := TSecretGenerator.Create(LBase32Codec);
  LURIBuilder := TQRCodeURIBuilder.Create;

  Result := TAuth2FAService.Create(
    AConfig,
    LSecretGenerator,
    LHMACStrategy,
    LBase32Codec,
    LURIBuilder
  );
end;

end.
