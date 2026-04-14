unit Infra.ORM.Core.Query.Filtro;

{
  Responsabilidade:
    Modelos de dados para filtros de consulta.
    Representa predicados individuais e grupos compostos.
    Sem dependência de banco — apenas estrutura de dados.
}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos;

type

  // ---------------------------------------------------------------------------
  // Predicado atômico: coluna operador valor
  // ---------------------------------------------------------------------------
  TFiltro = record
    Coluna: string;
    Operador: TOperadorFiltro;
    Valor: TValue;
    ValoresLista: TArray<TValue>;  // usado em ofEm / ofNaoEm
    Conector: TConectorFiltro;     // como este filtro se conecta ao anterior

    class function Criar(
      const AColuna: string;
      AOperador: TOperadorFiltro;
      const AValor: TValue;
      AConector: TConectorFiltro = cfE): TFiltro; static;

    class function CriarLista(
      const AColuna: string;
      AOperador: TOperadorFiltro;
      const AValores: TArray<TValue>;
      AConector: TConectorFiltro = cfE): TFiltro; static;

    class function CriarUnario(
      const AColuna: string;
      AOperador: TOperadorFiltro;
      AConector: TConectorFiltro = cfE): TFiltro; static;
  end;

  TListaFiltros = TArray<TFiltro>;

  // ---------------------------------------------------------------------------
  // Grupo de filtros — permite (A AND B) OR (C AND D)
  // No MVP suportamos um único nível de agrupamento
  // ---------------------------------------------------------------------------
  TGrupoFiltro = record
    Filtros: TListaFiltros;
    Conector: TConectorFiltro; // conector deste grupo com o anterior

    class function Criar(
      AConector: TConectorFiltro = cfE): TGrupoFiltro; static;

    procedure AdicionarFiltro(const AFiltro: TFiltro);
    function EstaVazio: Boolean;
  end;

  TListaGrupos = TArray<TGrupoFiltro>;

implementation

{ TFiltro }

class function TFiltro.Criar(
  const AColuna: string;
  AOperador: TOperadorFiltro;
  const AValor: TValue;
  AConector: TConectorFiltro): TFiltro;
begin
  Result.Coluna      := AColuna;
  Result.Operador    := AOperador;
  Result.Valor       := AValor;
  Result.ValoresLista := nil;
  Result.Conector    := AConector;
end;

class function TFiltro.CriarLista(
  const AColuna: string;
  AOperador: TOperadorFiltro;
  const AValores: TArray<TValue>;
  AConector: TConectorFiltro): TFiltro;
begin
  Result.Coluna       := AColuna;
  Result.Operador     := AOperador;
  Result.Valor        := TValue.Empty;
  Result.ValoresLista := AValores;
  Result.Conector     := AConector;
end;

class function TFiltro.CriarUnario(
  const AColuna: string;
  AOperador: TOperadorFiltro;
  AConector: TConectorFiltro): TFiltro;
begin
  Result.Coluna       := AColuna;
  Result.Operador     := AOperador;
  Result.Valor        := TValue.Empty;
  Result.ValoresLista := nil;
  Result.Conector     := AConector;
end;

{ TGrupoFiltro }

class function TGrupoFiltro.Criar(AConector: TConectorFiltro): TGrupoFiltro;
begin
  Result.Filtros  := nil;
  Result.Conector := AConector;
end;

procedure TGrupoFiltro.AdicionarFiltro(const AFiltro: TFiltro);
var
  LIndice: Integer;
begin
  LIndice := Length(Filtros);
  SetLength(Filtros, LIndice + 1);
  Filtros[LIndice] := AFiltro;
end;

function TGrupoFiltro.EstaVazio: Boolean;
begin
  Result := Length(Filtros) = 0;
end;

end.
