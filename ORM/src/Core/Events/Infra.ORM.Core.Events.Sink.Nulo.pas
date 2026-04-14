unit Infra.ORM.Core.Events.Sink.Nulo;

{
  Responsabilidade:
    Implementação no-op de IOrmSink.
    Usada em testes e como padrão quando nenhum sink é configurado.
}

interface

uses
  System.SysUtils,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Events.Contratos;

type

  TSinkNulo = class(TInterfacedObject, IOrmSink)
  public
    function Nome: string;
    procedure Processar(const AEvento: TEventoOrmOperacao);
  end;

  // Despachante nulo — usado internamente para evitar loops
  TDespacanteNulo = class(TInterfacedObject, IOrmDespachante)
  public
    procedure Despachar(const AEvento: TEventoOrmOperacao);
  end;

implementation

{ TSinkNulo }

function TSinkNulo.Nome: string;
begin
  Result := 'SinkNulo';
end;

procedure TSinkNulo.Processar(const AEvento: TEventoOrmOperacao);
begin
  // Intencionalmente vazio
end;

{ TDespacanteNulo }

procedure TDespacanteNulo.Despachar(const AEvento: TEventoOrmOperacao);
begin
  // Intencionalmente vazio
end;

end.
