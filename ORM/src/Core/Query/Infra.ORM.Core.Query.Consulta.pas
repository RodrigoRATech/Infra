unit Infra.ORM.Core.Query.Consulta;

{
  Responsabilidade:
    Implementação de IOrmConsulta<T>.
    API fluente pública consumida pela aplicação.
    Acumula filtros, ordenação e paginação de forma imutável
    e delega a execução ao TExecutorConsulta.

    Regra: cada método mutante retorna Self para encadeamento.
    A consulta é lazy — SQL só é gerado ao chamar Listar,
    PrimeiroOuNulo, Contar ou Existe.
}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions,
  Infra.ORM.Core.Logging.Contrato,
  Infra.ORM.Core.Metadata.Cache,
  Infra.ORM.Core.Query.Filtro,
  Infra.ORM.Core.Query.Ordenacao,
  Infra.ORM.Core.Query.Paginacao,
  Infra.ORM.Core.Query.Executor;

type

  TConsultaORM<T: class, constructor> = class(
    TInterfacedObject, IOrmConsulta<T>)
  strict private
    FMetadado: IOrmMetadadoEntidade;
    FExecutor: TExecutorConsulta;
    FLogger: IOrmLogger;

    // Acumuladores
    FFiltrosSimples: TListaFiltros;
    FGrupos: TListaGrupos;
    FOrdenacao: TConstrutorOrdenacao;
    FPaginacao: TPaginacao;

    // Grupo de filtros corrente (aberto pelo usuário via IniciarGrupo)
    FGrupoAtual: Integer; // -1 = sem grupo aberto

    procedure AdicionarFiltroSimples(const AFiltro: TFiltro);

  public
    constructor Create(
      AMetadado: IOrmMetadadoEntidade;
      AExecutor: TExecutorConsulta;
      ALogger: IOrmLogger);

    // ── Filtros simples ───────────────────────────────────────────────────

    function Onde(
      const AColuna: string;
      AOperador: TOperadorFiltro;
      const AValor: TValue): IOrmConsulta<T>;

    function E(
      const AColuna: string;
      AOperador: TOperadorFiltro;
      const AValor: TValue): IOrmConsulta<T>;

    function Ou(
      const AColuna: string;
      AOperador: TOperadorFiltro;
      const AValor: TValue): IOrmConsulta<T>;

    // ── Filtros de lista (IN / NOT IN) ────────────────────────────────────

    function OndeEm(
      const AColuna: string;
      const AValores: TArray<TValue>): IOrmConsulta<T>;

    function OndeNaoEm(
      const AColuna: string;
      const AValores: TArray<TValue>): IOrmConsulta<T>;

    // ── Filtros unários ───────────────────────────────────────────────────

    function OndeNulo(const AColuna: string): IOrmConsulta<T>;
    function OndeNaoNulo(const AColuna: string): IOrmConsulta<T>;

    // ── Agrupamento ───────────────────────────────────────────────────────

    function IniciarGrupoE: IOrmConsulta<T>;
    function IniciarGrupoOu: IOrmConsulta<T>;
    function FecharGrupo: IOrmConsulta<T>;

    // ── Ordenação ─────────────────────────────────────────────────────────

    function OrdenarPor(
      const AColuna: string;
      ADirecao: TDirecaoOrdenacao = doAscendente): IOrmConsulta<T>;

    function OrdenarPorDescendente(
      const AColuna: string): IOrmConsulta<T>;

    // ── Paginação ─────────────────────────────────────────────────────────

    function Pular(AQuantidade: Integer): IOrmConsulta<T>;
    function Pegar(AQuantidade: Integer): IOrmConsulta<T>;

    // ── Execução ──────────────────────────────────────────────────────────

    function Listar: TObjectList<T>;
    function PrimeiroOuNulo: T;
    function Contar: Int64;
    function Existe: Boolean;
  end;

implementation

{ TConsultaORM<T> }

constructor TConsultaORM<T>.Create(
  AMetadado: IOrmMetadadoEntidade;
  AExecutor: TExecutorConsulta;
  ALogger: IOrmLogger);
begin
  inherited Create;

  if not Assigned(AMetadado) then
    raise EOrmConsultaExcecao.Create(
      'TConsultaORM', 'Metadado não pode ser nil.');

  if not Assigned(AExecutor) then
    raise EOrmConsultaExcecao.Create(
      'TConsultaORM', 'Executor não pode ser nil.');

  FMetadado       := AMetadado;
  FExecutor       := AExecutor;
  FLogger         := ALogger ?? TLoggerNulo.Create;
  FFiltrosSimples := nil;
  FGrupos         := nil;
  FOrdenacao      := TConstrutorOrdenacao.Novo;
  FPaginacao      := TPaginacao.Sem;
  FGrupoAtual     := -1;
end;

procedure TConsultaORM<T>.AdicionarFiltroSimples(const AFiltro: TFiltro);
var
  LIndice: Integer;
begin
  // Se há um grupo aberto, adiciona ao grupo
  if FGrupoAtual >= 0 then
    FGrupos[FGrupoAtual].AdicionarFiltro(AFiltro)
  else
  begin
    // Senão, adiciona à lista simples de filtros
    LIndice := Length(FFiltrosSimples);
    SetLength(FFiltrosSimples, LIndice + 1);
    FFiltrosSimples[LIndice] := AFiltro;
  end;
