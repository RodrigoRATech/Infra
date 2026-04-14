unit Infra.ORM.Core.Query.Construtor;

{
  Responsabilidade:
    Constrói o SQL final de consulta com WHERE, ORDER BY e paginação.
    Recebe filtros, ordenação e paginação já modelados e os
    serializa em SQL parametrizado para o dialeto configurado.

    Regra: este componente apenas serializa — não valida semântica
    de negócio. A validação de nomes de coluna é feita pelo executor.
}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions,
  Infra.ORM.Core.Query.Filtro,
  Infra.ORM.Core.Query.Ordenacao,
  Infra.ORM.Core.Query.Paginacao;

type

  // ---------------------------------------------------------------------------
  // Resultado da construção de consulta
  // ---------------------------------------------------------------------------
  TConsultaConstruida = record
    SQL: string;
    SQLContar: string;
    SQLExiste: string;
    Parametros: TArray<TParNomeValor>;
  end;

  // ---------------------------------------------------------------------------
  // Construtor SQL de consultas fluentes
  // ---------------------------------------------------------------------------
  TConstrutorConsulta = class
  strict private
    FDialeto: IOrmDialeto;
    FContadorParametro: Integer;

    function ProximoNomeParametro(const ANomeBase: string): string;
    function ResetarContador: TConstrutorConsulta;

    // Serializa um único filtro para SQL + parâmetro
    function SerializarFiltro(
      const AFiltro: TFiltro;
      AMetadado: IOrmMetadadoEntidade;
      var AParametros: TArray<TParNomeValor>): string;

    // Serializa lista de filtros em cláusula WHERE completa
    function SerializarWhere(
      const AFiltros: TListaFiltros;
      AMetadado: IOrmMetadadoEntidade;
      var AParametros: TArray<TParNomeValor>): string;

    // Serializa grupos de filtros com conectores entre grupos
    function SerializarGrupos(
      const AGrupos: TListaGrupos;
      AMetadado: IOrmMetadadoEntidade;
      var AParametros: TArray<TParNomeValor>): string;

    function OperadorParaSQL(AOperador: TOperadorFiltro): string;
    function ConectorParaSQL(AConector: TConectorFiltro): string;

    procedure AdicionarParametro(
      const ANome: string;
      const AValor: TValue;
      var AParametros: TArray<TParNomeValor>);

    function ValidarNomeColuna(
      const ANomeColuna: string;
      AMetadado: IOrmMetadadoEntidade): string;

  public
    constructor Create(ADialeto: IOrmDialeto);

    function Construir(
      AMetadado: IOrmMetadadoEntidade;
      const AFiltros: TListaFiltros;
      const AGrupos: TListaGrupos;
      const AOrdenacao: TConstrutorOrdenacao;
      const APaginacao: TPaginacao): TConsultaConstruida;
  end;

implementation

{ TConstrutorConsulta }

constructor TConstrutorConsulta.Create(ADialeto: IOrmDialeto);
begin
  inherited Create;

  if not Assigned(ADialeto) then
    raise EOrmDialetoExcecao.Create(
      'TConstrutorConsulta',
      'Dialeto não pode ser nil no construtor de consulta.');

  FDialeto           := ADialeto;
  FContadorParametro := 0;
end;

function TConstrutorConsulta.ResetarContador: TConstrutorConsulta;
begin
  FContadorParametro := 0;
  Result := Self;
end;

function TConstrutorConsulta.ProximoNomeParametro(
  const ANomeBase: string): string;
begin
  Result := Format('%sp_f%d_%s',
    [FDialeto.PrefixoParametro, FContadorParametro, ANomeBase.ToLower]);
  Inc(FContadorParametro);
end;

procedure TConstrutorConsulta.AdicionarParametro(
  const ANome: string;
  const AValor: TValue;
  var AParametros: TArray<TParNomeValor>);
var
  LIndice: Integer;
