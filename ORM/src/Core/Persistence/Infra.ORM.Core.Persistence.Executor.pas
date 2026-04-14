unit Infra.ORM.Core.Persistence.Executor;

{
  Responsabilidade:
    Coordena o ciclo completo de persistência de uma entidade:
    1. Resolve metadados
    2. Valida entidade
    3. Gera valores de chave se necessário
    4. Constrói SQL
    5. Executa via IOrmConexao
    6. Aplica valor retornado da chave gerada
    7. Preenche campos de auditoria automática
    8. Dispara eventos
    9. Registra em log
}

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.Rtti,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions,
  Infra.ORM.Core.Logging.Contrato,
  Infra.ORM.Core.Events.Contratos,
  Infra.ORM.Core.Generators.Contratos,
  Infra.ORM.Core.SQL.Construtor,
  Infra.ORM.Core.Persistence.Validador,
  Infra.ORM.Core.Persistence.Hidratador,
  Infra.ORM.Core.Metadata.Cache;

type

  TExecutorPersistencia = class
  strict private
    FConexao: IOrmConexao;
    FDialeto: IOrmDialeto;
    FLogger: IOrmLogger;
    FDespachante: IOrmDespachante;
    FProvedorIdentidade: IOrmProvedorIdentidade;
    FConstrutorSQL: TConstrutorSQL;
    FValidador: TValidadorEntidade;
    FHidratador: THidratador;

    procedure BindarParametros(
      AComando: IOrmComando;
      const AParametros: TArray<TParNomeValor>);

    procedure PreencherChaveGerada(
      AMetadado: IOrmMetadadoEntidade;
      AEntidade: TObject;
      AComando: IOrmComando);

    procedure PreencherGeradoresAplicacao(
      AMetadado: IOrmMetadadoEntidade;
      AEntidade: TObject);

    procedure PreencherCamposAutomaticos(
      AMetadado: IOrmMetadadoEntidade;
      AEntidade: TObject;
      AOperacao: TOperacaoOrm);

    procedure DispararEvento(
      AMetadado: IOrmMetadadoEntidade;
      AEntidade: TObject;
      AOperacao: TOperacaoOrm;
      ASucesso: Boolean;
      ADuracaoMs: Int64;
      const AMensagemErro: string = '');

    function ObterIdentidade: string;
    function ExtrairValoresChave(
      AMetadado: IOrmMetadadoEntidade;
      AEntidade: TObject): TValoresChave;

  public
    constructor Create(
      AConexao: IOrmConexao;
      ADialeto: IOrmDialeto;
      ALogger: IOrmLogger;
      ADespachante: IOrmDespachante;
      AProvedorIdentidade: IOrmProvedorIdentidade);

    destructor Destroy; override;

    procedure Inserir(AEntidade: TObject);
    procedure Atualizar(AEntidade: TObject);
    procedure Deletar(AEntidade: TObject);

    function BuscarPorId<T: class, constructor>(
      const AChave: TValoresChave): T;

    function Listar<T: class, constructor>: TObjectList<T>;

    function ExecutarSQL<T: class, constructor>(
      const ASQL: string;
      const AParametros: TArray<TParNomeValor>): TObjectList<T>;
  end;

implementation

uses
  System.Diagnostics;

{ TExecutorPersistencia }

constructor TExecutorPersistencia.Create(
  AConexao: IOrmConexao;
  ADialeto: IOrmDialeto;
  ALogger: IOrmLogger;
  ADespachante: IOrmDespachante;
  AProvedorIdentidade: IOrmProvedorIdentidade);
begin
  inherited Create;

  if not Assigned(AConexao) then
    raise EOrmConexaoExcecao.Create('Conexão não pode ser nil no executor.');

  if not Assigned(ADialeto) then
    raise EOrmDialetoExcecao.Create(
      'TExecutorPersistencia', 'Dialeto não pode ser nil no executor.');

  FConexao             := AConexao;
  FDialeto             := ADialeto;
  FLogger              := ALogger  ?? TLoggerNulo.Create;
  FDespachante         := ADespachante;
  FProvedorIdentidade  := AProvedorIdentidade;
  FConstrutorSQL       := TConstrutorSQL.Create(FDialeto);
  FValidador           := TValidadorEntidade.Create;
  FHidratador          := THidratador.Create(FLogger);
