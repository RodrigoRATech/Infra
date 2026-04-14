unit Infra.ORM.Tests.Metadata;

{
  Responsabilidade:
    Testes unitários do núcleo de metadados.
    Cobre: resolução de atributos, cache thread-safe,
    chaves compostas, flags de comportamento e casos de erro.
}

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions,
  Infra.ORM.Core.Mapping.Atributos,
  Infra.ORM.Core.Metadata.Resolvedor,
  Infra.ORM.Core.Metadata.Cache,
  Infra.ORM.Core.Generators.Contratos;

// ============================================================================
// Entidades de teste — declaradas aqui para isolar o escopo dos testes
// ============================================================================
type

  [Tabela('CLIENTES')]
  TClienteTeste = class
  private
    FId: Int64;
    FNome: string;
    FEmail: string;
    FCriadoEm: TDateTime;
    FAtualizadoEm: TDateTime;
    FAtivo: Boolean;
    FTransiente: string;
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
    [SomenteLeitura]
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;

    [Coluna('ATUALIZADO_EM')]
    [AtualizadoEm]
    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;

    [Coluna('ATIVO')]
    property Ativo: Boolean read FAtivo write FAtivo;

    [NaoMapear]
    property Transiente: string read FTransiente write FTransiente;
  end;

  [Tabela('PEDIDOS', 'COMERCIAL')]
  TPedidoTeste = class
  private
    FId: string;
    FClienteId: Int64;
    FValorTotal: Double;
  public
    [ChavePrimaria]
    [UuidV7Generator]
    [Coluna('ID')]
    property Id: string read FId write FId;

    [Coluna('CLIENTE_ID')]
    [Obrigatorio]
    property ClienteId: Int64 read FClienteId write FClienteId;

    [Coluna('VALOR_TOTAL')]
    [Precisao(18, 2)]
    property ValorTotal: Double read FValorTotal write FValorTotal;
  end;

  [Tabela('ITENS_PEDIDO')]
  TItemPedidoTeste = class
  private
    FPedidoId: string;
    FNumeroItem: Integer;
    FQuantidade: Double;
  public
    [ChavePrimaria(0)]
    [Coluna('PEDIDO_ID')]
    property PedidoId: string read FPedidoId write FPedidoId;

    [ChavePrimaria(1)]
    [Coluna('NUMERO_ITEM')]
    property NumeroItem: Integer read FNumeroItem write FNumeroItem;

    [Coluna('QUANTIDADE')]
    property Quantidade: Double read FQuantidade write FQuantidade;
  end;

  // Entidade intencionalmente sem [Tabela] — para teste de erro
  TEntidadeSemTabela = class
  private
    FId: Integer;
  public
    [ChavePrimaria]
    property Id: Integer read FId write FId;
  end;

  // Entidade sem chave primária — para teste de erro
  [Tabela('SEM_CHAVE')]
  TEntidadeSemChave = class
  private
    FNome: string;
  public
    [Coluna('NOME')]
    property Nome: string read FNome write FNome;
  end;

