unit Infra.ORM.Core.Mapping.Atributos;

{
  Responsabilidade:
    Atributos (CustomAttributes) utilizados para mapear
    entidades Delphi a tabelas e colunas do banco de dados.

    Regra: atributos devem ser simples portadores de metadado.
    Nenhuma lógica de acesso a banco deve residir aqui.
}

interface

uses
  System.SysUtils,
  Infra.ORM.Core.Common.Tipos;

type

  // ===========================================================================
  // ENTIDADE / TABELA
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // Mapeia a classe para uma tabela no banco de dados.
  // Uso: [Tabela('CLIENTES')] ou [Tabela('CLIENTES', 'PUBLIC')]
  // ---------------------------------------------------------------------------
  TabelaAttribute = class(TCustomAttribute)
  private
    FNome: string;
    FSchema: string;
  public
    constructor Create(const ANome: string;
      const ASchema: string = ''); overload;

    property Nome: string read FNome;
    property Schema: string read FSchema;
  end;

  // ---------------------------------------------------------------------------
  // Indica que a entidade não deve ser persistida diretamente.
  // Útil para classes base abstratas que não têm tabela própria.
  // ---------------------------------------------------------------------------
  NaoPersistirAttribute = class(TCustomAttribute);

  // ---------------------------------------------------------------------------
  // Indica a entidade para herança TPH (Table-Per-Hierarchy)
  // Fase 4 — marcador reservado para uso futuro
  // ---------------------------------------------------------------------------
  HerancaAttribute = class(TCustomAttribute)
  private
    FColunaDiscriminadora: string;
  public
    constructor Create(const AColunaDiscriminadora: string);
    property ColunaDiscriminadora: string read FColunaDiscriminadora;
  end;

  // ---------------------------------------------------------------------------
  // Define o valor discriminador desta subclasse em herança TPH
  // Fase 4 — marcador reservado para uso futuro
  // ---------------------------------------------------------------------------
  ValorDiscriminadorAttribute = class(TCustomAttribute)
  private
    FValor: string;
  public
    constructor Create(const AValor: string);
    property Valor: string read FValor;
  end;

  // ===========================================================================
  // COLUNA
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // Mapeia a property para uma coluna no banco de dados.
  // Uso: [Coluna('NOME')] ou [Coluna('VALOR', tcDecimal, 18, 4)]
  // ---------------------------------------------------------------------------
  ColunaAttribute = class(TCustomAttribute)
  private
    FNome: string;
    FTipo: TTipoColuna;
    FTamanho: Integer;
    FPrecisao: Integer;
    FEscala: Integer;
    FNulavel: Boolean;
  public
    constructor Create(
      const ANome: string;
      ATipo: TTipoColuna = tcDesconhecido;
      ATamanho: Integer = 0;
      APrecisao: Integer = 0;
      AEscala: Integer = 0;
      ANulavel: Boolean = True); overload;

    property Nome: string read FNome;
    property Tipo: TTipoColuna read FTipo;
    property Tamanho: Integer read FTamanho;
    property Precisao: Integer read FPrecisao;
    property Escala: Integer read FEscala;
    property Nulavel: Boolean read FNulavel;
  end;

  // ===========================================================================
  // CHAVE PRIMÁRIA
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // Marca a property como parte da chave primária.
  // Para chaves compostas, aplica-se em cada property participante.
  // A ordem é definida pelo atributo Ordem (padrão 0).
  // ---------------------------------------------------------------------------
  ChavePrimariaAttribute = class(TCustomAttribute)
  private
    FOrdem: Integer;
  public
    constructor Create(AOrdem: Integer = 0);
    property Ordem: Integer read FOrdem;
  end;

  // ---------------------------------------------------------------------------
  // Define a estratégia de geração do valor da chave primária
  // ---------------------------------------------------------------------------
  AutoIncrementoAttribute = class(TCustomAttribute);
  GuidGeneratorAttribute = class(TCustomAttribute);
  UuidV7GeneratorAttribute = class(TCustomAttribute);

  // ===========================================================================
  // COMPORTAMENTO DE PERSISTÊNCIA
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // Ignora completamente esta property no mapeamento ORM
  // ---------------------------------------------------------------------------
  NaoMapearAttribute = class(TCustomAttribute);

  // ---------------------------------------------------------------------------
  // Indica que esta coluna é somente leitura (não gera INSERT/UPDATE)
  // Útil para colunas calculadas ou gerenciadas pelo banco
  // ---------------------------------------------------------------------------
  SomenteLeituraAttribute = class(TCustomAttribute);

  // ---------------------------------------------------------------------------
  // Indica que o campo não pode ser nulo — dispara validação antes de persistir
  // ---------------------------------------------------------------------------
  ObrigatorioAttribute = class(TCustomAttribute);

  // ---------------------------------------------------------------------------
  // Define tamanho máximo para campos string
  // Uso: [Tamanho(150)]
  // ---------------------------------------------------------------------------
  TamanhoAttribute = class(TCustomAttribute)
  private
    FMaximo: Integer;
  public
    constructor Create(AMaximo: Integer);
    property Maximo: Integer read FMaximo;
  end;

  // ---------------------------------------------------------------------------
  // Define precisão e escala para campos decimais/numéricos
  // Uso: [Precisao(18, 4)]
  // ---------------------------------------------------------------------------
  PrecisaoAttribute = class(TCustomAttribute)
  private
    FPrecisao: Integer;
    FEscala: Integer;
  public
    constructor Create(APrecisao: Integer; AEscala: Integer = 2);
    property Precisao: Integer read FPrecisao;
    property Escala: Integer read FEscala;
  end;

  // ---------------------------------------------------------------------------
  // Indica que esta coluna participa do controle de versão para concorrência
  // Será verificada em UPDATEs para detecção de conflito
  // ---------------------------------------------------------------------------
  VersaoConcorrenciaAttribute = class(TCustomAttribute);

  // ---------------------------------------------------------------------------
  // Define o tipo explícito de banco de dados para a coluna.
  // Permite especificar VARCHAR(100), NUMERIC(18,4), etc.
  // Uso: [TipoBanco('VARCHAR(100)')]
  // ---------------------------------------------------------------------------
  TipoBancoAttribute = class(TCustomAttribute)
  private
    FTipoSQL: string;
  public
    constructor Create(const ATipoSQL: string);
    property TipoSQL: string read FTipoSQL;
  end;

  // ===========================================================================
  // RASTREAMENTO / AUDITORIA
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // Marca a property para ser preenchida automaticamente
  // com a data/hora de criação do registro
  // ---------------------------------------------------------------------------
  CriadoEmAttribute = class(TCustomAttribute);

  // ---------------------------------------------------------------------------
  // Marca a property para ser preenchida automaticamente
  // com a data/hora da última atualização
  // ---------------------------------------------------------------------------
  AtualizadoEmAttribute = class(TCustomAttribute);

  // ---------------------------------------------------------------------------
  // Marca a property para receber o identificador do usuário ou sistema
  // que criou o registro (string, int ou guid — genérico via TValue)
  // ---------------------------------------------------------------------------
  CriadoPorAttribute = class(TCustomAttribute);

  // ---------------------------------------------------------------------------
  // Marca a property para receber o identificador de quem fez a última
  // atualização
  // ---------------------------------------------------------------------------
  AtualizadoPorAttribute = class(TCustomAttribute);

  // ---------------------------------------------------------------------------
  // Habilita soft delete: ao invés de DELETE físico, atualiza o campo
  // marcado com este atributo para True/data
  // ---------------------------------------------------------------------------
  DeletadoEmAttribute = class(TCustomAttribute);

  // ===========================================================================
  // RELACIONAMENTOS
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // Define uma referência (N:1 ou 1:1) para outra entidade.
  // Uso: [Referencia(TEndereco, 'ENDERECO_ID')]
  // ---------------------------------------------------------------------------
  ReferenciaAttribute = class(TCustomAttribute)
  private
    FTipoRelacionado: TClass;
    FColunaFK: string;
    FCarregarAutomatico: Boolean;
  public
    constructor Create(
      ATipoRelacionado: TClass;
      const AColunaFK: string;
      ACarregarAutomatico: Boolean = False);

    property TipoRelacionado: TClass read FTipoRelacionado;
    property ColunaFK: string read FColunaFK;
    property CarregarAutomatico: Boolean read FCarregarAutomatico;
  end;

  // ---------------------------------------------------------------------------
  // Define uma coleção (1:N) de entidades relacionadas.
  // Uso: [Colecao(TItemPedido, 'PEDIDO_ID')]
  // ---------------------------------------------------------------------------
  ColecaoAttribute = class(TCustomAttribute)
  private
    FTipoElemento: TClass;
    FColunaFK: string;
    FCarregarAutomatico: Boolean;
  public
    constructor Create(
      ATipoElemento: TClass;
      const AColunaFK: string;
      ACarregarAutomatico: Boolean = False);

    property TipoElemento: TClass read FTipoElemento;
    property ColunaFK: string read FColunaFK;
    property CarregarAutomatico: Boolean read FCarregarAutomatico;
  end;

  // ===========================================================================
  // MULTI-TENANCY (reservado para Fase 4)
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // Marca a property que representa o tenant owner do registro.
  // O filtro automático por tenant será adicionado na Fase 4.
  // ---------------------------------------------------------------------------
  TenantIdAttribute = class(TCustomAttribute);

  // ===========================================================================
  // STORED PROCEDURE (reservado para Fase 4)
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // Marca uma classe como mapeada a uma stored procedure
  // ---------------------------------------------------------------------------
  StoredProcedureAttribute = class(TCustomAttribute)
  private
    FNome: string;
  public
    constructor Create(const ANome: string);
    property Nome: string read FNome;
  end;

  // ---------------------------------------------------------------------------
  // Mapeia uma property como parâmetro de stored procedure
  // ---------------------------------------------------------------------------
  ParametroProcedureAttribute = class(TCustomAttribute)
  private
    FNome: string;
    FDirecao: string; // 'IN', 'OUT', 'INOUT'
  public
    constructor Create(const ANome: string;
      const ADirecao: string = 'IN');
    property Nome: string read FNome;
    property Direcao: string read FDirecao;
  end;