end;

destructor TExecutorPersistencia.Destroy;
begin
  FHidratador.Free;
  FValidador.Free;
  FConstrutorSQL.Free;

  FConexao            := nil;
  FDialeto            := nil;
  FLogger             := nil;
  FDespachante        := nil;
  FProvedorIdentidade := nil;

  inherited Destroy;
end;

function TExecutorPersistencia.ObterIdentidade: string;
begin
  if Assigned(FProvedorIdentidade) then
    Result := FProvedorIdentidade.ObterIdentidade
  else
    Result := '';
end;

function TExecutorPersistencia.ExtrairValoresChave(
  AMetadado: IOrmMetadadoEntidade;
  AEntidade: TObject): TValoresChave;
var
  LChaves: TArray<IOrmMetadadoPropriedade>;
  LIndice: Integer;
begin
  LChaves := AMetadado.Chaves;
  SetLength(Result, Length(LChaves));
  for LIndice := 0 to High(LChaves) do
    Result[LIndice] := LChaves[LIndice].ObterValor(AEntidade);
end;

procedure TExecutorPersistencia.BindarParametros(
  AComando: IOrmComando;
  const AParametros: TArray<TParNomeValor>);
var
  LPar: TParNomeValor;
begin
  AComando.LimparParametros;
  for LPar in AParametros do
    AComando.AdicionarParametro(LPar.Nome, LPar.Valor);
end;

procedure TExecutorPersistencia.PreencherGeradoresAplicacao(
  AMetadado: IOrmMetadadoEntidade;
  AEntidade: TObject);
var
  LChave: IOrmMetadadoPropriedade;
  LGerador: IOrmGeradorValor;
  LValorAtual: TValue;
begin
  for LChave in AMetadado.Chaves do
  begin
    if LChave.EhAutoIncremento then
      Continue;

    if LChave.EstrategiaChave = ecNenhuma then
      Continue;

    // Só gera se o valor ainda estiver vazio/default
    LValorAtual := LChave.ObterValor(AEntidade);
    if not LValorAtual.IsEmpty then
    begin
      if (LValorAtual.Kind in [tkString, tkUString]) and
         not LValorAtual.AsString.IsEmpty then
        Continue;
    end;

    LGerador := TFabricaGeradores.ObterGerador(LChave.EstrategiaChave);

    if LGerador.GerarNaAplicacao then
      LChave.DefinirValor(
        AEntidade,
        TValue.From<string>(LGerador.Gerar));
  end;
end;

procedure TExecutorPersistencia.PreencherChaveGerada(
  AMetadado: IOrmMetadadoEntidade;
  AEntidade: TObject;
  AComando: IOrmComando);
var
  LChaves: TArray<IOrmMetadadoPropriedade>;
  LChave: IOrmMetadadoPropriedade;
  LValorGerado: TValue;
begin
  LChaves := AMetadado.Chaves;

  if (Length(LChaves) <> 1) or not LChaves[0].EhAutoIncremento then
    Exit;

  LChave := LChaves[0];

  try
    // Tenta ler via RETURNING (PostgreSQL, Firebird) ou last_insert_id
    if FDialeto.SuportaReturning then
      LValorGerado := AComando.ExecutarEscalar
    else
    begin
      // Executa SQL de obtenção da última chave gerada
      var LComandoChave := FConexao.CriarComando;
      LComandoChave.DefinirSQL(FDialeto.SQLChaveGerada);
      LValorGerado := LComandoChave.ExecutarEscalar;
    end;

    if not LValorGerado.IsEmpty then
      LChave.DefinirValor(AEntidade, LValorGerado);
  except
    on E: Exception do
      FLogger.Aviso(
        'Falha ao recuperar chave gerada pelo banco — entidade pode ficar sem ID',
        TContextoLog.Novo
          .Add('entidade', AMetadado.NomeClasse)
          .Add('erro', E.Message)
          .Construir);
  end;
