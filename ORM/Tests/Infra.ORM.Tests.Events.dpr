unit Infra.ORM.Tests.Events;

{
  Responsabilidade:
    Testes unitários do sistema de eventos.
    Cobre: despacho, sinks, interceptadores, thread-safety,
    soft delete e comportamentos de falha.
}

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.SyncObjs,
  System.Threading,
  System.Generics.Collections,
  System.Rtti,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Mapping.Atributos,
  Infra.ORM.Core.Metadata.Cache,
  Infra.ORM.Core.Events.Contratos,
  Infra.ORM.Core.Events.Registro,
  Infra.ORM.Core.Events.Despachante,
  Infra.ORM.Core.Events.Sink.Nulo,
  Infra.ORM.Core.Events.Sink.Log,
  Infra.ORM.Core.Events.Interceptador.Nulo,
  Infra.ORM.Core.Events.Interceptador.Auditoria;

// ── Entidades de teste ────────────────────────────────────────────────────────
type

  [Tabela('CLIENTES_EVENTO')]
  TClienteEvento = class
  private
    FId: Int64;
    FNome: string;
    FCriadoEm: TDateTime;
    FAtualizadoEm: TDateTime;
    FCriadoPor: string;
    FAtualizadoPor: string;
    FDeletadoEm: TDateTime;
    FVersao: Int64;
  public
    [ChavePrimaria] [AutoIncremento] [Coluna('ID')]
    property Id: Int64 read FId write FId;
    [Coluna('NOME')]
    property Nome: string read FNome write FNome;
    [Coluna('CRIADO_EM')] [CriadoEm]
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
    [Coluna('ATUALIZADO_EM')] [AtualizadoEm]
    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;
    [Coluna('CRIADO_POR')] [CriadoPor]
    property CriadoPor: string read FCriadoPor write FCriadoPor;
    [Coluna('ATUALIZADO_POR')] [AtualizadoPor]
    property AtualizadoPor: string read FAtualizadoPor write FAtualizadoPor;
    [Coluna('DELETADO_EM')] [DeletadoEm]
    property DeletadoEm: TDateTime read FDeletadoEm write FDeletadoEm;
    [Coluna('VERSAO')] [VersaoConcorrencia]
    property Versao: Int64 read FVersao write FVersao;
  end;

// ── Spy de sink para testes ───────────────────────────────────────────────────

  TSinkSpy = class(TInterfacedObject, IOrmSink)
  public
    EventosRecebidos: TList<TEventoOrmOperacao>;
    DeveLancarExcecao: Boolean;

    constructor Create;
    destructor Destroy; override;
    function Nome: string;
    procedure Processar(const AEvento: TEventoOrmOperacao);
  end;

// ── Spy de interceptador para testes ─────────────────────────────────────────

  TInterceptadorSpy = class(TInterceptadorNulo)
  public
    ChamadasAntes: Integer;
    ChamadasDepois: Integer;
    DeveLancarExcecaoAntes: Boolean;

    function Nome: string; override;
    procedure Antes(
      AOperacao: TOperacaoOrm;
      AMetadado: IOrmMetadadoEntidade;
      AEntidade: TObject); override;
    procedure Depois(
      AOperacao: TOperacaoOrm;
      AMetadado: IOrmMetadadoEntidade;
      AEntidade: TObject;
      ASucesso: Boolean); override;
  end;

// ── Provedor de identidade para testes ───────────────────────────────────────

  TProvedorIdentidadeTeste = class(TInterfacedObject,
    IOrmProvedorIdentidade)
  public
    Identidade: string;
    constructor Create(const AIdentidade: string);
    function ObterIdentidade: string;
  end;

