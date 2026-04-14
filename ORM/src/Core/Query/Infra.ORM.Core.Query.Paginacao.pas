unit Infra.ORM.Core.Query.Paginacao;

{
  Responsabilidade:
    Controle de paginação (SKIP + TAKE).
    Delegação ao dialeto para geração do SQL específico por banco.
}

interface

uses
  System.SysUtils,
  Infra.ORM.Core.Exceptions;

type

  TPaginacao = record
  private
    FOffset: Integer;
    FLimit: Integer;
    FAtiva: Boolean;
  public
    class function Sem: TPaginacao; static;
    class function Com(AOffset, ALimit: Integer): TPaginacao; static;

    procedure DefinirOffset(AValor: Integer);
    procedure DefinirLimit(AValor: Integer);

    function Ativa: Boolean;
    function Offset: Integer;
    function Limit: Integer;

    procedure Validar;
  end;

implementation

{ TPaginacao }

class function TPaginacao.Sem: TPaginacao;
begin
  Result.FOffset := 0;
  Result.FLimit  := 0;
  Result.FAtiva  := False;
end;

class function TPaginacao.Com(AOffset, ALimit: Integer): TPaginacao;
begin
  Result.FOffset := AOffset;
  Result.FLimit  := ALimit;
  Result.FAtiva  := True;
end;

procedure TPaginacao.DefinirOffset(AValor: Integer);
begin
  if AValor < 0 then
    raise EOrmConsultaExcecao.Create('TPaginacao',
      'Offset não pode ser negativo.');
  FOffset := AValor;
  FAtiva  := True;
end;

procedure TPaginacao.DefinirLimit(AValor: Integer);
begin
  if AValor < 1 then
    raise EOrmConsultaExcecao.Create('TPaginacao',
      'Limit deve ser maior que zero.');
  FLimit := AValor;
  FAtiva := True;
end;

function TPaginacao.Ativa: Boolean;
begin
  Result := FAtiva;
end;

function TPaginacao.Offset: Integer;
begin
  Result := FOffset;
end;

function TPaginacao.Limit: Integer;
begin
  Result := FLimit;
end;

procedure TPaginacao.Validar;
begin
  if FAtiva and (FLimit < 1) then
    raise EOrmConsultaExcecao.Create('TPaginacao',
      'Paginação ativa requer Limit maior que zero. Use Pegar(N).');
end;

end.
