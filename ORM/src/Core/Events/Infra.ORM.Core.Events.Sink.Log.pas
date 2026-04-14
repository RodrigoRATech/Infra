unit Infra.ORM.Core.Events.Sink.Log;

{
  Responsabilidade:
    Sink que grava eventos ORM no logger estruturado.
    Cada operação gera uma entrada de log com nível adequado:
      - Sucesso: Informacao
      - Falha:   Erro
      - Rollback/Commit: Aviso/Informacao
}

interface

uses
  System.SysUtils,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Logging.Contrato,
  Infra.ORM.Core.Events.Contratos,
  Infra.ORM.Core.Events.Registro;

type

  TSinkAuditoriaLog = class(TInterfacedObject, IOrmSink)
  strict private
    FLogger: IOrmLogger;
    FLogNivelSucesso: TNivelLog;
    FIncluirValores: Boolean;

    function DescricaoOperacao(AOperacao: TOperacaoOrm): string;

  public
    constructor Create(
      ALogger: IOrmLogger;
      ALogNivelSucesso: TNivelLog = nlInformacao;
      AIncluirValores: Boolean = False);

    function Nome: string;
    procedure Processar(const AEvento: TEventoOrmOperacao);
  end;

implementation

{ TSinkAuditoriaLog }

constructor TSinkAuditoriaLog.Create(
  ALogger: IOrmLogger;
  ALogNivelSucesso: TNivelLog;
  AIncluirValores: Boolean);
begin
  inherited Create;

  if not Assigned(ALogger) then
    FLogger := TLoggerNulo.Create
  else
    FLogger := ALogger;

  FLogNivelSucesso := ALogNivelSucesso;
  FIncluirValores  := AIncluirValores;
end;

function TSinkAuditoriaLog.Nome: string;
begin
  Result := 'SinkAuditoriaLog';
end;

function TSinkAuditoriaLog.DescricaoOperacao(
  AOperacao: TOperacaoOrm): string;
begin
  case AOperacao of
    ooInserir:   Result := 'INSERT';
    ooAtualizar: Result := 'UPDATE';
    ooDeletar:   Result := 'DELETE';
    ooBuscar:    Result := 'SELECT';
    ooListar:    Result := 'LIST';
    ooCommit:    Result := 'COMMIT';
    ooRollback:  Result := 'ROLLBACK';
  else
    Result := 'OPERACAO_' + IntToStr(Ord(AOperacao));
  end;
end;

procedure TSinkAuditoriaLog.Processar(const AEvento: TEventoOrmOperacao);
var
  LContexto: TContextoLog;
  LMensagem: string;
begin
  LContexto := TContextoLog.Novo
    .Add('operacao', DescricaoOperacao(AEvento.Operacao))
    .Add('entidade', AEvento.NomeEntidade)
    .Add('chave', TSerializadorValor.SerializarLista(AEvento.ValoresChave))
    .Add('duracao_ms', AEvento.DuracaoMs)
    .Add('identidade', AEvento.IdentidadeContexto)
    .Add('ocorrido_em', DateTimeToStr(AEvento.OcorridoEm));

  if not AEvento.MensagemErro.IsEmpty then
    LContexto := LContexto.Add('erro', AEvento.MensagemErro);

  if not AEvento.Sucesso then
  begin
    LMensagem := Format('ORM %s FALHOU — %s',
      [DescricaoOperacao(AEvento.Operacao), AEvento.NomeEntidade]);
    FLogger.Erro(LMensagem, nil, LContexto.Construir);
    Exit;
  end;

  LMensagem := Format('ORM %s — %s',
    [DescricaoOperacao(AEvento.Operacao), AEvento.NomeEntidade]);

  case FLogNivelSucesso of
    nlDebug:       FLogger.Debug(LMensagem, LContexto.Construir);
    nlInformacao:  FLogger.Informacao(LMensagem, LContexto.Construir);
    nlAviso:       FLogger.Aviso(LMensagem, LContexto.Construir);
  else
    FLogger.Informacao(LMensagem, LContexto.Construir);
  end;
end;

end.
