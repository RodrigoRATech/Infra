unit Infra.ORM.Core.Session.Transacao;

{
  Responsabilidade:
    Implementação de IOrmTransacao.
    Envolve a transação física do provider com semântica segura:
    - rollback automático se não houve commit ao ser destruído
    - estado rastreado para evitar double-commit/rollback
    - integração com logger e despachante de eventos
}

interface

uses
  System.SysUtils,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions,
  Infra.ORM.Core.Logging.Contrato,
  Infra.ORM.Core.Events.Contratos;

type

  TTransacao = class(TInterfacedObject, IOrmTransacao)
  strict private
    FTransacaoFisica: IOrmTransacao;
    FLogger: IOrmLogger;
    FDespachante: IOrmDespachante;
    FEstaAtiva: Boolean;
    FIdentidadeContexto: string;

    procedure DispararEvento(
      AOperacao: TOperacaoOrm;
      ASucesso: Boolean;
      const AMensagemErro: string = '');

  public
    constructor Create(
      ATransacaoFisica: IOrmTransacao;
      ALogger: IOrmLogger;
      ADespachante: IOrmDespachante;
      const AIdentidadeContexto: string = '');

    destructor Destroy; override;

    // IOrmTransacao
    procedure Commit;
    procedure Rollback;
    function EstaAtiva: Boolean;
  end;

implementation

uses
  System.DateUtils;

{ TTransacao }

constructor TTransacao.Create(
  ATransacaoFisica: IOrmTransacao;
  ALogger: IOrmLogger;
  ADespachante: IOrmDespachante;
  const AIdentidadeContexto: string);
begin
  inherited Create;

  if not Assigned(ATransacaoFisica) then
    raise EOrmTransacaoExcecao.Create(
      'Transação física não pode ser nil.');

  FTransacaoFisica    := ATransacaoFisica;
  FLogger             := ALogger;
  FDespachante        := ADespachante;
  FIdentidadeContexto := AIdentidadeContexto;
  FEstaAtiva          := True;

  FLogger.Debug('Transação iniciada',
    TContextoLog.Novo
      .Add('identidade', FIdentidadeContexto)
      .Construir);
end;

destructor TTransacao.Destroy;
begin
  // Rollback automático de segurança caso a transação
  // seja destruída sem commit explícito
  if FEstaAtiva then
  begin
    FLogger.Aviso(
      'Transação destruída sem commit — executando rollback automático',
      TContextoLog.Novo
        .Add('identidade', FIdentidadeContexto)
        .Construir);
    try
      FTransacaoFisica.Rollback;
    except
      on E: Exception do
        FLogger.Erro(
          'Falha no rollback automático durante destruição da transação',
          E,
          TContextoLog.Novo
            .Add('identidade', FIdentidadeContexto)
            .Construir);
    end;
  end;

  FTransacaoFisica := nil;
  FLogger          := nil;
  FDespachante     := nil;
  inherited Destroy;
end;

procedure TTransacao.Commit;
begin
  if not FEstaAtiva then
    raise EOrmTransacaoExcecao.Create(
      'Não é possível confirmar uma transação já encerrada.');
  try
    FTransacaoFisica.Commit;
    FEstaAtiva := False;

    DispararEvento(TOperacaoOrm.ooCommit, True);

    FLogger.Informacao('Transação confirmada (commit)',
      TContextoLog.Novo
        .Add('identidade', FIdentidadeContexto)
        .Construir);
  except
    on E: Exception do
    begin
      FLogger.Erro('Falha ao confirmar transação (commit)', E,
        TContextoLog.Novo
          .Add('identidade', FIdentidadeContexto)
          .Construir);

      raise EOrmTransacaoExcecao.Create(
        Format('Falha ao confirmar transação: %s', [E.Message]), E);
    end;
  end;
end;

procedure TTransacao.Rollback;
begin
  if not FEstaAtiva then
    Exit; // Rollback em transação já encerrada é silencioso
  try
    FTransacaoFisica.Rollback;
    FEstaAtiva := False;

    DispararEvento(TOperacaoOrm.ooRollback, True);

    FLogger.Aviso('Transação desfeita (rollback)',
      TContextoLog.Novo
        .Add('identidade', FIdentidadeContexto)
        .Construir);
  except
    on E: Exception do
    begin
      FEstaAtiva := False;
      FLogger.Erro('Falha ao desfazer transação (rollback)', E,
        TContextoLog.Novo
          .Add('identidade', FIdentidadeContexto)
          .Construir);
      raise EOrmTransacaoExcecao.Create(
        Format('Falha ao desfazer transação: %s', [E.Message]), E);
    end;
  end;
end;

function TTransacao.EstaAtiva: Boolean;
begin
  Result := FEstaAtiva;
end;

procedure TTransacao.DispararEvento(
  AOperacao: TOperacaoOrm;
  ASucesso: Boolean;
  const AMensagemErro: string);
var
  LEvento: TEventoOrmOperacao;
begin
  if not Assigned(FDespachante) then
    Exit;
  try
    LEvento.IdEvento          := '';
    LEvento.OcorridoEm        := Now;
    LEvento.Operacao          := AOperacao;
    LEvento.NomeEntidade      := '';
    LEvento.ValoresChave      := nil;
    LEvento.Entidade          := nil;
    LEvento.DadosAnteriores   := nil;
    LEvento.DadosPosteriores  := nil;
    LEvento.Sucesso           := ASucesso;
    LEvento.MensagemErro      := AMensagemErro;
    LEvento.IdentidadeContexto := FIdentidadeContexto;
    LEvento.DuracaoMs         := 0;

    FDespachante.Despachar(LEvento);
  except
    on E: Exception do
      FLogger.Aviso(
        'Falha ao despachar evento de transação — ignorado',
        TContextoLog.Novo
          .Add('erro', E.Message)
          .Construir);
  end;
end;

end.
