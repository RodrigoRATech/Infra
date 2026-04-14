unit Exemplo05.MultiTenant;

{
  Exemplo 05 — Multi-Tenant
  Demonstra: isolamento de dados por tenant via [TenantId],
  provedor de identidade configurável e interceptador automático.
  Cada sessão respeita o tenant configurado — sem necessidade
  de filtros manuais em cada consulta.
}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Mapping.Atributos,
  Infra.ORM.Core.Session.Fabrica,
  Infra.ORM.Core.Events.Despachante,
  Infra.ORM.Core.Events.Interceptador.Auditoria;

type

  // ---------------------------------------------------------------------------
  // Provedor de tenant baseado em contexto de execução
  // ---------------------------------------------------------------------------
  TContextoTenant = class
  strict private
    class var FTenantAtual: string;
  public
    class procedure DefinirTenant(const ATenantId: string);
    class function TenantAtual: string;
  end;

  TProvedorTenantContexto = class(TInterfacedObject, IOrmProvedorTenant)
  public
    function ObterTenantId: string;
  end;

  // Provedor de identidade baseado em contexto de execução
  TContextoIdentidade = class
  strict private
    class var FIdentidadeAtual: string;
  public
    class procedure DefinirIdentidade(const AIdentidade: string);
    class function IdentidadeAtual: string;
  end;

  TProvedorIdentidadeContexto = class(TInterfacedObject,
    IOrmProvedorIdentidade)
  public
    function ObterIdentidade: string;
  end;

  // ---------------------------------------------------------------------------
  // Entidade multi-tenant
  // ---------------------------------------------------------------------------
  [Tabela('MT_PROJETOS')]
  TProjetoMT = class
  private
    FId: Int64;
    FTenantId: string;
    FNome: string;
    FStatus: string;
    FCriadoEm: TDateTime;
    FCriadoPor: string;
  public
    [ChavePrimaria] [AutoIncremento] [Coluna('ID')]
    property Id: Int64 read FId write FId;
    [Coluna('TENANT_ID')] [TenantId] [Obrigatorio] [Tamanho(50)]
    property TenantId: string read FTenantId write FTenantId;
    [Coluna('NOME')] [Obrigatorio] [Tamanho(200)]
    property Nome: string read FNome write FNome;
    [Coluna('STATUS')] [Tamanho(30)]
    property Status: string read FStatus write FStatus;
    [Coluna('CRIADO_EM')] [CriadoEm] [SomenteLeitura]
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
    [Coluna('CRIADO_POR')] [CriadoPor] [Tamanho(100)]
    property CriadoPor: string read FCriadoPor write FCriadoPor;
  end;

  // ---------------------------------------------------------------------------
  // Fábrica de sessão com suporte a tenant
  // ---------------------------------------------------------------------------
  TFabricaSessionMultiTenant = class
  public
    class function Criar(
      AFabricaConexao: IOrmFabricaConexao;
      ADialeto: IOrmDialeto): IOrmFabricaSessao;
  end;

implementation

{ TContextoTenant }

class procedure TContextoTenant.DefinirTenant(const ATenantId: string);
begin
  FTenantAtual := ATenantId;
end;

class function TContextoTenant.TenantAtual: string;
begin
  Result := FTenantAtual;
end;

{ TProvedorTenantContexto }

function TProvedorTenantContexto.ObterTenantId: string;
begin
  Result := TContextoTenant.TenantAtual;

  if Result.Trim.IsEmpty then
    raise Exception.Create(
      'TenantId não definido no contexto. ' +
      'Use TContextoTenant.DefinirTenant() antes de operar.');
end;

{ TContextoIdentidade }

class procedure TContextoIdentidade.DefinirIdentidade(
  const AIdentidade: string);
begin
  FIdentidadeAtual := AIdentidade;
end;

class function TContextoIdentidade.IdentidadeAtual: string;
begin
  Result := FIdentidadeAtual;
end;

{ TProvedorIdentidadeContexto }

function TProvedorIdentidadeContexto.ObterIdentidade: string;
begin
  Result := TContextoIdentidade.IdentidadeAtual;
end;

{ TFabricaSessionMultiTenant }

class function TFabricaSessionMultiTenant.Criar(
  AFabricaConexao: IOrmFabricaConexao;
  ADialeto: IOrmDialeto): IOrmFabricaSessao;
var
  LProvIdentidade: IOrmProvedorIdentidade;
  LProvTenant: IOrmProvedorTenant;
  LDespachante: TDespachante;
begin
  LProvIdentidade := TProvedorIdentidadeContexto.Create;
  LProvTenant     := TProvedorTenantContexto.Create;
  LDespachante    := TDespachante.Create(TLoggerNulo.Create);

  LDespachante.RegistrarInterceptador(
    TInterceptadorAuditoria.Create(
      LProvIdentidade,
      TLoggerNulo.Create,
      LProvTenant));

  Result := TOrmFabricaSessao.Configurar
    .UsarConexao(AFabricaConexao)
    .UsarDialeto(ADialeto)
    .UsarDespachante(LDespachante)
    .UsarProvedorIdentidade(LProvIdentidade)
    .UsarProvedorTenant(LProvTenant)
    .Construir;
end;

end.
