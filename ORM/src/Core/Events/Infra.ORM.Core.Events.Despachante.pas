unit Infra.ORM.Core.Events.Despachante;

{
  Responsabilidade:
    Implementação thread-safe de IOrmDespachante.
    Mantém lista de IOrmSink e IOrmInterceptador.
    Garante que falhas em sinks não propagam para a operação principal.
    Suporta execução de sinks em modo síncrono ou assíncrono.
}

interface

uses
  System.SysUtils,
  System.SyncObjs,
  System.Classes,
  System.Threading,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions,
  Infra.ORM.Core.Logging.Contrato,
  Infra.ORM.Core.Events.Contratos;

type

  // Modo de execução dos sinks
  TModoExecucaoSink = (meSincrono, meAssincrono);

  TDespachante = class(TInterfacedObject, IOrmDespachante)
  strict private
    FLock: TMREWSync;
    FSinks: TList<IOrmSink>;
    FInterceptadores: TList<IOrmInterceptador>;
    FLogger: IOrmLogger;
    FModoExecucao: TModoExecucaoSink;
    FAtivo: Boolean;

    // Cópia defensiva thread-safe da lista de sinks
    function CopiarSinks: TArray<IOrmSink>;
    function CopiarInterceptadores: TArray<IOrmInterceptador>;

    // Notifica um único sink capturando exceções
    procedure NotificarSink(
      ASink: IOrmSink;
      const AEvento: TEventoOrmOperacao);

  public
    constructor Create(
      ALogger: IOrmLogger;
      AModo: TModoExecucaoSink = meSincrono);

    destructor Destroy; override;

    // IOrmDespachante
    procedure Despachar(const AEvento: TEventoOrmOperacao);

    // Gerenciamento de sinks
    procedure RegistrarSink(ASink: IOrmSink);
    procedure RemoverSink(ASink: IOrmSink);
    procedure LimparSinks;

    // Gerenciamento de interceptadores
    procedure RegistrarInterceptador(AInterceptador: IOrmInterceptador);
    procedure RemoverInterceptador(AInterceptador: IOrmInterceptador);

    // Interceptação pré-operação — pode lançar exceção para cancelar
    procedure Antes(
      AOperacao: TOperacaoOrm;
      AMetadado: IOrmMetadadoEntidade;
      AEntidade: TObject);

    // Interceptação pós-operação — falha é logada, não propaga
    procedure Depois(
      AOperacao: TOperacaoOrm;
      AMetadado: IOrmMetadadoEntidade;
      AEntidade: TObject;
      ASucesso: Boolean);

    // Habilita/desabilita o despachante globalmente
    procedure Ativar;
    procedure Desativar;
    function EstaAtivo: Boolean;

    // Total de sinks registrados
    function TotalSinks: Integer;
    function TotalInterceptadores: Integer;
  end;

implementation

{ TDespachante }

constructor TDespachante.Create(
  ALogger: IOrmLogger;
  AModo: TModoExecucaoSink);
begin
  inherited Create;

  FLock           := TMREWSync.Create;
  FSinks          := TList<IOrmSink>.Create;
  FInterceptadores := TList<IOrmInterceptador>.Create;
  FLogger         := ALogger ?? TLoggerNulo.Create;
  FModoExecucao   := AModo;
  FAtivo          := True;
end;

destructor TDespachante.Destroy;
begin
  FLock.BeginWrite;
  try
    FSinks.Clear;
    FInterceptadores.Clear;
  finally
    FLock.EndWrite;
  end;

  FSinks.Free;
  FInterceptadores.Free;
  FLock.Free;
  FLogger := nil;

  inherited Destroy;
end;

function TDespachante.CopiarSinks: TArray<IOrmSink>;
begin
  FLock.BeginRead;
  try
    Result := FSinks.ToArray;
  finally
    FLock.EndRead;
  end;
end;

function TDespachante.CopiarInterceptadores: TArray<IOrmInterceptador>;
begin
  FLock.BeginRead;
  try
    Result := FInterceptadores.ToArray;
  finally
    FLock.EndRead;
  end;
end;

procedure TDespachante.NotificarSink(
  ASink: IOrmSink;
  const AEvento: TEventoOrmOperacao);
begin
  try
    ASink.Processar(AEvento);
  except
    on E: Exception do
      FLogger.Aviso(
        'Falha em sink de evento — ignorada para não afetar operação principal',
        TContextoLog.Novo
          .Add('sink', ASink.Nome)
          .Add('operacao', Ord(AEvento.Operacao))
          .Add('entidade', AEvento.NomeEntidade)
          .Add('erro', E.Message)
          .Construir);
  end;
end;

procedure TDespachante.Despachar(const AEvento: TEventoOrmOperacao);
var
  LCopia: TArray<IOrmSink>;
  LSink: IOrmSink;
