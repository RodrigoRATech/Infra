program Exemplo02_Query_Fluente;

{$APPTYPE CONSOLE}

{
  Exemplo 02 — Query Fluente
  Demonstra: filtros simples, AND/OR, IN, LIKE,
             paginação, ordenação e contagem.
}

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Mapping.Atributos,
  Infra.ORM.Core.Session.Fabrica,
  Infra.ORM.FireDAC.Configuracao,
  Infra.ORM.FireDAC.Fabrica,
  Infra.ORM.Firebird.Dialeto;

type

  [Tabela('EX_PRODUTOS')]
  TProduto = class
  private
    FId: Int64;
    FNome: string;
    FCategoria: string;
    FPreco: Double;
    FEstoque: Integer;
    FAtivo: Boolean;
    FCriadoEm: TDateTime;
  public
    [ChavePrimaria] [AutoIncremento] [Coluna('ID')]
    property Id: Int64 read FId write FId;
    [Coluna('NOME')] [Obrigatorio] [Tamanho(200)]
    property Nome: string read FNome write FNome;
    [Coluna('CATEGORIA')] [Tamanho(80)]
    property Categoria: string read FCategoria write FCategoria;
    [Coluna('PRECO')] [Precisao(18,2)]
    property Preco: Double read FPreco write FPreco;
    [Coluna('ESTOQUE')]
    property Estoque: Integer read FEstoque write FEstoque;
    [Coluna('ATIVO')]
    property Ativo: Boolean read FAtivo write FAtivo;
    [Coluna('CRIADO_EM')] [CriadoEm] [SomenteLeitura]
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
  end;

var
  GFabrica: IOrmFabricaSessao;

procedure Inicializar;
begin
  var LConfig := TConfiguracaoFirebird.Criar
    .Servidor('localhost')
    .BancoDados('C:\ORM\exemplos.fdb')
    .Usuario('SYSDBA')
    .Senha('masterkey')
    .Construir;

  GFabrica := TOrmFabricaSessao.Configurar
    .UsarConexao(TFabricaConexaoFireDAC.Create(LConfig))
    .UsarDialeto(TDialetoFirebird.Create)
    .Construir;
end;

procedure ImprimirProdutos(const ATitulo: string;
  AProdutos: TObjectList<TProduto>);
var
  LP: TProduto;
begin
  Writeln('');
  Writeln('── ' + ATitulo + ' (' + IntToStr(AProdutos.Count) + ' resultados)');
  for LP in AProdutos do
    Writeln(Format('  [%3d] %-30s  R$ %8.2f  %-15s  Estq:%3d  %s',
      [LP.Id, LP.Nome, LP.Preco, LP.Categoria,
       LP.Estoque, BoolToStr(LP.Ativo, True)]));
end;