begin
  LIndice := Length(AParametros);
  SetLength(AParametros, LIndice + 1);
  AParametros[LIndice] := TParNomeValor.Create(ANome, AValor);
end;

function TConstrutorConsulta.ValidarNomeColuna(
  const ANomeColuna: string;
  AMetadado: IOrmMetadadoEntidade): string;
var
  LProp: IOrmMetadadoPropriedade;
begin
  if ANomeColuna.IsEmpty then
    raise EOrmConsultaExcecao.Create(
      AMetadado.NomeClasse,
      'Nome de coluna não pode ser vazio em filtro de consulta.');

  // Tenta localizar pelo nome de coluna
  LProp := AMetadado.PropriedadePorColuna(ANomeColuna);

  // Tenta pelo nome de property como fallback
  if not Assigned(LProp) then
    LProp := AMetadado.PropriedadePorNome(ANomeColuna);

  if not Assigned(LProp) then
    raise EOrmConsultaExcecao.Create(
      AMetadado.NomeClasse,
      Format(
        'Coluna ou propriedade "%s" não encontrada nos metadados de "%s". ' +
        'Verifique o nome e o mapeamento.',
        [ANomeColuna, AMetadado.NomeClasse]));

  // Retorna o nome real da coluna no banco
  Result := LProp.NomeColuna;
end;

function TConstrutorConsulta.OperadorParaSQL(
  AOperador: TOperadorFiltro): string;
begin
  case AOperador of
    ofIgual:         Result := '=';
    ofDiferente:     Result := '<>';
    ofMaior:         Result := '>';
    ofMenor:         Result := '<';
    ofMaiorOuIgual:  Result := '>=';
    ofMenorOuIgual:  Result := '<=';
    ofContem:        Result := 'LIKE';
    ofIniciacom:     Result := 'LIKE';
    ofTerminaCom:    Result := 'LIKE';
    ofNulo:          Result := 'IS NULL';
    ofNaoNulo:       Result := 'IS NOT NULL';
    ofEm:            Result := 'IN';
    ofNaoEm:         Result := 'NOT IN';
  else
    raise EOrmConsultaExcecao.Create(
      'TConstrutorConsulta',
      Format('Operador de filtro não suportado: %d', [Ord(AOperador)]));
  end;
end;

function TConstrutorConsulta.ConectorParaSQL(
  AConector: TConectorFiltro): string;
begin
  case AConector of
    cfE:  Result := 'AND';
    cfOu: Result := 'OR';
  else
    Result := 'AND';
  end;
end;

function TConstrutorConsulta.SerializarFiltro(
  const AFiltro: TFiltro;
  AMetadado: IOrmMetadadoEntidade;
  var AParametros: TArray<TParNomeValor>): string;
var
  LNomeColunaBanco: string;
  LNomeParam: string;
  LValorLike: string;
  LSB: TStringBuilder;
  LValor: TValue;
  LIndice: Integer;
