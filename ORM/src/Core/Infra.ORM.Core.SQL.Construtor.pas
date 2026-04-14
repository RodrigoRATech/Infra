unit Infra.ORM.Core.SQL.Construtor;

{
  Responsabilidade:
    Construtor de SQL parametrizado baseado em metadados.
    Gera INSERT, UPDATE, DELETE e SELECT com parâmetros nomeados.
    Não conhece o dialeto — usa IOrmDialeto para particularidades
    de quoting, paginação e recuperação de chave gerada.

    Regra: nunca interpola valores diretamente no SQL.
    Sempre usa parâmetros nomeados via PREFIXO_PARAMETRO.
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions;

type

  // ---------------------------------------------------------------------------
  // Resultado da construção de um SQL com seus parâmetros associados
  // ---------------------------------------------------------------------------
  TComandoSQL = record
    SQL: string;
    Parametros: TArray<TParNomeValor>;

    class function Criar(
      const ASQL: string;
      const AParametros: TArray<TParNomeValor>): TComandoSQL; static;
  end;

  // ---------------------------------------------------------------------------
  // Construtor de SQL baseado em metadados e dialeto
  // Stateless — seguro para compartilhamento entre threads
  // ---------------------------------------------------------------------------
  TConstrutorSQL = class
  strict private
    FDialeto: IOrmDialeto;

    function NomeParametro(const ANomeColuna: string): string;
    function MontarListaColunas(
      const APropriedades: TArray<IOrmMetadadoPropriedade>;
      AIncluirChaves: Boolean = True): string;
    function MontarListaParametros(
      const APropriedades: TArray<IOrmMetadadoPropriedade>;
      AIncluirChaves: Boolean = True): string;
    function MontarClausulaWhere(
      const AChaves: TArray<IOrmMetadadoPropriedade>): string;
    function MontarListaSet(
      const APropriedades: TArray<IOrmMetadadoPropriedade>): string;

  public
    constructor Create(ADialeto: IOrmDialeto);

    // Gera SQL de INSERT
    // AIncluirChaveAutoInc: False quando a chave é gerada pelo banco
    function GerarInsert(
      AMetadado: IOrmMetadadoEntidade;
      AEntidade: TObject): TComandoSQL;

    // Gera SQL de UPDATE por chave primária
    function GerarUpdate(
      AMetadado: IOrmMetadadoEntidade;
      AEntidade: TObject): TComandoSQL;

    // Gera SQL de DELETE por chave primária
    function GerarDelete(
      AMetadado: IOrmMetadadoEntidade;
      AEntidade: TObject): TComandoSQL;

    // Gera SQL de SELECT por chave primária
    function GerarSelectPorId(
      AMetadado: IOrmMetadadoEntidade): string;

    // Gera SQL de SELECT sem filtro (LIST ALL)
    function GerarSelectTodos(
      AMetadado: IOrmMetadadoEntidade): string;

    // Gera SQL de SELECT paginado
    function GerarSelectPaginado(
      AMetadado: IOrmMetadadoEntidade;
      AOffset, ALimit: Integer): string;
  end;

implementation

{ TComandoSQL }

class function TComandoSQL.Criar(
  const ASQL: string;
  const AParametros: TArray<TParNomeValor>): TComandoSQL;
begin
  Result.SQL        := ASQL;
  Result.Parametros := AParametros;
end;

{ TConstrutorSQL }

constructor TConstrutorSQL.Create(ADialeto: IOrmDialeto);
begin
  inherited Create;

  if not Assigned(ADialeto) then
    raise EOrmDialetoExcecao.Create(
      'TConstrutorSQL',
      'Dialeto não pode ser nil na construção do construtor SQL.');

  FDialeto := ADialeto;
end;

function TConstrutorSQL.NomeParametro(const ANomeColuna: string): string;
begin
  Result := FDialeto.PrefixoParametro + ANomeColuna.ToLower;
end;

function TConstrutorSQL.MontarListaColunas(
  const APropriedades: TArray<IOrmMetadadoPropriedade>;
  AIncluirChaves: Boolean): string;
var
  LProp: IOrmMetadadoPropriedade;
  LPartes: TStringBuilder;
  LPrimeiro: Boolean;
begin
  LPartes  := TStringBuilder.Create;
  LPrimeiro := True;
  try
    for LProp in APropriedades do
    begin
      if not AIncluirChaves and LProp.EhChavePrimaria then
        Continue;
      if LProp.EhSomenteLeitura and not LProp.EhChavePrimaria then
        Continue;

      if not LPrimeiro then
        LPartes.Append(', ');

      LPartes.Append(FDialeto.Quotar(LProp.NomeColuna));
      LPrimeiro := False;
    end;
    Result := LPartes.ToString;
  finally
    LPartes.Free;
  end;
end;

function TConstrutorSQL.MontarListaParametros(
  const APropriedades: TArray<IOrmMetadadoPropriedade>;
  AIncluirChaves: Boolean): string;
var
  LProp: IOrmMetadadoPropriedade;
  LPartes: TStringBuilder;
  LPrimeiro: Boolean;
begin
  LPartes   := TStringBuilder.Create;
  LPrimeiro := True;
  try
    for LProp in APropriedades do
    begin
      if not AIncluirChaves and LProp.EhChavePrimaria then
        Continue;
      if LProp.EhSomenteLeitura and not LProp.EhChavePrimaria then
        Continue;

      if not LPrimeiro then
        LPartes.Append(', ');

      LPartes.Append(NomeParametro(LProp.NomeColuna));
      LPrimeiro := False;
    end;
    Result := LPartes.ToString;
  finally
    LPartes.Free;
  end;
end;

function TConstrutorSQL.MontarClausulaWhere(
  const AChaves: TArray<IOrmMetadadoPropriedade>): string;
var
  LChave: IOrmMetadadoPropriedade;
  LPartes: TStringBuilder;
  LPrimeiro: Boolean;
begin
  if Length(AChaves) = 0 then
    raise EOrmConsultaExcecao.Create(
      'MontarClausulaWhere',
      'Não é possível gerar cláusula WHERE sem chaves primárias definidas.');

  LPartes   := TStringBuilder.Create;
  LPrimeiro := True;
  try
    for LChave in AChaves do
    begin
      if not LPrimeiro then
        LPartes.Append(' AND ');

      LPartes.Append(FDialeto.Quotar(LChave.NomeColuna));
      LPartes.Append(' = ');
      LPartes.Append(NomeParametro(LChave.NomeColuna));
      LPrimeiro := False;
    end;
    Result := LPartes.ToString;
  finally
    LPartes.Free;
  end;
end;

function TConstrutorSQL.MontarListaSet(
  const APropriedades: TArray<IOrmMetadadoPropriedade>): string;
var
  LProp: IOrmMetadadoPropriedade;
  LPartes: TStringBuilder;
  LPrimeiro: Boolean;
begin
  LPartes   := TStringBuilder.Create;
  LPrimeiro := True;
  try
    for LProp in APropriedades do
    begin
      // Não atualizar chaves primárias e campos somente leitura
      if LProp.EhChavePrimaria then
        Continue;
      if LProp.EhSomenteLeitura and not LProp.EhCriadoPor then
        Continue;
      // CriadoEm não é atualizado em UPDATE
      if LProp.EhCriadoEm then
        Continue;

      if not LPrimeiro then
        LPartes.Append(', ');

      LPartes.Append(FDialeto.Quotar(LProp.NomeColuna));
      LPartes.Append(' = ');
      LPartes.Append(NomeParametro(LProp.NomeColuna));
      LPrimeiro := False;
    end;
    Result := LPartes.ToString;
  finally
    LPartes.Free;
  end;
end;

function TConstrutorSQL.GerarInsert(
  AMetadado: IOrmMetadadoEntidade;
  AEntidade: TObject): TComandoSQL;
var
  LProps: TArray<IOrmMetadadoPropriedade>;
  LChaves: TArray<IOrmMetadadoPropriedade>;
  LProp: IOrmMetadadoPropriedade;
  LSQL: TStringBuilder;
  LParametros: TArray<TParNomeValor>;
  LContador: Integer;
  LIncluirChaveNoInsert: Boolean;
begin
  LProps  := AMetadado.PropriedadesPersistidas;
  LChaves := AMetadado.Chaves;

  // Determina se a chave deve estar no INSERT
  // AutoIncremento → banco gera, não incluir
  // GUID/UUIDv7    → aplicação gera, incluir
  LIncluirChaveNoInsert := True;
  if (Length(LChaves) = 1) and LChaves[0].EhAutoIncremento then
    LIncluirChaveNoInsert := False;

  LSQL := TStringBuilder.Create;
  try
    LSQL.Append('INSERT INTO ');
    LSQL.Append(FDialeto.QuotarTabela(
      AMetadado.NomeTabela, AMetadado.NomeSchema));
    LSQL.Append(' (');
    LSQL.Append(MontarListaColunas(LProps, LIncluirChaveNoInsert));
    LSQL.Append(') VALUES (');
    LSQL.Append(MontarListaParametros(LProps, LIncluirChaveNoInsert));
    LSQL.Append(')');

    // RETURNING para dialetos que suportam (PostgreSQL, Firebird)
    if FDialeto.SuportaReturning and not LIncluirChaveNoInsert then
    begin
      if Length(LChaves) = 1 then
        LSQL.Append(FDialeto.ClausulaReturning(LChaves[0].NomeColuna));
    end;

    // Montar parâmetros com valores reais da entidade
    LContador := 0;
    for LProp in LProps do
    begin
      if not LIncluirChaveNoInsert and LProp.EhChavePrimaria then
        Continue;
      if LProp.EhSomenteLeitura and not LProp.EhChavePrimaria then
        Continue;

      SetLength(LParametros, LContador + 1);
      LParametros[LContador] := TParNomeValor.Create(
        NomeParametro(LProp.NomeColuna),
        LProp.ObterValor(AEntidade));
      Inc(LContador);
    end;

    Result := TComandoSQL.Criar(LSQL.ToString, LParametros);
  finally
    LSQL.Free;
  end;
end;

function TConstrutorSQL.GerarUpdate(
  AMetadado: IOrmMetadadoEntidade;
  AEntidade: TObject): TComandoSQL;
var
  LProps: TArray<IOrmMetadadoPropriedade>;
  LChaves: TArray<IOrmMetadadoPropriedade>;
  LProp: IOrmMetadadoPropriedade;
  LSQL: TStringBuilder;
  LParametros: TArray<TParNomeValor>;
  LContador: Integer;
begin
  LProps  := AMetadado.PropriedadesPersistidas;
  LChaves := AMetadado.Chaves;

  LSQL := TStringBuilder.Create;
  try
    LSQL.Append('UPDATE ');
    LSQL.Append(FDialeto.QuotarTabela(
      AMetadado.NomeTabela, AMetadado.NomeSchema));
    LSQL.Append(' SET ');
    LSQL.Append(MontarListaSet(LProps));
    LSQL.Append(' WHERE ');
    LSQL.Append(MontarClausulaWhere(LChaves));

    // Parâmetros: primeiro os campos SET, depois as chaves do WHERE
    LContador := 0;
    for LProp in LProps do
    begin
      if LProp.EhChavePrimaria then Continue;
      if LProp.EhSomenteLeitura and not LProp.EhCriadoPor then Continue;
      if LProp.EhCriadoEm then Continue;

      SetLength(LParametros, LContador + 1);
      LParametros[LContador] := TParNomeValor.Create(
        NomeParametro(LProp.NomeColuna),
        LProp.ObterValor(AEntidade));
      Inc(LContador);
    end;

    // Parâmetros das chaves (WHERE)
    for LProp in LChaves do
    begin
      SetLength(LParametros, LContador + 1);
      LParametros[LContador] := TParNomeValor.Create(
        NomeParametro(LProp.NomeColuna),
        LProp.ObterValor(AEntidade));
      Inc(LContador);
    end;

    Result := TComandoSQL.Criar(LSQL.ToString, LParametros);
  finally
    LSQL.Free;
  end;
end;

function TConstrutorSQL.GerarDelete(
  AMetadado: IOrmMetadadoEntidade;
  AEntidade: TObject): TComandoSQL;
var
  LChaves: TArray<IOrmMetadadoPropriedade>;
  LChave: IOrmMetadadoPropriedade;
  LSQL: TStringBuilder;
  LParametros: TArray<TParNomeValor>;
  LContador: Integer;
begin
  LChaves := AMetadado.Chaves;

  LSQL := TStringBuilder.Create;
  try
    LSQL.Append('DELETE FROM ');
    LSQL.Append(FDialeto.QuotarTabela(
      AMetadado.NomeTabela, AMetadado.NomeSchema));
    LSQL.Append(' WHERE ');
    LSQL.Append(MontarClausulaWhere(LChaves));

    LContador := 0;
    for LChave in LChaves do
    begin
      SetLength(LParametros, LContador + 1);
      LParametros[LContador] := TParNomeValor.Create(
        NomeParametro(LChave.NomeColuna),
        LChave.ObterValor(AEntidade));
      Inc(LContador);
    end;

    Result := TComandoSQL.Criar(LSQL.ToString, LParametros);
  finally
    LSQL.Free;
  end;
end;

function TConstrutorSQL.GerarSelectPorId(
  AMetadado: IOrmMetadadoEntidade): string;
var
  LChaves: TArray<IOrmMetadadoPropriedade>;
  LSQL: TStringBuilder;
begin
  LChaves := AMetadado.Chaves;

  LSQL := TStringBuilder.Create;
  try
    LSQL.Append('SELECT * FROM ');
    LSQL.Append(FDialeto.QuotarTabela(
      AMetadado.NomeTabela, AMetadado.NomeSchema));
    LSQL.Append(' WHERE ');
    LSQL.Append(MontarClausulaWhere(LChaves));
    Result := LSQL.ToString;
  finally
    LSQL.Free;
  end;
end;

function TConstrutorSQL.GerarSelectTodos(
  AMetadado: IOrmMetadadoEntidade): string;
var
  LSQL: TStringBuilder;
begin
  LSQL := TStringBuilder.Create;
  try
    LSQL.Append('SELECT * FROM ');
    LSQL.Append(FDialeto.QuotarTabela(
      AMetadado.NomeTabela, AMetadado.NomeSchema));
    Result := LSQL.ToString;
  finally
    LSQL.Free;
  end;
end;

function TConstrutorSQL.GerarSelectPaginado(
  AMetadado: IOrmMetadadoEntidade;
  AOffset, ALimit: Integer): string;
begin
  Result := FDialeto.AplicarPaginacao(
    GerarSelectTodos(AMetadado), AOffset, ALimit);
end;

end.
