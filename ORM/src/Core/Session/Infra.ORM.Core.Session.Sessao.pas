unit Infra.ORM.Core.Session.Sessao;

{
  Responsabilidade:
    Implementação principal de IOrmSessao.
    Ponto central de acesso ao ORM pela aplicação.
    Coordena conexão, transação e execução via TExecutorPersistencia.

    REGRA: esta classe NÃO é thread-safe por design.
    Cada thread deve criar sua própria instância via IOrmFabricaSessao.
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Rtti,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions,
  Infra.ORM.Core.Logging.Contrato,
  Infra.ORM.Core.Events.Contratos,
  Infra.ORM.Core.Session.Transacao,
  Infra.ORM.Core.Query.Consulta,
  Infra.ORM.Core.Persistence.Executor,
  
type

  TOrmSessao = class(TInterfacedObject, IOrmSessao)
  strict private
    FConexao: IOrmConexao;
    FDialeto: IOrmDialeto;
    FLogger: IOrmLogger;
    FDespachante: IOrmDespachante;
    FProvedorIdentidade: IOrmProvedorIdentidade;
    FExecutor: TExecutorPersistencia;
    FTransacaoAtiva: IOrmTransacao;
	FExecutorConsulta: TExecutorConsulta;

    procedure VerificarConexaoAberta;

  public
    constructor Create(
      AConexao: IOrmConexao;
      ADialeto: IOrmDialeto;
      ALogger: IOrmLogger;
      ADespachante: IOrmDespachante;
      AProvedorIdentidade: IOrmProvedorIdentidade);

    destructor Destroy; override;

    // IOrmSessao — Transação
    function IniciarTransacao: IOrmTransacao;
    function TransacaoAtiva: Boolean;

    // IOrmSessao — CRUD
    procedure Inserir(AEntidade: TObject);
    procedure Atualizar(AEntidade: TObject);
    procedure Deletar(AEntidade: TObject);
    procedure Salvar(AEntidade: TObject);

    // IOrmSessao — Busca
    function BuscarPorId<T: class, constructor>(
      const AChave: TValoresChave): T; overload;
    function BuscarPorId<T: class, constructor>(
      const AId: TValue): T; overload;

    // IOrmSessao — Listagem
    function Listar<T: class, constructor>: TObjectList<T>;

    // IOrmSessao — Query fluente (implementado na Entrega 6)
    function Consultar<T: class, constructor>: IOrmConsulta<T>;

    // IOrmSessao — SQL direto
    function ExecutarSQL<T: class, constructor>(
      const ASQL: string;
      const AParametros: TArray<TParNomeValor>): TObjectList<T>;

    // IOrmSessao — Acesso interno
    function ObterConexao: IOrmConexao;
    function ObterDialeto: IOrmDialeto;
  end;

implementation

uses
  Infra.ORM.Core.Metadata.Cache;

{ TOrmSessao }

constructor TOrmSessao.Create(
  AConexao: IOrmConexao;
  ADialeto: IOrmDialeto;
  ALogger: IOrmLogger;
  ADespachante: IOrmDespachante;
  AProvedorIdentidade: IOrmProvedorIdentidade);
begin
  inherited Create;

  if not Assigned(AConexao) then
    raise EOrmConexaoExcecao.Create(
      'Conexão não pode ser nil na criação da sessão.');

  if not Assigned(ADialeto) then
    raise EOrmDialetoExcecao.Create(
      'TOrmSessao', 'Dialeto não pode ser nil na criação da sessão.');

  FConexao            := AConexao;
  FDialeto            := ADialeto;
  FLogger             := ALogger ?? TLoggerNulo.Create;
  FDespachante        := ADespachante;
  FProvedorIdentidade := AProvedorIdentidade;
  FTransacaoAtiva     := nil;

  FConexao.Abrir;

  FExecutor := TExecutorPersistencia.Create(
    FConexao,
    FDialeto,
    FLogger,
    FDespachante,
    FProvedorIdentidade);
	
  FExecutorConsulta := TExecutorConsulta.Create(
      FConexao, FDialeto, FLogger);

  FLogger.Debug('Sessão ORM criada e conexão aberta');
end;

destructor TOrmSessao.Destroy;
begin
  // Encerra transação pendente com rollback de segurança
  if Assigned(FTransacaoAtiva) and FTransacaoAtiva.EstaAtiva then
  begin
    FLogger.Aviso(
      'Sessão destruída com transação ativa — executando rollback de segurança');
    try
      FTransacaoAtiva.Rollback;
    except
      on E: Exception do
        FLogger.Erro('Falha no rollback de segurança ao destruir sessão', E);
    end;
  end;

  FTransacaoAtiva := nil;
  FExecutor.Free;
  FExecutorConsulta.Free;

  try
    if FConexao.EstaAberta then
      FConexao.Fechar;
  except
    on E: Exception do
      FLogger.Erro('Falha ao fechar conexão na destruição da sessão', E);
  end;

  FConexao            := nil;
  FDialeto            := nil;
  FLogger             := nil;
  FDespachante        := nil;
  FProvedorIdentidade := nil;

  inherited Destroy;
end;

procedure TOrmSessao.VerificarConexaoAberta;
begin
  if not FConexao.EstaAberta then
    raise EOrmConexaoExcecao.Create(
      'Operação requer conexão aberta. A conexão está fechada.');
end;

function TOrmSessao.IniciarTransacao: IOrmTransacao;
var
  LTransacaoFisica: IOrmTransacao;
  LIdentidade: string;
begin
  VerificarConexaoAberta;

  if Assigned(FTransacaoAtiva) and FTransacaoAtiva.EstaAtiva then
    raise EOrmTransacaoExcecao.Create(
      'Já existe uma transação ativa nesta sessão. ' +
      'Finalize a transação atual antes de iniciar uma nova.');

  LTransacaoFisica := FConexao.IniciarTransacao;

  if Assigned(FProvedorIdentidade) then
    LIdentidade := FProvedorIdentidade.ObterIdentidade
  else
    LIdentidade := '';

  FTransacaoAtiva := TTransacao.Create(
    LTransacaoFisica,
    FLogger,
    FDespachante,
    LIdentidade);

  Result := FTransacaoAtiva;
end;

function TOrmSessao.TransacaoAtiva: Boolean;
begin
  Result := Assigned(FTransacaoAtiva) and FTransacaoAtiva.EstaAtiva;
end;

procedure TOrmSessao.Inserir(AEntidade: TObject);
begin
  VerificarConexaoAberta;
  FExecutor.Inserir(AEntidade);
end;

procedure TOrmSessao.Atualizar(AEntidade: TObject);
begin
  VerificarConexaoAberta;
  FExecutor.Atualizar(AEntidade);
end;

procedure TOrmSessao.Deletar(AEntidade: TObject);
begin
  VerificarConexaoAberta;
  FExecutor.Deletar(AEntidade);
end;

procedure TOrmSessao.Salvar(AEntidade: TObject);
var
  LMetadado: IOrmMetadadoEntidade;
  LChaves: TArray<IOrmMetadadoPropriedade>;
  LChave: IOrmMetadadoPropriedade;
  LValor: TValue;
  LEhNovo: Boolean;
begin
  {
    Estratégia de Salvar:
    - Chave autoincremento: se Id = 0 → Insert, senão → Update
    - Chave GUID/UUID:      se string vazia ou GUID vazio → Insert, senão → Update
    - Chave composta:       não suportado em Salvar — use Inserir ou Atualizar
  }
  VerificarConexaoAberta;
  LMetadado := TCacheMetadados.Instancia.Resolver(AEntidade.ClassType);
  LChaves   := LMetadado.Chaves;

  if Length(LChaves) > 1 then
    raise EOrmPersistenciaExcecao.Create(
      LMetadado.NomeClasse,
      'Salvar',
      'O método Salvar não suporta entidades com chave primária composta. ' +
      'Use Inserir ou Atualizar explicitamente.');

  LChave    := LChaves[0];
  LValor    := LChave.ObterValor(AEntidade);
  LEhNovo   := False;

  if LChave.EhAutoIncremento then
    LEhNovo := LValor.IsEmpty or (LValor.AsInt64 = 0)
  else if LValor.Kind in [tkString, tkUString] then
    LEhNovo := LValor.AsString.Trim.IsEmpty
  else if LValor.IsEmpty then
    LEhNovo := True;

  if LEhNovo then
    FExecutor.Inserir(AEntidade)
  else
    FExecutor.Atualizar(AEntidade);
end;

function TOrmSessao.BuscarPorId<T>(
  const AChave: TValoresChave): T;
begin
  VerificarConexaoAberta;
  Result := FExecutor.BuscarPorId<T>(AChave);
end;

function TOrmSessao.BuscarPorId<T>(const AId: TValue): T;
begin
  // Conveniência para chave simples
  Result := BuscarPorId<T>(TValoresChave.Create(AId));
end;

function TOrmSessao.Listar<T>: TObjectList<T>;
var
  LMetadado: IOrmMetadadoEntidade;
  LOrdenacaoVazia: TConstrutorOrdenacao;
  LPaginacaoSem: TPaginacao;
begin
  VerificarConexaoAberta;

  LMetadado      := TCacheMetadados.Instancia.Resolver(T);
  LOrdenacaoVazia := TConstrutorOrdenacao.Novo;
  LPaginacaoSem  := TPaginacao.Sem;

  // Reutiliza o executor de consultas — sem filtros, sem paginação
  Result := FExecutorConsulta.Listar<T>(
    LMetadado,
    nil,   // AFiltros — vazio
    nil,   // AGrupos — vazio
    LOrdenacaoVazia,
    LPaginacaoSem);
end;

function TOrmSessao.Consultar<T>: IOrmConsulta<T>;
var
  LMetadado: IOrmMetadadoEntidade;
begin
  VerificarConexaoAberta;

  LMetadado := TCacheMetadados.Instancia.Resolver(T);

  Result := TConsultaORM<T>.Create(
    LMetadado,
    FExecutorConsulta,
    FLogger);
end;

function TOrmSessao.ExecutarSQL<T>(
  const ASQL: string;
  const AParametros: TArray<TParNomeValor>): TObjectList<T>;
begin
  VerificarConexaoAberta;
  Result := FExecutor.ExecutarSQL<T>(ASQL, AParametros);
end;

function TOrmSessao.ObterConexao: IOrmConexao;
begin
  Result := FConexao;
end;

function TOrmSessao.ObterDialeto: IOrmDialeto;
begin
  Result := FDialeto;
end;

end.
