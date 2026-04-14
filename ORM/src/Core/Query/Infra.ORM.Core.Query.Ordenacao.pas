unit Infra.ORM.Core.Query.Ordenacao;

{
  Responsabilidade:
    Modelo de dados para ordenação de resultados.
    Acumula múltiplos campos com suas direções.
}

interface

uses
  System.SysUtils,
  Infra.ORM.Core.Common.Tipos;

type

  // ---------------------------------------------------------------------------
  // Descritor de um campo de ordenação
  // ---------------------------------------------------------------------------
  TDescriptorOrdenacao = record
    NomeColuna: string;
    Direcao: TDirecaoOrdenacao;

    class function Criar(
      const ANomeColuna: string;
      ADirecao: TDirecaoOrdenacao = doAscendente): TDescriptorOrdenacao; static;

    function ToSQL(ADialeto: IInterface): string;
  end;

  TListaOrdenacao = TArray<TDescriptorOrdenacao>;

  // ---------------------------------------------------------------------------
  // Construtor de cláusula ORDER BY
  // ---------------------------------------------------------------------------
  TConstrutorOrdenacao = record
  private
    FDescritores: TListaOrdenacao;
  public
    class function Novo: TConstrutorOrdenacao; static;

    procedure Adicionar(
      const ANomeColuna: string;
      ADirecao: TDirecaoOrdenacao = doAscendente);

    function EstaVazio: Boolean;
    function Descritores: TListaOrdenacao;

    // Gera cláusula ORDER BY completa
    function GerarSQL(
      const ADialetoQuotar: TFunc<string, string>): string;
  end;

implementation

{ TDescriptorOrdenacao }

class function TDescriptorOrdenacao.Criar(
  const ANomeColuna: string;
  ADirecao: TDirecaoOrdenacao): TDescriptorOrdenacao;
begin
  Result.NomeColuna := ANomeColuna;
  Result.Direcao    := ADirecao;
end;

function TDescriptorOrdenacao.ToSQL(ADialeto: IInterface): string;
begin
  // Implementação concreta usa o quotador — chamado pelo TConstrutorOrdenacao
  if Direcao = doDescendente then
    Result := NomeColuna + ' DESC'
  else
    Result := NomeColuna + ' ASC';
end;

{ TConstrutorOrdenacao }

class function TConstrutorOrdenacao.Novo: TConstrutorOrdenacao;
begin
  Result.FDescritores := nil;
end;

procedure TConstrutorOrdenacao.Adicionar(
  const ANomeColuna: string;
  ADirecao: TDirecaoOrdenacao);
var
  LIndice: Integer;
begin
  LIndice := Length(FDescritores);
  SetLength(FDescritores, LIndice + 1);
  FDescritores[LIndice] := TDescriptorOrdenacao.Criar(ANomeColuna, ADirecao);
end;

function TConstrutorOrdenacao.EstaVazio: Boolean;
begin
  Result := Length(FDescritores) = 0;
end;

function TConstrutorOrdenacao.Descritores: TListaOrdenacao;
begin
  Result := FDescritores;
end;

function TConstrutorOrdenacao.GerarSQL(
  const ADialetoQuotar: TFunc<string, string>): string;
var
  LPartes: TStringBuilder;
  LDescriptor: TDescriptorOrdenacao;
  LPrimeiro: Boolean;
begin
  if EstaVazio then
  begin
    Result := string.Empty;
    Exit;
  end;

  LPartes   := TStringBuilder.Create;
  LPrimeiro := True;
  try
    LPartes.Append(' ORDER BY ');
    for LDescriptor in FDescritores do
    begin
      if not LPrimeiro then
        LPartes.Append(', ');

      LPartes.Append(ADialetoQuotar(LDescriptor.NomeColuna));

      if LDescriptor.Direcao = doDescendente then
        LPartes.Append(' DESC')
      else
        LPartes.Append(' ASC');

      LPrimeiro := False;
    end;
    Result := LPartes.ToString;
  finally
    LPartes.Free;
  end;
end;

end.
