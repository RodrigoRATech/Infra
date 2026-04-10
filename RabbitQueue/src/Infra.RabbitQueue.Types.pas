unit Infra.RabbitQueue.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>Status do item na fila</summary>
  TQueueItemStatus = (
    qisWaiting,
    qisProcessing,
    qisCompleted,
    qisFailed,
    qisRetrying
  );

  /// <summary>Nível de prioridade da mensagem</summary>
  TQueuePriority = (qpLow, qpNormal, qpHigh, qpCritical);

  /// <summary>Informações do item na fila</summary>
  TQueueItemInfo = record
    MessageId  : string;
    Queue      : string;
    Body       : string;
    Priority   : TQueuePriority;
    RetryCount : Integer;
    EnqueuedAt : TDateTime;
    Status     : TQueueItemStatus;
  end;

  /// <summary>Resultado do processamento</summary>
  TProcessResult = (prSuccess, prFailure, prRequeue);

  /// <summary>Configurações de conexão com RabbitMQ</summary>
  TRabbitConnectionConfig = record
    Host        : string;
    Port        : Integer;
    VirtualHost : string;
    Username    : string;
    Password    : string;
    HeartBeat   : Integer;
    MaxRetries  : Integer;
    RetryDelay  : Integer; // ms
    class function Default: TRabbitConnectionConfig; static;
  end;

  // ──────────────────────────────────────────────
  //  Eventos da fila (operações)
  // ──────────────────────────────────────────────

  /// <summary>Dispara ao enfileirar um item</summary>
  TOnEnqueue = reference to procedure(const AItem: TQueueItemInfo);

  /// <summary>Dispara ao desenfileirar um item</summary>
  TOnDequeue = reference to procedure(const AItem: TQueueItemInfo);

  /// <summary>Dispara ao a fila ficar vazia</summary>
  TOnQueueEmpty = reference to procedure(const AQueueName: string);

  /// <summary>Dispara ao ocorrer erro na fila</summary>
  TOnQueueError = reference to procedure(const AQueueName: string;
    const AError: Exception);

  // ──────────────────────────────────────────────
  //  Eventos de processamento (item)
  // ──────────────────────────────────────────────

  /// <summary>Dispara ANTES do processamento</summary>
  TOnBeforeProcess = reference to procedure(const AItem: TQueueItemInfo);

  /// <summary>Dispara APÓS o processamento</summary>
  TOnAfterProcess = reference to procedure(const AItem: TQueueItemInfo;
    const AResult: TProcessResult);

  /// <summary>Dispara em caso de falha no processamento</summary>
  TOnProcessError = reference to procedure(const AItem: TQueueItemInfo;
    const AError: Exception; var AShouldRequeue: Boolean);

  EQueueException          = class(Exception);
  EQueueConnectionException = class(EQueueException);
  EQueueHandlerException    = class(EQueueException);

implementation

{ TRabbitConnectionConfig }

class function TRabbitConnectionConfig.Default: TRabbitConnectionConfig;
begin
  Result.Host        := 'localhost';
  Result.Port        := 61613; // STOMP default port
  Result.VirtualHost := '/';
  Result.Username    := 'guest';
  Result.Password    := 'guest';
  Result.HeartBeat   := 0;
  Result.MaxRetries  := 3;
  Result.RetryDelay  := 1000;
end;

end.
