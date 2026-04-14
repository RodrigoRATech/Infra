unit Infra.ORM.Core.Events.Sink.Tabela;

{
  Responsabilidade:
    Sink que persiste eventos de auditoria em tabela dedicada.
    Usa sessão ORM própria e independente da transação corrente.
    Nunca falha silenciosamente — avisa no logger mas não propaga.

    Estrutura da tabela ORM_AUDITORIA:
      ID            BIGINT / VARCHAR(36)   PK autoincremento ou UUID
      OCORRIDO_EM   TIMESTAMP              data/hora do evento
      OPERACAO      VARCHAR(20)            INSERT/UPDATE/DELETE/etc
      ENTIDADE      VARCHAR(150)           nome da classe
      CHAVE         VARCHAR(500)           chave primária serializada
      IDENTIDADE    VARCHAR(150)           usuário/contexto
      SUCESSO       CHAR(1)                S ou N
      DURACAO_MS    INTEGER                duração em ms
      MENSAGEM_ERRO VARCHAR(2000)          mensagem de erro se houver
      DADOS         CLOB / TEXT            snapshot JSON da entidade
}

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.Rtti,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Logging.Contrato,
  Infra.ORM.Core.Events.Contratos,
  Infra.ORM.Core.Events.Registro,
  Infra.ORM.Core.Events.Sink.Nulo;

type

  // Configuração do sink de tabela
  TConfigSinkTabela = record
    NomeTabela: string;
    IncluirDados: Boolean;
    TamanhoMaxDados: Integer;    // caracteres máximos para a coluna DADOS
    UsarUuidComoId: Boolean;     // True = UUID, False = autoincremento

    class function Padrao: TConfigSinkTabela; static;
  end;

  TSinkAuditoriaTabela = class(TInterfacedObject, IOrmSink)
  strict private
    FFabricaSessao: IOrmFabricaSessao;
    FLogger: IOrmLogger;
    FConfig: TConfigSinkTabela;

    function DescricaoOperacao(AOperacao: TOperacaoOrm): string;
    function SerializarDados(const AEvento: TEventoOrmOperacao): string;
    function TruncarString(const ATexto: string; ATamanho: Integer): string;

    procedure PersistirEvento(const AEvento: TEventoOrmOperacao);

  public
    constructor Create(
      AFabricaSessao: IOrmFabricaSessao;
      ALogger: IOrmLogger;
      AConfig: TConfigSinkTabela);

    function Nome: string;
    procedure Processar(const AEvento: TEventoOrmOperacao);
  end;

implementation

{ TConfigSinkTabela }

class function TConfigSinkTabela.Padrao: TConfigSinkTabela;
begin
  Result.NomeTabela       := 'ORM_AUDITORIA';
  Result.IncluirDados     := True;
  Result.TamanhoMaxDados  := 4000;
  Result.UsarUuidComoId   := False;
end;

{ TSinkAuditoriaTabela }

constructor TSinkAuditoriaTabela.Create(
  AFabricaSessao: IOrmFabricaSessao;
  ALogger: IOrmLogger;
  AConfig: TConfigSinkTabela);
begin
  inherited Create;

  if not Assigned(AFabricaSessao) then
    raise EOrmConfiguracaoExcecao.Create(
      'FabricaSessao é obrigatória no sink de tabela de auditoria.');

  FFabricaSessao := AFabricaSessao;
  FLogger        := ALogger ?? TLoggerNulo.Create;
  FConfig        := AConfig;
end;

function TSinkAuditoriaTabela.Nome: string;
begin
  Result := 'SinkAuditoriaTabela';
end;

