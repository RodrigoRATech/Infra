unit Infra.ORM.Tests.Query;

{
  Responsabilidade:
    Testes unitários do sistema de query fluente.
    Cobre: construção de SQL, serialização de filtros,
    ordenação, paginação e casos de borda.
    Usa dialeto Firebird como referência.
}

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Mapping.Atributos,
  Infra.ORM.Core.Metadata.Cache,
  Infra.ORM.Core.Query.Filtro,
  Infra.ORM.Core.Query.Ordenacao,
  Infra.ORM.Core.Query.Paginacao,
  Infra.ORM.Core.Query.Construtor,
  Infra.ORM.Firebird.Dialeto,
  Infra.ORM.MySQL.Dialeto;

// ── Entidade de teste ─────────────────────────────────────────────────────────
type

  [Tabela('PRODUTOS')]
  TProdutoQuery = class
  private
    FId: Int64;
    FNome: string;
    FPreco: Double;
    FAtivo: Boolean;
    FCategoria: string;
    FCriadoEm: TDateTime;
  public
    [ChavePrimaria] [AutoIncremento] [Coluna('ID')]
    property Id: Int64 read FId write FId;

    [Coluna('NOME')] [Obrigatorio] [Tamanho(200)]
    property Nome: string read FNome write FNome;

    [Coluna('PRECO')] [Precisao(18,2)]
    property Preco: Double read FPreco write FPreco;

    [Coluna('ATIVO')]
    property Ativo: Boolean read FAtivo write FAtivo;

    [Coluna('CATEGORIA')] [Tamanho(80)]
    property Categoria: string read FCategoria write FCategoria;

    [Coluna('CRIADO_EM')] [CriadoEm]
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
  end;

// ── Suite de testes ───────────────────────────────────────────────────────────

  [TestFixture]
  TTestesConstrutorConsulta = class
  strict private
    FDialetoFirebird: IOrmDialeto;
    FDialetoMySQL: IOrmDialeto;
    FMetadado: IOrmMetadadoEntidade;
    FConstrutorFB: TConstrutorConsulta;
    FConstrutorMySQL: TConstrutorConsulta;

    function FiltrosVazios: TListaFiltros;
    function GruposVazios: TListaGrupos;
    function OrdenacaoVazia: TConstrutorOrdenacao;
    function PaginacaoSem: TPaginacao;

  public
    [Setup]
    procedure Configurar;

    [TearDown]
    procedure Limpar;

    // ── SELECT base ───────────────────────────────────────────────────────

    [Test]
    procedure DeveGerarSelectBasicoFirebird;

    [Test]
    procedure DeveGerarSelectBasicoMySQL;

    // ── WHERE simples ─────────────────────────────────────────────────────

    [Test]
    procedure DeveGerarWhereComFiltroIgual;

    [Test]
    procedure DeveGerarWhereComFiltroMaior;

    [Test]
    procedure DeveGerarWhereComFiltroDiferente;

    [Test]
    procedure DeveGerarWhereComFiltroContem;

    [Test]
    procedure DeveGerarWhereComFiltroIniciacom;

    [Test]
    procedure DeveGerarWhereComFiltroTerminaCom;

    [Test]
    procedure DeveGerarWhereComFiltroNulo;

    [Test]
    procedure DeveGerarWhereComFiltroNaoNulo;

    // ── WHERE composto ────────────────────────────────────────────────────

    [Test]
    procedure DeveGerarWhereComAndEntreFiltros;

    [Test]
    procedure DeveGerarWhereComOrEntreFiltros;

    [Test]
    procedure DeveGerarWhereComMistoAndOr;

    // ── IN / NOT IN ───────────────────────────────────────────────────────

    [Test]
    procedure DeveGerarWhereComIn;

    [Test]
    procedure DeveGerarWhereComNotIn;

    [Test]
    procedure DeveGerarCondicaoFalsaParaInVazio;

    [Test]
    procedure DeveGerarCondicaoVerdadeiraParaNotInVazio;

    // ── Grupos ────────────────────────────────────────────────────────────

    [Test]
    procedure DeveGerarWhereComGrupoSimples;

    [Test]
    procedure DeveGerarWhereComDoisGruposOu;

    // ── ORDER BY ──────────────────────────────────────────────────────────

    [Test]
    procedure DeveGerarOrderByAscendente;

    [Test]
    procedure DeveGerarOrderByDescendente;

    [Test]
    procedure DeveGerarOrderByMultiploCampos;

    // ── Paginação ─────────────────────────────────────────────────────────

    [Test]
    procedure DeveAplicarPaginacaoFirebird;

    [Test]
    procedure DeveAplicarPaginacaoMySQL;

    // ── COUNT e EXISTS ────────────────────────────────────────────────────

    [Test]
    procedure DeveGerarSQLCount;

    [Test]
    procedure DeveGerarSQLExists;

    // ── Parâmetros ────────────────────────────────────────────────────────

    [Test]
    procedure DeveGerarParametrosNomeadosSemColisao;

    [Test]
    procedure DeveGerarParametroLikeComCuringas;

    // ── Erros ─────────────────────────────────────────────────────────────

    [Test]
    procedure DeveLancarExcecaoParaColunaInexistente;

    [Test]
    procedure DeveLancarExcecaoParaPaginacaoSemLimit;
  end;

