unit Infra.ORM.Tests.Integracao.Base;

{
  Responsabilidade:
    Infraestrutura base para testes de integração.
    Gerencia setup/teardown de banco, fábrica e sessão.
    Subclasses especializam para Firebird ou MySQL.
}

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Mapping.Atributos,
  Infra.ORM.Core.Session.Fabrica,
  Infra.ORM.Core.Metadata.Cache,
  Infra.ORM.FireDAC.Configuracao,
  Infra.ORM.FireDAC.Fabrica;

type

  // ── Entidades de teste de integração ─────────────────────────────────────

  [Tabela('ORM_TEST_CLIENTES')]
  TClienteIntegracao = class
  private
    FId: Int64;
    FNome: string;
    FEmail: string;
    FCriadoEm: TDateTime;
  public
    [ChavePrimaria]
    [AutoIncremento]
    [Coluna('ID')]
    property Id: Int64 read FId write FId;

    [Coluna('NOME')]
    [Obrigatorio]
    [Tamanho(150)]
    property Nome: string read FNome write FNome;

    [Coluna('EMAIL')]
    [Tamanho(200)]
    property Email: string read FEmail write FEmail;

    [Coluna('CRIADO_EM')]
    [CriadoEm]
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
  end;

  [Tabela('ORM_TEST_PEDIDOS')]
  TPedidoIntegracao = class
  private
    FId: string;
    FClienteId: Int64;
    FTotal: Double;
  public
    [ChavePrimaria]
    [UuidV7Generator]
    [Coluna('ID')]
    property Id: string read FId write FId;

    [Coluna('CLIENTE_ID')]
    [Obrigatorio]
    property ClienteId: Int64 read FClienteId write FClienteId;

    [Coluna('TOTAL')]
    [Precisao(18, 2)]
    property Total: Double read FTotal write FTotal;
  end;

  // ── Classe base de fixture ────────────────────────────────────────────────

  TFixtureIntegracaoBase = class abstract
  strict protected
    FFabricaSessao: IOrmFabricaSessao;
    FSessao: IOrmSessao;

    // Subclasses fornecem a configuração específica do banco
    function CriarConfiguracao: TConfiguracaoConexao; virtual; abstract;
    function CriarDialeto: IOrmDialeto; virtual; abstract;

    // DDL específico por banco — subclasses implementam
    procedure CriarEstruturaBanco; virtual; abstract;
    procedure RemoverEstruturaBanco; virtual; abstract;

  public
    [Setup]
    procedure Configurar;

    [TearDown]
    procedure Limpar;
  end;

implementation

uses
  Infra.ORM.Core.Session.Sessao;

{ TFixtureIntegracaoBase }

procedure TFixtureIntegracaoBase.Configurar;
var
  LConfig: TConfiguracaoConexao;
  LFabricaConexao: IOrmFabricaConexao;
  LDialeto: IOrmDialeto;
begin
  TCacheMetadados.Instancia.InvalidarTudo;

  LConfig        := CriarConfiguracao;
  LFabricaConexao := TFabricaConexaoFireDAC.Create(LConfig);
  LDialeto       := CriarDialeto;

  FFabricaSessao := TOrmFabricaSessao.Configurar
    .UsarConexao(LFabricaConexao)
    .UsarDialeto(LDialeto)
    .Construir;

  FSessao := FFabricaSessao.CriarSessao;

  CriarEstruturaBanco;
end;

procedure TFixtureIntegracaoBase.Limpar;
begin
  try
    RemoverEstruturaBanco;
  except
    // Silencioso — limpeza best-effort
  end;
  FSessao        := nil;
  FFabricaSessao := nil;
end;

end.
