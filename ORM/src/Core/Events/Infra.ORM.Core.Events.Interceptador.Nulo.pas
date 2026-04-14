unit Infra.ORM.Core.Events.Interceptador.Nulo;

{
  Responsabilidade:
    Implementação no-op de IOrmInterceptador.
    Base para herança e padrão quando nenhum interceptador é necessário.
}

interface

uses
  System.SysUtils,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Events.Contratos;

type

  TInterceptadorNulo = class(TInterfacedObject, IOrmInterceptador)
  public
    function Nome: string; virtual;

    procedure Antes(
      AOperacao: TOperacaoOrm;
      AMetadado: IOrmMetadadoEntidade;
      AEntidade: TObject); virtual;

    procedure Depois(
      AOperacao: TOperacaoOrm;
      AMetadado: IOrmMetadadoEntidade;
      AEntidade: TObject;
      ASucesso: Boolean); virtual;
  end;

implementation

{ TInterceptadorNulo }

function TInterceptadorNulo.Nome: string;
begin
  Result := 'InterceptadorNulo';
end;

procedure TInterceptadorNulo.Antes(
  AOperacao: TOperacaoOrm;
  AMetadado: IOrmMetadadoEntidade;
  AEntidade: TObject);
begin
  // no-op
end;

procedure TInterceptadorNulo.Depois(
  AOperacao: TOperacaoOrm;
  AMetadado: IOrmMetadadoEntidade;
  AEntidade: TObject;
  ASucesso: Boolean);
begin
  // no-op
end;

end.