implementation

{ TTestesConstrutorConsulta }

procedure TTestesConstrutorConsulta.Configurar;
begin
  TCacheMetadados.Instancia.InvalidarTudo;
  FDialetoFirebird := TDialetoFirebird.Create;
  FDialetoMySQL    := TDialetoMySQL.Create;
  FMetadado        := TCacheMetadados.Instancia.Resolver(TProdutoQuery);
  FConstrutorFB    := TConstrutorConsulta.Create(FDialetoFirebird);
  FConstrutorMySQL := TConstrutorConsulta.Create(FDialetoMySQL);
end;

procedure TTestesConstrutorConsulta.Limpar;
begin
  FConstrutorMySQL.Free;
  FConstrutorFB.Free;
  TCacheMetadados.Instancia.InvalidarTudo;
end;

function TTestesConstrutorConsulta.FiltrosVazios: TListaFiltros;
begin
  Result := nil;
end;

function TTestesConstrutorConsulta.GruposVazios: TListaGrupos;
begin
  Result := nil;
end;

function TTestesConstrutorConsulta.OrdenacaoVazia: TConstrutorOrdenacao;
begin
  Result := TConstrutorOrdenacao.Novo;
end;

function TTestesConstrutorConsulta.PaginacaoSem: TPaginacao;
begin
  Result := TPaginacao.Sem;
end;

// ── SELECT base ───────────────────────────────────────────────────────────────

procedure TTestesConstrutorConsulta.DeveGerarSelectBasicoFirebird;
var
  LC: TConsultaConstruida;
begin
  LC := FConstrutorFB.Construir(
    FMetadado, FiltrosVazios, GruposVazios,
    OrdenacaoVazia, PaginacaoSem);

  Assert.AreEqual(
    'SELECT * FROM "PRODUTOS"', LC.SQL,
    'SQL base Firebird deve usar aspas duplas');
end;

procedure TTestesConstrutorConsulta.DeveGerarSelectBasicoMySQL;
var
  LC: TConsultaConstruida;
begin
  LC := FConstrutorMySQL.Construir(
    FMetadado, FiltrosVazios, GruposVazios,
    OrdenacaoVazia, PaginacaoSem);

  Assert.AreEqual(
    'SELECT * FROM `PRODUTOS`', LC.SQL,
    'SQL base MySQL deve usar backtick');
end;

// ── WHERE simples ─────────────────────────────────────────────────────────────

procedure TTestesConstrutorConsulta.DeveGerarWhereComFiltroIgual;
var
  LFiltros: TListaFiltros;
  LC: TConsultaConstruida;
begin
  SetLength(LFiltros, 1);
  LFiltros[0] := TFiltro.Criar('ATIVO', ofIgual,
    TValue.From<Boolean>(True));

  LC := FConstrutorFB.Construir(
    FMetadado, LFiltros, GruposVazios,
    OrdenacaoVazia, PaginacaoSem);

  Assert.IsTrue(
    LC.SQL.Contains('WHERE "ATIVO" ='),
    'SQL deve conter WHERE com operador igual');
  Assert.AreEqual(1, Length(LC.Parametros),
    'Deve haver exatamente 1 parâmetro');
end;

procedure TTestesConstrutorConsulta.DeveGerarWhereComFiltroMaior;
var
  LFiltros: TListaFiltros;
  LC: TConsultaConstruida;