end;

procedure TExecutorPersistencia.PreencherCamposAutomaticos(
  AMetadado: IOrmMetadadoEntidade;
  AEntidade: TObject;
  AOperacao: TOperacaoOrm);
var
  LProp: IOrmMetadadoPropriedade;
  LAgora: TDateTime;
  LIdentidade: TValue;
begin
  LAgora      := Now;
  LIdentidade := TValue.From<string>(ObterIdentidade);

  for LProp in AMetadado.Propriedades do
  begin
    case AOperacao of
      ooInserir:
        begin
          if LProp.EhCriadoEm then
            LProp.DefinirValor(AEntidade, TValue.From<TDateTime>(LAgora));
          if LProp.EhAtualizadoEm then
            LProp.DefinirValor(AEntidade, TValue.From<TDateTime>(LAgora));
          if LProp.EhCriadoPor then
            LProp.DefinirValor(AEntidade, LIdentidade);
          if LProp.EhAtualizadoPor then
            LProp.DefinirValor(AEntidade, LIdentidade);
        end;

      ooAtualizar:
        begin
          if LProp.EhAtualizadoEm then
            LProp.DefinirValor(AEntidade, TValue.From<TDateTime>(LAgora));
          if LProp.EhAtualizadoPor then
            LProp.DefinirValor(AEntidade, LIdentidade);
        end;
    end;
  end;
end;

procedure TExecutorPersistencia.DispararEvento(
  AMetadado: IOrmMetadadoEntidade;
  AEntidade: TObject;
  AOperacao: TOperacaoOrm;
  ASucesso: Boolean;
  ADuracaoMs: Int64;
  const AMensagemErro: string);
var
  LEvento: TEventoOrmOperacao;
begin
  if not Assigned(FDespachante) then
    Exit;
  try
    LEvento.IdEvento           := '';
    LEvento.OcorridoEm         := Now;
    LEvento.Operacao           := AOperacao;
    LEvento.NomeEntidade       := AMetadado.NomeClasse;
    LEvento.ValoresChave       := ExtrairValoresChave(AMetadado, AEntidade);
    LEvento.Entidade           := AEntidade;
    LEvento.DadosAnteriores    := nil;
    LEvento.DadosPosteriores   := nil;
    LEvento.Sucesso            := ASucesso;
    LEvento.MensagemErro       := AMensagemErro;
    LEvento.IdentidadeContexto := ObterIdentidade;
    LEvento.DuracaoMs          := ADuracaoMs;

    FDespachante.Despachar(LEvento);
  except
    on E: Exception do
      FLogger.Aviso('Falha ao despachar evento de persistência — ignorado',
        TContextoLog.Novo
          .Add('entidade', AMetadado.NomeClasse)
          .Add('operacao', Ord(AOperacao))
          .Add('erro', E.Message)
          .Construir);
  end;
end;

procedure TExecutorPersistencia.Inserir(AEntidade: TObject);
var
  LSQL: string;
  LComando: IOrmComando;
  LCronometro: TStopwatch;
  LChave: TValoresChave;
  LIdentidade: string;