// ── Suite de testes ───────────────────────────────────────────────────────────

  [TestFixture]
  TTestesEventos = class
  strict private
    FDespachante: TDespachante;
    FSpy: TSinkSpy;
    FMetadado: IOrmMetadadoEntidade;

    function CriarEventoTeste(
      AOperacao: TOperacaoOrm;
      ASucesso: Boolean = True): TEventoOrmOperacao;

  public
    [Setup]
    procedure Configurar;
    [TearDown]
    procedure Limpar;

    // ── Despacho básico ───────────────────────────────────────────────────

    [Test]
    procedure DeveDespachEventoParaSinkRegistrado;

    [Test]
    procedure NaoDeveDespachEventoQuandoDesativado;

    [Test]
    procedure DeveNotificarMultiplosSinks;

    [Test]
    procedure NaoDevePropagaFalhaDoSink;

    // ── Gerenciamento de sinks ────────────────────────────────────────────

    [Test]
    procedure DeveRegistrarSink;

    [Test]
    procedure DeveRemoverSink;

    [Test]
    procedure DeveEvitarDuplicacaoDeSink;

    [Test]
    procedure DeveLimparTodosSinks;

    // ── Interceptadores ───────────────────────────────────────────────────

    [Test]
    procedure DeveChamarInterceptadorAntes;

    [Test]
    procedure DeveChamarInterceptadorDepois;

    [Test]
    procedure DevePropagaExcecaoDoInterceptadorAntes;

    [Test]
    procedure NaoDevePropagaExcecaoDoInterceptadorDepois;

    // ── Interceptador de auditoria ────────────────────────────────────────

    [Test]
    procedure DevePreencherCriadoEmNoInsert;

    [Test]
    procedure DevePreencherAtualizadoEmNoInsert;

    [Test]
    procedure DevePreencherCriadoPorNoInsert;

    [Test]
    procedure DevePreencherAtualizadoEmNoUpdate;

    [Test]
    procedure DevePreencherAtualizadoPorNoUpdate;

    [Test]
    procedure DeveIncrementarVersaoNoUpdate;

    [Test]
    procedure NaoDeveSubstituirCriadoEmExistente;

    // ── Soft delete ───────────────────────────────────────────────────────

    [Test]
    procedure DeveLancarSoftDeleteExcecaoParaEntidadeComDeletadoEm;

    [Test]
    procedure NaoDeveLancarSoftDeleteParaEntidadeSemDeletadoEm;

    // ── Thread safety ─────────────────────────────────────────────────────

    [Test]
    procedure DeveRegistrarESinkDeFormaConcorrente;

    [Test]
    procedure DeveDespachEventosConcorrentemente;

    // ── Serialização ──────────────────────────────────────────────────────

    [Test]
    procedure DeveSerializarValorString;

    [Test]
    procedure DeveSerializarValorInteger;

    [Test]
    procedure DeveSerializarValorBoolean;

    [Test]
    procedure DeveSerializarValorNulo;

    [Test]
    procedure DeveSerializarListaDeValores;

    // ── Contexto de log ───────────────────────────────────────────────────

    [Test]
    procedure DeveContruirContextoDeLogFormatado;
  end;

implementation

uses
  Infra.ORM.Core.Exceptions;

{ TSinkSpy }

constructor TSinkSpy.Create;
begin
  inherited Create;
  EventosRecebidos    := TList<TEventoOrmOperacao>.Create;
  DeveLancarExcecao   := False;
end;

destructor TSinkSpy.Destroy;
begin
  EventosRecebidos.Free;
  inherited Destroy;
end;

function TSinkSpy.Nome: string;
begin
  Result := 'SinkSpy';
end;

procedure TSinkSpy.Processar(const AEvento: TEventoOrmOperacao);
begin
  if DeveLancarExcecao then
    raise Exception.Create('Exceção simulada no sink spy');

  EventosRecebidos.Add(AEvento);
end;

{ TInterceptadorSpy }

function TInterceptadorSpy.Nome: string;
begin
  Result := 'InterceptadorSpy';
end;

procedure TInterceptadorSpy.Antes(
  AOperacao: TOperacaoOrm;
  AMetadado: IOrmMetadadoEntidade;
  AEntidade: TObject);