function TSinkAuditoriaTabela.DescricaoOperacao(
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
    Result := 'OUTRO';
  end;
end;

function TSinkAuditoriaTabela.TruncarString(
  const ATexto: string; ATamanho: Integer): string;
begin
  if Length(ATexto) <= ATamanho then
    Result := ATexto
  else
    Result := Copy(ATexto, 1, ATamanho - 3) + '...';
end;

function TSinkAuditoriaTabela.SerializarDados(
  const AEvento: TEventoOrmOperacao): string;
var
  LSB: TStringBuilder;
  LEntradas: TListaEntradaAuditoria;
  LEntrada: TEntradaAuditoria;
  LPrimeiro: Boolean;
begin
  if not FConfig.IncluirDados then
  begin
    Result := '';
    Exit;
  end;

  if not Assigned(AEvento.Entidade) then
  begin
    Result := '{}';
    Exit;
  end;

  // Tenta serializar via metadados se disponível
  if Assigned(AEvento.DadosPosteriores) then
    LEntradas := TListaEntradaAuditoria(AEvento.DadosPosteriores)
  else
    LEntradas := nil;

  if Length(LEntradas) = 0 then
  begin
    Result := '{}';
    Exit;
  end;

  LSB      := TStringBuilder.Create;
  LPrimeiro := True;
  try
    LSB.Append('{');
    for LEntrada in LEntradas do
    begin
      if not LPrimeiro then LSB.Append(', ');
      LSB.Append('"');
      LSB.Append(LEntrada.Coluna);
      LSB.Append('": ');
      LSB.Append(LEntrada.Valor);
      LPrimeiro := False;
    end;
    LSB.Append('}');
    Result := TruncarString(LSB.ToString, FConfig.TamanhoMaxDados);
  finally
    LSB.Free;
  end;
end;

procedure TSinkAuditoriaTabela.PersistirEvento(
  const AEvento: TEventoOrmOperacao);
var
  LSessao: IOrmSessao;
  LComando: IOrmComando;
  LTransacao: IOrmTransacao;
  LSQL: string;
  LDados: string;
  LChave: string;
begin
  // Cria sessão dedicada para auditoria com despachante nulo
  // para evitar loop de eventos
  LSessao := FFabricaSessao.CriarSessao;

  LDados := SerializarDados(AEvento);
  LChave := TSerializadorValor.SerializarLista(AEvento.ValoresChave);

  LSQL := Format(
    'INSERT INTO %s ' +
    '(OCORRIDO_EM, OPERACAO, ENTIDADE, CHAVE, IDENTIDADE, ' +
    ' SUCESSO, DURACAO_MS, MENSAGEM_ERRO, DADOS) ' +
    'VALUES ' +
    '(:p_ocorrido_em, :p_operacao, :p_entidade, :p_chave, :p_identidade,' +
    ' :p_sucesso, :p_duracao_ms, :p_mensagem_erro, :p_dados)',
    [FConfig.NomeTabela]);

  LTransacao := LSessao.IniciarTransacao;
  try
    LComando := LSessao.ObterConexao.CriarComando;
    LComando.DefinirSQL(LSQL);

    LComando.AdicionarParametro(':p_ocorrido_em',
      TValue.From<TDateTime>(AEvento.OcorridoEm));
    LComando.AdicionarParametro(':p_operacao',
      TValue.From<string>(DescricaoOperacao(AEvento.Operacao)));
    LComando.AdicionarParametro(':p_entidade',
      TValue.From<string>(TruncarString(AEvento.NomeEntidade, 150)));
    LComando.AdicionarParametro(':p_chave',
      TValue.From<string>(TruncarString(LChave, 500)));
    LComando.AdicionarParametro(':p_identidade',
      TValue.From<string>(TruncarString(AEvento.IdentidadeContexto, 150)));
    LComando.AdicionarParametro(':p_sucesso',
      TValue.From<string>(IfThen(AEvento.Sucesso, 'S', 'N')));
    LComando.AdicionarParametro(':p_duracao_ms',
      TValue.From<Integer>(AEvento.DuracaoMs));
    LComando.AdicionarParametro(':p_mensagem_erro',
      TValue.From<string>(
        TruncarString(AEvento.MensagemErro, 2000)));
    LComando.AdicionarParametro(':p_dados',
      TValue.From<string>(LDados));

    LComando.ExecutarSemRetorno;
    LTransacao.Commit;
  except
    LTransacao.Rollback;
    raise;
  end;
end;

procedure TSinkAuditoriaTabela.Processar(const AEvento: TEventoOrmOperacao);
begin
  // Audita apenas operações de mutação e transação
  if not (AEvento.Operacao in
    [ooInserir, ooAtualizar, ooDeletar, ooCommit, ooRollback]) then
    Exit;

  try
    PersistirEvento(AEvento);
  except
    on E: Exception do
      FLogger.Aviso(
        'Falha ao persistir evento de auditoria na tabela — ignorada',
        TContextoLog.Novo
          .Add('tabela', FConfig.NomeTabela)
          .Add('operacao', DescricaoOperacao(AEvento.Operacao))
          .Add('entidade', AEvento.NomeEntidade)
          .Add('erro', E.Message)
          .Construir);
  end;
end;

end.
