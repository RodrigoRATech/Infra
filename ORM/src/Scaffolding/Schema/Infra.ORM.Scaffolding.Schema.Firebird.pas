unit Infra.ORM.Scaffolding.Schema.Firebird;

{
  Responsabilidade:
    Leitor de schema para Firebird 2.5+.
    Consulta RDB$RELATION_FIELDS, RDB$FIELDS e RDB$RELATION_CONSTRAINTS.
    Detecta autoincremento via IDENTITY (Firebird 3+) e geradores convencionais.
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

  TLeitorSchemaFirebird = class(TInterfacedObject, IOrmLeitorSchema)
  strict private
    FConexao: IOrmConexao;
    FLogger: IOrmLogger;

    function ExecutarConsulta(const ASQL: string): IOrmLeitorDados;
    function ExecutarComParametro(
      const ASQL, ANomeParam, AValor: string): IOrmLeitorDados;

    function CarregarChavesPrimarias(
      const ANomeTabela: string): TArray<string>;

    function CarregarColunas(
      const ANomeTabela: string;
      const AChavesPrimarias: TArray<string>): TArray<IOrmColunaSchema>;

    function DetectarAutoIncremento(
      const ANomeTabela, ANomeColuna: string): Boolean;

    function MapearTipoFirebird(
      const ATipoSQL: string;
      ASubTipo: Integer): string;

  public
    constructor Create(AConexao: IOrmConexao; ALogger: IOrmLogger);

    function LerTabelas: TArray<IOrmTabelaSchema>;
    function LerTabela(const ANomeTabela: string): IOrmTabelaSchema;
    function ListarNomesTabelas: TArray<string>;
  end;

implementation

{ TLeitorSchemaFirebird }

constructor TLeitorSchemaFirebird.Create(
  AConexao: IOrmConexao; ALogger: IOrmLogger);
begin
  inherited Create;

  if not Assigned(AConexao) then
    raise EOrmConexaoExcecao.Create(
      'Conexão não pode ser nil no leitor de schema Firebird.');

  FConexao := AConexao;
  FLogger  := ALogger ?? TLoggerNulo.Create;
end;

function TLeitorSchemaFirebird.ExecutarConsulta(
  const ASQL: string): IOrmLeitorDados;
var
  LComando: IOrmComando;
begin
  LComando := FConexao.CriarComando;
  LComando.DefinirSQL(ASQL);
  Result := LComando.ExecutarConsulta;
end;

function TLeitorSchemaFirebird.ExecutarComParametro(
  const ASQL, ANomeParam, AValor: string): IOrmLeitorDados;
var
  LComando: IOrmComando;
begin
  LComando := FConexao.CriarComando;
  LComando.DefinirSQL(ASQL);
  LComando.AdicionarParametro(
    ANomeParam, TValue.From<string>(AValor));
  Result := LComando.ExecutarConsulta;
end;

function TLeitorSchemaFirebird.ListarNomesTabelas: TArray<string>;
const
  SQL_TABELAS =
    'SELECT TRIM(r.RDB$RELATION_NAME) AS NOME_TABELA ' +
    'FROM RDB$RELATIONS r ' +
    'WHERE r.RDB$SYSTEM_FLAG = 0 ' +
    '  AND r.RDB$VIEW_BLR IS NULL ' +
    'ORDER BY r.RDB$RELATION_NAME';
var
  LLeitor: IOrmLeitorDados;
  LNomes: TArray<string>;
  LContador: Integer;
begin
  FLogger.Debug('Listando tabelas do schema Firebird');

  LLeitor   := ExecutarConsulta(SQL_TABELAS);
  LContador := 0;

  while LLeitor.Proximo do
  begin
    SetLength(LNomes, LContador + 1);
    LNomes[LContador] := LLeitor.ObterString('NOME_TABELA').Trim;
    Inc(LContador);
  end;

  Result := LNomes;

  FLogger.Debug(Format('Encontradas %d tabelas no schema', [LContador]));
end;

function TLeitorSchemaFirebird.CarregarChavesPrimarias(
  const ANomeTabela: string): TArray<string>;
const
  SQL_PKS =
    'SELECT TRIM(s.RDB$FIELD_NAME) AS NOME_COLUNA ' +
    'FROM RDB$RELATION_CONSTRAINTS rc ' +
    '  JOIN RDB$INDEX_SEGMENTS s ' +
    '    ON s.RDB$INDEX_NAME = rc.RDB$INDEX_NAME ' +
    'WHERE rc.RDB$RELATION_NAME = :p_tabela ' +
    '  AND rc.RDB$CONSTRAINT_TYPE = ''PRIMARY KEY'' ' +
    'ORDER BY s.RDB$FIELD_POSITION';
var
  LLeitor: IOrmLeitorDados;
  LNomes: TArray<string>;
  LContador: Integer;
begin
  LLeitor   := ExecutarComParametro(SQL_PKS, ':p_tabela', ANomeTabela);
  LContador := 0;

  while LLeitor.Proximo do
  begin
    SetLength(LNomes, LContador + 1);
    LNomes[LContador] := LLeitor.ObterString('NOME_COLUNA').Trim;
    Inc(LContador);
  end;

  Result := LNomes;
end;

function TLeitorSchemaFirebird.DetectarAutoIncremento(
  const ANomeTabela, ANomeColuna: string): Boolean;
const
  // Firebird 3+ — IDENTITY column
  SQL_IDENTITY =
    'SELECT rf.RDB$IDENTITY_TYPE ' +
    'FROM RDB$RELATION_FIELDS rf ' +
    'WHERE rf.RDB$RELATION_NAME = :p_tabela ' +
    '  AND TRIM(rf.RDB$FIELD_NAME) = :p_coluna';
  // Firebird 2.5 — verifica trigger DEFAULT + gerador convencional
  SQL_TRIGGER =
    'SELECT COUNT(*) AS TOTAL ' +
    'FROM RDB$TRIGGERS t ' +
    'WHERE t.RDB$RELATION_NAME = :p_tabela ' +
    '  AND t.RDB$TRIGGER_TYPE = 1 ' +  // BEFORE INSERT
    '  AND UPPER(t.RDB$TRIGGER_SOURCE) LIKE ''%GEN_ID%''';
var
  LComando: IOrmComando;
  LLeitor: IOrmLeitorDados;
  LValor: TValue;
begin
  Result := False;

  // Tenta via IDENTITY (Firebird 3+)
  try
    LComando := FConexao.CriarComando;
    LComando.DefinirSQL(SQL_IDENTITY);
    LComando.AdicionarParametro(':p_tabela',
      TValue.From<string>(ANomeTabela));
    LComando.AdicionarParametro(':p_coluna',
      TValue.From<string>(ANomeColuna));

    LLeitor := LComando.ExecutarConsulta;
    if LLeitor.Proximo then
    begin
      LValor := LLeitor.ObterValor('RDB$IDENTITY_TYPE');
      if not LValor.IsEmpty and (LValor.AsInteger >= 0) then
      begin
        Result := True;
        Exit;
      end;
    end;
  except
    // RDB$IDENTITY_TYPE não existe no Firebird 2.5 — ignora
  end;

  // Fallback: detecta trigger BEFORE INSERT com GEN_ID (Firebird 2.5)
  try
    LComando := FConexao.CriarComando;
    LComando.DefinirSQL(SQL_TRIGGER);
    LComando.AdicionarParametro(':p_tabela',
      TValue.From<string>(ANomeTabela));

    LValor := LComando.ExecutarEscalar;
    Result := not LValor.IsEmpty and (LValor.AsInteger > 0);
  except
    Result := False;
  end;
end;

function TLeitorSchemaFirebird.MapearTipoFirebird(
  const ATipoSQL: string; ASubTipo: Integer): string;
var
  LTipo: string;
begin
  LTipo := ATipoSQL.Trim.ToUpper;

  if (LTipo = 'BLOB') and (ASubTipo = 1) then
    Result := 'CLOB'
  else if LTipo = 'BLOB' then
    Result := 'BLOB'
  else
    Result := LTipo;
end;

function TLeitorSchemaFirebird.CarregarColunas(
  const ANomeTabela: string;
  const AChavesPrimarias: TArray<string>): TArray<IOrmColunaSchema>;
const
  SQL_COLUNAS =
    'SELECT ' +
    '  TRIM(rf.RDB$FIELD_NAME)         AS NOME_COLUNA,' +
    '  f.RDB$FIELD_TYPE                AS TIPO_NUM,' +
    '  f.RDB$FIELD_SUB_TYPE            AS SUB_TIPO,' +
    '  COALESCE(f.RDB$FIELD_LENGTH, 0) AS TAMANHO,' +
    '  COALESCE(f.RDB$FIELD_PRECISION, 0) AS PRECISAO,' +
    '  COALESCE(f.RDB$FIELD_SCALE, 0)  AS ESCALA,' +
    '  COALESCE(rf.RDB$NULL_FLAG, 0)   AS NAO_NULO,' +
    '  rf.RDB$FIELD_POSITION           AS POSICAO,' +
    '  rf.RDB$DEFAULT_SOURCE           AS VALOR_DEFAULT,' +
    '  TRIM(tp.RDB$TYPE_NAME)          AS NOME_TIPO ' +
    'FROM RDB$RELATION_FIELDS rf ' +
    '  JOIN RDB$FIELDS f ' +
    '    ON f.RDB$FIELD_NAME = rf.RDB$FIELD_SOURCE ' +
    '  LEFT JOIN RDB$TYPES tp ' +
    '    ON tp.RDB$TYPE = f.RDB$FIELD_TYPE ' +
    '   AND tp.RDB$FIELD_NAME = ''RDB$FIELD_TYPE'' ' +
    'WHERE rf.RDB$RELATION_NAME = :p_tabela ' +
    'ORDER BY rf.RDB$FIELD_POSITION';
var
  LLeitor: IOrmLeitorDados;
  LColunas: TArray<IOrmColunaSchema>;
  LColuna: TColunaSchema;
  LContador: Integer;
  LNomeColuna: string;
  LTipoNum: Integer;
  LSubTipo: Integer;
  LEhPK: Boolean;
  LNomeTipo: string;
begin
  LLeitor   := ExecutarComParametro(
    SQL_COLUNAS, ':p_tabela', ANomeTabela);
  LContador := 0;

  while LLeitor.Proximo do
  begin
    LNomeColuna := LLeitor.ObterString('NOME_COLUNA').Trim;
    LTipoNum    := LLeitor.ObterInteger('TIPO_NUM');
    LSubTipo    := LLeitor.ObterInteger('SUB_TIPO');
    LNomeTipo   := LLeitor.ObterString('NOME_TIPO').Trim;
    LEhPK       := False;

    for var LPK in AChavesPrimarias do
      if LPK.Trim.ToUpper = LNomeColuna.ToUpper then
        LEhPK := True;

    LColuna                 := TColunaSchema.Create;
    LColuna.FNomeColuna     := LNomeColuna;
    LColuna.FTipoSQL        := MapearTipoFirebird(LNomeTipo, LSubTipo);
    LColuna.FTamanhoPrecisao := LLeitor.ObterInteger('PRECISAO');
    LColuna.FTamanhoEscala  := Abs(LLeitor.ObterInteger('ESCALA'));
    LColuna.FNullable       := LLeitor.ObterInteger('NAO_NULO') = 0;
    LColuna.FEhChavePrimaria := LEhPK;
    LColuna.FValorDefault   := LLeitor.ObterString('VALOR_DEFAULT').Trim;
    LColuna.FPosicao        := LLeitor.ObterInteger('POSICAO');

    // Tamanho efetivo para strings
    if LColuna.FTamanhoPrecisao = 0 then
      LColuna.FTamanhoPrecisao := LLeitor.ObterInteger('TAMANHO');

    // Detecta autoincremento apenas para PKs inteiras
    if LEhPK then
      LColuna.FEhAutoIncremento :=
        DetectarAutoIncremento(ANomeTabela, LNomeColuna);

    SetLength(LColunas, LContador + 1);
    LColunas[LContador] := LColuna;
    Inc(LContador);
  end;

  Result := LColunas;
end;

function TLeitorSchemaFirebird.LerTabela(
  const ANomeTabela: string): IOrmTabelaSchema;
var
  LTabela: TTabelaSchema;
  LChaves: TArray<string>;
begin
  FLogger.Debug(Format('Lendo schema da tabela: %s', [ANomeTabela]));

  LChaves := CarregarChavesPrimarias(ANomeTabela.Trim.ToUpper);

  LTabela              := TTabelaSchema.Create;
  LTabela.FNomeTabela  := ANomeTabela.Trim.ToUpper;
  LTabela.FNomeSchema  := '';
  LTabela.FChavesPrimarias := LChaves;
  LTabela.FColunas     := CarregarColunas(
    ANomeTabela.Trim.ToUpper, LChaves);
  LTabela.FDescricao   := '';

  Result := LTabela;
end;

function TLeitorSchemaFirebird.LerTabelas: TArray<IOrmTabelaSchema>;
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
      begin
        FLogger.Aviso(
          Format('Falha ao ler tabela "%s" — ignorada', [LNomes[LIndice]]),
          TContextoLog.Novo
            .Add('tabela', LNomes[LIndice])
            .Add('erro', E.Message)
            .Construir);
      end;
    end;
  end;

  Result := LTabelas;
end;

end.