// ============================================================================
// Suite de testes
// ============================================================================

  [TestFixture]
  TTestesMetadados = class
  strict private
    FResolvedor: TResolvedorMetadados;

  public
    [Setup]
    procedure Configurar;

    [TearDown]
    procedure Limpar;

    // ── Resolução básica ──────────────────────────────────────────────────

    [Test]
    procedure DeveResolverNomeTabelaCorretamente;

    [Test]
    procedure DeveResolverSchemaDaTabelaCorretamente;

    [Test]
    procedure DeveResolverNomeQualificadoSemSchema;

    [Test]
    procedure DeveResolverNomeQualificadoComSchema;

    [Test]
    procedure DeveResolverPropriedadesMapeadas;

    [Test]
    procedure DeveIgnorarPropriedadesNaoMapeadas;

    // ── Chaves primárias ──────────────────────────────────────────────────

    [Test]
    procedure DeveIdentificarChavePrimariaSimples;

    [Test]
    procedure DeveIdentificarEstrategiaAutoIncremento;

    [Test]
    procedure DeveIdentificarEstrategiaUuidV7;

    [Test]
    procedure DeveResolverChavePrimariaComposta;

    [Test]
    procedure DeveOrdenarChavesCompostasCorretamente;

    // ── Flags de comportamento ────────────────────────────────────────────

    [Test]
    procedure DeveIdentificarPropriedadeCriadoEm;

    [Test]
    procedure DeveIdentificarPropriedadeAtualizadoEm;

    [Test]
    procedure DeveIdentificarPropriedadeSomenteLeitura;

    [Test]
    procedure DeveIdentificarPropriedadeObrigatoria;

    // ── Flags da entidade ─────────────────────────────────────────────────

    [Test]
    procedure DeveSinalizarPossuiCriadoEm;

    [Test]
    procedure DeveSinalizarPossuiAtualizadoEm;

    // ── Lookup ────────────────────────────────────────────────────────────

    [Test]
    procedure DeveBuscarPropriedadePorNomeColuna;

    [Test]
    procedure DeveBuscarPropriedadePorNomeDaProperty;

    [Test]
    procedure DeveRetornarNilParaColunaInexistente;

    // ── Erros esperados ───────────────────────────────────────────────────

    [Test]
    procedure DeveLancarExcecaoParaEntidadeSemAtributoTabela;

    [Test]
    procedure DeveLancarExcecaoParaEntidadeSemChavePrimaria;

    // ── Cache ─────────────────────────────────────────────────────────────

    [Test]
    procedure DeveRetornarMesmaInstanciaDoCache;

    [Test]
    procedure DeveInvalidarEntradaDoCache;

    [Test]
    procedure DeveInvalidarCacheCompleto;

    [Test]
    procedure DeveContarEntidadesEmCache;
  end;

  // ── Testes de UUID v7 ─────────────────────────────────────────────────────

  [TestFixture]
  TTestesUuidV7 = class
  public
    [Test]
    procedure DeveGerarUuidComFormatoCorreto;

    [Test]
    procedure DeveGerarUuidsUnicos;

    [Test]
    procedure DeveGerarUuidsMonotonicos;

    [Test]
    procedure DeveConterVersao7NoPosicaoCorreta;

    [Test]
    procedure DeveConterVarianteRFC4122;
  end;

implementation

uses
  System.Threading,
  System.RegularExpressions;

{ TTestesMetadados }

procedure TTestesMetadados.Configurar;
begin
  FResolvedor := TResolvedorMetadados.Create;
  TCacheMetadados.Instancia.InvalidarTudo;
end;

procedure TTestesMetadados.Limpar;
begin
  FResolvedor.Free;
  TCacheMetadados.Instancia.InvalidarTudo;
end;

procedure TTestesMetadados.DeveResolverNomeTabelaCorretamente;
var
  LMetadado: IOrmMetadadoEntidade;
begin
  LMetadado := TCacheMetadados.Instancia.Resolver(TClienteTeste);
  Assert.AreEqual('CLIENTES', LMetadado.NomeTabela);
end;

procedure TTestesMetadados.DeveResolverSchemaDaTabelaCorretamente;
var
  LMetadado: IOrmMetadadoEntidade;
begin
  LMetadado := TCacheMetadados.Instancia.Resolver(TPedidoTeste);
  Assert.AreEqual('COMERCIAL', LMetadado.NomeSchema);
end;

procedure TTestesMetadados.DeveResolverNomeQualificadoSemSchema;
var
  LMetadado: IOrmMetadadoEntidade;
begin
  LMetadado := TCacheMetadados.Instancia.Resolver(TClienteTeste);
  Assert.AreEqual('CLIENTES', LMetadado.NomeQualificado);
end;

procedure TTestesMetadados.DeveResolverNomeQualificadoComSchema;
var
  LMetadado: IOrmMetadadoEntidade;
begin
  LMetadado := TCacheMetadados.Instancia.Resolver(TPedidoTeste);
  Assert.AreEqual('COMERCIAL.PEDIDOS', LMetadado.NomeQualificado);
end;

procedure TTestesMetadados.DeveResolverPropriedadesMapeadas;
var
  LMetadado: IOrmMetadadoEntidade;
  LProps: TArray<IOrmMetadadoPropriedade>;
begin
  LMetadado := TCacheMetadados.Instancia.Resolver(TClienteTeste);
  LProps    := LMetadado.Propriedades;

  // TClienteTeste tem 6 properties mapeadas (Transiente é ignorada)
  Assert.AreEqual(6, Length(LProps),
    'Deve resolver exatamente 6 propriedades mapeadas');
end;

procedure TTestesMetadados.DeveIgnorarPropriedadesNaoMapeadas;
var
  LMetadado: IOrmMetadadoEntidade;
  LProp: IOrmMetadadoPropriedade;