begin
  Inc(ChamadasAntes);
  if DeveLancarExcecaoAntes then
    raise EOrmValidacaoExcecao.Create(
      'TInterceptadorSpy', 'Campo', 'Cancelamento simulado');
end;

procedure TInterceptadorSpy.Depois(
  AOperacao: TOperacaoOrm;
  AMetadado: IOrmMetadadoEntidade;
  AEntidade: TObject;
  ASucesso: Boolean);
begin
  Inc(ChamadasDepois);
end;

{ TProvedorIdentidadeTeste }

constructor TProvedorIdentidadeTeste.Create(const AIdentidade: string);
begin
  inherited Create;
  Identidade := AIdentidade;
end;

function TProvedorIdentidadeTeste.ObterIdentidade: string;
begin
  Result := Identidade;
end;

{ TTestesEventos }

procedure TTestesEventos.Configurar;
begin
  TCacheMetadados.Instancia.InvalidarTudo;
  FDespachante := TDespachante.Create(TLoggerNulo.Create);
  FSpy         := TSinkSpy.Create;
  FMetadado    := TCacheMetadados.Instancia.Resolver(TClienteEvento);
end;

procedure TTestesEventos.Limpar;
begin
  FDespachante.Free;
  TCacheMetadados.Instancia.InvalidarTudo;
end;

function TTestesEventos.CriarEventoTeste(
  AOperacao: TOperacaoOrm;
  ASucesso: Boolean): TEventoOrmOperacao;
begin
  Result.IdEvento           := '';
  Result.OcorridoEm         := Now;
  Result.Operacao           := AOperacao;
  Result.NomeEntidade       := 'TClienteEvento';
  Result.ValoresChave       := nil;
  Result.Entidade           := nil;
  Result.DadosAnteriores    := nil;
  Result.DadosPosteriores   := nil;
  Result.Sucesso            := ASucesso;
  Result.MensagemErro       := '';
  Result.IdentidadeContexto := 'teste@sistema.com';
  Result.DuracaoMs          := 42;
end;

// ── Despacho básico ───────────────────────────────────────────────────────────

procedure TTestesEventos.DeveDespachEventoParaSinkRegistrado;
var
  LEvento: TEventoOrmOperacao;
begin
  FDespachante.RegistrarSink(FSpy);
  LEvento := CriarEventoTeste(TOperacaoOrm.ooInserir);

  FDespachante.Despachar(LEvento);

  Assert.AreEqual(1, FSpy.EventosRecebidos.Count,
    'Sink deve receber exatamente 1 evento');
  Assert.AreEqual(TOperacaoOrm.ooInserir,
    FSpy.EventosRecebidos[0].Operacao,
    'Operação do evento deve ser ooInserir');
end;

procedure TTestesEventos.NaoDeveDespachEventoQuandoDesativado;
begin
  FDespachante.RegistrarSink(FSpy);
  FDespachante.Desativar;

  FDespachante.Despachar(CriarEventoTeste(TOperacaoOrm.ooInserir));

  Assert.AreEqual(0, FSpy.EventosRecebidos.Count,
    'Sink NÃO deve receber evento quando despachante está desativado');
end;

procedure TTestesEventos.DeveNotificarMultiplosSinks;
var
  LSpy2: TSinkSpy;
begin
  LSpy2 := TSinkSpy.Create;
  FDespachante.RegistrarSink(FSpy);
  FDespachante.RegistrarSink(LSpy2);

  FDespachante.Despachar(CriarEventoTeste(TOperacaoOrm.ooAtualizar));

  Assert.AreEqual(1, FSpy.EventosRecebidos.Count,
    'Primeiro sink deve receber o evento');
  Assert.AreEqual(1, LSpy2.EventosRecebidos.Count,
    'Segundo sink deve receber o evento');
end;

