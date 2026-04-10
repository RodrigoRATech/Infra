unit RabbitQueue.Connection;

interface

uses
  RabbitQueue.Interfaces,
  RabbitQueue.Types,
  StompClient,        // danieleteti/delphistompclient — única unit necessária
  System.SysUtils,
  System.SyncObjs,
  System.Generics.Collections;

type
  /// <summary>
  ///   Adaptador sobre o StompClient real (danieleteti/delphistompclient).
  ///   Toda comunicação STOMP/RabbitMQ passa por esta classe.
  ///   Padrão: Adapter.
  /// </summary>
  TRabbitConnection = class(TInterfacedObject, IRabbitConnection)
  strict private
    FConfig          : TRabbitConnectionConfig;
    FStomp           : IStompClient;
    FLock            : TCriticalSection;
    FIsConnected     : Boolean;
    FSubscribedQueues: TDictionary<string, Boolean>;

    function BuildHeaders(const APriority: TQueuePriority): IStompHeaders;
    function PriorityToInt(const APriority: TQueuePriority): Integer;
    function MapFrameToItem(const AFrame: IStompFrame;
      const AQueue: string): TQueueItemInfo;
    procedure EnsureConnected;
    procedure SubscribeIfNeeded(const AQueueName: string);
  public
    constructor Create(const AConfig: TRabbitConnectionConfig);
    destructor Destroy; override;

    // IRabbitConnection
    function  GetIsConnected: Boolean;
    function  GetConfig: TRabbitConnectionConfig;
    procedure Connect;
    procedure Disconnect;
    procedure Send(const ADestination, ABody: string;
      const APriority: TQueuePriority = qpNormal);
    function  Receive(const ADestination: string;
      const ATimeoutMs: Integer = 500): TQueueItemInfo;
    procedure Ack(const AMessageId: string);
    procedure Nack(const AMessageId: string; const ARequeue: Boolean = True);
  end;

implementation

{ TRabbitConnection }

constructor TRabbitConnection.Create(const AConfig: TRabbitConnectionConfig);
begin
  inherited Create;
  FConfig           := AConfig;
  FLock             := TCriticalSection.Create;
  FSubscribedQueues := TDictionary<string, Boolean>.Create;
  FIsConnected      := False;
end;

destructor TRabbitConnection.Destroy;
begin
  Disconnect;
  FSubscribedQueues.Free;
  FLock.Free;
  // FStomp é interface — ref count cuida da liberação
  inherited;
end;

// ─────────────────────────────────────────────────────────────────────────────
//  Privados
// ─────────────────────────────────────────────────────────────────────────────

procedure TRabbitConnection.EnsureConnected;
begin
  if not FIsConnected then
    raise EQueueConnectionException.Create(
      'Nenhuma conexão ativa com o broker. Chame Connect() antes.');
end;

function TRabbitConnection.PriorityToInt(
  const APriority: TQueuePriority): Integer;
begin
  case APriority of
    qpLow      : Result := 1;
    qpNormal   : Result := 5;
    qpHigh     : Result := 7;
    qpCritical : Result := 9;
  else
    Result := 5;
  end;
end;

function TRabbitConnection.BuildHeaders(
  const APriority: TQueuePriority): IStompHeaders;
begin
  // API real: StompUtils.NewHeaders retorna IStompHeaders
  // encadeamento via .Add(Key, Value): IStompHeaders
  Result := StompUtils.NewHeaders
    .Add('priority',     IntToStr(PriorityToInt(APriority)))
    .Add('persistent',   'true')
    .Add('content-type', 'text/plain; charset=utf-8');
end;

function TRabbitConnection.MapFrameToItem(const AFrame: IStompFrame;
  const AQueue: string): TQueueItemInfo;
begin
  // API real do IStompFrame:
  //   MessageID : string  — ID da mensagem
  //   GetBody   : string  — corpo da mensagem
  //   GetHeaders: IStompHeaders — cabeçalhos
  FillChar(Result, SizeOf(Result), 0);
  Result.MessageId  := AFrame.MessageID;
  Result.Queue      := AQueue;
  Result.Body       := AFrame.GetBody;
  Result.Priority   := qpNormal;
  Result.RetryCount := 0;
  Result.EnqueuedAt := Now;
  Result.Status     := qisWaiting;
end;

procedure TRabbitConnection.SubscribeIfNeeded(const AQueueName: string);
begin
  // Subscribe deve ser chamado UMA única vez por fila por sessão.
  // Chamadas repetidas dentro de Receive causavam subscribe duplicado.
  if not FSubscribedQueues.ContainsKey(AQueueName) then
  begin
    // API real: Subscribe(Destination: string; Ack: TAckMode; Headers: IStompHeaders)
    FStomp.Subscribe(
      '/queue/' + AQueueName,
      amClient,             // TAckMode — amClient requer ACK explícito
      StompUtils.NewHeaders
        .Add('prefetch-count', '1')
        .Add('ack', 'client')
    );
    FSubscribedQueues.Add(AQueueName, True);
  end;