begin
  SetLength(LFiltros, 1);
  LFiltros[0] := TFiltro.Criar('PRECO', ofMaior,
    TValue.From<Double>(100.0));

  LC := FConstrutorFB.Construir(
    FMetadado, LFiltros, GruposVazios,
    OrdenacaoVazia, PaginacaoSem);

  Assert.IsTrue(LC.SQL.Contains('"PRECO" >'),
    'SQL deve conter operador maior (>)');
end;

procedure TTestesConstrutorConsulta.DeveGerarWhereComFiltroDiferente;
var
  LFiltros: TListaFiltros;
  LC: TConsultaConstruida;
begin
  SetLength(LFiltros, 1);
  LFiltros[0] := TFiltro.Criar('CATEGORIA', ofDiferente,
    TValue.From<string>('INATIVO'));

  LC := FConstrutorFB.Construir(
    FMetadado, LFiltros, GruposVazios,
    OrdenacaoVazia, PaginacaoSem);

  Assert.IsTrue(LC.SQL.Contains('"CATEGORIA" <>'),
    'SQL deve conter operador diferente (<>)');
end;

procedure TTestesConstrutorConsulta.DeveGerarWhereComFiltroContem;
var
  LFiltros: TListaFiltros;
  LC: TConsultaConstruida;
begin
  SetLength(LFiltros, 1);
  LFiltros[0] := TFiltro.Criar('NOME', ofContem,
    TValue.From<string>('Monitor'));

  LC := FConstrutorFB.Construir(
    FMetadado, LFiltros, GruposVazios,
    OrdenacaoVazia, PaginacaoSem);

  Assert.IsTrue(LC.SQL.Contains('LIKE'),
    'SQL deve usar LIKE para ofContem');
  Assert.AreEqual('%Monitor%',
    LC.Parametros[0].Valor.AsString,
    'Valor LIKE deve ter curingas em ambos os lados');
end;

procedure TTestesConstrutorConsulta.DeveGerarWhereComFiltroIniciacom;
var
  LFiltros: TListaFiltros;
  LC: TConsultaConstruida;
begin
  SetLength(LFiltros, 1);
  LFiltros[0] := TFiltro.Criar('NOME', ofIniciacom,
    TValue.From<string>('Note'));

  LC := FConstrutorFB.Construir(
    FMetadado, LFiltros, GruposVazios,
    OrdenacaoVazia, PaginacaoSem);

  Assert.AreEqual('Note%',
    LC.Parametros[0].Valor.AsString,
    'Valor LIKE deve ter curinga apenas no final (Iniciacom)');
end;

procedure TTestesConstrutorConsulta.DeveGerarWhereComFiltroTerminaCom;
var
  LFiltros: TListaFiltros;
  LC: TConsultaConstruida;
begin
  SetLength(LFiltros, 1);
  LFiltros[0] := TFiltro.Criar('NOME', ofTerminaCom,
    TValue.From<string>('4K'));

  LC := FConstrutorFB.Construir(
    FMetadado, LFiltros, GruposVazios,
    OrdenacaoVazia, PaginacaoSem);

  Assert.AreEqual('%4K',
    LC.Parametros[0].Valor.AsString,
    'Valor LIKE deve ter curinga apenas no início (TerminaCom)');
end;

procedure TTestesConstrutorConsulta.DeveGerarWhereComFiltroNulo;
var
  LFiltros: TListaFiltros;
  LC: TConsultaConstruida;
begin
  SetLength(LFiltros, 1);
  LFiltros[0] := TFiltro.CriarUnario('CATEGORIA', ofNulo);

  LC := FConstrutorFB.Construir(
    FMetadado, LFiltros, GruposVazios,
    OrdenacaoVazia, PaginacaoSem);

  Assert.IsTrue(LC.SQL.Contains('IS NULL'),
    'SQL deve conter IS NULL para filtro nulo');
  Assert.AreEqual(0, Length(LC.Parametros),
    'Filtro IS NULL não deve gerar parâmetro');
end;

procedure TTestesConstrutorConsulta.DeveGerarWhereComFiltroNaoNulo;
var
  LFiltros: TListaFiltros;
  LC: TConsultaConstruida;
begin
  SetLength(LFiltros, 1);
  LFiltros[0] := TFiltro.CriarUnario('CATEGORIA', ofNaoNulo);

  LC := FConstrutorFB.Construir(
    FMetadado, LFiltros, GruposVazios,
    OrdenacaoVazia, PaginacaoSem);

  Assert.IsTrue(LC.SQL.Contains('IS NOT NULL'),
    'SQL deve conter IS NOT NULL');