begin
  LNomeColunaBanco := ValidarNomeColuna(AFiltro.Coluna, AMetadado);

  // Filtros unários — sem parâmetro
  if AFiltro.Operador in [ofNulo, ofNaoNulo] then
  begin
    Result := Format('%s %s',
      [FDialeto.Quotar(LNomeColunaBanco),
       OperadorParaSQL(AFiltro.Operador)]);
    Exit;
  end;

  // IN / NOT IN com lista
  if AFiltro.Operador in [ofEm, ofNaoEm] then
  begin
    if Length(AFiltro.ValoresLista) = 0 then
    begin
      // Lista vazia → condição impossível (IN) ou sempre verdadeira (NOT IN)
      if AFiltro.Operador = ofEm then
        Result := '1=0'
      else
        Result := '1=1';
      Exit;
    end;

    LSB := TStringBuilder.Create;
    try
      LSB.Append(FDialeto.Quotar(LNomeColunaBanco));
      LSB.Append(' ');
      LSB.Append(OperadorParaSQL(AFiltro.Operador));
      LSB.Append(' (');

      for LIndice := 0 to High(AFiltro.ValoresLista) do
      begin
        LNomeParam := ProximoNomeParametro(LNomeColunaBanco);
        if LIndice > 0 then LSB.Append(', ');
        LSB.Append(LNomeParam);
        AdicionarParametro(LNomeParam,
          AFiltro.ValoresLista[LIndice], AParametros);
      end;

      LSB.Append(')');
      Result := LSB.ToString;
    finally
      LSB.Free;
    end;
    Exit;
  end;

  // LIKE — transforma o valor conforme o operador
  if AFiltro.Operador in [ofContem, ofIniciacom, ofTerminaCom] then
  begin
    LValorLike := AFiltro.Valor.AsString;

    case AFiltro.Operador of
      ofContem:     LValorLike := '%' + LValorLike + '%';
      ofIniciacom:  LValorLike := LValorLike + '%';
      ofTerminaCom: LValorLike := '%' + LValorLike;
    end;

    LNomeParam := ProximoNomeParametro(LNomeColunaBanco);
    AdicionarParametro(LNomeParam,
      TValue.From<string>(LValorLike), AParametros);

    Result := Format('%s LIKE %s',
      [FDialeto.Quotar(LNomeColunaBanco), LNomeParam]);
    Exit;
  end;

  // Operadores binários simples (=, <>, >, <, >=, <=)
  LNomeParam := ProximoNomeParametro(LNomeColunaBanco);
  AdicionarParametro(LNomeParam, AFiltro.Valor, AParametros);

  Result := Format('%s %s %s',
    [FDialeto.Quotar(LNomeColunaBanco),
     OperadorParaSQL(AFiltro.Operador),
     LNomeParam]);
end;

function TConstrutorConsulta.SerializarWhere(
  const AFiltros: TListaFiltros;
  AMetadado: IOrmMetadadoEntidade;
  var AParametros: TArray<TParNomeValor>): string;
var
  LSB: TStringBuilder;
  LFiltro: TFiltro;
  LPrimeiro: Boolean;
  LExprFiltro: string;
begin
  if Length(AFiltros) = 0 then
  begin
    Result := string.Empty;
    Exit;
  end;

  LSB       := TStringBuilder.Create;
  LPrimeiro := True;
  try
    for LFiltro in AFiltros do
    begin
      LExprFiltro := SerializarFiltro(LFiltro, AMetadado, AParametros);

      if LPrimeiro then
        LSB.Append(LExprFiltro)
      else
      begin
        LSB.Append(' ');
        LSB.Append(ConectorParaSQL(LFiltro.Conector));
        LSB.Append(' ');
        LSB.Append(LExprFiltro);
      end;

      LPrimeiro := False;
    end;
    Result := LSB.ToString;
  finally
    LSB.Free;
  end;
end;

function TConstrutorConsulta.SerializarGrupos(
  const AGrupos: TListaGrupos;
  AMetadado: IOrmMetadadoEntidade;
  var AParametros: TArray<TParNomeValor>): string;
var
  LSB: TStringBuilder;
  LGrupo: TGrupoFiltro;
  LExprGrupo: string;
  LPrimeiro: Boolean;
begin
  if Length(AGrupos) = 0 then
  begin
    Result := string.Empty;
    Exit;
  end;

  LSB       := TStringBuilder.Create;
  LPrimeiro := True;
  try
    for LGrupo in AGrupos do
    begin
      if LGrupo.EstaVazio then
        Continue;

      LExprGrupo := SerializarWhere(LGrupo.Filtros, AMetadado, AParametros);

      if LExprGrupo.IsEmpty then
        Continue;

      if not LPrimeiro then
      begin
        LSB.Append(' ');
        LSB.Append(ConectorParaSQL(LGrupo.Conector));
        LSB.Append(' ');
      end;

      // Grupos com mais de um filtro são envolvidos em parênteses
      if Length(LGrupo.Filtros) > 1 then
      begin
        LSB.Append('(');
        LSB.Append(LExprGrupo);
        LSB.Append(')');
      end
      else
        LSB.Append(LExprGrupo);

      LPrimeiro := False;
    end;
    Result := LSB.ToString;
  finally
    LSB.Free;
  end;