begin
  LMetadado := TCacheMetadados.Instancia.Resolver(TClienteTeste);
  LProp     := LMetadado.PropriedadePorNome('Transiente');

  Assert.IsNull(LProp,
    'Property marcada com [NaoMapear] não deve aparecer nos metadados');
end;

procedure TTestesMetadados.DeveIdentificarChavePrimariaSimples;
var
  LMetadado: IOrmMetadadoEntidade;
  LChaves: TArray<IOrmMetadadoPropriedade>;
begin
  LMetadado := TCacheMetadados.Instancia.Resolver(TClienteTeste);
  LChaves   := LMetadado.Chaves;

  Assert.AreEqual(1, Length(LChaves), 'Deve ter exatamente 1 chave primária');
  Assert.AreEqual('ID', LChaves[0].NomeColuna);
  Assert.IsTrue(LChaves[0].EhChavePrimaria);
end;

procedure TTestesMetadados.DeveIdentificarEstrategiaAutoIncremento;
var
  LMetadado: IOrmMetadadoEntidade;
  LChaves: TArray<IOrmMetadadoPropriedade>;
begin
  LMetadado := TCacheMetadados.Instancia.Resolver(TClienteTeste);
  LChaves   := LMetadado.Chaves;

  Assert.AreEqual(TEstategiaChave.ecAutoIncremento,
    LChaves[0].EstrategiaChave,
    'Estratégia deve ser AutoIncremento');
  Assert.IsTrue(LChaves[0].EhAutoIncremento);
end;

procedure TTestesMetadados.DeveIdentificarEstrategiaUuidV7;
var
  LMetadado: IOrmMetadadoEntidade;
  LChaves: TArray<IOrmMetadadoPropriedade>;
begin
  LMetadado := TCacheMetadados.Instancia.Resolver(TPedidoTeste);
  LChaves   := LMetadado.Chaves;

  Assert.AreEqual(TEstategiaChave.ecUuidV7,
    LChaves[0].EstrategiaChave,
    'Estratégia deve ser UuidV7');
end;

procedure TTestesMetadados.DeveResolverChavePrimariaComposta;
var
  LMetadado: IOrmMetadadoEntidade;
  LChaves: TArray<IOrmMetadadoPropriedade>;
begin
  LMetadado := TCacheMetadados.Instancia.Resolver(TItemPedidoTeste);
  LChaves   := LMetadado.Chaves;

  Assert.AreEqual(2, Length(LChaves),
    'TItemPedidoTeste deve ter 2 campos na chave composta');
end;

procedure TTestesMetadados.DeveOrdenarChavesCompostasCorretamente;
var
  LMetadado: IOrmMetadadoEntidade;
  LChaves: TArray<IOrmMetadadoPropriedade>;
begin
  LMetadado := TCacheMetadados.Instancia.Resolver(TItemPedidoTeste);
  LChaves   := LMetadado.Chaves;

  Assert.AreEqual('PEDIDO_ID', LChaves[0].NomeColuna,
    'Primeira chave deve ser PEDIDO_ID (ordem 0)');
  Assert.AreEqual('NUMERO_ITEM', LChaves[1].NomeColuna,
    'Segunda chave deve ser NUMERO_ITEM (ordem 1)');
end;

procedure TTestesMetadados.DeveIdentificarPropriedadeCriadoEm;
var
  LMetadado: IOrmMetadadoEntidade;
  LProp: IOrmMetadadoPropriedade;
begin
  LMetadado := TCacheMetadados.Instancia.Resolver(TClienteTeste);
  LProp     := LMetadado.PropriedadePorColuna('CRIADO_EM');

  Assert.IsNotNull(LProp);
  Assert.IsTrue(LProp.EhSomenteLeitura,
    'CriadoEm deve ser somente leitura');
end;

procedure TTestesMetadados.DeveIdentificarPropriedadeAtualizadoEm;
var
  LMetadado: IOrmMetadadoEntidade;
begin
  LMetadado := TCacheMetadados.Instancia.Resolver(TClienteTeste);
  Assert.IsTrue(LMetadado.PossuiAtualizadoEm);
end;

procedure TTestesMetadados.DeveIdentificarPropriedadeSomenteLeitura;
var
  LMetadado: IOrmMetadadoEntidade;
  LProp: IOrmMetadadoPropriedade;
begin
  LMetadado := TCacheMetadados.Instancia.Resolver(TClienteTeste);
  LProp     := LMetadado.PropriedadePorColuna('CRIADO_EM');

  Assert.IsNotNull(LProp);
  Assert.IsTrue(LProp.EhSomenteLeitura);