end;

// ── WHERE composto ────────────────────────────────────────────────────────────

procedure TTestesConstrutorConsulta.DeveGerarWhereComAndEntreFiltros;
var
  LFiltros: TListaFiltros;
  LC: TConsultaConstruida;
begin
  SetLength(LFiltros, 2);
  LFiltros[0] := TFiltro.Criar('ATIVO', ofIgual,
    TValue.From<Boolean>(True), cfE);
  LFiltros[1] := TFiltro.Criar('PRECO', ofMaior,
    TValue.From<Double>(50.0), cfE);

  LC := FConstrutorFB.Construir(
    FMetadado, LFiltros, GruposVazios,
    OrdenacaoVazia, PaginacaoSem);

  Assert.IsTrue(LC.SQL.Contains(' AND '),
    'SQL deve conter AND entre dois filtros E');
end;

procedure TTestesConstrutorConsulta.DeveGerarWhereComOrEntreFiltros;
var
  LFiltros: TListaFiltros;
  LC: TConsultaConstruida;
begin
  SetLength(LFiltros, 2);
  LFiltros[0] := TFiltro.Criar('CATEGORIA', ofIgual,
    TValue.From<string>('TV'), cfE);
  LFiltros[1] := TFiltro.Criar('CATEGORIA', ofIgual,
    TValue.From<string>('Monitor'), cfOu);

  LC := FConstrutorFB.Construir(
    FMetadado, LFiltros, GruposVazios,
    OrdenacaoVazia, PaginacaoSem);

  Assert.IsTrue(LC.SQL.Contains(' OR '),
    'SQL deve conter OR entre filtros com conector Ou');
end;

procedure TTestesConstrutorConsulta.DeveGerarWhereComMistoAndOr;
var
  LFiltros: TListaFiltros;
  LC: TConsultaConstruida;
begin
  SetLength(LFiltros, 3);
  LFiltros[0] := TFiltro.Criar('ATIVO', ofIgual,
    TValue.From<Boolean>(True), cfE);
  LFiltros[1] := TFiltro.Criar('PRECO', ofMaior,
    TValue.From<Double>(100.0), cfE);
  LFiltros[2] := TFiltro.Criar('CATEGORIA', ofIgual,
    TValue.From<string>('Eletrônico'), cfOu);

  LC := FConstrutorFB.Construir(
    FMetadado, LFiltros, GruposVazios,
    OrdenacaoVazia, PaginacaoSem);

  Assert.IsTrue(LC.SQL.Contains(' AND '), 'SQL deve ter AND');
  Assert.IsTrue(LC.SQL.Contains(' OR '),  'SQL deve ter OR');
  Assert.AreEqual(3, Length(LC.Parametros), 'Deve gerar 3 parâmetros');
end;

// ── IN / NOT IN ───────────────────────────────────────────────────────────────

procedure TTestesConstrutorConsulta.DeveGerarWhereComIn;
var
  LFiltros: TListaFiltros;
  LValores: TArray<TValue>;
  LC: TConsultaConstruida;
begin
  SetLength(LValores, 3);
  LValores[0] := TValue.From<string>('TV');
  LValores[1] := TValue.From<string>('Monitor');
  LValores[2] := TValue.From<string>('Notebook');

  SetLength(LFiltros, 1);
  LFiltros[0] := TFiltro.CriarLista('CATEGORIA', ofEm, LValores);

  LC := FConstrutorFB.Construir(
    FMetadado, LFiltros, GruposVazios,
    OrdenacaoVazia, PaginacaoSem);

  Assert.IsTrue(LC.SQL.Contains(' IN ('), 'SQL deve conter IN (');
  Assert.AreEqual(3, Length(LC.Parametros),
    'Deve gerar 1 parâmetro por item do IN');
end;

procedure TTestesConstrutorConsulta.DeveGerarWhereComNotIn;
var
  LFiltros: TListaFiltros;
  LValores: TArray<TValue>;
  LC: TConsultaConstruida;