begin
  VerificarNaoNulo(AEntidade, 'Entidade não pode ser nil para Inserir.');

  // ── 1. Interceptação PRÉ-operação ─────────────────────────────────────────
  // Preenche campos automáticos (CriadoEm, CriadoPor, TenantId, etc.)
  // Pode lançar EOrmSoftDeleteExcecao (não ocorre no Insert, mas padrão geral)
  if Assigned(FDespachante) then
    FDespachante.Antes(ooInserir, AMetadado, AEntidade);

  // ── 2. Validação ──────────────────────────────────────────────────────────
  FValidador.Validar(AMetadado, AEntidade);

  // ── 3. Geração de chave (UUID) ────────────────────────────────────────────
  GerarChaveSePreciso(AMetadado, AEntidade);

  // ── 4. Construção e execução do SQL ───────────────────────────────────────
  LCronometro := TStopwatch.StartNew;
  try
    LSQL     := FSqlBuilder.ConstruirInsert(AMetadado, AEntidade);
    LComando := FConexao.CriarComando;
    LComando.DefinirSQL(LSQL);
    LComando.Preparar;
    BindarParametros(LComando, AMetadado, AEntidade);
    LComando.ExecutarSemRetorno;

    // Recupera ID autoincremento se aplicável
    RecuperarIdAutoIncremento(AMetadado, AEntidade, LComando);

    LCronometro.Stop;

    // ── 5. Interceptação PÓS-operação (sucesso) ───────────────────────────
    if Assigned(FDespachante) then
      FDespachante.Depois(ooInserir, AMetadado, AEntidade, True);

    // ── 6. Despacho do evento de auditoria ────────────────────────────────
    if Assigned(FDespachante) then
    begin
      LChave      := ExtrairValoresChave(AMetadado, AEntidade);
      LIdentidade := ObterIdentidade;

      FDespachante.Despachar(
        TEventoOrmOperacao.CriarSucesso(
          ooInserir,
          AMetadado.NomeClasse,
          AEntidade,
          LChave,
          LIdentidade,
          LCronometro.ElapsedMilliseconds));
    end;

  except
    on E: Exception do
    begin
      LCronometro.Stop;

      // Interceptação PÓS-operação (falha)
      if Assigned(FDespachante) then
        FDespachante.Depois(ooInserir, AMetadado, AEntidade, False);

      // Despacha evento de falha
      if Assigned(FDespachante) then
        FDespachante.Despachar(
          TEventoOrmOperacao.CriarFalha(
            ooInserir,
            AMetadado.NomeClasse,
            E.Message,
            ObterIdentidade));

      if E is EOrmExcecao then raise;

      raise EOrmComandoExcecao.Create(
        AMetadado.NomeClasse,
        Format('Falha ao inserir "%s": %s',
          [AMetadado.NomeClasse, E.Message]), E);
    end;
  end;
end;

procedure TExecutorPersistencia.Atualizar(AEntidade: TObject);
var
  LMetadado: IOrmMetadadoEntidade;
  LComandoSQL: TComandoSQL;
  LComando: IOrmComando;
  LLinhasAfetadas: Integer;
  LCronometro: TStopwatch;
begin
  if not Assigned(AEntidade) then
    raise EOrmPersistenciaExcecao.Create(
      'TObject', 'Atualizar', 'Entidade não pode ser nil.');

  LMetadado := TCacheMetadados.Instancia.Resolver(AEntidade.ClassType);
  LCronometro := TStopwatch.StartNew;
  try
    FValidador.Validar(LMetadado, AEntidade);
    FValidador.ValidarChaves(LMetadado, AEntidade);
    PreencherCamposAutomaticos(LMetadado, AEntidade, TOperacaoOrm.ooAtualizar);

    LComandoSQL := FConstrutorSQL.GerarUpdate(LMetadado, AEntidade);

    FLogger.Debug('Executando UPDATE',
      TContextoLog.Novo
        .Add('entidade', LMetadado.NomeClasse)
        .Add('tabela', LMetadado.NomeQualificado)
        .Add('sql', LComandoSQL.SQL)
        .Construir);

    LComando := FConexao.CriarComando;
    LComando.DefinirSQL(LComandoSQL.SQL);
    LComando.Preparar;
    BindarParametros(LComando, LComandoSQL.Parametros);
    LLinhasAfetadas := LComando.ExecutarSemRetorno;

    if LLinhasAfetadas = 0 then
      raise EOrmConcorrenciaExcecao.Create(
        LMetadado.NomeClasse,
        'Nenhuma linha afetada no UPDATE. ' +
        'O registro pode ter sido removido por outra sessão.');

    LCronometro.Stop;
    DispararEvento(LMetadado, AEntidade,
      TOperacaoOrm.ooAtualizar, True, LCronometro.ElapsedMilliseconds);

    FLogger.Informacao('UPDATE concluído',
      TContextoLog.Novo
        .Add('entidade', LMetadado.NomeClasse)
        .Add('linhas_afetadas', LLinhasAfetadas)
        .Add('duracao_ms', LCronometro.ElapsedMilliseconds)
        .Construir);
  except
    on E: Exception do
    begin
      LCronometro.Stop;
      DispararEvento(LMetadado, AEntidade,
        TOperacaoOrm.ooAtualizar, False,
        LCronometro.ElapsedMilliseconds, E.Message);

      FLogger.Erro('Falha no UPDATE', E,
        TContextoLog.Novo
          .Add('entidade', LMetadado.NomeClasse)
          .Construir);

      if E is EOrmExcecao then raise;

      raise EOrmPersistenciaExcecao.Create(
        LMetadado.NomeClasse, 'Atualizar',
        Format('Falha ao atualizar entidade: %s', [E.Message]), E);
    end;
  end;