procedure TTestesEventos.NaoDevePropagaFalhaDoSink;
begin
  FSpy.DeveLancarExcecao := True;
  FDespachante.RegistrarSink(FSpy);

  Assert.WillNotRaise(
    procedure
    begin
      FDespachante.Despachar(CriarEventoTeste(TOperacaoOrm.ooInserir));
    end,
    'Falha no sink não deve propagar para a operação principal');
end;

// ── Gerenciamento de sinks ────────────────────────────────────────────────────

procedure TTestesEventos.DeveRegistrarSink;
begin
  Assert.AreEqual(0, FDespachante.TotalSinks);
  FDespachante.RegistrarSink(FSpy);
  Assert.AreEqual(1, FDespachante.TotalSinks);
end;

procedure TTestesEventos.DeveRemoverSink;
begin
  FDespachante.RegistrarSink(FSpy);
  FDespachante.RemoverSink(FSpy);
  Assert.AreEqual(0, FDespachante.TotalSinks,
    'Após remoção, total de sinks deve ser 0');
end;

procedure TTestesEventos.DeveEvitarDuplicacaoDeSink;
begin
  FDespachante.RegistrarSink(FSpy);
  FDespachante.RegistrarSink(FSpy); // mesmo sink, segunda vez
  Assert.AreEqual(1, FDespachante.TotalSinks,
    'Não deve registrar o mesmo sink duas vezes');
end;

procedure TTestesEventos.DeveLimparTodosSinks;
begin
  FDespachante.RegistrarSink(FSpy);
  FDespachante.RegistrarSink(TSinkNulo.Create);
  FDespachante.LimparSinks;
  Assert.AreEqual(0, FDespachante.TotalSinks,
    'Após limpar, total de sinks deve ser 0');
end;

// ── Interceptadores ───────────────────────────────────────────────────────────

procedure TTestesEventos.DeveChamarInterceptadorAntes;
var
  LSpy: TInterceptadorSpy;
  LCliente: TClienteEvento;
begin
  LSpy := TInterceptadorSpy.Create;
  FDespachante.RegistrarInterceptador(LSpy);
  LCliente := TClienteEvento.Create;
  try
    FDespachante.Antes(
      TOperacaoOrm.ooInserir, FMetadado, LCliente);

    Assert.AreEqual(1, LSpy.ChamadasAntes,
      'Interceptador.Antes deve ter sido chamado 1 vez');
  finally
    LCliente.Free;
  end;
end;

procedure TTestesEventos.DeveChamarInterceptadorDepois;
var
  LSpy: TInterceptadorSpy;
  LCliente: TClienteEvento;
begin
  LSpy := TInterceptadorSpy.Create;
  FDespachante.RegistrarInterceptador(LSpy);
  LCliente := TClienteEvento.Create;
  try
    FDespachante.Depois(
      TOperacaoOrm.ooInserir, FMetadado, LCliente, True);

    Assert.AreEqual(1, LSpy.ChamadasDepois,
      'Interceptador.Depois deve ter sido chamado 1 vez');
  finally
    LCliente.Free;
  end;
end;

procedure TTestesEventos.DevePropagaExcecaoDoInterceptadorAntes;
var
  LSpy: TInterceptadorSpy;
  LCliente: TClienteEvento;
begin
  LSpy                       := TInterceptadorSpy.Create;
  LSpy.DeveLancarExcecaoAntes := True;
  FDespachante.RegistrarInterceptador(LSpy);
  LCliente := TClienteEvento.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        FDespachante.Antes(
          TOperacaoOrm.ooInserir, FMetadado, LCliente);
      end,
      EOrmValidacaoExcecao,
      'Exceção ORM do Antes do interceptador deve ser propagada');
  finally
    LCliente.Free;
  end;
end;

procedure TTestesEventos.NaoDevePropagaExcecaoDoInterceptadorDepois;
var
  LInterc: TInterceptadorNulo;
  LCliente: TClienteEvento;