begin
  SetLength(LValores, 2);
  LValores[0] := TValue.From<string>('INATIVO');
  LValores[1] := TValue.From<string>('OBSOLETO');

  SetLength(LFiltros, 1);
  LFiltros[0] := TFiltro.CriarLista('CATEGORIA', ofNaoEm, LValores);

  LC := FConstrutorFB.Construir(
    FMetadado, LFiltros, GruposVazios,
    OrdenacaoVazia, PaginacaoSem);

  Assert.IsTrue(LC.SQL.Contains(' NOT IN ('),
    'SQL deve conter NOT IN (');
end;

procedure TTestesConstrutorConsulta.DeveGerarCondicaoFalsaParaInVazio;
var
  LFiltros: TListaFiltros;
  LC: TConsultaConstruida;
begin
  SetLength(LFiltros, 1);
  LFiltros[0] := TFiltro.CriarLista('CATEGORIA', ofEm, nil);

  LC := FConstrutorFB.Construir(
    FMetadado, LFiltros, GruposVazios,
    OrdenacaoVazia, PaginacaoSem);

  Assert.IsTrue(LC.SQL.Contains('1=0'),
    'IN com lista vazia deve gerar condição sempre falsa (1=0)');
end;

procedure TTestesConstrutorConsulta.DeveGerarCondicaoVerdadeiraParaNotInVazio;
var
  LFiltros: TListaFiltros;
  LC: TConsultaConstruida;
begin
  SetLength(LFiltros, 1);
  LFiltros[0] := TFiltro.CriarLista('CATEGORIA', ofNaoEm, nil);

  LC := FConstrutorFB.Construir(
    FMetadado, LFiltros, GruposVazios,
    OrdenacaoVazia, PaginacaoSem);

  Assert.IsTrue(LC.SQL.Contains('1=1'),
    'NOT IN com lista vazia deve gerar condição sempre verdadeira (1=1)');
end;

// ── Grupos ────────────────────────────────────────────────────────────────────

procedure TTestesConstrutorConsulta.DeveGerarWhereComGrupoSimples;
var
  LGrupos: TListaGrupos;
  LC: TConsultaConstruida;
begin
  SetLength(LGrupos, 1);
  LGrupos[0] := TGrupoFiltro.Criar(cfE);
  LGrupos[0].AdicionarFiltro(TFiltro.Criar('ATIVO', ofIgual,
    TValue.From<Boolean>(True), cfE));
  LGrupos[0].AdicionarFiltro(TFiltro.Criar('PRECO', ofMaior,
    TValue.From<Double>(0.0), cfE));

  LC := FConstrutorFB.Construir(
    FMetadado, FiltrosVazios, LGrupos,
    OrdenacaoVazia, PaginacaoSem);

  Assert.IsTrue(
    LC.SQL.Contains('("ATIVO" =') and LC.SQL.Contains('"PRECO" >'),
    'Grupo deve gerar parênteses ao redor dos filtros');
end;

procedure TTestesConstrutorConsulta.DeveGerarWhereComDoisGruposOu;
var
  LGrupos: TListaGrupos;
  LC: TConsultaConstruida;
begin
  SetLength(LGrupos, 2);

  LGrupos[0] := TGrupoFiltro.Criar(cfE);
  LGrupos[0].AdicionarFiltro(TFiltro.Criar('CATEGORIA', ofIgual,
    TValue.From<string>('TV'), cfE));
  LGrupos[0].AdicionarFiltro(TFiltro.Criar('PRECO', ofMenorOuIgual,
    TValue.From<Double>(5000.0), cfE));

  LGrupos[1] := TGrupoFiltro.Criar(cfOu);
  LGrupos[1].AdicionarFiltro(TFiltro.Criar('CATEGORIA', ofIgual,
    TValue.From<string>('Monitor'), cfE));
  LGrupos[1].AdicionarFiltro(TFiltro.Criar('PRECO', ofMenorOuIgual,
    TValue.From<Double>(3000.0), cfE));

  LC := FConstrutorFB.Construir(
    FMetadado, FiltrosVazios, LGrupos,
    OrdenacaoVazia, PaginacaoSem);

  Assert.IsTrue(LC.SQL.Contains(') OR ('),
    'SQL deve conter OR entre dois grupos com parênteses');
end;

// ── ORDER BY ──────────────────────────────────────────────────────────────────

procedure TTestesConstrutorConsulta.DeveGerarOrderByAscendente;
var
  LOrdenacao: TConstrutorOrdenacao;
  LC: TConsultaConstruida;