begin
  try
    Writeln('╔══════════════════════════════════════════╗');
    Writeln('║  Infra.ORM — Exemplo 02: Query Fluente  ║');
    Writeln('╚══════════════════════════════════════════╝');

    Inicializar;
    var LSessao := GFabrica.CriarSessao;

    // ── 1. Todos os produtos ativos ────────────────────────────────────────
    var LProdutos := LSessao.Consultar<TProduto>
      .Onde('ATIVO', ofIgual, TValue.From<Boolean>(True))
      .OrdenarPor('NOME')
      .Listar;
    ImprimirProdutos('Ativos ordenados por nome', LProdutos);
    LProdutos.Free;

    // ── 2. Produtos caros em categorias específicas ────────────────────────
    LProdutos := LSessao.Consultar<TProduto>
      .OndeEm('CATEGORIA', [
        TValue.From<string>('Eletrônicos'),
        TValue.From<string>('Informática')])
      .E('PRECO', ofMaior, TValue.From<Double>(1000.0))
      .OrdenarPor('PRECO', doDescendente)
      .Listar;
    ImprimirProdutos('Eletrônicos/Informática > R$1.000', LProdutos);
    LProdutos.Free;

    // ── 3. Busca por nome (LIKE) ───────────────────────────────────────────
    LProdutos := LSessao.Consultar<TProduto>
      .Onde('NOME', ofContem, TValue.From<string>('Samsung'))
      .OrdenarPor('PRECO')
      .Listar;
    ImprimirProdutos('Produtos com "Samsung" no nome', LProdutos);
    LProdutos.Free;

    // ── 4. Paginação — página 2 com 5 itens por página ────────────────────
    LProdutos := LSessao.Consultar<TProduto>
      .Onde('ATIVO', ofIgual, TValue.From<Boolean>(True))
      .OrdenarPor('ID')
      .Pular(5)    // OFFSET 5 → página 2
      .Pegar(5)    // LIMIT 5
      .Listar;
    ImprimirProdutos('Página 2 (5 por página)', LProdutos);
    LProdutos.Free;

    // ── 5. PrimeiroOuNulo ─────────────────────────────────────────────────
    var LPrimeiro := LSessao.Consultar<TProduto>
      .Onde('CATEGORIA', ofIgual, TValue.From<string>('Eletrônicos'))
      .OrdenarPor('PRECO', doDescendente)
      .PrimeiroOuNulo;

    Writeln('');
    Writeln('── Produto mais caro em Eletrônicos:');
    if Assigned(LPrimeiro) then
    begin
      Writeln(Format('  %s — R$ %.2f', [LPrimeiro.Nome, LPrimeiro.Preco]));
      LPrimeiro.Free;
    end
    else
      Writeln('  (nenhum encontrado)');

    // ── 6. Contar ─────────────────────────────────────────────────────────
    var LTotal := LSessao.Consultar<TProduto>
      .Onde('ATIVO', ofIgual, TValue.From<Boolean>(True))
      .E('ESTOQUE', ofMaior, TValue.From<Integer>(0))
      .Contar;
    Writeln('');
    Writeln(Format('── Total de produtos ativos com estoque: %d', [LTotal]));

    // ── 7. Existe ─────────────────────────────────────────────────────────
    var LExiste := LSessao.Consultar<TProduto>
      .Onde('NOME', ofIgual, TValue.From<string>('iPhone 15 Pro'))
      .Existe;
    Writeln(Format('── iPhone 15 Pro cadastrado: %s',
      [BoolToStr(LExiste, True)]));

    // ── 8. Grupos (A AND B) OR (C AND D) ──────────────────────────────────
    LProdutos := LSessao.Consultar<TProduto>
      .IniciarGrupoE
        .Onde('CATEGORIA', ofIgual, TValue.From<string>('Eletrônicos'))
        .E('PRECO', ofMenorOuIgual, TValue.From<Double>(3000.0))
      .FecharGrupo
      .IniciarGrupoOu
        .Onde('CATEGORIA', ofIgual, TValue.From<string>('Informática'))
        .E('PRECO', ofMenorOuIgual, TValue.From<Double>(2000.0))
      .FecharGrupo
      .OrdenarPor('CATEGORIA')
      .OrdenarPor('PRECO')
      .Listar;
    ImprimirProdutos(
      '(Eletrônicos ≤ R$3.000) OR (Informática ≤ R$2.000)',
      LProdutos);
    LProdutos.Free;

    // ── 9. Sem estoque (IS NULL ou zero) ──────────────────────────────────
    LProdutos := LSessao.Consultar<TProduto>
      .Onde('ESTOQUE', ofMenorOuIgual, TValue.From<Integer>(0))
      .Ou('ESTOQUE', ofIgual, TValue.From<Integer>(0))
      .OrdenarPor('NOME')
      .Listar;
    ImprimirProdutos('Produtos sem estoque', LProdutos);
    LProdutos.Free;

    Writeln('');
    Writeln('Exemplo 02 concluído com sucesso.');
  except
    on E: Exception do
      Writeln('ERRO: ', E.ClassName, ': ', E.Message);
  end;
  Readln;
end.