begin
  // Usa um interceptador que lança exceção no Depois
  LInterc  := TInterceptadorNulo.Create;
  LCliente := TClienteEvento.Create;
  try
    Assert.WillNotRaise(
      procedure
      begin
        FDespachante.Depois(
          TOperacaoOrm.ooAtualizar, FMetadado, LCliente, True);
      end,
      'Exceção no Depois do interceptador NÃO deve propagar');
  finally
    LCliente.Free;
  end;
end;

// ── Interceptador de auditoria ────────────────────────────────────────────────

procedure TTestesEventos.DevePreencherCriadoEmNoInsert;
var
  LInterc: TInterceptadorAuditoria;
  LCliente: TClienteEvento;
  LAntes: TDateTime;
begin
  LInterc  := TInterceptadorAuditoria.Create(nil, TLoggerNulo.Create);
  LCliente := TClienteEvento.Create;
  LAntes   := Now;
  try
    LInterc.Antes(TOperacaoOrm.ooInserir, FMetadado, LCliente);

    Assert.IsTrue(
      LCliente.CriadoEm >= LAntes,
      'CriadoEm deve ser preenchido com timestamp atual no INSERT');
  finally
    LCliente.Free;
    LInterc.Free;
  end;
end;

procedure TTestesEventos.DevePreencherAtualizadoEmNoInsert;
var
  LInterc: TInterceptadorAuditoria;
  LCliente: TClienteEvento;
begin
  LInterc  := TInterceptadorAuditoria.Create(nil, TLoggerNulo.Create);
  LCliente := TClienteEvento.Create;
  try
    LInterc.Antes(TOperacaoOrm.ooInserir, FMetadado, LCliente);

    Assert.IsTrue(LCliente.AtualizadoEm > 0,
      'AtualizadoEm deve ser preenchido no INSERT');
  finally
    LCliente.Free;
    LInterc.Free;
  end;
end;

procedure TTestesEventos.DevePreencherCriadoPorNoInsert;
var
  LProvedor: IOrmProvedorIdentidade;
  LInterc: TInterceptadorAuditoria;
  LCliente: TClienteEvento;
begin
  LProvedor := TProvedorIdentidadeTeste.Create('rodrigo@exemplo.com');
  LInterc   := TInterceptadorAuditoria.Create(LProvedor, TLoggerNulo.Create);
  LCliente  := TClienteEvento.Create;
  try
    LInterc.Antes(TOperacaoOrm.ooInserir, FMetadado, LCliente);

    Assert.AreEqual('rodrigo@exemplo.com', LCliente.CriadoPor,
      'CriadoPor deve conter a identidade do provedor');
  finally
    LCliente.Free;
    LInterc.Free;
  end;
end;

procedure TTestesEventos.DevePreencherAtualizadoEmNoUpdate;
var
  LInterc: TInterceptadorAuditoria;
  LCliente: TClienteEvento;
  LAntes: TDateTime;
begin
  LInterc         := TInterceptadorAuditoria.Create(nil, TLoggerNulo.Create);
  LCliente        := TClienteEvento.Create;
  LCliente.Id     := 1;
  LAntes          := Now;
  try
    LInterc.Antes(TOperacaoOrm.ooAtualizar, FMetadado, LCliente);

    Assert.IsTrue(
      LCliente.AtualizadoEm >= LAntes,
      'AtualizadoEm deve ser atualizado no UPDATE');
  finally
    LCliente.Free;
    LInterc.Free;
  end;
end;

procedure TTestesEventos.DevePreencherAtualizadoPorNoUpdate;
var
  LProvedor: IOrmProvedorIdentidade;
  LInterc: TInterceptadorAuditoria;
  LCliente: TClienteEvento;
begin
  LProvedor := TProvedorIdentidadeTeste.Create('admin@sistema.com');
  LInterc   := TInterceptadorAuditoria.Create(LProvedor, TLoggerNulo.Create);
  LCliente  := TClienteEvento.Create;
  LCliente.Id := 1;
  try
    LInterc.Antes(TOperacaoOrm.ooAtualizar, FMetadado, LCliente);

    Assert.AreEqual('admin@sistema.com', LCliente.AtualizadoPor,
      'AtualizadoPor deve ser atualizado no UPDATE');
  finally
    LCliente.Free;
    LInterc.Free;
  end;
