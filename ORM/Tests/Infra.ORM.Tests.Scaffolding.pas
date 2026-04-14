unit Infra.ORM.Tests.Scaffolding;

{
  Responsabilidade:
    Testes unitários do scaffolding.
    Usa schemas sintéticos (sem banco real) para testar
    o gerador de nomes, mapeador de tipos e gerador de código.
}

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Scaffolding.Schema.Contratos,
  Infra.ORM.Scaffolding.Mapeador.Tipo,
  Infra.ORM.Scaffolding.Gerador.Nome,
  Infra.ORM.Scaffolding.Gerador.Entidade,
  Infra.ORM.Scaffolding.Configuracao;

type

  [TestFixture]
  TTestesGeradorNome = class
  public

    // ── SNAKE_CASE → PascalCase ───────────────────────────────────────────

    [Test]
    procedure DeveConverterTabelaSimples;

    [Test]
    procedure DeveConverterTabelaComPrefixoTB;

    [Test]
    procedure DeveConverterTabelaComMultiplosPrefixos;

    [Test]
    procedure DeveConverterColunaNomeComposto;

    [Test]
    procedure DeveEscaparPalavraReservada;

    [Test]
    procedure DeveGerarNomeCampoPrivado;

    [Test]
    procedure DeveGerarNomeUnitSemPrefixoClasse;
  end;

  [TestFixture]
  TTestesMappeadorTipo = class
  public

    // ── Firebird ──────────────────────────────────────────────────────────

    [Test]
    procedure DeveMapearIntegerFirebird;

    [Test]
    procedure DeveMapearBigIntFirebird;

    [Test]
    procedure DeveMapearVarcharFirebird;

    [Test]
    procedure DeveMapearTimestampFirebird;

    [Test]
    procedure DeveMapearNumericComEscalaFirebird;

    [Test]
    procedure DeveMapearBooleanFirebird;

    [Test]
    procedure DeveMapearBlobFirebird;

    [Test]
    procedure DeveUsarStringParaTipoDesconhecido;

    // ── MySQL ─────────────────────────────────────────────────────────────

    [Test]
    procedure DeveMapearIntegerMySQL;

    [Test]
    procedure DeveMapearBigIntMySQL;

    [Test]
    procedure DeveMapearVarcharMySQL;

    [Test]
    procedure DeveMapearDatetimeMySQL;

    [Test]
    procedure DeveMapearDecimalComEscalaMySQL;

    // ── UUID ──────────────────────────────────────────────────────────────

    [Test]
    procedure DeveDetectarCandidatoUUID;

    [Test]
    procedure NaoDeveDetectarUUIDParaVarcharPequeno;
  end;

  [TestFixture]
  TTestesGeradorEntidade = class
  strict private
    FConfig: TConfiguracaoScaffolding;

    function CriarTabelaSimples: IOrmTabelaSchema;
    function CriarTabelaComCamposAuditoria: IOrmTabelaSchema;
    function CriarTabelaSemPK: IOrmTabelaSchema;
    function CriarColuna(
      const ANome, ATipo: string;
      APrecisao: Integer = 0;
      AEscala: Integer = 0;
      ANullable: Boolean = True;
      AEhPK: Boolean = False;
      AAutoInc: Boolean = False): IOrmColunaSchema;

  public
    [Setup]
    procedure Configurar;

    // ── Geração de código ─────────────────────────────────────────────────

    [Test]
    procedure DeveGerarUnitComNomeCorreto;

    [Test]
    procedure DeveGerarAtributoTabela;

    [Test]
    procedure DeveGerarAtributoChavePrimaria;

    [Test]
    procedure DeveGerarAtributoAutoIncremento;

    [Test]
    procedure DeveGerarAtributoColuna;

    [Test]
    procedure DeveGerarAtributoObrigatorio;

    [Test]
    procedure DeveGerarAtributoTamanho;

    [Test]
    procedure DeveGerarAtributoCriadoEm;

    [Test]
    procedure DeveGerarAtributoAtualizadoEm;

    [Test]
    procedure DeveGerarAtributoDeletadoEm;

    [Test]
    procedure DeveGerarPropertyComTipoCorreto;

    [Test]
    procedure DeveGerarAvisoParaTabelaSemPK;

    [Test]
    procedure DeveGerarAvisoParaTipoNaoMapeado;
  end;

implementation

uses
  Infra.ORM.Core.Logging.Contrato;

// ── Helpers internos ──────────────────────────────────────────────────────────

