unit Infra.ORM.FireDAC.Conexao;

{
  Responsabilidade:
    Implementação de IOrmConexao sobre TFDConnection do FireDAC.
    Gerencia ciclo de vida da conexão física, criação de comandos
    e controle de transação para uma sessão ORM isolada.
}

interface

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  FireDAC.Stan.Def,
  FireDAC.Stan.Intf,
  FireDAC.Phys.Intf,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions,
  Infra.ORM.FireDAC.Configuracao,
  Infra.ORM.FireDAC.Transacao,
  Infra.ORM.FireDAC.Comando;

type

  TConexaoFireDAC = class(TInterfacedObject, IOrmConexao)
  strict private
    FConexaoFD: TFDConnection;
    FConfig: TConfiguracaoConexao;
    FTipoBanco: TTipoBancoDados;

    procedure ConfigurarFirebird;
    procedure ConfigurarMySQL;
    procedure ConfigurarMariaDB;
    procedure AplicarOpcoesComuns;

  public
    constructor Create(AConfig: TConfiguracaoConexao);
    destructor Destroy; override;

    // IOrmConexao
    procedure Abrir;
    procedure Fechar;
    function EstaAberta: Boolean;
    function CriarComando: IOrmComando;
    function IniciarTransacao: IOrmTransacao;
    function TransacaoAtiva: Boolean;
    function TipoBanco: TTipoBancoDados;
  end;

implementation

{ TConexaoFireDAC }

constructor TConexaoFireDAC.Create(AConfig: TConfiguracaoConexao);
begin
  inherited Create;

  if not Assigned(AConfig) then
    raise EOrmConexaoExcecao.Create(
      'Configuração não pode ser nil na conexão FireDAC.');

  FConfig    := AConfig;
  FTipoBanco := AConfig.TipoBanco;

  FConexaoFD                    := TFDConnection.Create(nil);
  FConexaoFD.LoginPrompt        := False;
  FConexaoFD.ResourceOptions.AutoReconnect := False;

  AplicarOpcoesComuns;

  case FTipoBanco of
    tbFirebird:        ConfigurarFirebird;
    tbMySQL:           ConfigurarMySQL;
    tbMariaDB:         ConfigurarMariaDB;
  else
    raise EOrmConexaoExcecao.Create(
      Format('Banco de dados não suportado pelo módulo FireDAC: %d',
        [Ord(FTipoBanco)]));
  end;
end;

destructor TConexaoFireDAC.Destroy;
begin
  if EstaAberta then
  begin
    try
      FConexaoFD.Close;
    except
      // Silencioso — destructor não deve propagar exceções
    end;
  end;
  FConexaoFD.Free;
  inherited Destroy;
end;

procedure TConexaoFireDAC.AplicarOpcoesComuns;
begin
  FConexaoFD.TxOptions.AutoCommit     := False;
  FConexaoFD.TxOptions.Isolation      := xiReadCommitted;
  FConexaoFD.TxOptions.EnableNested   := False;
end;

procedure TConexaoFireDAC.ConfigurarFirebird;
begin
  FConexaoFD.DriverName := 'FB';

  with FConexaoFD.Params do
  begin
    Clear;
    Add('DriverID=FB');
    Add(Format('Server=%s', [FConfig.Servidor]));
    Add(Format('Port=%d', [FConfig.Porta]));
    Add(Format('Database=%s', [FConfig.BancoDados]));
    Add(Format('User_Name=%s', [FConfig.Usuario]));
    Add(Format('Password=%s', [FConfig.Senha]));
    Add(Format('CharacterSet=%s', [FConfig.Charset]));
    Add('Protocol=TCPIP');

    if FConfig.UsarPool then
    begin
      Add('Pooling=True');
      Add(Format('MaxPoolSize=%d', [FConfig.TamanhoPool]));
    end;
  end;
end;

procedure TConexaoFireDAC.ConfigurarMySQL;
begin
  FConexaoFD.DriverName := 'MySQL';

  with FConexaoFD.Params do
  begin
    Clear;
    Add('DriverID=MySQL');
    Add(Format('Server=%s', [FConfig.Servidor]));
    Add(Format('Port=%d', [FConfig.Porta]));
    Add(Format('Database=%s', [FConfig.BancoDados]));
    Add(Format('User_Name=%s', [FConfig.Usuario]));
    Add(Format('Password=%s', [FConfig.Senha]));
    Add(Format('CharSet=%s', [FConfig.Charset]));

    if FConfig.UsarPool then
    begin
      Add('Pooling=True');
      Add(Format('MaxPoolSize=%d', [FConfig.TamanhoPool]));
    end;
  end;
end;

procedure TConexaoFireDAC.ConfigurarMariaDB;
begin
  // MariaDB usa o mesmo driver MySQL no FireDAC
  ConfigurarMySQL;
end;

procedure TConexaoFireDAC.Abrir;
begin
  if EstaAberta then
    Exit;
  try
    FConexaoFD.Open;
  except
    on E: Exception do
      raise EOrmConexaoExcecao.Create(
        FConfig.BancoDados,
        Format('Falha ao abrir conexão FireDAC (%s): %s',
          [FConfig.Servidor, E.Message]),
        E);
  end;
end;

procedure TConexaoFireDAC.Fechar;
begin
  if not EstaAberta then
    Exit;
  try
    FConexaoFD.Close;
  except
    on E: Exception do
      raise EOrmConexaoExcecao.Create(
        FConfig.BancoDados,
        Format('Falha ao fechar conexão FireDAC: %s', [E.Message]), E);
  end;
end;

function TConexaoFireDAC.EstaAberta: Boolean;
begin
  Result := Assigned(FConexaoFD) and FConexaoFD.Connected;
end;

function TConexaoFireDAC.CriarComando: IOrmComando;
begin
  if not EstaAberta then
    raise EOrmConexaoExcecao.Create(
      'Não é possível criar comando com conexão fechada.');

  Result := TComandoFireDAC.Create(FConexaoFD);
end;

function TConexaoFireDAC.IniciarTransacao: IOrmTransacao;
begin
  if not EstaAberta then
    raise EOrmTransacaoExcecao.Create(
      'Não é possível iniciar transação com conexão fechada.');

  if TransacaoAtiva then
    raise EOrmTransacaoExcecao.Create(
      'Já existe uma transação ativa nesta conexão FireDAC.');

  Result := TTransacaoFireDAC.Create(FConexaoFD);
end;

function TConexaoFireDAC.TransacaoAtiva: Boolean;
begin
  Result := Assigned(FConexaoFD) and FConexaoFD.InTransaction;
end;

function TConexaoFireDAC.TipoBanco: TTipoBancoDados;
begin
  Result := FTipoBanco;
end;

end.
