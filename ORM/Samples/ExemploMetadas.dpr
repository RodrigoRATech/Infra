program ExemploMetadados;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Mapping.Atributos,
  Infra.ORM.Core.Metadata.Cache,
  Infra.ORM.Core.Generators.Contratos;

// Entidade de exemplo
type
  [Tabela('PRODUTOS')]
  TProduto = class
  private
    FId: string;
    FNome: string;
    FPreco: Double;
    FCriadoEm: TDateTime;
  public
    [ChavePrimaria]
    [UuidV7Generator]
    [Coluna('ID')]
    property Id: string read FId write FId;

    [Coluna('NOME')]
    [Obrigatorio]
    [Tamanho(200)]
    property Nome: string read FNome write FNome;

    [Coluna('PRECO')]
    [Precisao(18, 2)]
    property Preco: Double read FPreco write FPreco;

    [Coluna('CRIADO_EM')]
    [CriadoEm]
    [SomenteLeitura]
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
  end;

var
  LMetadado: IOrmMetadadoEntidade;
  LChaves: TArray<IOrmMetadadoPropriedade>;
  LProps: TArray<IOrmMetadadoPropriedade>;
  LProp: IOrmMetadadoPropriedade;
  LGerador: IOrmGeradorValor;
  LProduto: TProduto;

begin
  try
    // ── Resolver metadados ─────────────────────────────────────────────────
    LMetadado := TCacheMetadados.Instancia.Resolver(TProduto);

    Writeln('=== Metadados de TProduto ===');
    Writeln('Tabela    : ', LMetadado.NomeTabela);
    Writeln('Schema    : ', LMetadado.NomeSchema);
    Writeln('Qualific. : ', LMetadado.NomeQualificado);
    Writeln('CriadoEm  : ', BoolToStr(LMetadado.PossuiCriadoEm, True));
    Writeln;

    // ── Chaves ─────────────────────────────────────────────────────────────
    LChaves := LMetadado.Chaves;
    Writeln('=== Chaves primárias ===');
    for LProp in LChaves do
      Writeln(Format('  [%d] %s → coluna: %s | estratégia: %d',
        [LProp.OrdemChave, LProp.Nome, LProp.NomeColuna,
         Ord(LProp.EstrategiaChave)]));
    Writeln;

    // ── Propriedades ───────────────────────────────────────────────────────
    LProps := LMetadado.Propriedades;
    Writeln('=== Propriedades mapeadas ===');
    for LProp in LProps do
      Writeln(Format('  %-20s → %-20s | obrig: %-5s | s/leit: %s',
        [LProp.Nome, LProp.NomeColuna,
         BoolToStr(LProp.EhObrigatorio, True),
         BoolToStr(LProp.EhSomenteLeitura, True)]));
    Writeln;

    // ── Geração de UUID v7 ─────────────────────────────────────────────────
    LGerador := TFabricaGeradores.ObterGerador(ecUuidV7);

    Writeln('=== UUID v7 gerados ===');
    Writeln('  ', LGerador.Gerar);
    Writeln('  ', LGerador.Gerar);
    Writeln('  ', LGerador.Gerar);
    Writeln;

    // ── Accessor RTTI em uso real ──────────────────────────────────────────
    LProduto := TProduto.Create;
    try
      LProp := LMetadado.PropriedadePorNome('Nome');
      LProp.DefinirValor(LProduto, 'Monitor 4K');

      Writeln('=== Acesso via accessor RTTI ===');
      Writeln('Nome definido: ', LProp.ObterValor(LProduto).AsString);
    finally
      LProduto.Free;
    end;

    // ── Verificar cache ────────────────────────────────────────────────────
    Writeln;
    Writeln('=== Cache ===');
    Writeln('Total em cache: ', TCacheMetadados.Instancia.TotalEmCache);
    Writeln('TProduto em cache: ',
      BoolToStr(TCacheMetadados.Instancia.EstaEmCache(TProduto), True));

  except
    on E: Exception do
      Writeln('ERRO: ', E.ClassName, ' → ', E.Message);
  end;

  Readln;
end.
