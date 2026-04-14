unit Infra.ORM.Scaffolding.Schema.MySQL;

{
  Responsabilidade:
    Leitor de schema para MySQL 5.7+ e MariaDB 10.3+.
    Consulta INFORMATION_SCHEMA.COLUMNS e TABLE_CONSTRAINTS.
    Detecta AUTO_INCREMENT e tipos nativos MySQL.
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions,
  Infra.ORM.Core.Logging.Contrato,
  Infra.ORM.Scaffolding.Schema.Contratos;

type

  TLeitorSchemaMySQL = class(TInterfacedObject, IOrmLeitorSchema)
  strict private
    FConexao: IOrmConexao;
    FLogger: IOrmLogger;
    FNomeDatabase: string;

    function ExecutarComParametros(
      const ASQL: string;
      const AParams: array of TPair<string, string>): IOrmLeitorDados;

    function CarregarChavesPrimarias(
      const ANomeTabela: string): TArray<string>;

  public
    constructor Create(
      AConexao: IOrmConexao;
      ALogger: IOrmLogger;
      const ANomeDatabase: string);

    function LerTabelas: TArray<IOrmTabelaSchema>;
    function LerTabela(const ANomeTabela: string): IOrmTabelaSchema;
    function ListarNomesTabelas: TArray<string>;
  end;

implementation

{ TLeitorSchemaMySQL }

constructor TLeitorSchemaMySQL.Create(
  AConexao: IOrmConexao;
  ALogger: IOrmLogger;
  const ANomeDatabase: string);
begin
  inherited Create;

  if not Assigned(AConexao) then
    raise EOrmConexaoExcecao.Create(
      'Conexão não pode ser nil no leitor de schema MySQL.');

  if ANomeDatabase.Trim.IsEmpty then
    raise EOrmConfiguracaoExcecao.Create(
      'Nome do database é obrigatório no leitor de schema MySQL.');

  FConexao      := AConexao;
  FLogger       := ALogger ?? TLoggerNulo.Create;
  FNomeDatabase := ANomeDatabase;
end;

function TLeitorSchemaMySQL.ExecutarComParametros(
  const ASQL: string;
  const AParams: array of TPair<string, string>): IOrmLeitorDados;
var
  LComando: IOrmComando;
  LPar: TPair<string, string>;
begin
  LComando := FConexao.CriarComando;
  LComando.DefinirSQL(ASQL);

  for LPar in AParams do
    LComando.AdicionarParametro(
      LPar.Key, TValue.From<string>(LPar.Value));

  Result := LComando.ExecutarConsulta;
end;

function TLeitorSchemaMySQL.ListarNomesTabelas: TArray<string>;
const
  SQL_TABELAS =
    'SELECT TABLE_NAME ' +
    'FROM INFORMATION_SCHEMA.TABLES ' +
    'WHERE TABLE_SCHEMA = :p_schema ' +
    '  AND TABLE_TYPE = ''BASE TABLE'' ' +
    'ORDER BY TABLE_NAME';
var
  LLeitor: IOrmLeitorDados;
  LNomes: TArray<string>;
  LContador: Integer;
begin
  FLogger.Debug('Listando tabelas do schema MySQL: ' + FNomeDatabase);

  LLeitor   := ExecutarComParametros(SQL_TABELAS,
    [TPair<string,string>.Create(':p_schema', FNomeDatabase)]);
  LContador := 0;

  while LLeitor.Proximo do
  begin
    SetLength(LNomes, LContador + 1);
    LNomes[LContador] := LLeitor.ObterString('TABLE_NAME');
    Inc(LContador);
  end;

  Result := LNomes;
  FLogger.Debug(Format('Encontradas %d tabelas', [LContador]));
end;

function TLeitorSchemaMySQL.CarregarChavesPrimarias(
  const ANomeTabela: string): TArray<string>;
const
  SQL_PKS =
    'SELECT kcu.COLUMN_NAME ' +
    'FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc ' +
    '  JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu ' +
    '    ON kcu.CONSTRAINT_NAME = tc.CONSTRAINT_NAME ' +
    '   AND kcu.TABLE_SCHEMA    = tc.TABLE_SCHEMA ' +
    '   AND kcu.TABLE_NAME      = tc.TABLE_NAME ' +
    'WHERE tc.TABLE_SCHEMA      = :p_schema ' +
    '  AND tc.TABLE_NAME        = :p_tabela ' +
    '  AND tc.CONSTRAINT_TYPE   = ''PRIMARY KEY'' ' +
    'ORDER BY kcu.ORDINAL_POSITION';
var
  LLeitor: IOrmLeitorDados;
  LNomes: TArray<string>;
  LContador: Integer;
begin
  LLeitor := ExecutarComParametros(SQL_PKS, [
    TPair<string,string>.Create(':p_schema', FNomeDatabase),
    TPair<string,string>.Create(':p_tabela', ANomeTabela)]);
  LContador := 0;

  while LLeitor.Proximo do
  begin
    SetLength(LNomes, LContador + 1);
    LNomes[LContador] := LLeitor.ObterString('COLUMN_NAME');
    Inc(LContador);
  end;

  Result := LNomes;
end;

function TLeitorSchemaMySQL.LerTabela(
  const ANomeTabela: string): IOrmTabelaSchema;
const
  SQL_COLUNAS =
    'SELECT ' +
    '  COLUMN_NAME,' +
    '  DATA_TYPE,' +
    '  COALESCE(CHARACTER_MAXIMUM_LENGTH, 0) AS CHAR_LENGTH,' +
    '  COALESCE(NUMERIC_PRECISION, 0)        AS PRECISAO,' +
    '  COALESCE(NUMERIC_SCALE, 0)            AS ESCALA,' +
    '  IS_NULLABLE,' +
    '  EXTRA,' +
    '  COLUMN_DEFAULT,' +
    '  ORDINAL_POSITION ' +
    'FROM INFORMATION_SCHEMA.COLUMNS ' +
    'WHERE TABLE_SCHEMA = :p_schema ' +
    '  AND TABLE_NAME   = :p_tabela ' +
    'ORDER BY ORDINAL_POSITION';
var
  LLeitor: IOrmLeitorDados;
  LTabela: TTabelaSchema;
  LColuna: TColunaSchema;
  LColunas: TArray<IOrmColunaSchema>;
  LContador: Integer;
  LNomeColuna: string;
  LEhPK: Boolean;
  LChaves: TArray<string>;
  LPK: string;
begin
  FLogger.Debug(Format('Lendo schema da tabela MySQL: %s', [ANomeTabela]));

  LChaves   := CarregarChavesPrimarias(ANomeTabela);
  LLeitor   := ExecutarComParametros(SQL_COLUNAS, [
    TPair<string,string>.Create(':p_schema', FNomeDatabase),
    TPair<string,string>.Create(':p_tabela', ANomeTabela)]);
  LContador := 0;

  while LLeitor.Proximo do
  begin
    LNomeColuna := LLeitor.ObterString('COLUMN_NAME');
    LEhPK       := False;

    for LPK in LChaves do
      if LPK.ToUpper = LNomeColuna.ToUpper then
        LEhPK := True;

    LColuna                  := TColunaSchema.Create;
    LColuna.FNomeColuna      := LNomeColuna;
    LColuna.FTipoSQL         := LLeitor.ObterString('DATA_TYPE').ToUpper;
    LColuna.FNullable        :=
      LLeitor.ObterString('IS_NULLABLE').ToUpper = 'YES';
    LColuna.FEhChavePrimaria := LEhPK;
    LColuna.FValorDefault    := LLeitor.ObterString('COLUMN_DEFAULT');
    LColuna.FPosicao         := LLeitor.ObterInteger('ORDINAL_POSITION');

    // Tamanhos
    LColuna.FTamanhoPrecisao := LLeitor.ObterInteger('CHAR_LENGTH');
    if LColuna.FTamanhoPrecisao = 0 then
      LColuna.FTamanhoPrecisao := LLeitor.ObterInteger('PRECISAO');
    LColuna.FTamanhoEscala := LLeitor.ObterInteger('ESCALA');

    // AUTO_INCREMENT
    LColuna.FEhAutoIncremento :=
      LLeitor.ObterString('EXTRA').ToUpper.Contains('AUTO_INCREMENT');

    SetLength(LColunas, LContador + 1);
    LColunas[LContador] := LColuna;
    Inc(LContador);
  end;

  LTabela                  := TTabelaSchema.Create;
  LTabela.FNomeTabela      := ANomeTabela;
  LTabela.FNomeSchema      := FNomeDatabase;
  LTabela.FColunas         := LColunas;
  LTabela.FChavesPrimarias := LChaves;
  LTabela.FDescricao       := '';

  Result := LTabela;
end;

function TLeitorSchemaMySQL.LerTabelas: TArray<IOrmTabelaSchema>;
var
  LNomes: TArray<string>;
  LTabelas: TArray<IOrmTabelaSchema>;
  LIndice: Integer;
begin
  LNomes := ListarNomesTabelas;
  SetLength(LTabelas, Length(LNomes));

  for LIndice := 0 to High(LNomes) do
  begin
    try
      LTabelas[LIndice] := LerTabela(LNomes[LIndice]);
    except
      on E: Exception do
        FLogger.Aviso(
          Format('Falha ao ler tabela "%s" — ignorada', [LNomes[LIndice]]),
          TContextoLog.Novo
            .Add('erro', E.Message)
            .Construir);
    end;
  end;

  Result := LTabelas;
end;

end.