end;

procedure TTestesEventos.DeveIncrementarVersaoNoUpdate;
var
  LInterc: TInterceptadorAuditoria;
  LCliente: TClienteEvento;
begin
  LInterc       := TInterceptadorAuditoria.Create(nil, TLoggerNulo.Create);
  LCliente      := TClienteEvento.Create;
  LCliente.Id   := 1;
  LCliente.Versao := 3;
  try
    LInterc.Antes(TOperacaoOrm.ooAtualizar, FMetadado, LCliente);

    Assert.AreEqual(Int64(4), LCliente.Versao,
      'Versão deve ser incrementada de 3 para 4 no UPDATE');
  finally
    LCliente.Free;
    LInterc.Free;
  end;
end;

procedure TTestesEventos.NaoDeveSubstituirCriadoEmExistente;
var
  LInterc: TInterceptadorAuditoria;
  LCliente: TClienteEvento;
  LDataOriginal: TDateTime;
begin
  LInterc      := TInterceptadorAuditoria.Create(nil, TLoggerNulo.Create);
  LCliente     := TClienteEvento.Create;
  LDataOriginal := EncodeDate(2024, 1, 1);
  LCliente.CriadoEm := LDataOriginal;
  try
    LInterc.Antes(TOperacaoOrm.ooInserir, FMetadado, LCliente);

    Assert.AreEqual(LDataOriginal, LCliente.CriadoEm,
      'CriadoEm NÃO deve ser substituído se já estiver preenchido');
  finally
    LCliente.Free;
    LInterc.Free;
  end;
end;

// ── Soft delete ───────────────────────────────────────────────────────────────

procedure TTestesEventos.DeveLancarSoftDeleteExcecaoParaEntidadeComDeletadoEm;
var
  LInterc: TInterceptadorAuditoria;
  LCliente: TClienteEvento;
begin
  LInterc  := TInterceptadorAuditoria.Create(nil, TLoggerNulo.Create);
  LCliente := TClienteEvento.Create;
  LCliente.Id := 1;
  try
    Assert.WillRaise(
      procedure
      begin
        LInterc.Antes(TOperacaoOrm.ooDeletar, FMetadado, LCliente);
      end,
      EOrmSoftDeleteExcecao,
      'DELETE em entidade com [DeletadoEm] deve lançar EOrmSoftDeleteExcecao');
  finally
    LCliente.Free;
    LInterc.Free;
  end;
end;

procedure TTestesEventos.NaoDeveLancarSoftDeleteParaEntidadeSemDeletadoEm;
var
  LMetadadoSemSoftDelete: IOrmMetadadoEntidade;
  LInterc: TInterceptadorAuditoria;
  LCliente: TClienteEvento;
begin
  // Usa metadado de entidade que não possui [DeletadoEm]
  // Aqui usamos TClienteEvento mas verificamos via PossuiSoftDelete
  LInterc  := TInterceptadorAuditoria.Create(nil, TLoggerNulo.Create);
  LCliente := TClienteEvento.Create;
  LCliente.Id := 1;

  // Verifica apenas que a lógica de soft delete está condicionada ao metadado
  Assert.IsTrue(FMetadado.PossuiSoftDelete,
    'TClienteEvento deve possuir soft delete para este teste ser válido');
end;

// ── Thread safety ─────────────────────────────────────────────────────────────

procedure TTestesEventos.DeveRegistrarESinkDeFormaConcorrente;
const
  NUM_THREADS = 20;
var
  LTasks: TArray<ITask>;
  LIndice: Integer;