function CriarColunaRapida(
  const ANome, ATipo: string;
  APrecisao: Integer = 0;
  AEscala: Integer = 0;
  ANullable: Boolean = True;
  AEhPK: Boolean = False;
  AAutoInc: Boolean = False): IOrmColunaSchema;
var
  LC: TColunaSchema;
begin
  LC                  := TColunaSchema.Create;
  LC.FNomeColuna      := ANome;
  LC.FTipoSQL         := ATipo;
  LC.FTamanhoPrecisao := APrecisao;
  LC.FTamanhoEscala   := AEscala;
  LC.FNullable        := ANullable;
  LC.FEhChavePrimaria := AEhPK;
  LC.FEhAutoIncremento := AAutoInc;
  LC.FPosicao         := 0;
  Result := LC;
end;

{ TTestesGeradorNome }

procedure TTestesGeradorNome.DeveConverterTabelaSimples;
var
  LGerador: TGeradorNome;
begin
  LGerador := TGeradorNome.Create('T', nil);
  try
    Assert.AreEqual('TClientes',
      LGerador.NomeClasseParaTabela('CLIENTES'));
  finally
    LGerador.Free;
  end;
end;

procedure TTestesGeradorNome.DeveConverterTabelaComPrefixoTB;
var
  LGerador: TGeradorNome;
begin
  LGerador := TGeradorNome.Create('T', ['TB_']);
  try
    Assert.AreEqual('TClientes',
      LGerador.NomeClasseParaTabela('TB_CLIENTES'),
      'Deve remover prefixo TB_ do nome da tabela');
  finally
    LGerador.Free;
  end;
end;

procedure TTestesGeradorNome.DeveConverterTabelaComMultiplosPrefixos;
var
  LGerador: TGeradorNome;
begin
  LGerador := TGeradorNome.Create('T', ['TB_', 'TBL_', 'CAD_']);
  try
    Assert.AreEqual('TPedidos',
      LGerador.NomeClasseParaTabela('CAD_PEDIDOS'));
    Assert.AreEqual('TProdutos',
      LGerador.NomeClasseParaTabela('TBL_PRODUTOS'));
  finally
    LGerador.Free;
  end;
end;

procedure TTestesGeradorNome.DeveConverterColunaNomeComposto;
var
  LGerador: TGeradorNome;
begin
  LGerador := TGeradorNome.Create;
  try
    Assert.AreEqual('NomeCompleto',
      LGerador.NomePropriedadeParaColuna('NOME_COMPLETO'));
    Assert.AreEqual('DataNascimento',
      LGerador.NomePropriedadeParaColuna('DATA_NASCIMENTO'));
    Assert.AreEqual('CriadoEm',
      LGerador.NomePropriedadeParaColuna('CRIADO_EM'));
  finally
    LGerador.Free;
  end;
end;

procedure TTestesGeradorNome.DeveEscaparPalavraReservada;
var
  LGerador: TGeradorNome;
begin
  LGerador := TGeradorNome.Create;
  try
    Assert.AreEqual('String_',
      LGerador.NomePropriedadeParaColuna('STRING'),
      'Palavra reservada deve receber sufixo _');
    Assert.AreEqual('Type_',
      LGerador.NomePropriedadeParaColuna('TYPE'));
    Assert.AreEqual('End_',
      LGerador.NomePropriedadeParaColuna('END'));
  finally
    LGerador.Free;
  end;
end;

procedure TTestesGeradorNome.DeveGerarNomeCampoPrivado;
var
  LGerador: TGeradorNome;
begin
  LGerador := TGeradorNome.Create;
  try
    Assert.AreEqual('FNomeCompleto',
      LGerador.NomeCampoPrivado('NomeCompleto'));
    Assert.AreEqual('FId',
      LGerador.NomeCampoPrivado('Id'));
  finally
    LGerador.Free;
  end;
end;

procedure TTestesGeradorNome.DeveGerarNomeUnitSemPrefixoClasse;
var
  LGerador: TGeradorNome;
begin
  LGerador := TGeradorNome.Create('T', nil);
  try
    Assert.AreEqual('Clientes',
      LGerador.NomeUnitParaClasse('TClientes'),
      'Deve remover o prefixo T do nome da unit');
  finally
    LGerador.Free;
  end;
end;

{ TTestesMappeadorTipo }

procedure TTestesMappeadorTipo.DeveMapearIntegerFirebird;
var
  LR: TResultadoMapeamento;