end;

// ─────────────────────────────────────────────────────────────────────────────
//  IRabbitConnection — implementação
// ─────────────────────────────────────────────────────────────────────────────

procedure TRabbitConnection.Connect;
begin
  FLock.Acquire;
  try
    if FIsConnected then
      Exit;

    // API real: StompUtils.NewStomp cria a instância IStompClient
    // Não existe TStompClient.Create — é sempre via factory function
    FStomp := StompUtils.StompClient;

    // API real de Connect:
    FStomp.SetHost( FConfig.Host);
    FStomp.SetPort( FConfig.Port);
    FStomp.SetUserName( FConfig.Username);
    FStomp.SetPassword( FConfig.Password);
    FStomp.SetVirtualHost( FConfig.VirtualHost);

    FStomp.Connect;
    FIsConnected := True;
    FSubscribedQueues.Clear;
  except
    on E: Exception do
    begin
      FIsConnected := False;
      FStomp       := nil;
      raise EQueueConnectionException.CreateFmt(
        'Falha ao conectar ao RabbitMQ em [%s:%d] — %s',
        [FConfig.Host, FConfig.Port, E.Message]);
    end;
  end;
  FLock.Release;
end;

procedure TRabbitConnection.Disconnect;
begin
  FLock.Acquire;
  try
    if not FIsConnected then
      Exit;
    try
      if Assigned(FStomp) then
        FStomp.Disconnect;
    finally
      FStomp       := nil;
      FIsConnected := False;
      FSubscribedQueues.Clear;
    end;
  finally
    FLock.Release;
  end;
end;

function TRabbitConnection.GetConfig: TRabbitConnectionConfig;
begin
  Result := FConfig;
end;

function TRabbitConnection.GetIsConnected: Boolean;
begin
  FLock.Acquire;
  try
    Result := FIsConnected;
  finally
    FLock.Release;
  end;
end;

procedure TRabbitConnection.Send(const ADestination, ABody: string;
  const APriority: TQueuePriority);
begin
  FLock.Acquire;
  try
    EnsureConnected;
    // API real: Send(Destination, Body, Headers)
    // Destino RabbitMQ via STOMP usa prefixo /queue/
    FStomp.Send(
      '/queue/' + ADestination,
      ABody,
      BuildHeaders(APriority)
    );
  finally
    FLock.Release;
  end;
end;

function TRabbitConnection.Receive(const ADestination: string;
  const ATimeoutMs: Integer): TQueueItemInfo;
var
  LFrame: IStompFrame;
begin
  FillChar(Result, SizeOf(Result), 0);
  FLock.Acquire;
  try
    EnsureConnected;

    // Subscribe feito uma única vez por fila (gerenciado por dicionário)
    SubscribeIfNeeded(ADestination);

    // API real: Receive(var Frame: IStompFrame; Timeout: Integer): Boolean
    // Retorna True se recebeu frame dentro do timeout, False caso contrário
    LFrame := nil;
    if FStomp.Receive(LFrame, ATimeoutMs) and Assigned(LFrame) then
      Result := MapFrameToItem(LFrame, ADestination);
    // Se não recebeu, Result.MessageId permanece vazio (verificado pelo Worker)
  finally
    FLock.Release;
  end;
end;

procedure TRabbitConnection.Ack(const AMessageId: string);
begin
  FLock.Acquire;
  try
    EnsureConnected;

    // ✅ CORRETO: Ack(MessageID: string) — sem segundo parâmetro
    // A assinatura real da IStompClient possui apenas o MessageID
    FStomp.Ack(AMessageId);
  finally
    FLock.Release;
  end;
end;

procedure TRabbitConnection.Nack(const AMessageId: string;
  const ARequeue: Boolean);
begin
  FLock.Acquire;
  try
    EnsureConnected;

    // IStompClient NÃO possui método Nack.
    // Com TAckMode = amClient, não fazer Ack faz o broker
    // re-entregar a mensagem automaticamente após o timeout.
    //
    // Para descarte definitivo (ARequeue = False): fazemos Ack
    // para confirmar e remover da fila sem reprocessar.
    if not ARequeue then
      FStomp.Ack(AMessageId);

    // Se ARequeue = True: simplesmente não fazemos nada.
    // O broker vai re-entregar ao expirar o timeout de ack.
  finally
    FLock.Release;
  end;
end;

end.
