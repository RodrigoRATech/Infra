unit Infra.ORM.Core.Common.Tipos;

{
  Responsabilidade:
    Tipos, enumerações e constantes compartilhadas por todo o núcleo do ORM.
    Nenhuma dependência externa além da RTL.
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Rtti;

type

  // ---------------------------------------------------------------------------
  // Estratégias de geração de chave primária
  // ---------------------------------------------------------------------------
  TEstategiaChave = (
    ecNenhuma,         // valor atribuído manualmente pela aplicação
    ecAutoIncremento,  // sequência/identity gerada pelo banco
    ecGuid,            // GUID gerado pela aplicação
    ecUuidV7           // UUID v7 (time-ordered) gerado pela aplicação
  );

  // ---------------------------------------------------------------------------
  // Tipos de banco de dados suportados
  // ---------------------------------------------------------------------------
  TTipoBancoDados = (
    tbDesconhecido,
    tbFirebird,
    tbMySQL,
    tbMariaDB,
    tbPostgreSQL,
    tbSQLServer,
    tbSQLite,
    tbOracle
  );

  // ---------------------------------------------------------------------------
  // Tipos de dado no banco de dados
  // ---------------------------------------------------------------------------
  TTipoColuna = (
    tcString,
    tcInteger,
    tcInt64,
    tcFloat,
    tcDecimal,
    tcBoolean,
    tcData,
    tcDataHora,
    tcHora,
    tcGuid,
    tcUuid,
    tcBlob,
    tcClob,
    tcJson,
    tcJsonb,
    tcArray,
    tcDesconhecido
  );

  // ---------------------------------------------------------------------------
  // Operações de persistência rastreadas pelo ORM
  // ---------------------------------------------------------------------------
  TOperacaoOrm = (
    ooInserir,
    ooAtualizar,
    ooDeletar,
    ooBuscarPorId,
    ooListar,
    ooConsultar,
    ooCommit,
    ooRollback
  );

  // ---------------------------------------------------------------------------
  // Estados possíveis de uma entidade gerenciada
  // ---------------------------------------------------------------------------
  TEstadoEntidade = (
    eeNovo,
    eeGerenciado,
    eeModificado,
    eeDeletado,
    eeDetached
  );

  // ---------------------------------------------------------------------------
  // Direção de ordenação em queries
  // ---------------------------------------------------------------------------
  TDirecaoOrdenacao = (
    doAscendente,
    doDescendente
  );

  // ---------------------------------------------------------------------------
  // Tipo de join em consultas
  // ---------------------------------------------------------------------------
  TTipoJoin = (
    tjInner,
    tjLeft,
    tjRight,
    tjFull
  );

  // ---------------------------------------------------------------------------
  // Operadores de comparação usados em filtros
  // ---------------------------------------------------------------------------
  TOperadorFiltro = (
    ofIgual,
    ofDiferente,
    ofMaior,
    ofMenorOuIgual,
    ofMaiorOuIgual,
    ofMenor,
    ofContem,        // LIKE '%valor%'
    ofIniciacom,     // LIKE 'valor%'
    ofTerminaCom,    // LIKE '%valor'
    ofNulo,          // IS NULL
    ofNaoNulo,       // IS NOT NULL
    ofEm,            // IN (...)
    ofNaoEm          // NOT IN (...)
  );

  // ---------------------------------------------------------------------------
  // Conectores de filtro (AND / OR)
  // ---------------------------------------------------------------------------
  TConectorFiltro = (
    cfE,   // AND
    cfOu   // OR
  );

  // ---------------------------------------------------------------------------
  // Nível de severidade de log
  // ---------------------------------------------------------------------------
  TNivelLog = (
    nlDebug,
    nlInformacao,
    nlAviso,
    nlErro,
    nlFatal
  );

  // ---------------------------------------------------------------------------
  // Representação de uma chave primária composta ou simples
  // Usa TArray<TValue> para suportar múltiplos campos de forma genérica
  // ---------------------------------------------------------------------------
  TValoresChave = TArray<TValue>;

  // ---------------------------------------------------------------------------
  // Par nome/valor utilizado em contextos estruturados (log, eventos, params)
  // ---------------------------------------------------------------------------
  TParNomeValor = record
    Nome: string;
    Valor: TValue;
    constructor Create(const ANome: string; const AValor: TValue);
  end;

  TContextoEstruturado = TArray<TParNomeValor>;

  // ---------------------------------------------------------------------------
  // Resultado de operação de persistência
  // ---------------------------------------------------------------------------
  TResultadoOperacao = record
    Sucesso: Boolean;
    LinhasAfetadas: Integer;
    MensagemErro: string;
    ExcecaoOriginal: Exception;

    class function Ok(const ALinhas: Integer = 0): TResultadoOperacao; static;
    class function Falha(const AMensagem: string;
      AExcecao: Exception = nil): TResultadoOperacao; static;
  end;

const
  // Versão corrente do ORM
  VERSAO_ORM = '1.0.0-mvp';

  // Nome interno do produto
  PRODUTO_ORM = 'Infra.ORM';

  // Prefixo padrão para parâmetros nomeados
  PREFIXO_PARAMETRO = ':p_';

  // Tamanho padrão para campos string sem tamanho definido
  TAMANHO_STRING_PADRAO = 255;

implementation

{ TParNomeValor }

constructor TParNomeValor.Create(const ANome: string; const AValor: TValue);
begin
  Nome := ANome;
  Valor := AValor;
end;

{ TResultadoOperacao }

class function TResultadoOperacao.Ok(
  const ALinhas: Integer): TResultadoOperacao;
begin
  Result.Sucesso := True;
  Result.LinhasAfetadas := ALinhas;
  Result.MensagemErro := string.Empty;
  Result.ExcecaoOriginal := nil;
end;

class function TResultadoOperacao.Falha(const AMensagem: string;
  AExcecao: Exception): TResultadoOperacao;
begin
  Result.Sucesso := False;
  Result.LinhasAfetadas := 0;
  Result.MensagemErro := AMensagem;
  Result.ExcecaoOriginal := AExcecao;
end;

end.