end;

// ── Filtros simples ───────────────────────────────────────────────────────────

function TConsultaORM<T>.Onde(
  const AColuna: string;
  AOperador: TOperadorFiltro;
  const AValor: TValue): IOrmConsulta<T>;
begin
  // Onde é sempre o primeiro filtro — sem conector explícito
  AdicionarFiltroSimples(
    TFiltro.Criar(AColuna, AOperador, AValor, cfE));
  Result := Self;
end;

function TConsultaORM<T>.E(
  const AColuna: string;
  AOperador: TOperadorFiltro;
  const AValor: TValue): IOrmConsulta<T>;
begin
  AdicionarFiltroSimples(
    TFiltro.Criar(AColuna, AOperador, AValor, cfE));
  Result := Self;
end;

function TConsultaORM<T>.Ou(
  const AColuna: string;
  AOperador: TOperadorFiltro;
  const AValor: TValue): IOrmConsulta<T>;
begin
  AdicionarFiltroSimples(
    TFiltro.Criar(AColuna, AOperador, AValor, cfOu));
  Result := Self;
end;

// ── Filtros de lista ──────────────────────────────────────────────────────────

function TConsultaORM<T>.OndeEm(
  const AColuna: string;
  const AValores: TArray<TValue>): IOrmConsulta<T>;
begin
  AdicionarFiltroSimples(
    TFiltro.CriarLista(AColuna, ofEm, AValores, cfE));
  Result := Self;
end;

function TConsultaORM<T>.OndeNaoEm(
  const AColuna: string;
  const AValores: TArray<TValue>): IOrmConsulta<T>;
begin
  AdicionarFiltroSimples(
    TFiltro.CriarLista(AColuna, ofNaoEm, AValores, cfE));
  Result := Self;
end;

// ── Filtros unários ───────────────────────────────────────────────────────────

function TConsultaORM<T>.OndeNulo(const AColuna: string): IOrmConsulta<T>;
begin
  AdicionarFiltroSimples(
    TFiltro.CriarUnario(AColuna, ofNulo, cfE));
  Result := Self;
end;

function TConsultaORM<T>.OndeNaoNulo(const AColuna: string): IOrmConsulta<T>;
begin
  AdicionarFiltroSimples(
    TFiltro.CriarUnario(AColuna, ofNaoNulo, cfE));
  Result := Self;
end;

// ── Agrupamento ───────────────────────────────────────────────────────────────

function TConsultaORM<T>.IniciarGrupoE: IOrmConsulta<T>;
var
  LIndice: Integer;
begin
  LIndice := Length(FGrupos);
  SetLength(FGrupos, LIndice + 1);
  FGrupos[LIndice] := TGrupoFiltro.Criar(cfE);
  FGrupoAtual      := LIndice;
  Result := Self;
end;

function TConsultaORM<T>.IniciarGrupoOu: IOrmConsulta<T>;
var
  LIndice: Integer;
begin
  LIndice := Length(FGrupos);
  SetLength(FGrupos, LIndice + 1);
  FGrupos[LIndice] := TGrupoFiltro.Criar(cfOu);
  FGrupoAtual      := LIndice;
  Result := Self;
end;

function TConsultaORM<T>.FecharGrupo: IOrmConsulta<T>;
begin
  FGrupoAtual := -1;
  Result := Self;
end;

// ── Ordenação ─────────────────────────────────────────────────────────────────

function TConsultaORM<T>.OrdenarPor(
  const AColuna: string;
  ADirecao: TDirecaoOrdenacao): IOrmConsulta<T>;
begin
  FOrdenacao.Adicionar(AColuna, ADirecao);
  Result := Self;
end;

function TConsultaORM<T>.OrdenarPorDescendente(
  const AColuna: string): IOrmConsulta<T>;
begin
  FOrdenacao.Adicionar(AColuna, doDescendente);
  Result := Self;
end;

// ── Paginação ─────────────────────────────────────────────────────────────────

function TConsultaORM<T>.Pular(AQuantidade: Integer): IOrmConsulta<T>;
begin
  FPaginacao.DefinirOffset(AQuantidade);
  Result := Self;
end;

function TConsultaORM<T>.Pegar(AQuantidade: Integer): IOrmConsulta<T>;
begin
  FPaginacao.DefinirLimit(AQuantidade);
  Result := Self;
end;

// ── Execução ──────────────────────────────────────────────────────────────────

function TConsultaORM<T>.Listar: TObjectList<T>;
begin
  Result := FExecutor.Listar<T>(
    FMetadado,
    FFiltrosSimples,
    FGrupos,
    FOrdenacao,
    FPaginacao);
end;

function TConsultaORM<T>.PrimeiroOuNulo: T;
begin
  Result := FExecutor.PrimeiroOuNulo<T>(
    FMetadado,
    FFiltrosSimples,
    FGrupos,
    FOrdenacao);
end;

function TConsultaORM<T>.Contar: Int64;
begin
  Result := FExecutor.Contar(
    FMetadado,
    FFiltrosSimples,
    FGrupos);
end;

function TConsultaORM<T>.Existe: Boolean;
begin
  Result := FExecutor.Existe(
    FMetadado,
    FFiltrosSimples,
    FGrupos);
end;

end.