begin
  LR := TMappeadorTipo.Mapear(tbFirebird, 'INTEGER', 0, 0);
  Assert.AreEqual(tcInteger, LR.TipoColuna);
  Assert.AreEqual('Integer', LR.TipoDelphiStr);
end;

procedure TTestesMappeadorTipo.DeveMapearBigIntFirebird;
var
  LR: TResultadoMapeamento;
begin
  LR := TMappeadorTipo.Mapear(tbFirebird, 'INT64', 0, 0);
  Assert.AreEqual(tcInt64, LR.TipoColuna);
  Assert.AreEqual('Int64', LR.TipoDelphiStr);
end;

procedure TTestesMappeadorTipo.DeveMapearVarcharFirebird;
var
  LR: TResultadoMapeamento;
begin
  LR := TMappeadorTipo.Mapear(tbFirebird, 'VARCHAR', 150, 0);
  Assert.AreEqual(tcString, LR.TipoColuna);
  Assert.AreEqual('string', LR.TipoDelphiStr);
end;

procedure TTestesMappeadorTipo.DeveMapearTimestampFirebird;
var
  LR: TResultadoMapeamento;
begin
  LR := TMappeadorTipo.Mapear(tbFirebird, 'TIMESTAMP', 0, 0);
  Assert.AreEqual(tcDataHora, LR.TipoColuna);
  Assert.AreEqual('TDateTime', LR.TipoDelphiStr);
end;

procedure TTestesMappeadorTipo.DeveMapearNumericComEscalaFirebird;
var
  LR: TResultadoMapeamento;
begin
  LR := TMappeadorTipo.Mapear(tbFirebird, 'NUMERIC', 18, 2);
  Assert.AreEqual(tcDecimal, LR.TipoColuna,
    'NUMERIC com escala deve mapear para tcDecimal');
end;

procedure TTestesMappeadorTipo.DeveMapearBooleanFirebird;
var
  LR: TResultadoMapeamento;
begin
  LR := TMappeadorTipo.Mapear(tbFirebird, 'BOOLEAN', 0, 0);
  Assert.AreEqual(tcBoolean, LR.TipoColuna);
  Assert.AreEqual('Boolean', LR.TipoDelphiStr);
end;

procedure TTestesMappeadorTipo.DeveMapearBlobFirebird;
var
  LR: TResultadoMapeamento;
begin
  LR := TMappeadorTipo.Mapear(tbFirebird, 'BLOB', 0, 0);
  Assert.AreEqual(tcBlob, LR.TipoColuna);
end;

procedure TTestesMappeadorTipo.DeveUsarStringParaTipoDesconhecido;
var
  LR: TResultadoMapeamento;
begin
  LR := TMappeadorTipo.Mapear(tbFirebird, 'TIPO_FANTASMA', 0, 0);
  Assert.AreEqual(tcString, LR.TipoColuna,
    'Tipo desconhecido deve fazer fallback para string');
  Assert.IsFalse(LR.Aviso.IsEmpty,
    'Aviso deve ser preenchido para tipo desconhecido');
end;

procedure TTestesMappeadorTipo.DeveMapearIntegerMySQL;
var
  LR: TResultadoMapeamento;
begin
  LR := TMappeadorTipo.Mapear(tbMySQL, 'INT', 0, 0);
  Assert.AreEqual(tcInteger, LR.TipoColuna);
end;

procedure TTestesMappeadorTipo.DeveMapearBigIntMySQL;
var
  LR: TResultadoMapeamento;
begin
  LR := TMappeadorTipo.Mapear(tbMySQL, 'BIGINT', 0, 0);
  Assert.AreEqual(tcInt64, LR.TipoColuna);
end;

procedure TTestesMappeadorTipo.DeveMapearVarcharMySQL;
var
  LR: TResultadoMapeamento;
begin
  LR := TMappeadorTipo.Mapear(tbMySQL, 'VARCHAR', 200, 0);
  Assert.AreEqual(tcString, LR.TipoColuna);
end;

procedure TTestesMappeadorTipo.DeveMapearDatetimeMySQL;
var
  LR: TResultadoMapeamento;
begin
  LR := TMappeadorTipo.Mapear(tbMySQL, 'DATETIME', 0, 0);
  Assert.AreEqual(tcDataHora, LR.TipoColuna);
  Assert.AreEqual('TDateTime', LR.TipoDelphiStr);
end;

procedure TTestesMappeadorTipo.DeveMapearDecimalComEscalaMySQL;
var
  LR: TResultadoMapeamento;
