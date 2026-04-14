unit Infra.ORM.Core.Query.Executor;

{
  Responsabilidade:
    Executa consultas construídas pelo TConstrutorConsulta.
    Materializa resultados em entidades tipadas via THidratador.
    Encapsula o ciclo completo: construção → bind → execução → hidratação.
}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  System.Diagnostics,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions,
  Infra.ORM.Core.Logging.Contrato,
  Infra.ORM.Core.Persistence.Hidratador,
  Infra.ORM.Core.Query.Filtro,
  Infra.ORM.Core.Query.Ordenacao,
  Infra.ORM.Core.Query.Paginacao,
  Infra.ORM.Core.Query.Construtor;

type

  TExecutorConsulta = class
  strict private
    FConexao: IOrmConexao;
    FDialeto: IOrmDialeto;
    FLogger: IOrmLogger;
    FHidratador: THidratador;
    FConstrutorConsulta: TConstrutorConsulta;

    procedure BindarParametros(
      AComando: IOrmComando;
      const AParametros: TArray<TParNomeValor>);

  public
    constructor Create(
      AConexao: IOrmConexao;
      ADialeto: IOrmDialeto;
      ALogger: IOrmLogger);

    destructor Destroy; override;

    function Listar<T: class, constructor>(
      AMetadado: IOrmMetadadoEntidade;
      const AFiltros: TListaFiltros;
      const AGrupos: TListaGrupos;
      const AOrdenacao: TConstrutorOrdenacao;
      const APaginacao: TPaginacao): TObjectList<T>;

    function PrimeiroOuNulo<T: class, constructor>(
      AMetadado: IOrmMetadadoEntidade;
      const AFiltros: TListaFiltros;
      const AGrupos: TListaGrupos;
      const AOrdenacao: TConstrutorOrdenacao): T;

    function Contar(
      AMetadado: IOrmMetadadoEntidade;
      const AFiltros: TListaFiltros;
      const AGrupos: TListaGrupos): Int64;

    function Existe(
      AMetadado: IOrmMetadadoEntidade;
      const AFiltros: TListaFiltros;
      const AGrupos: TListaGrupos): Boolean;
  end;

implementation

{ TExecutorConsulta }

constructor TExecutorConsulta.Create(
  AConexao: IOrmConexao;
  ADialeto: IOrmDialeto;
  ALogger: IOrmLogger);
begin
  inherited Create;

  if not Assigned(AConexao) then
    raise EOrmConexaoExcecao.Create(
      'Conexão não pode ser nil no executor de consultas.');

  if not Assigned(ADialeto) then
    raise EOrmDialetoExcecao.Create(
      'TExecutorConsulta', 'Dialeto não pode ser nil.');

  FConexao            := AConexao;
  FDialeto            := ADialeto;
  FLogger             := ALogger ?? TLoggerNulo.Create;
  FHidratador         := THidratador.Create(FLogger);
  FConstrutorConsulta := TConstrutorConsulta.Create(FDialeto);
end;

destructor TExecutorConsulta.Destroy;
begin
  FConstrutorConsulta.Free;
  FHidratador.Free;
  FConexao := nil;
  FDialeto := nil;
  FLogger  := nil;
  inherited Destroy;
end;

procedure TExecutorConsulta.BindarParametros(
  AComando: IOrmComando;
  const AParametros: TArray<TParNomeValor>);
var
  LPar: TParNomeValor;
begin
  AComando.LimparParametros;
  for LPar in AParametros do
    AComando.AdicionarParametro(LPar.Nome, LPar.Valor);
end;

function TExecutorConsulta.Listar<T>(
  AMetadado: IOrmMetadadoEntidade;
  const AFiltros: TListaFiltros;
  const AGrupos: TListaGrupos;
  const AOrdenacao: TConstrutorOrdenacao;
  const APaginacao: TPaginacao): TObjectList<T>;
var
  LConsulta: TConsultaConstruida;
  LComando: IOrmComando;
  LLeitor: IOrmLeitorDados;
  LCronometro: TStopwatch;