end;

procedure TTestesMetadados.DeveIdentificarPropriedadeObrigatoria;
var
  LMetadado: IOrmMetadadoEntidade;
  LProp: IOrmMetadadoPropriedade;
begin
  LMetadado := TCacheMetadados.Instancia.Resolver(TClienteTeste);
  LProp     := LMetadado.PropriedadePorColuna('NOME');

  Assert.IsNotNull(LProp);
  Assert.IsTrue(LProp.EhObrigatorio);
end;

procedure TTestesMetadados.DeveSinalizarPossuiCriadoEm;
var
  LMetadado: IOrmMetadadoEntidade;
begin
  LMetadado := TCacheMetadados.Instancia.Resolver(TClienteTeste);
  Assert.IsTrue(LMetadado.PossuiCriadoEm);
end;

procedure TTestesMetadados.DeveSinalizarPossuiAtualizadoEm;
var
  LMetadado: IOrmMetadadoEntidade;
begin
  LMetadado := TCacheMetadados.Instancia.Resolver(TClienteTeste);
  Assert.IsTrue(LMetadado.PossuiAtualizadoEm);
end;

procedure TTestesMetadados.DeveBuscarPropriedadePorNomeColuna;
var
  LMetadado: IOrmMetadadoEntidade;
  LProp: IOrmMetadadoPropriedade;
begin
  LMetadado := TCacheMetadados.Instancia.Resolver(TClienteTeste);
  LProp     := LMetadado.PropriedadePorColuna('NOME');

  Assert.IsNotNull(LProp);
  Assert.AreEqual('Nome', LProp.Nome);
end;

procedure TTestesMetadados.DeveBuscarPropriedadePorNomeDaProperty;
var
  LMetadado: IOrmMetadadoEntidade;
  LProp: IOrmMetadadoPropriedade;
begin
  LMetadado := TCacheMetadados.Instancia.Resolver(TClienteTeste);
  LProp     := LMetadado.PropriedadePorNome('Nome');

  Assert.IsNotNull(LProp);
  Assert.AreEqual('NOME', LProp.NomeColuna);
end;

procedure TTestesMetadados.DeveRetornarNilParaColunaInexistente;
var
  LMetadado: IOrmMetadadoEntidade;
  LProp: IOrmMetadadoPropriedade;
begin
  LMetadado := TCacheMetadados.Instancia.Resolver(TClienteTeste);
  LProp     := LMetadado.PropriedadePorColuna('COLUNA_INEXISTENTE');

  Assert.IsNull(LProp);
end;

procedure TTestesMetadados.DeveLancarExcecaoParaEntidadeSemAtributoTabela;
begin
  Assert.WillRaise(
    procedure
    begin
      TCacheMetadados.Instancia.Resolver(TEntidadeSemTabela);
    end,
    EOrmMapeamentoExcecao,
    'Deve lançar EOrmMapeamentoExcecao para entidade sem [Tabela]');
end;

procedure TTestesMetadados.DeveLancarExcecaoParaEntidadeSemChavePrimaria;
begin
  Assert.WillRaise(
    procedure
    begin
      TCacheMetadados.Instancia.Resolver(TEntidadeSemChave);
    end,
    EOrmMapeamentoExcecao,
    'Deve lançar EOrmMapeamentoExcecao para entidade sem chave primária');
end;

procedure TTestesMetadados.DeveRetornarMesmaInstanciaDoCache;
var
  LMeta1, LMeta2: IOrmMetadadoEntidade;
begin
  LMeta1 := TCacheMetadados.Instancia.Resolver(TClienteTeste);
  LMeta2 := TCacheMetadados.Instancia.Resolver(TClienteTeste);

  Assert.AreSame(LMeta1, LMeta2,
    'Deve retornar a mesma interface (mesma instância cacheada)');
end;

procedure TTestesMetadados.DeveInvalidarEntradaDoCache;
var
  LMeta1, LMeta2: IOrmMetadadoEntidade;
begin
  LMeta1 := TCacheMetadados.Instancia.Resolver(TClienteTeste);
  TCacheMetadados.Instancia.Invalidar(TClienteTeste);
  LMeta2 := TCacheMetadados.Instancia.Resolver(TClienteTeste);

  Assert.AreNotSame(LMeta1, LMeta2,
    'Após invalidação, deve retornar nova instância');
end;