end;

procedure TExecutorPersistencia.Deletar(AEntidade: TObject);
var
  LMetadado: IOrmMetadadoEntidade;
  LComandoSQL: TComandoSQL;
  LComando: IOrmComando;
  LLinhasAfetadas: Integer;
  LCronometro: TStopwatch;
begin
  if not Assigned(AEntidade) then
    raise EOrmPersistenciaExcecao.Create(
      'TObject', 'Deletar', 'Entidade não pode ser nil.');

  LMetadado := TCacheMetadados.Instancia.Resolver(AEntidade.ClassType);
  LCronometro := TStopwatch.StartNew;
  try
    FValidador.ValidarChaves(LMetadado, AEntidade);

    LComandoSQL := FConstrutorSQL.GerarDelete(LMetadado, AEntidade);

    FLogger.Debug('Executando DELETE',
      TContextoLog.Novo
        .Add('entidade', LMetadado.NomeClasse)
        .Add('tabela', LMetadado.NomeQualificado)
        .Add('sql', LComandoSQL.SQL)
        .Construir);

    LComando := FConexao.CriarComando;
    LComando.DefinirSQL(LComandoSQL.SQL);
    LComando.Preparar;
    BindarParametros(LComando, LComandoSQL.Parametros);
    LLinhasAfetadas := LComando.ExecutarSemRetorno;

    if LLinhasAfetadas = 0 then
      FLogger.Aviso('DELETE não afetou nenhuma linha',
        TContextoLog.Novo
          .Add('entidade', LMetadado.NomeClasse)
          .Construir);

    LCronometro.Stop;
    DispararEvento(LMetadado, AEntidade,
      TOperacaoOrm.ooDeletar, True, LCronometro.ElapsedMilliseconds);

    FLogger.Informacao('DELETE concluído',
      TContextoLog.Novo
        .Add('entidade', LMetadado.NomeClasse)
        .Add('linhas_afetadas', LLinhasAfetadas)
        .Add('duracao_ms', LCronometro.ElapsedMilliseconds)
        .Construir);
  except
    on E: Exception do
    begin
      LCronometro.Stop;
      DispararEvento(LMetadado, AEntidade,
        TOperacaoOrm.ooDeletar, False,
        LCronometro.ElapsedMilliseconds, E.Message);

      FLogger.Erro('Falha no DELETE', E,
        TContextoLog.Novo
          .Add('entidade', LMetadado.NomeClasse)
          .Construir);

      if E is EOrmExcecao then raise;

      raise EOrmPersistenciaExcecao.Create(
        LMetadado.NomeClasse, 'Deletar',
        Format('Falha ao deletar entidade: %s', [E.Message]), E);
    end;
  end;
end;

function TExecutorPersistencia.BuscarPorId<T>(
  const AChave: TValoresChave): T;
var
  LMetadado: IOrmMetadadoEntidade;
  LChaves: TArray<IOrmMetadadoPropriedade>;
  LSQL: string;
  LComando: IOrmComando;
  LLeitor: IOrmLeitorDados;
  LIndice: Integer;
  LCronometro: TStopwatch;