begin
  LOrdenacao := TConstrutorOrdenacao.Novo;
  LOrdenacao.Adicionar('NOME', doAscendente);

  LC := FConstrutorFB.Construir(
    FMetadado, FiltrosVazios, GruposVazios,
    LOrdenacao, PaginacaoSem);

  Assert.IsTrue(
    LC.SQL.Contains('ORDER BY "NOME" ASC'),
    'SQL deve conter ORDER BY coluna ASC');
end;

procedure TTestesConstrutorConsulta.DeveGerarOrderByDescendente;
var
  LOrdenacao: TConstrutorOrdenacao;
  LC: TConsultaConstruida;
begin
  LOrdenacao := TConstrutorOrdenacao.Novo;
  LOrdenacao.Adicionar('CRIADO_EM', doDescendente);

  LC := FConstrutorFB.Construir(
    FMetadado, FiltrosVazios, GruposVazios,
    LOrdenacao, PaginacaoSem);

  Assert.IsTrue(
    LC.SQL.Contains('ORDER BY "CRIADO_EM" DESC'),
    'SQL deve conter ORDER BY coluna DESC');
end;

procedure TTestesConstrutorConsulta.DeveGerarOrderByMultiploCampos;
var
  LOrdenacao: TConstrutorOrdenacao;
  LC: TConsultaConstruida;
begin
  LOrdenacao := TConstrutorOrdenacao.Novo;
  LOrdenacao.Adicionar('CATEGORIA', doAscendente);
  LOrdenacao.Adicionar('PRECO', doDescendente);
  LOrdenacao.Adicionar('NOME', doAscendente);

  LC := FConstrutorFB.Construir(
    FMetadado, FiltrosVazios, GruposVazios,
    LOrdenacao, PaginacaoSem);

  Assert.IsTrue(
    LC.SQL.Contains('"CATEGORIA" ASC, "PRECO" DESC, "NOME" ASC'),
    'SQL deve ordenar por múltiplos campos na sequência correta');
end;

// ── Paginação ─────────────────────────────────────────────────────────────────

procedure TTestesConstrutorConsulta.DeveAplicarPaginacaoFirebird;
var
  LPaginacao: TPaginacao;
  LC: TConsultaConstruida;
begin
  LPaginacao := TPaginacao.Com(20, 10);

  LC := FConstrutorFB.Construir(
    FMetadado, FiltrosVazios, GruposVazios,
    OrdenacaoVazia, LPaginacao);

  // Firebird: ROWS offset+1 TO offset+limit → ROWS 21 TO 30
  Assert.IsTrue(
    LC.SQL.Contains('ROWS 21 TO 30'),
    'Firebird deve usar sintaxe ROWS N TO M para paginação');
end;

procedure TTestesConstrutorConsulta.DeveAplicarPaginacaoMySQL;
var
  LPaginacao: TPaginacao;
  LC: TConsultaConstruida;
begin
  LPaginacao := TPaginacao.Com(20, 10);

  LC := FConstrutorMySQL.Construir(
    FMetadado, FiltrosVazios, GruposVazios,
    OrdenacaoVazia, LPaginacao);

  // MySQL: LIMIT 10 OFFSET 20
  Assert.IsTrue(
    LC.SQL.Contains('LIMIT 10 OFFSET 20'),
    'MySQL deve usar sintaxe LIMIT N OFFSET M para paginação');
end;

// ── COUNT e EXISTS ────────────────────────────────────────────────────────────

procedure TTestesConstrutorConsulta.DeveGerarSQLCount;
var
  LFiltros: TListaFiltros;
  LC: TConsultaConstruida;
begin
  SetLength(LFiltros, 1);
  LFiltros[0] := TFiltro.Criar('ATIVO', ofIgual,
    TValue.From<Boolean>(True));

  LC := FConstrutorFB.Construir(
    FMetadado, LFiltros, GruposVazios,
    OrdenacaoVazia, PaginacaoSem);

  Assert.IsTrue(
    LC.SQLContar.StartsWith('SELECT COUNT(*)'),
    'SQL de contagem deve iniciar com SELECT COUNT(*)');
  Assert.IsTrue(
    LC.SQLContar.Contains('WHERE'),
    'SQL de contagem deve aplicar os mesmos filtros');
  Assert.IsFalse(
    LC.SQLContar.Contains('ORDER BY'),
    'SQL de contagem não deve conter ORDER BY');
end;

procedure TTestesConstrutorConsulta.DeveGerarSQLExists;
var
  LC: TConsultaConstruida;