procedure TTestesMetadados.DeveInvalidarCacheCompleto;
begin
  TCacheMetadados.Instancia.Resolver(TClienteTeste);
  TCacheMetadados.Instancia.Resolver(TPedidoTeste);
  TCacheMetadados.Instancia.InvalidarTudo;

  Assert.AreEqual(0, TCacheMetadados.Instancia.TotalEmCache,
    'Cache deve estar vazio após invalidação completa');
end;

procedure TTestesMetadados.DeveContarEntidadesEmCache;
begin
  TCacheMetadados.Instancia.InvalidarTudo;
  TCacheMetadados.Instancia.Resolver(TClienteTeste);
  TCacheMetadados.Instancia.Resolver(TPedidoTeste);

  Assert.AreEqual(2, TCacheMetadados.Instancia.TotalEmCache);
end;

{ TTestesUuidV7 }

procedure TTestesUuidV7.DeveGerarUuidComFormatoCorreto;
var
  LGerador: IOrmGeradorValor;
  LUuid: string;
  LRegex: TRegEx;
begin
  LGerador := TFabricaGeradores.ObterGerador(ecUuidV7);
  LUuid    := LGerador.Gerar;

  // Formato: xxxxxxxx-xxxx-7xxx-yxxx-xxxxxxxxxxxx
  LRegex := TRegEx.Create(
    '^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    [roIgnoreCase]);

  Assert.IsTrue(LRegex.IsMatch(LUuid),
    Format('UUID gerado não tem formato válido v7: %s', [LUuid]));
end;

procedure TTestesUuidV7.DeveGerarUuidsUnicos;
const
  QUANTIDADE = 1000;
var
  LGerador: IOrmGeradorValor;
  LSet: TDictionary<string, Boolean>;
  LIndice: Integer;
  LUuid: string;
begin
  LGerador := TFabricaGeradores.ObterGerador(ecUuidV7);
  LSet     := TDictionary<string, Boolean>.Create;
  try
    for LIndice := 1 to QUANTIDADE do
    begin
      LUuid := LGerador.Gerar;
      Assert.IsFalse(LSet.ContainsKey(LUuid),
        Format('UUID duplicado detectado na iteração %d: %s',
          [LIndice, LUuid]));
      LSet.Add(LUuid, True);
    end;
  finally
    LSet.Free;
  end;
end;

procedure TTestesUuidV7.DeveGerarUuidsMonotonicos;
var
  LGerador: IOrmGeradorValor;
  LAnterior, LAtual: string;
  LIndice: Integer;
begin
  LGerador  := TFabricaGeradores.ObterGerador(ecUuidV7);
  LAnterior := LGerador.Gerar;

  for LIndice := 1 to 100 do
  begin
    LAtual := LGerador.Gerar;
    Assert.IsTrue(
      String.CompareOrdinal(LAtual, LAnterior) >= 0,
      Format('UUID v7 não é monotônico: anterior=%s atual=%s',
        [LAnterior, LAtual]));
    LAnterior := LAtual;
  end;
end;

procedure TTestesUuidV7.DeveConterVersao7NoPosicaoCorreta;
var
  LGerador: IOrmGeradorValor;
  LUuid: string;
  LCaractereVersao: Char;
begin
  LGerador         := TFabricaGeradores.ObterGerador(ecUuidV7);
  LUuid            := LGerador.Gerar;
  // Posição 14 (0-indexed) = caractere após 'xxxxxxxx-xxxx-'
  LCaractereVersao := LUuid[15]; // 1-indexed em Delphi

  Assert.AreEqual('7', LCaractereVersao,
    Format('Versão do UUID deve ser 7, encontrado: %s na posição 15 de %s',
      [LCaractereVersao, LUuid]));
end;

procedure TTestesUuidV7.DeveConterVarianteRFC4122;
var
  LGerador: IOrmGeradorValor;
  LUuid: string;
  LCaractere: Char;
begin
  LGerador    := TFabricaGeradores.ObterGerador(ecUuidV7);
  LUuid       := LGerador.Gerar;
  // Posição 19 (1-indexed) = primeiro caractere do grupo de variante
  LCaractere  := LUuid[20];

  Assert.IsTrue(
    CharInSet(LCaractere, ['8', '9', 'a', 'b', 'A', 'B']),
    Format('Variante RFC 4122 inválida: "%s" em "%s"',
      [LCaractere, LUuid]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesMetadados);
  TDUnitX.RegisterTestFixture(TTestesUuidV7);

end.