implementation

{ TabelaAttribute }

constructor TabelaAttribute.Create(const ANome: string;
  const ASchema: string);
begin
  inherited Create;
  FNome := ANome;
  FSchema := ASchema;
end;

{ HerancaAttribute }

constructor HerancaAttribute.Create(const AColunaDiscriminadora: string);
begin
  inherited Create;
  FColunaDiscriminadora := AColunaDiscriminadora;
end;

{ ValorDiscriminadorAttribute }

constructor ValorDiscriminadorAttribute.Create(const AValor: string);
begin
  inherited Create;
  FValor := AValor;
end;

{ ColunaAttribute }

constructor ColunaAttribute.Create(const ANome: string; ATipo: TTipoColuna;
  ATamanho, APrecisao, AEscala: Integer; ANulavel: Boolean);
begin
  inherited Create;
  FNome := ANome;
  FTipo := ATipo;
  FTamanho := ATamanho;
  FPrecisao := APrecisao;
  FEscala := AEscala;
  FNulavel := ANulavel;
end;

{ ChavePrimariaAttribute }

constructor ChavePrimariaAttribute.Create(AOrdem: Integer);
begin
  inherited Create;
  FOrdem := AOrdem;
end;

{ TamanhoAttribute }

constructor TamanhoAttribute.Create(AMaximo: Integer);
begin
  inherited Create;
  FMaximo := AMaximo;