begin
  LC := FConstrutorFB.Construir(
    FMetadado, FiltrosVazios, GruposVazios,
    OrdenacaoVazia, PaginacaoSem);

  Assert.IsTrue(
    LC.SQLExiste.StartsWith('SELECT 1 FROM'),
    'SQL EXISTS deve iniciar com SELECT 1 FROM');
end;

// ── Parâmetros ────────────────────────────────────────────────────────────────

procedure TTestesConstrutorConsulta.DeveGerarParametrosNomeadosSemColisao;
var
  LFiltros: TListaFiltros;
  LC: TConsultaConstruida;
  LNomes: TArray<string>;
  LIndice, LJ: Integer;
begin
  // Dois filtros na mesma coluna — parâmetros devem ter nomes distintos
  SetLength(LFiltros, 2);
  LFiltros[0] := TFiltro.Criar('PRECO', ofMaiorOuIgual,
    TValue.From<Double>(100.0), cfE);
  LFiltros[1] := TFiltro.Criar('PRECO', ofMenorOuIgual,
    TValue.From<Double>(500.0), cfE);

  LC := FConstrutorFB.Construir(
    FMetadado, LFiltros, GruposVazios,
    OrdenacaoVazia, PaginacaoSem);

  Assert.AreEqual(2, Length(LC.Parametros),
    'Dois filtros devem gerar dois parâmetros distintos');

  // Verificar que os nomes são únicos
  SetLength(LNomes, Length(LC.Parametros));
  for LIndice := 0 to High(LC.Parametros) do
    LNomes[LIndice] := LC.Parametros[LIndice].Nome;

  for LIndice := 0 to High(LNomes) do
    for LJ := LIndice + 1 to High(LNomes) do
      Assert.AreNotEqual(LNomes[LIndice], LNomes[LJ],
        Format('Parâmetros não podem ter nomes duplicados: %s',
          [LNomes[LIndice]]));
end;

procedure TTestesConstrutorConsulta.DeveGerarParametroLikeComCuringas;
var
  LFiltros: TListaFiltros;
  LC: TConsultaConstruida;
begin
  SetLength(LFiltros, 3);
  LFiltros[0] := TFiltro.Criar('NOME', ofContem,     TValue.From<string>('A'));
  LFiltros[1] := TFiltro.Criar('NOME', ofIniciacom,  TValue.From<string>('B'));
  LFiltros[2] := TFiltro.Criar('NOME', ofTerminaCom, TValue.From<string>('C'));

  LC := FConstrutorFB.Construir(
    FMetadado, LFiltros, GruposVazios,
    OrdenacaoVazia, PaginacaoSem);

  Assert.AreEqual('%A%', LC.Parametros[0].Valor.AsString, 'Contem: %A%');
  Assert.AreEqual('B%',  LC.Parametros[1].Valor.AsString, 'IniciaEm: B%');
  Assert.AreEqual('%C',  LC.Parametros[2].Valor.AsString, 'TerminaCom: %C');
end;

// ── Erros ─────────────────────────────────────────────────────────────────────

procedure TTestesConstrutorConsulta.DeveLancarExcecaoParaColunaInexistente;
var
  LFiltros: TListaFiltros;
begin
  SetLength(LFiltros, 1);
  LFiltros[0] := TFiltro.Criar('COLUNA_FANTASMA', ofIgual,
    TValue.From<string>('X'));

  Assert.WillRaise(
    procedure
    begin
      FConstrutorFB.Construir(
        FMetadado, LFiltros, GruposVazios,
        OrdenacaoVazia, PaginacaoSem);
    end,
    EOrmConsultaExcecao,
    'Deve lançar EOrmConsultaExcecao para coluna inexistente nos metadados');
end;

procedure TTestesConstrutorConsulta.DeveLancarExcecaoParaPaginacaoSemLimit;
var
  LPaginacao: TPaginacao;
begin
  LPaginacao := TPaginacao.Sem;
  LPaginacao.DefinirOffset(10); // offset sem limit

  Assert.WillRaise(
    procedure
    begin
      FConstrutorFB.Construir(
        FMetadado, FiltrosVazios, GruposVazios,
        OrdenacaoVazia, LPaginacao);
    end,
    EOrmConsultaExcecao,
    'Deve lançar exceção para paginação com offset sem limit');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesConstrutorConsulta);

end.
