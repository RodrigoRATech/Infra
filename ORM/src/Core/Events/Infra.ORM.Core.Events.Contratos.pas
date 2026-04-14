unit Infra.ORM.Core.Events.Contratos;

{
  Responsabilidade:
    Contratos, enumerações e tipos de dados do sistema de eventos.
    Referenciada por TODAS as units do módulo Events.
    Declara: TOperacaoOrm, TEventoOrmOperacao, IOrmSink,
             IOrmInterceptador, IOrmDespachante,
             IOrmProvedorIdentidade, IOrmProvedorTenant.
}

interface

uses
  System.SysUtils,
  System.Rtti,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts;

type

  // ---------------------------------------------------------------------------
  // Enumeração das operações monitoradas pelo ORM
  // ---------------------------------------------------------------------------
  TOperacaoOrm = (
    ooInserir,    // INSERT
    ooAtualizar,  // UPDATE
    ooDeletar,    // DELETE
    ooBuscar,     // SELECT por ID
    ooListar,     // SELECT lista
    ooCommit,     // COMMIT de transação
    ooRollback    // ROLLBACK de transação
  );

  // ---------------------------------------------------------------------------
  // Valores de chave primária serializados para auditoria
  // ---------------------------------------------------------------------------
  TValoresChave = TArray<TValue>;

  // ---------------------------------------------------------------------------
  // Snapshot de dados para auditoria (antes/depois)
  // ---------------------------------------------------------------------------
  TDadosAuditoria = TArray<TObject>; // ponteiro opaco — TListaEntradaAuditoria

  // ---------------------------------------------------------------------------
  // Evento de operação ORM — imutável, passado por valor para os sinks
  // ---------------------------------------------------------------------------
  TEventoOrmOperacao = record
    /// Identificador único do evento (UUID)
    IdEvento: string;

    /// Momento exato da ocorrência (UTC)
    OcorridoEm: TDateTime;

    /// Tipo de operação executada
    Operacao: TOperacaoOrm;

    /// Nome da classe da entidade (ex: 'TCliente')
    NomeEntidade: string;

    /// Valores da chave primária da entidade
    ValoresChave: TValoresChave;

    /// Referência à entidade (pode ser nil após delete)
    Entidade: TObject;

    /// Snapshot anterior ao UPDATE/DELETE (para auditoria)
    DadosAnteriores: Pointer;

    /// Snapshot posterior ao INSERT/UPDATE (para auditoria)
    DadosPosteriores: Pointer;

    /// Indica se a operação foi bem-sucedida
    Sucesso: Boolean;

    /// Mensagem de erro em caso de falha
    MensagemErro: string;

    /// Identidade do usuário que executou a operação
    IdentidadeContexto: string;

    /// Duração da operação em milissegundos
    DuracaoMs: Integer;

    /// Cria um evento de sucesso
    class function CriarSucesso(
      AOperacao: TOperacaoOrm;
      const ANomeEntidade: string;
      AEntidade: TObject;
      const AValoresChave: TValoresChave;
      const AIdentidade: string;
      ADuracaoMs: Integer): TEventoOrmOperacao; static;

    /// Cria um evento de falha
    class function CriarFalha(
      AOperacao: TOperacaoOrm;
      const ANomeEntidade: string;
      const AMensagemErro: string;
      const AIdentidade: string): TEventoOrmOperacao; static;
  end;

  // ---------------------------------------------------------------------------
  // Contrato de sink — observador de eventos ORM
  // ---------------------------------------------------------------------------
  IOrmSink = interface
    ['{11111111-AAAA-0000-0001-000000000001}']

    /// Nome identificador do sink (para log e diagnóstico)
    function Nome: string;

    /// Processa um evento ORM — nunca deve propagar exceção
    procedure Processar(const AEvento: TEventoOrmOperacao);
  end;

  // ---------------------------------------------------------------------------
  // Contrato de interceptador — pré e pós operação
  // ---------------------------------------------------------------------------
  IOrmInterceptador = interface
    ['{22222222-BBBB-0000-0001-000000000002}']

    /// Nome identificador do interceptador
    function Nome: string;

    /// Chamado ANTES da operação — pode lançar exceção para cancelar
    procedure Antes(
      AOperacao: TOperacaoOrm;
      AMetadado: IOrmMetadadoEntidade;
      AEntidade: TObject);

    /// Chamado DEPOIS da operação — falha é logada, não propaga
    procedure Depois(
      AOperacao: TOperacaoOrm;
      AMetadado: IOrmMetadadoEntidade;
      AEntidade: TObject;
      ASucesso: Boolean);
  end;

  // ---------------------------------------------------------------------------
  // Contrato do despachante central de eventos
  // ---------------------------------------------------------------------------
  IOrmDespachante = interface
    ['{33333333-CCCC-0000-0001-000000000003}']

    /// Despacha evento para todos os sinks registrados
    procedure Despachar(const AEvento: TEventoOrmOperacao);
  end;

  // ---------------------------------------------------------------------------
  // Provedor de identidade — quem está executando a operação
  // ---------------------------------------------------------------------------
  IOrmProvedorIdentidade = interface
    ['{44444444-DDDD-0000-0001-000000000004}']

    /// Retorna o identificador do usuário/serviço corrente
    /// Ex: 'rodrigo@empresa.com', 'servico-api', 'batch-nfe'
    function ObterIdentidade: string;
  end;

  // ---------------------------------------------------------------------------
  // Provedor de tenant — isolamento multi-tenant
  // ---------------------------------------------------------------------------
  IOrmProvedorTenant = interface
    ['{55555555-EEEE-0000-0001-000000000005}']

    /// Retorna o identificador do tenant corrente
    /// Ex: 'empresa-a', 'filial-sp-01', 'tenant-0042'
    function ObterTenantId: string;
  end;

implementation

{ TEventoOrmOperacao }

class function TEventoOrmOperacao.CriarSucesso(
  AOperacao: TOperacaoOrm;
  const ANomeEntidade: string;
  AEntidade: TObject;
  const AValoresChave: TValoresChave;
  const AIdentidade: string;
  ADuracaoMs: Integer): TEventoOrmOperacao;
begin
  Result.IdEvento           := TGuid.NewGuid.ToString;
  Result.OcorridoEm         := Now;
  Result.Operacao           := AOperacao;
  Result.NomeEntidade       := ANomeEntidade;
  Result.Entidade           := AEntidade;
  Result.ValoresChave       := AValoresChave;
  Result.DadosAnteriores    := nil;
  Result.DadosPosteriores   := nil;
  Result.Sucesso            := True;
  Result.MensagemErro       := '';
  Result.IdentidadeContexto := AIdentidade;
  Result.DuracaoMs          := ADuracaoMs;
end;

class function TEventoOrmOperacao.CriarFalha(
  AOperacao: TOperacaoOrm;
  const ANomeEntidade: string;
  const AMensagemErro: string;
  const AIdentidade: string): TEventoOrmOperacao;
begin
  Result.IdEvento           := TGuid.NewGuid.ToString;
  Result.OcorridoEm         := Now;
  Result.Operacao           := AOperacao;
  Result.NomeEntidade       := ANomeEntidade;
  Result.Entidade           := nil;
  Result.ValoresChave       := nil;
  Result.DadosAnteriores    := nil;
  Result.DadosPosteriores   := nil;
  Result.Sucesso            := False;
  Result.MensagemErro       := AMensagemErro;
  Result.IdentidadeContexto := AIdentidade;
  Result.DuracaoMs          := 0;
end;

end.