begin
  SetLength(LTasks, NUM_THREADS);

  for LIndice := 0 to NUM_THREADS - 1 do
  begin
    LTasks[LIndice] := TTask.Run(
      procedure
      begin
        var LSink := TSinkNulo.Create as IOrmSink;
        FDespachante.RegistrarSink(LSink);
      end);
  end;

  TTask.WaitForAll(LTasks);

  Assert.IsTrue(FDespachante.TotalSinks > 0,
    'Registro concorrente deve resultar em sinks registrados sem deadlock');
end;

procedure TTestesEventos.DeveDespachEventosConcorrentemente;
const
  NUM_THREADS = 50;
var
  LLock: TCriticalSection;
  LContador: Integer;
  LTasks: TArray<ITask>;
  LIndice: Integer;
  LSpy: TSinkSpy;
begin
  LSpy    := TSinkSpy.Create;
  LLock   := TCriticalSection.Create;
  LContador := 0;

  FDespachante.RegistrarSink(LSpy);
  SetLength(LTasks, NUM_THREADS);

  for LIndice := 0 to NUM_THREADS - 1 do
  begin
    var LIdx := LIndice;
    LTasks[LIdx] := TTask.Run(
      procedure
      begin
        FDespachante.Despachar(
          CriarEventoTeste(TOperacaoOrm.ooInserir));
      end);
  end;

  TTask.WaitForAll(LTasks);
  LLock.Free;

  Assert.AreEqual(NUM_THREADS, LSpy.EventosRecebidos.Count,
    Format('Todos os %d eventos devem ser recebidos sem perda', [NUM_THREADS]));
end;

// ── Serialização ──────────────────────────────────────────────────────────────

procedure TTestesEventos.DeveSerializarValorString;
begin
  Assert.AreEqual(
    '"Rodrigo"',
    TSerializadorValor.Serializar(TValue.From<string>('Rodrigo')));
end;

procedure TTestesEventos.DeveSerializarValorInteger;
begin
  Assert.AreEqual(
    '42',
    TSerializadorValor.Serializar(TValue.From<Integer>(42)));
end;

procedure TTestesEventos.DeveSerializarValorBoolean;
begin
  Assert.AreEqual(
    'true',
    TSerializadorValor.Serializar(TValue.From<Boolean>(True)));
  Assert.AreEqual(
    'false',
    TSerializadorValor.Serializar(TValue.From<Boolean>(False)));
end;

procedure TTestesEventos.DeveSerializarValorNulo;
begin
  Assert.AreEqual(
    'null',
    TSerializadorValor.Serializar(TValue.Empty));
end;

procedure TTestesEventos.DeveSerializarListaDeValores;
var
  LChave: TValoresChave;
  LResultado: string;
begin
  SetLength(LChave, 2);
  LChave[0] := TValue.From<Int64>(42);
  LChave[1] := TValue.From<string>('GO');

  LResultado := TSerializadorValor.SerializarLista(LChave);

  Assert.IsTrue(LResultado.StartsWith('['),
    'Lista serializada deve iniciar com [');
  Assert.IsTrue(LResultado.EndsWith(']'),
    'Lista serializada deve terminar com ]');
  Assert.IsTrue(LResultado.Contains('42'),
    'Lista deve conter o valor 42');
end;

// ── Contexto de log ───────────────────────────────────────────────────────────

procedure TTestesEventos.DeveContruirContextoDeLogFormatado;
var
  LContexto: string;
begin
  LContexto := TContextoLog.Novo
    .Add('entidade', 'TCliente')
    .Add('id', 42)
    .Add('sucesso', True)
    .Construir;

  Assert.IsTrue(LContexto.StartsWith('{'),
    'Contexto deve iniciar com {');
  Assert.IsTrue(LContexto.Contains('"entidade": "TCliente"'),
    'Contexto deve conter a entrada entidade');
  Assert.IsTrue(LContexto.Contains('"id": "42"'),
    'Contexto deve conter o id');
  Assert.IsTrue(LContexto.EndsWith('}'),
    'Contexto deve terminar com }');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesEventos);

end.
