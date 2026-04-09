unit Auth2FA.Example;

interface

procedure DemoSetup2FA;
procedure DemoValidate2FA;

implementation

uses
  System.SysUtils,
  Vcl.Dialogs,
  Auth2FA.Interfaces,
  Auth2FA.Factory;

procedure DemoSetup2FA;
var
  LAuthService: ITwoFactorAuthService;
  LSecret: string;
  LURI: string;
begin
  // 1. Criar o serviço com configuração padrão (Google Authenticator)
  LAuthService := TTwoFactorAuthFactory.CreateDefault(
    'MinhaSuaEmpresa',         // Issuer (nome da empresa/app)
    'rodrigo@empresa.com.br'   // Conta do usuário
  );

  // 2. Gerar um novo segredo para o usuário
  LSecret := LAuthService.GenerateSecret;
  ShowMessage('Segredo gerado (salvar no banco): ' + LSecret);

  // 3. Gerar a URI para o QR Code
  LURI := LAuthService.GetProvisioningURI(LSecret);
  ShowMessage('URI para QR Code: ' + LURI);
  // Exemplo de saída:
  // otpauth://totp/MinhaSuaEmpresa:rodrigo%40empresa.com.br?secret=JBSWY3DPEHPK3PXP&issuer=MinhaSuaEmpresa&algorithm=SHA1&digits=6&period=30

  // 4. Exibir esta URI como QR Code usando sua lib favorita:
  //    - DelphiZXingQRCode
  //    - TMS Software
  //    - Skia4Delphi
end;

procedure DemoValidate2FA;
var
  LAuthService: ITwoFactorAuthService;
  LSecretFromDB: string;
  LTokenDoUsuario: string;
  LResult: TTOTPValidationResult;
begin
  // Segredo recuperado do banco de dados do usuário
  LSecretFromDB := 'JBSWY3DPEHPK3PXP';

  // Token digitado pelo usuário (vindo do Google Authenticator)
  LTokenDoUsuario := '482913';

  // Criar o serviço
  LAuthService := TTwoFactorAuthFactory.CreateDefault(
    'MinhaSuaEmpresa',
    'rodrigo@empresa.com.br'
  );

  // Validar
  LResult := LAuthService.ValidateToken(LSecretFromDB, LTokenDoUsuario);

  if LResult.IsValid then
  begin
    ShowMessage('✅ Autenticação 2FA aprovada!');

    if LResult.MatchedStep <> 0 then
      ShowMessage(Format('⚠ Alerta: Token válido com desvio de %d janela(s). ' +
        'Verifique sincronização de relógio.', [LResult.MatchedStep]));
  end
  else
    ShowMessage('❌ Token inválido. Acesso negado.');

  // Info: segundos restantes até o próximo token
  ShowMessage(Format('Segundos restantes: %d', [LAuthService.GetRemainingSeconds]));
end;

end.