begin
  LR := TMappeadorTipo.Mapear(tbMySQL, 'DECIMAL', 18, 4);
  Assert.AreEqual(tcDecimal, LR.TipoColuna);
end;

procedure TTestesMappeadorTipo.DeveDetectarCandidatoUUID;
begin
  Assert.IsTrue(
    TMappeadorTipo.EhCandidatoUUID('ID', 'VARCHAR', 36),
    'VARCHAR(36) com nome ID deve ser candidato UUID');
  Assert.IsTrue(
    TMappeadorTipo.EhCandidatoUUID('CLIENTE_ID', 'CHAR', 36),
    'CHAR(36) com nome terminando em _ID deve ser candidato UUID');
end;

procedure TTestesMappeadorTipo.NaoDeveDetectarUUIDParaVarcharPequeno;
begin
  Assert.IsFalse(
    TMappeadorTipo.EhCandidatoUUID('ID', 'VARCHAR', 20),
    'VARCHAR(20) NÃO deve ser candidato UUID');
end;

{ TTestesGeradorEntidade }

procedure TTestesGeradorEntidade.Configurar;
begin
  FConfig := TConfiguracaoScaffolding.Padrao(tbFirebird);
  FConfig.PrefixoUnitModel := 'Model';
  FConfig.Modo             := meRetornarStrings;
end;

function TTestesGeradorEntidade.CriarColuna(
  const ANome, ATipo: string;
  APrecisao, AEscala: Integer;
  ANullable, AEhPK, AAutoInc: Boolean): IOrmColunaSchema;
begin
  Result := CriarColunaRapida(
    ANome, ATipo, APrecisao, AEscala, ANullable, AEhPK, AAutoInc);
end;

function TTestesGeradorEntidade.CriarTabelaSimples: IOrmTabelaSchema;
var
  LT: TTabelaSchema;
begin
  LT             := TTabelaSchema.Create;
  LT.FNomeTabela := 'CLIENTES';
  LT.FNomeSchema := '';
  SetLength(LT.FChavesPrimarias, 1);
  LT.FChavesPrimarias[0] := 'ID';
  SetLength(LT.FColunas, 3);
  LT.FColunas[0] := CriarColuna('ID', 'INTEGER', 0, 0, False, True, True);
  LT.FColunas[1] := CriarColuna('NOME', 'VARCHAR', 150, 0, False, False, False);
  LT.FColunas[2] := CriarColuna('EMAIL', 'VARCHAR', 200, 0, True, False, False);
  Result := LT;
end;

function TTestesGeradorEntidade.CriarTabelaComCamposAuditoria: IOrmTabelaSchema;
var
  LT: TTabelaSchema;
begin
  LT             := TTabelaSchema.Create;
  LT.FNomeTabela := 'PEDIDOS';
  SetLength(LT.FChavesPrimarias, 1);
  LT.FChavesPrimarias[0] := 'ID';
  SetLength(LT.FColunas, 5);
  LT.FColunas[0] := CriarColuna('ID', 'INTEGER', 0, 0, False, True, True);
  LT.FColunas[1] := CriarColuna('TOTAL', 'NUMERIC', 18, 2, False);
  LT.FColunas[2] := CriarColuna('CRIADO_EM', 'TIMESTAMP', 0, 0, True);
  LT.FColunas[3] := CriarColuna('ATUALIZADO_EM', 'TIMESTAMP', 0, 0, True);
  LT.FColunas[4] := CriarColuna('DELETADO_EM', 'TIMESTAMP', 0, 0, True);
  Result := LT;
end;

function TTestesGeradorEntidade.CriarTabelaSemPK: IOrmTabelaSchema;
var
  LT: TTabelaSchema;
begin
  LT             := TTabelaSchema.Create;
  LT.FNomeTabela := 'LOG_ERROS';
  LT.FChavesPrimarias := nil;
  SetLength(LT.FColunas, 2);
  LT.FColunas[0] := CriarColuna('MENSAGEM', 'VARCHAR', 500, 0, True);
  LT.FColunas[1] := CriarColuna('OCORRIDO_EM', 'TIMESTAMP', 0, 0, True);
  Result := LT;
end;

procedure TTestesGeradorEntidade.DeveGerarUnitComNomeCorreto;
var
  LGerador: TGeradorEntidade;
  LResultado: TResultadoGeracaoEntidade;