begin
  LCronometro := TStopwatch.StartNew;
  try
    // Aviso de paginação sem ordenação
    if APaginacao.Ativa and AOrdenacao.EstaVazio then
      FLogger.Aviso(
        'Consulta paginada sem ORDER BY — resultado pode ser não determinístico',
        TContextoLog.Novo
          .Add('entidade', AMetadado.NomeClasse)
          .Construir);

    LConsulta := FConstrutorConsulta.Construir(
      AMetadado, AFiltros, AGrupos, AOrdenacao, APaginacao);

    FLogger.Debug('Executando consulta fluente',
      TContextoLog.Novo
        .Add('entidade', AMetadado.NomeClasse)
        .Add('sql', LConsulta.SQL)
        .Construir);

    LComando := FConexao.CriarComando;
    LComando.DefinirSQL(LConsulta.SQL);
    LComando.Preparar;
    BindarParametros(LComando, LConsulta.Parametros);

    LLeitor := LComando.ExecutarConsulta;
    Result  := FHidratador.HidratarLista<T>(AMetadado, LLeitor);

    LCronometro.Stop;
    FLogger.Debug('Consulta fluente concluída',
      TContextoLog.Novo
        .Add('entidade', AMetadado.NomeClasse)
        .Add('total', Result.Count)
        .Add('duracao_ms', LCronometro.ElapsedMilliseconds)
        .Construir);
  except
    on E: Exception do
    begin
      LCronometro.Stop;
      FLogger.Erro('Falha na consulta fluente', E,
        TContextoLog.Novo
          .Add('entidade', AMetadado.NomeClasse)
          .Construir);

      if E is EOrmExcecao then raise;

      raise EOrmConsultaExcecao.Create(
        AMetadado.NomeClasse,
        Format('Falha ao executar consulta: %s', [E.Message]), E);
    end;
  end;
end;

function TExecutorConsulta.PrimeiroOuNulo<T>(
  AMetadado: IOrmMetadadoEntidade;
  const AFiltros: TListaFiltros;
  const AGrupos: TListaGrupos;
  const AOrdenacao: TConstrutorOrdenacao): T;
var
  LPaginacaoUm: TPaginacao;
  LLista: TObjectList<T>;
begin
  // Otimização: busca apenas 1 registro
  LPaginacaoUm := TPaginacao.Com(0, 1);

  LLista := Listar<T>(AMetadado, AFiltros, AGrupos, AOrdenacao, LPaginacaoUm);
  try
    if LLista.Count > 0 then
    begin
      Result := LLista.Extract(LLista[0]);
    end
    else
      Result := nil;
  finally
    LLista.Free;
  end;
end;

function TExecutorConsulta.Contar(
  AMetadado: IOrmMetadadoEntidade;
  const AFiltros: TListaFiltros;
  const AGrupos: TListaGrupos): Int64;
var
  LConsulta: TConsultaConstruida;
  LComando: IOrmComando;
  LValor: TValue;
  LPaginacaoSem: TPaginacao;
  LOrdenacaoVazia: TConstrutorOrdenacao;
begin
  LPaginacaoSem  := TPaginacao.Sem;
  LOrdenacaoVazia := TConstrutorOrdenacao.Novo;

  LConsulta := FConstrutorConsulta.Construir(
    AMetadado, AFiltros, AGrupos, LOrdenacaoVazia, LPaginacaoSem);

  FLogger.Debug('Executando COUNT',
    TContextoLog.Novo
      .Add('entidade', AMetadado.NomeClasse)
      .Add('sql', LConsulta.SQLContar)
      .Construir);

  LComando := FConexao.CriarComando;
  LComando.DefinirSQL(LConsulta.SQLContar);
  LComando.Preparar;
  BindarParametros(LComando, LConsulta.Parametros);

  LValor := LComando.ExecutarEscalar;

  if LValor.IsEmpty then
    Result := 0
  else
    Result := LValor.AsInt64;
end;

function TExecutorConsulta.Existe(
  AMetadado: IOrmMetadadoEntidade;
  const AFiltros: TListaFiltros;
  const AGrupos: TListaGrupos): Boolean;
var
  LConsulta: TConsultaConstruida;
  LComando: IOrmComando;
  LLeitor: IOrmLeitorDados;
  LPaginacaoSem: TPaginacao;
  LOrdenacaoVazia: TConstrutorOrdenacao;
begin
  LPaginacaoSem  := TPaginacao.Sem;
  LOrdenacaoVazia := TConstrutorOrdenacao.Novo;

  LConsulta := FConstrutorConsulta.Construir(
    AMetadado, AFiltros, AGrupos, LOrdenacaoVazia, LPaginacaoSem);

  FLogger.Debug('Executando EXISTS',
    TContextoLog.Novo
      .Add('entidade', AMetadado.NomeClasse)
      .Add('sql', LConsulta.SQLExiste)
      .Construir);

  LComando := FConexao.CriarComando;
  LComando.DefinirSQL(LConsulta.SQLExiste);
  LComando.Preparar;
  BindarParametros(LComando, LConsulta.Parametros);

  LLeitor := LComando.ExecutarConsulta;
  Result  := LLeitor.Proximo and not LLeitor.EhNulo('1');
end;

end.