end;

{ PrecisaoAttribute }

constructor PrecisaoAttribute.Create(APrecisao, AEscala: Integer);
begin
  inherited Create;
  FPrecisao := APrecisao;
  FEscala := AEscala;
end;

{ TipoBancoAttribute }

constructor TipoBancoAttribute.Create(const ATipoSQL: string);
begin
  inherited Create;
  FTipoSQL := ATipoSQL;
end;

{ ReferenciaAttribute }

constructor ReferenciaAttribute.Create(ATipoRelacionado: TClass;
  const AColunaFK: string; ACarregarAutomatico: Boolean);
begin
  inherited Create;
  FTipoRelacionado := ATipoRelacionado;
  FColunaFK := AColunaFK;
  FCarregarAutomatico := ACarregarAutomatico;
end;

{ ColecaoAttribute }

constructor ColecaoAttribute.Create(ATipoElemento: TClass;
  const AColunaFK: string; ACarregarAutomatico: Boolean);
begin
  inherited Create;
  FTipoElemento := ATipoElemento;
  FColunaFK := AColunaFK;
  FCarregarAutomatico := ACarregarAutomatico;
end;

{ StoredProcedureAttribute }

constructor StoredProcedureAttribute.Create(const ANome: string);
begin
  inherited Create;
  FNome := ANome;
end;

{ ParametroProcedureAttribute }

constructor ParametroProcedureAttribute.Create(const ANome,
  ADirecao: string);
begin
  inherited Create;
  FNome := ANome;
  FDirecao := ADirecao;
end;

end.
