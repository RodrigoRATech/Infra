unit Infra.ORM.FireDAC.Configuracao;

{
  Responsabilidade:
    Configuração tipada para conexões FireDAC.
    Suporta Firebird e MySQL/MariaDB com opções específicas por banco.
    Imutável após construção via builder.
}

interface

uses
  System.SysUtils,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Exceptions;

type

  // ---------------------------------------------------------------------------
  // Configuração base de conexão
  // ---------------------------------------------------------------------------
  TConfiguracaoConexao = class
  strict private
    FTipoBanco: TTipoBancoDados;
    FServidor: string;
    FPorta: Integer;
    FBancoDados: string;
    FUsuario: string;
    FSenha: string;
    FCharset: string;
    FTimeoutConexao: Integer;
    FTimeoutComando: Integer;
    FUsarPool: Boolean;
    FTamanhoPool: Integer;
    FModoLog: Boolean;

  public
    constructor Create(ATipoBanco: TTipoBancoDados);

    property TipoBanco: TTipoBancoDados read FTipoBanco;
    property Servidor: string read FServidor write FServidor;
    property Porta: Integer read FPorta write FPorta;
    property BancoDados: string read FBancoDados write FBancoDados;
    property Usuario: string read FUsuario write FUsuario;
    property Senha: string read FSenha write FSenha;
    property Charset: string read FCharset write FCharset;
    property TimeoutConexao: Integer
      read FTimeoutConexao write FTimeoutConexao;
    property TimeoutComando: Integer
      read FTimeoutComando write FTimeoutComando;
    property UsarPool: Boolean read FUsarPool write FUsarPool;
    property TamanhoPool: Integer read FTamanhoPool write FTamanhoPool;
    property ModoLog: Boolean read FModoLog write FModoLog;

    procedure Validar;
  end;

  // ---------------------------------------------------------------------------
  // Builder fluente de configuração
  // ---------------------------------------------------------------------------
  TConfiguracaoConexaoBuilder = class
  strict private
    FConfig: TConfiguracaoConexao;

  public
    constructor Create(ATipoBanco: TTipoBancoDados);
    destructor Destroy; override;

    function Servidor(const AValor: string): TConfiguracaoConexaoBuilder;
    function Porta(AValor: Integer): TConfiguracaoConexaoBuilder;
    function BancoDados(const AValor: string): TConfiguracaoConexaoBuilder;
    function Usuario(const AValor: string): TConfiguracaoConexaoBuilder;
    function Senha(const AValor: string): TConfiguracaoConexaoBuilder;
    function Charset(const AValor: string): TConfiguracaoConexaoBuilder;
    function TimeoutConexao(AValor: Integer): TConfiguracaoConexaoBuilder;
    function TimeoutComando(AValor: Integer): TConfiguracaoConexaoBuilder;
    function UsarPool(ATamanho: Integer = 10): TConfiguracaoConexaoBuilder;
    function ModoLog(AAtivo: Boolean = True): TConfiguracaoConexaoBuilder;

    // Constrói e transfere ownership ao chamador
    function Construir: TConfiguracaoConexao;
  end;

  // ---------------------------------------------------------------------------
  // Helpers de fábrica por banco
  // ---------------------------------------------------------------------------
  TConfiguracaoFirebird = class
  public
    class function Criar: TConfiguracaoConexaoBuilder;
  end;

  TConfiguracaoMySQL = class
  public
    class function Criar: TConfiguracaoConexaoBuilder;
  end;

  TConfiguracaoMariaDB = class
  public
    class function Criar: TConfiguracaoConexaoBuilder;
  end;

implementation

{ TConfiguracaoConexao }

constructor TConfiguracaoConexao.Create(ATipoBanco: TTipoBancoDados);
begin
  inherited Create;
  FTipoBanco      := ATipoBanco;
  FServidor       := 'localhost';
  FPorta          := 0; // 0 = usar padrão do banco
  FCharset        := 'UTF8';
  FTimeoutConexao := 30;
  FTimeoutComando := 60;
  FUsarPool       := False;
  FTamanhoPool    := 10;
  FModoLog        := False;
end;