begin
  LGerador := TGeradorEntidade.Create(FConfig, TLoggerNulo.Create);
  try
    LResultado := LGerador.Gerar(CriarTabelaSimples);

    Assert.IsTrue(LResultado.Sucesso);
    Assert.AreEqual('Model.Clientes.pas', LResultado.NomeArquivo,
      'Nome do arquivo deve seguir o padrão Model.NomeClasse.pas');
    Assert.IsTrue(
      LResultado.ConteudoPas.Contains('unit Model.Clientes;'),
      'Unit deve ter o nome correto no cabeçalho');
  finally
    LGerador.Free;
  end;
end;

procedure TTestesGeradorEntidade.DeveGerarAtributoTabela;
var
  LGerador: TGeradorEntidade;
  LResultado: TResultadoGeracaoEntidade;
begin
  LGerador := TGeradorEntidade.Create(FConfig, TLoggerNulo.Create);
  try
    LResultado := LGerador.Gerar(CriarTabelaSimples);
    Assert.IsTrue(
      LResultado.ConteudoPas.Contains('[Tabela(''CLIENTES'')]'),
      'Deve gerar atributo [Tabela] com nome correto');
  finally
    LGerador.Free;
  end;
end;

procedure TTestesGeradorEntidade.DeveGerarAtributoChavePrimaria;
var
  LGerador: TGeradorEntidade;
  LResultado: TResultadoGeracaoEntidade;
begin
  LGerador := TGeradorEntidade.Create(FConfig, TLoggerNulo.Create);
  try
    LResultado := LGerador.Gerar(CriarTabelaSimples);
    Assert.IsTrue(
      LResultado.ConteudoPas.Contains('[ChavePrimaria]'),
      'Deve gerar atributo [ChavePrimaria]');
  finally
    LGerador.Free;
  end;
end;

procedure TTestesGeradorEntidade.DeveGerarAtributoAutoIncremento;
var
  LGerador: TGeradorEntidade;
  LResultado: TResultadoGeracaoEntidade;
begin
  LGerador := TGeradorEntidade.Create(FConfig, TLoggerNulo.Create);
  try
    LResultado := LGerador.Gerar(CriarTabelaSimples);
    Assert.IsTrue(
      LResultado.ConteudoPas.Contains('[AutoIncremento]'),
      'Deve gerar atributo [AutoIncremento] para PK com autoincremento');
  finally
    LGerador.Free;
  end;
end;

procedure TTestesGeradorEntidade.DeveGerarAtributoColuna;
var
  LGerador: TGeradorEntidade;
  LResultado: TResultadoGeracaoEntidade;
begin
  LGerador := TGeradorEntidade.Create(FConfig, TLoggerNulo.Create);
  try
    LResultado := LGerador.Gerar(CriarTabelaSimples);
    Assert.IsTrue(
      LResultado.ConteudoPas.Contains('[Coluna(''NOME'')]'),
      'Deve gerar atributo [Coluna] com nome da coluna SQL');
  finally
    LGerador.Free;
  end;
end;

procedure TTestesGeradorEntidade.DeveGerarAtributoObrigatorio;
var
  LGerador: TGeradorEntidade;
  LResultado: TResultadoGeracaoEntidade;
begin
  LGerador := TGeradorEntidade.Create(FConfig, TLoggerNulo.Create);
  try
    LResultado := LGerador.Gerar(CriarTabelaSimples);
    Assert.IsTrue(
      LResultado.ConteudoPas.Contains('[Obrigatorio]'),
      'Coluna NOT NULL não-PK deve gerar atributo [Obrigatorio]');
  finally
    LGerador.Free;
  end;
end;

procedure TTestesGeradorEntidade.DeveGerarAtributoTamanho;
var
  LGerador: TGeradorEntidade;
  LResultado: TResultadoGeracaoEntidade;
begin
  LGerador := TGeradorEntidade.Create(FConfig, TLoggerNulo.Create);
  try
    LResultado := LGerador.Gerar(CriarTabelaSimples);
    Assert.IsTrue(
      LResultado.ConteudoPas.Contains('[Tamanho(150)]'),
      'VARCHAR(150) deve gerar atributo [Tamanho(150)]');
  finally
    LGerador.Free;
  end;
end;

procedure TTestesGeradorEntidade.DeveGerarAtributoCriadoEm;
var
  LGerador: TGeradorEntidade;
  LResultado: TResultadoGeracaoEntidade;
