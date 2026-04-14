unit Infra.ORM.Core.Contracts;

{
  Responsabilidade:
    Contratos centrais do ORM.
    Toda a comunicação entre módulos se dá via estas interfaces.
    Nenhuma implementação concreta aqui.
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Rtti,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Events.Contratos,
  Infra.ORM.Core.Logging.Contrato;

type

  // Declarações forward
  IOrmSessao = interface;
  IOrmTransacao = interface;
  IOrmConexao = interface;
  IOrmComando = interface;
  IOrmLeitorDados = interface;
  IOrmConsulta<T: class> = interface;

  // ---------------------------------------------------------------------------
  // DIALETO SQL
  // ---------------------------------------------------------------------------

  IOrmDialeto = interface
    ['{10111213-1415-1617-1819-202122232425}']

    // Tipo de banco representado
    function TipoBanco: TTipoBancoDados;

    // Quotar identificadores: tabela, coluna, schema
    function Quotar(const ANome: string): string;
    function QuotarTabela(const ANome, ASchema: string): string;

    // SQL de paginação
    function AplicarPaginacao(const ASQL: string;
      AOffset, ALimit: Integer): string;

    // SQL para recuperar última chave gerada após INSERT
    function SQLChaveGerada: string;

    // SQL EXISTS para verificar existência de registro
    function SQLExiste(const ATabela, AColunaChave: string): string;

    // Prefixo de parâmetro (:p_ para maioria, @p_ para SQL Server)
    function PrefixoParametro: string;

    // Indica se o banco suporta RETURNING no INSERT
    function SuportaReturning: Boolean;

    // Cláusula RETURNING para INSERT
    function ClausulaReturning(const AColuna: string): string;
  end;

  // ---------------------------------------------------------------------------
  // PARÂMETRO DE COMANDO
  // ---------------------------------------------------------------------------

  IOrmParametro = interface
    ['{20212223-2425-2627-2829-303132333435}']
    function Nome: string;
    function Valor: TValue;
    function TipoColuna: TTipoColuna;
  end;

  // ---------------------------------------------------------------------------
  // LEITOR DE DADOS (abstração do TDataSet / TFDQuery result)
  // ---------------------------------------------------------------------------

  IOrmLeitorDados = interface
    ['{30313233-3435-3637-3839-404142434445}']

    function Proximo: Boolean;
    function EhFim: Boolean;
    function NomeColunas: TArray<string>;

    function ObterString(const AColuna: string): string;
    function ObterInteger(const AColuna: string): Integer;
    function ObterInt64(const AColuna: string): Int64;
    function ObterDouble(const AColuna: string): Double;
    function ObterBoolean(const AColuna: string): Boolean;
    function ObterDateTime(const AColuna: string): TDateTime;
    function ObterGuid(const AColuna: string): TGUID;
    function ObterValor(const AColuna: string): TValue;
    function EhNulo(const AColuna: string): Boolean;
  end;

  // ---------------------------------------------------------------------------
  // COMANDO SQL
  // ---------------------------------------------------------------------------

  IOrmComando = interface
    ['{40414243-4445-4647-4849-505152535455}']

    procedure DefinirSQL(const ASQL: string);
    function ObterSQL: string;

    procedure AdicionarParametro(const ANome: string;
      const AValor: TValue; ATipo: TTipoColuna = tcDesconhecido);

    procedure LimparParametros;

    function ExecutarSemRetorno: Integer; // rows affected
    function ExecutarEscalar: TValue;
    function ExecutarConsulta: IOrmLeitorDados;

    procedure Preparar;
  end;

  // ---------------------------------------------------------------------------
  // TRANSAÇÃO
  // ---------------------------------------------------------------------------

  IOrmTransacao = interface
    ['{50515253-5455-5657-5859-606162636465}']

    procedure Commit;
    procedure Rollback;
    function EstaAtiva: Boolean;
  end;

  // ---------------------------------------------------------------------------
  // CONEXÃO
  // ---------------------------------------------------------------------------

  IOrmConexao = interface
    ['{60616263-6465-6667-6869-707172737475}']

    procedure Abrir;
    procedure Fechar;
    function EstaAberta: Boolean;

    function CriarComando: IOrmComando;
    function IniciarTransacao: IOrmTransacao;
    function TransacaoAtiva: Boolean;

    function TipoBanco: TTipoBancoDados;
  end;

  // ---------------------------------------------------------------------------
  // FÁBRICA DE CONEXÕES
  // ---------------------------------------------------------------------------

  IOrmFabricaConexao = interface
    ['{70717273-7475-7677-7879-808182838485}']

    function CriarConexao: IOrmConexao;
    function TipoBanco: TTipoBancoDados;
  end;

  // ---------------------------------------------------------------------------
  // CONSULTA FLUENTE
  // ---------------------------------------------------------------------------

  IOrmConsulta<T: class> = interface
    ['{80818283-8485-8687-8889-909192939495}']

    // Filtros
    function Onde(const AColuna: string;
      AOperador: TOperadorFiltro;
      const AValor: TValue): IOrmConsulta<T>;

    function E(const AColuna: string;
      AOperador: TOperadorFiltro;
      const AValor: TValue): IOrmConsulta<T>;

    function Ou(const AColuna: string;
      AOperador: TOperadorFiltro;
      const AValor: TValue): IOrmConsulta<T>;

    // Ordenação
    function OrdenarPor(const AColuna: string;
      ADirecao: TDirecaoOrdenacao = doAscendente): IOrmConsulta<T>;

    // Paginação
    function Pular(AQuantidade: Integer): IOrmConsulta<T>;
    function Pegar(AQuantidade: Integer): IOrmConsulta<T>;

    // Execução
    function Listar: TObjectList<T>;
    function PrimeiroOuNulo: T;
    function Contar: Int64;
    function Existe: Boolean;
  end;

  // ---------------------------------------------------------------------------
  // SESSÃO PRINCIPAL DO ORM
  // ---------------------------------------------------------------------------

  IOrmSessao = interface
    ['{90919293-9495-9697-9899-A0A1A2A3A4A5}']

    // Transação
    function IniciarTransacao: IOrmTransacao;
    function TransacaoAtiva: Boolean;

    // CRUD
    procedure Inserir(AEntidade: TObject);
    procedure Atualizar(AEntidade: TObject);
    procedure Deletar(AEntidade: TObject);
    procedure Salvar(AEntidade: TObject);

    // Busca por chave
    function BuscarPorId<T: class, constructor>(
      const AChave: TValoresChave): T; overload;

    function BuscarPorId<T: class, constructor>(
      const AId: TValue): T; overload;

    // Listagem
    function Listar<T: class, constructor>: TObjectList<T>;

    // Query fluente
    function Consultar<T: class, constructor>: IOrmConsulta<T>;

    // SQL direto com hidratação automática
    function ExecutarSQL<T: class, constructor>(
      const ASQL: string;
      const AParametros: TArray<TParNomeValor>): TObjectList<T>;

    // Acesso interno
    function ObterConexao: IOrmConexao;
    function ObterDialeto: IOrmDialeto;
  end;

  // ---------------------------------------------------------------------------
  // FÁBRICA DE SESSÕES
  // ---------------------------------------------------------------------------

  IOrmFabricaSessao = interface
    ['{A0A1A2A3-A4A5-A6A7-A8A9-B0B1B2B3B4B5}']

    function CriarSessao: IOrmSessao;
  end;

  // ---------------------------------------------------------------------------
  // PROVEDOR DE METADADOS DE ENTIDADE
  // ---------------------------------------------------------------------------

  IOrmMetadadoPropriedade = interface
    ['{B0B1B2B3-B4B5-B6B7-B8B9-C0C1C2C3C4C5}']

    function Nome: string;           // nome da property Delphi
    function NomeColuna: string;     // nome da coluna no banco
    function TipoColuna: TTipoColuna;
    function Tamanho: Integer;
    function Precisao: Integer;
    function Escala: Integer;
    function EhChavePrimaria: Boolean;
    function EhNulavel: Boolean;
    function EhSomenteLeitura: Boolean;
    function EhObrigatorio: Boolean;
    function EhAutoIncremento: Boolean;
    function EstrategiaChave: TEstategiaChave;
    function OrdemChave: Integer;

    // Acesso ao valor via RTTI
    function ObterValor(AInstancia: TObject): TValue;
    procedure DefinirValor(AInstancia: TObject; const AValor: TValue);
  end;

  IOrmMetadadoEntidade = interface
    ['{C0C1C2C3-C4C5-C6C7-C8C9-D0D1D2D3D4D5}']

    function NomeClasse: string;
    function NomeTabela: string;
    function NomeSchema: string;
    function NomeQualificado: string; // schema.tabela

    function Propriedades: TArray<IOrmMetadadoPropriedade>;
    function Chaves: TArray<IOrmMetadadoPropriedade>;
    function PropriedadesPersistidas: TArray<IOrmMetadadoPropriedade>;
    function PropriedadePorColuna(const ANomeColuna: string): IOrmMetadadoPropriedade;
    function PropriedadePorNome(const ANome: string): IOrmMetadadoPropriedade;

    function PossuiSoftDelete: Boolean;
    function PossuiCriadoEm: Boolean;
    function PossuiAtualizadoEm: Boolean;
    function PossuiVersao: Boolean;
  end;

  IOrmCacheMetadados = interface
    ['{D0D1D2D3-D4D5-D6D7-D8D9-E0E1E2E3E4E5}']

    function Resolver(AClasse: TClass): IOrmMetadadoEntidade;
    function ResolverPorNome(const ANomeClasse: string): IOrmMetadadoEntidade;
    function EstaEmCache(AClasse: TClass): Boolean;
    procedure Invalidar(AClasse: TClass);
    procedure InvalidarTudo;
    function TotalEmCache: Integer;
  end;

implementation

end.
