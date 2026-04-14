unit Infra.ORM.FireDAC.Transacao;

{
  Responsabilidade:
    Implementação de IOrmTransacao sobre TFDConnection do FireDAC.
    Envolve o controle físico de transação do FireDAC.
    O controle de rollback automático e logging está em TTransacao (Core).
}

interface

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions;

type

  TTransacaoFireDAC = class(TInterfacedObject, IOrmTransacao)
  strict private
    FConexao: TFDConnection;
    FEstaAtiva: Boolean;

  public
    constructor Create(AConexao: TFDConnection);

    procedure Commit;
    procedure Rollback;
    function EstaAtiva: Boolean;
  end;

implementation

{ TTransacaoFireDAC }

constructor TTransacaoFireDAC.Create(AConexao: TFDConnection);
begin
  inherited Create;

  if not Assigned(AConexao) then
    raise EOrmTransacaoExcecao.Create(
      'TFDConnection não pode ser nil na transação FireDAC.');

  FConexao   := AConexao;
  FEstaAtiva := True;

  // Inicia transação física no FireDAC
  FConexao.StartTransaction;
end;

procedure TTransacaoFireDAC.Commit;
begin
  if not FEstaAtiva then
    raise EOrmTransacaoExcecao.Create(
      'Transação FireDAC já encerrada — commit não permitido.');
  try
    FConexao.Commit;
    FEstaAtiva := False;
  except
    on E: Exception do
      raise EOrmTransacaoExcecao.Create(
        Format('Falha no commit FireDAC: %s', [E.Message]), E);
  end;
end;

procedure TTransacaoFireDAC.Rollback;
begin
  if not FEstaAtiva then
    Exit;
  try
    FConexao.Rollback;
    FEstaAtiva := False;
  except
    on E: Exception do
    begin
      FEstaAtiva := False;
      raise EOrmTransacaoExcecao.Create(
        Format('Falha no rollback FireDAC: %s', [E.Message]), E);
    end;
  end;
end;

function TTransacaoFireDAC.EstaAtiva: Boolean;
begin
  Result := FEstaAtiva;
end;

end.