begin
  LGerador := TGeradorEntidade.Create(FConfig, TLoggerNulo.Create);
  try
    LResultado := LGerador.Gerar(CriarTabelaComCamposAuditoria);
    Assert.IsTrue(
      LResultado.ConteudoPas.Contains('[CriadoEm]'),
      'Campo CRIADO_EM deve gerar atributo [CriadoEm]');
  finally
    LGerador.Free;
  end;
end;

procedure TTestesGeradorEntidade.DeveGerarAtributoAtualizadoEm;
var
  LGerador: TGeradorEntidade;
  LResultado: TResultadoGeracaoEntidade;
begin
  LGerador := TGeradorEntidade.Create(FConfig, TLoggerNulo.Create);
  try
    LResultado := LGerador.Gerar(CriarTabelaComCamposAuditoria);
    Assert.IsTrue(
      LResultado.ConteudoPas.Contains('[AtualizadoEm]'),
      'Campo ATUALIZADO_EM deve gerar atributo [AtualizadoEm]');
  finally
    LGerador.Free;
  end;
end;

procedure TTestesGeradorEntidade.DeveGerarAtributoDeletadoEm;
var
  LGerador: TGeradorEntidade;
  LResultado: TResultadoGeracaoEntidade;
begin
  LGerador := TGeradorEntidade.Create(FConfig, TLoggerNulo.Create);
  try
    LResultado := LGerador.Gerar(CriarTabelaComCamposAuditoria);
    Assert.IsTrue(
      LResultado.ConteudoPas.Contains('[DeletadoEm]'),
      'Campo DELETADO_EM deve gerar atributo [DeletadoEm]');
  finally
    LGerador.Free;
  end;
end;

procedure TTestesGeradorEntidade.DeveGerarPropertyComTipoCorreto;
var
  LGerador: TGeradorEntidade;
  LResultado: TResultadoGeracaoEntidade;
begin
  LGerador := TGeradorEntidade.Create(FConfig, TLoggerNulo.Create);
  try
    LResultado := LGerador.Gerar(CriarTabelaSimples);
    Assert.IsTrue(
      LResultado.ConteudoPas.Contains('property Nome: string'),
      'Coluna NOME VARCHAR deve gerar property do tipo string');
    Assert.IsTrue(
      LResultado.ConteudoPas.Contains('property Id: Integer'),
      'Coluna ID INTEGER deve gerar property do tipo Integer');
  finally
    LGerador.Free;
  end;
end;

procedure TTestesGeradorEntidade.DeveGerarAvisoParaTabelaSemPK;
var
  LGerador: TGeradorEntidade;
  LResultado: TResultadoGeracaoEntidade;
begin
  LGerador := TGeradorEntidade.Create(FConfig, TLoggerNulo.Create);
  try
    LResultado := LGerador.Gerar(CriarTabelaSemPK);
    Assert.IsTrue(LResultado.Sucesso,
      'Geração deve ser bem-sucedida mesmo sem PK');
    Assert.IsTrue(Length(LResultado.Avisos) > 0,
      'Deve gerar aviso para tabela sem chave primária detectada');
    Assert.IsTrue(
      LResultado.Avisos[0].Contains('chave primária'),
      'Aviso deve mencionar a ausência de chave primária');
  finally
    LGerador.Free;
  end;
end;

procedure TTestesGeradorEntidade.DeveGerarAvisoParaTipoNaoMapeado;
var
  LGerador: TGeradorEntidade;
  LT: TTabelaSchema;
  LResultado: TResultadoGeracaoEntidade;
begin
  LT             := TTabelaSchema.Create;
  LT.FNomeTabela := 'TESTE';
  SetLength(LT.FChavesPrimarias, 1);
  LT.FChavesPrimarias[0] := 'ID';
  SetLength(LT.FColunas, 2);
  LT.FColunas[0] := CriarColuna('ID', 'INTEGER', 0, 0, False, True, True);
  LT.FColunas[1] := CriarColuna('DADO', 'TIPO_EXOTICO', 0, 0, True);

  LGerador := TGeradorEntidade.Create(FConfig, TLoggerNulo.Create);
  try
    LResultado := LGerador.Gerar(LT);
    Assert.IsTrue(LResultado.Sucesso);
    Assert.IsTrue(Length(LResultado.Avisos) > 0,
      'Deve gerar aviso para tipo SQL sem mapeamento definido');
  finally
    LGerador.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesGeradorNome);
  TDUnitX.RegisterTestFixture(TTestesMappeadorTipo);
  TDUnitX.RegisterTestFixture(TTestesGeradorEntidade);

end.