begin
  Result    := nil;
  LMetadado := TCacheMetadados.Instancia.Resolver(T);
  LChaves   := LMetadado.Chaves;
  LCronometro := TStopwatch.StartNew;

  if Length(AChave) <> Length(LChaves) then
    raise EOrmConsultaExcecao.Create(
      LMetadado.NomeClasse,
      Format(
        'Quantidade de valores de chave informados (%d) ' +
        'não corresponde ao número de chaves da entidade (%d).',
        [Length(AChave), Length(LChaves)]));
  try
    LSQL    := FConstrutorSQL.GerarSelectPorId(LMetadado);
    LComando := FConexao.CriarComando;
    LComando.DefinirSQL(LSQL);
    LComando.Preparar;

    for LIndice := 0 to High(LChaves) do
      LComando.AdicionarParametro(
        FDialeto.PrefixoParametro + LChaves[LIndice].NomeColuna.ToLower,
        AChave[LIndice]);

    LLeitor := LComando.ExecutarConsulta;

    if LLeitor.Proximo then
      Result := FHidratador.Hidratar<T>(LMetadado, LLeitor);

    LCronometro.Stop;
    FLogger.Debug('BuscarPorId concluído',
      TContextoLog.Novo
        .Add('entidade', LMetadado.NomeClasse)
        .Add('encontrado', Assigned(Result))
        .Add('duracao_ms', LCronometro.ElapsedMilliseconds)
        .Construir);
  except
    on E: Exception do
    begin
      LCronometro.Stop;
      FLogger.Erro('Falha no BuscarPorId', E,
        TContextoLog.Novo
          .Add('entidade', LMetadado.NomeClasse)
          .Construir);

      if E is EOrmExcecao then raise;

      raise EOrmConsultaExcecao.Create(
        LMetadado.NomeClasse,
        Format('Falha ao buscar por ID: %s', [E.Message]), E);
    end;
  end;
end;

function TExecutorPersistencia.Listar<T>: TObjectList<T>;
var
  LMetadado: IOrmMetadadoEntidade;
  LSQL: string;
  LComando: IOrmComando;
  LLeitor: IOrmLeitorDados;
  LCronometro: TStopwatch;
begin
  LMetadado   := TCacheMetadados.Instancia.Resolver(T);
  LCronometro := TStopwatch.StartNew;
  try
    LSQL     := FConstrutorSQL.GerarSelectTodos(LMetadado);
    LComando := FConexao.CriarComando;
    LComando.DefinirSQL(LSQL);
    LComando.Preparar;
    LLeitor := LComando.ExecutarConsulta;

    Result := FHidratador.HidratarLista<T>(LMetadado, LLeitor);

    LCronometro.Stop;
    FLogger.Debug('Listar concluído',
      TContextoLog.Novo
        .Add('entidade', LMetadado.NomeClasse)
        .Add('total', Result.Count)
        .Add('duracao_ms', LCronometro.ElapsedMilliseconds)
        .Construir);
  except
    on E: Exception do
    begin
      LCronometro.Stop;
      FLogger.Erro('Falha no Listar', E,
        TContextoLog.Novo
          .Add('entidade', LMetadado.NomeClasse)
          .Construir);

      if E is EOrmExcecao then raise;

      raise EOrmConsultaExcecao.Create(
        LMetadado.NomeClasse,
        Format('Falha ao listar entidades: %s', [E.Message]), E);
    end;
  end;
end;

function TExecutorPersistencia.ExecutarSQL<T>(
  const ASQL: string;
  const AParametros: TArray<TParNomeValor>): TObjectList<T>;
var
  LMetadado: IOrmMetadadoEntidade;
  LComando: IOrmComando;
  LLeitor: IOrmLeitorDados;
  LPar: TParNomeValor;
begin
  LMetadado := TCacheMetadados.Instancia.Resolver(T);

  LComando := FConexao.CriarComando;
  LComando.DefinirSQL(ASQL);

  for LPar in AParametros do
    LComando.AdicionarParametro(LPar.Nome, LPar.Valor);

  LLeitor := LComando.ExecutarConsulta;
  Result  := FHidratador.HidratarLista<T>(LMetadado, LLeitor);
end;

end.