begin
  if not FAtivo then
    Exit;

  LCopia := CopiarSinks;

  if Length(LCopia) = 0 then
    Exit;

  case FModoExecucao of
    meSincrono:
      begin
        for LSink in LCopia do
          NotificarSink(LSink, AEvento);
      end;

    meAssincrono:
      begin
        // Cópia do evento para a closure
        var LEvento := AEvento;

        TTask.Run(
          procedure
          var
            LSinkAsync: IOrmSink;
          begin
            for LSinkAsync in LCopia do
              NotificarSink(LSinkAsync, LEvento);
          end);
      end;
  end;
end;

procedure TDespachante.RegistrarSink(ASink: IOrmSink);
begin
  if not Assigned(ASink) then
    raise EOrmConfiguracaoExcecao.Create(
      'Sink não pode ser nil ao registrar no despachante.');

  FLock.BeginWrite;
  try
    if not FSinks.Contains(ASink) then
    begin
      FSinks.Add(ASink);

      FLogger.Debug('Sink registrado no despachante',
        TContextoLog.Novo
          .Add('sink', ASink.Nome)
          .Add('total', FSinks.Count)
          .Construir);
    end;
  finally
    FLock.EndWrite;
  end;
end;

procedure TDespachante.RemoverSink(ASink: IOrmSink);
begin
  FLock.BeginWrite;
  try
    FSinks.Remove(ASink);
  finally
    FLock.EndWrite;
  end;
end;

procedure TDespachante.LimparSinks;
begin
  FLock.BeginWrite;
  try
    FSinks.Clear;
    FLogger.Debug('Todos os sinks removidos do despachante.');
  finally
    FLock.EndWrite;
  end;
end;

procedure TDespachante.RegistrarInterceptador(
  AInterceptador: IOrmInterceptador);
begin
  if not Assigned(AInterceptador) then
    raise EOrmConfiguracaoExcecao.Create(
      'Interceptador não pode ser nil ao registrar no despachante.');

  FLock.BeginWrite;
  try
    if not FInterceptadores.Contains(AInterceptador) then
      FInterceptadores.Add(AInterceptador);
  finally
    FLock.EndWrite;
  end;
end;

procedure TDespachante.RemoverInterceptador(
  AInterceptador: IOrmInterceptador);
begin
  FLock.BeginWrite;
  try
    FInterceptadores.Remove(AInterceptador);
  finally
    FLock.EndWrite;
  end;
end;

procedure TDespachante.Antes(
  AOperacao: TOperacaoOrm;
  AMetadado: IOrmMetadadoEntidade;
  AEntidade: TObject);
var
  LCopia: TArray<IOrmInterceptador>;
  LInterc: IOrmInterceptador;
begin
  if not FAtivo then
    Exit;

  LCopia := CopiarInterceptadores;

  for LInterc in LCopia do
  begin
    // Falha em Antes é intencional — pode cancelar a operação
    try
      LInterc.Antes(AOperacao, AMetadado, AEntidade);
    except
      on E: EOrmExcecao do
        raise; // Propaga exceções ORM (intencionais — cancelam a operação)
      on E: Exception do
        raise EOrmInterceptadorExcecao.Create(
          LInterc.Nome,
          Format('Interceptador falhou antes da operação %d: %s',
            [Ord(AOperacao), E.Message]), E);
    end;
  end;
end;

procedure TDespachante.Depois(
  AOperacao: TOperacaoOrm;
  AMetadado: IOrmMetadadoEntidade;
  AEntidade: TObject;
  ASucesso: Boolean);
var
  LCopia: TArray<IOrmInterceptador>;
  LInterc: IOrmInterceptador;
begin
  if not FAtivo then
    Exit;

  LCopia := CopiarInterceptadores;

  for LInterc in LCopia do
  begin
    try
      LInterc.Depois(AOperacao, AMetadado, AEntidade, ASucesso);
    except
      on E: Exception do
        FLogger.Aviso(
          'Falha em interceptador pós-operação — ignorada',
          TContextoLog.Novo
            .Add('interceptador', LInterc.Nome)
            .Add('operacao', Ord(AOperacao))
            .Add('erro', E.Message)
            .Construir);
    end;
  end;
end;

procedure TDespachante.Ativar;
begin
  FAtivo := True;
  FLogger.Debug('Despachante de eventos ativado.');
end;

procedure TDespachante.Desativar;
begin
  FAtivo := False;
  FLogger.Debug('Despachante de eventos desativado.');
end;

function TDespachante.EstaAtivo: Boolean;
begin
  Result := FAtivo;
end;

function TDespachante.TotalSinks: Integer;
begin
  FLock.BeginRead;
  try
    Result := FSinks.Count;
  finally
    FLock.EndRead;
  end;
end;

function TDespachante.TotalInterceptadores: Integer;
begin
  FLock.BeginRead;
  try
    Result := FInterceptadores.Count;
  finally
    FLock.EndRead;
  end;
end;

end.