procedure TConfiguracaoConexao.Validar;
begin
  if FBancoDados.Trim.IsEmpty then
    raise EOrmConfiguracaoExcecao.Create(
      'BancoDados é obrigatório na configuração de conexão.');

  if FUsuario.Trim.IsEmpty then
    raise EOrmConfiguracaoExcecao.Create(
      'Usuário é obrigatório na configuração de conexão.');

  case FTipoBanco of
    tbFirebird:
      begin
        if FServidor.Trim.IsEmpty then
          raise EOrmConfiguracaoExcecao.Create(
            'Servidor é obrigatório para conexão Firebird.');
        if FPorta = 0 then
          FPorta := 3050; // porta padrão Firebird
      end;

    tbMySQL, tbMariaDB:
      begin
        if FServidor.Trim.IsEmpty then
          raise EOrmConfiguracaoExcecao.Create(
            'Servidor é obrigatório para conexão MySQL/MariaDB.');
        if FPorta = 0 then
          FPorta := 3306; // porta padrão MySQL/MariaDB
      end;
  else
    raise EOrmConfiguracaoExcecao.Create(
      Format('Banco de dados não suportado neste módulo: %d',
        [Ord(FTipoBanco)]));
  end;
end;

{ TConfiguracaoConexaoBuilder }

constructor TConfiguracaoConexaoBuilder.Create(ATipoBanco: TTipoBancoDados);
begin
  inherited Create;
  FConfig := TConfiguracaoConexao.Create(ATipoBanco);
end;

destructor TConfiguracaoConexaoBuilder.Destroy;
begin
  // Se Construir não foi chamado, libera a config
  FConfig.Free;
  inherited Destroy;
end;

function TConfiguracaoConexaoBuilder.Servidor(
  const AValor: string): TConfiguracaoConexaoBuilder;
begin
  FConfig.Servidor := AValor;
  Result := Self;
end;

function TConfiguracaoConexaoBuilder.Porta(
  AValor: Integer): TConfiguracaoConexaoBuilder;
begin
  FConfig.Porta := AValor;
  Result := Self;
end;

function TConfiguracaoConexaoBuilder.BancoDados(
  const AValor: string): TConfiguracaoConexaoBuilder;
begin
  FConfig.BancoDados := AValor;
  Result := Self;
end;

function TConfiguracaoConexaoBuilder.Usuario(
  const AValor: string): TConfiguracaoConexaoBuilder;
begin
  FConfig.Usuario := AValor;
  Result := Self;
end;

function TConfiguracaoConexaoBuilder.Senha(
  const AValor: string): TConfiguracaoConexaoBuilder;
begin
  FConfig.Senha := AValor;
  Result := Self;
end;

function TConfiguracaoConexaoBuilder.Charset(
  const AValor: string): TConfiguracaoConexaoBuilder;
begin
  FConfig.Charset := AValor;
  Result := Self;
end;

function TConfiguracaoConexaoBuilder.TimeoutConexao(
  AValor: Integer): TConfiguracaoConexaoBuilder;
begin
  FConfig.TimeoutConexao := AValor;
  Result := Self;
end;

function TConfiguracaoConexaoBuilder.TimeoutComando(
  AValor: Integer): TConfiguracaoConexaoBuilder;
begin
  FConfig.TimeoutComando := AValor;
  Result := Self;
end;

function TConfiguracaoConexaoBuilder.UsarPool(
  ATamanho: Integer): TConfiguracaoConexaoBuilder;
begin
  FConfig.UsarPool    := True;
  FConfig.TamanhoPool := ATamanho;
  Result := Self;
end;

function TConfiguracaoConexaoBuilder.ModoLog(
  AAtivo: Boolean): TConfiguracaoConexaoBuilder;
begin
  FConfig.ModoLog := AAtivo;
  Result := Self;
end;

function TConfiguracaoConexaoBuilder.Construir: TConfiguracaoConexao;
begin
  FConfig.Validar;
  Result  := FConfig;
  FConfig := nil; // transfere ownership
end;

{ TConfiguracaoFirebird }

class function TConfiguracaoFirebird.Criar: TConfiguracaoConexaoBuilder;
begin
  Result := TConfiguracaoConexaoBuilder.Create(TTipoBancoDados.tbFirebird);
end;

{ TConfiguracaoMySQL }

class function TConfiguracaoMySQL.Criar: TConfiguracaoConexaoBuilder;
begin
  Result := TConfiguracaoConexaoBuilder.Create(TTipoBancoDados.tbMySQL);
end;

{ TConfiguracaoMariaDB }

class function TConfiguracaoMariaDB.Criar: TConfiguracaoConexaoBuilder;
begin
  Result := TConfiguracaoConexaoBuilder.Create(TTipoBancoDados.tbMariaDB);
end;

end.