end;

function TConstrutorConsulta.Construir(
  AMetadado: IOrmMetadadoEntidade;
  const AFiltros: TListaFiltros;
  const AGrupos: TListaGrupos;
  const AOrdenacao: TConstrutorOrdenacao;
  const APaginacao: TPaginacao): TConsultaConstruida;
var
  LSQLBase: TStringBuilder;
  LWhereSimples: string;
  LWhereGrupos: string;
  LClausulaWhere: string;
  LClausulaOrder: string;
  LParametros: TArray<TParNomeValor>;
begin
  ResetarContador;
  LParametros := nil;

  // ── FROM ──────────────────────────────────────────────────────────────────
  LSQLBase := TStringBuilder.Create;
  try
    LSQLBase.Append('SELECT * FROM ');
    LSQLBase.Append(FDialeto.QuotarTabela(
      AMetadado.NomeTabela, AMetadado.NomeSchema));

    // ── WHERE ────────────────────────────────────────────────────────────────
    LWhereSimples := SerializarWhere(AFiltros, AMetadado, LParametros);
    LWhereGrupos  := SerializarGrupos(AGrupos, AMetadado, LParametros);

    if not LWhereSimples.IsEmpty and not LWhereGrupos.IsEmpty then
      LClausulaWhere := LWhereSimples + ' AND ' + LWhereGrupos
    else if not LWhereSimples.IsEmpty then
      LClausulaWhere := LWhereSimples
    else
      LClausulaWhere := LWhereGrupos;

    if not LClausulaWhere.IsEmpty then
    begin
      LSQLBase.Append(' WHERE ');
      LSQLBase.Append(LClausulaWhere);
    end;

    // ── ORDER BY ─────────────────────────────────────────────────────────────
    LClausulaOrder := AOrdenacao.GerarSQL(FDialeto.Quotar);
    if not LClausulaOrder.IsEmpty then
      LSQLBase.Append(LClausulaOrder);

    // ── SQL SELECT com paginação ──────────────────────────────────────────────
    APaginacao.Validar;
    if APaginacao.Ativa then
      Result.SQL := FDialeto.AplicarPaginacao(
        LSQLBase.ToString,
        APaginacao.Offset,
        APaginacao.Limit)
    else
      Result.SQL := LSQLBase.ToString;

    // ── SQL COUNT ────────────────────────────────────────────────────────────
    var LSQLCount := TStringBuilder.Create;
    try
      LSQLCount.Append('SELECT COUNT(*) FROM ');
      LSQLCount.Append(FDialeto.QuotarTabela(
        AMetadado.NomeTabela, AMetadado.NomeSchema));

      if not LClausulaWhere.IsEmpty then
      begin
        LSQLCount.Append(' WHERE ');
        LSQLCount.Append(LClausulaWhere);
      end;

      Result.SQLContar := LSQLCount.ToString;
    finally
      LSQLCount.Free;
    end;

    // ── SQL EXISTS ────────────────────────────────────────────────────────────
    var LSQLExists := TStringBuilder.Create;
    try
      LSQLExists.Append('SELECT 1 FROM ');
      LSQLExists.Append(FDialeto.QuotarTabela(
        AMetadado.NomeTabela, AMetadado.NomeSchema));

      if not LClausulaWhere.IsEmpty then
      begin
        LSQLExists.Append(' WHERE ');
        LSQLExists.Append(LClausulaWhere);
      end;

      // Dialetos que suportam LIMIT (MySQL) ou ROWS (Firebird)
      Result.SQLExiste := FDialeto.AplicarPaginacao(
        LSQLExists.ToString, 0, 1);
    finally
      LSQLExists.Free;
    end;

    Result.Parametros := LParametros;
  finally
    LSQLBase.Free;
  end;
end;

end.
