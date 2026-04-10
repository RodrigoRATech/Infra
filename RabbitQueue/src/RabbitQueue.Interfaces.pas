unit RabbitQueue.Interfaces;

interface

uses
  RabbitQueue.Types,
  System.SysUtils,
  System.Generics.Collections;

type
  // Forward declarations
  IRabbitQueueHandler = interface;
  IRabbitQueue        = interface;
  IRabbitQueueWorker  = interface;
  IRabbitConnection   = interface;

  // ──────────────────────────────────────────────
  //  Handler — processa mensagens da fila
  // ──────────────────────────────────────────────

  /// <summary>
  ///   Contrato para handlers de processamento de mensagens.
  ///   Implemente esta interface para definir o comportamento
  ///   de cada tipo de mensagem.
  /// </summary>
  IRabbitQueueHandler = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function GetHandlerName: string;
    function CanHandle(const AQueueName: string): Boolean;
    function Execute(const AItem: TQueueItemInfo): TProcessResult;
    property HandlerName: string read GetHandlerName;
  end;

  // ──────────────────────────────────────────────
  //  Conexão STOMP
  // ──────────────────────────────────────────────

  /// <summary>
  ///   Gerencia o ciclo de vida da conexão com o broker.
  /// </summary>
  IRabbitConnection = interface
    ['{B2C3D4E5-F6A7-8901-BCDE-F12345678901}']
    function GetIsConnected: Boolean;
    function GetConfig: TRabbitConnectionConfig;
    procedure Connect;
    procedure Disconnect;
    procedure Send(const ADestination, ABody: string;
      const APriority: TQueuePriority = qpNormal);
    function Receive(const ADestination: string;
      const ATimeoutMs: Integer = 500): TQueueItemInfo;
    procedure Ack(const AMessageId: string);
    procedure Nack(const AMessageId: string; const ARequeue: Boolean = True);
    property IsConnected: Boolean read GetIsConnected;
    property Config: TRabbitConnectionConfig read GetConfig;
  end;

  // ──────────────────────────────────────────────
  //  Worker — thread de background
  // ──────────────────────────────────────────────

  /// <summary>
  ///   Thread de processamento em background.
  /// </summary>
  IRabbitQueueWorker = interface
    ['{C3D4E5F6-A7B8-9012-CDEF-123456789012}']
    function GetIsRunning: Boolean;
    procedure Start;
    procedure Stop;
    procedure SetOnBeforeProcess(const AEvent: TOnBeforeProcess);
    procedure SetOnAfterProcess(const AEvent: TOnAfterProcess);
    procedure SetOnProcessError(const AEvent: TOnProcessError);
    property IsRunning: Boolean read GetIsRunning;
  end;

  // ──────────────────────────────────────────────
  //  Fila principal
  // ──────────────────────────────────────────────

  /// <summary>
  ///   Contrato principal da fila RabbitMQ.
  ///   Ponto de entrada para todas as operações.
  /// </summary>
  IRabbitQueue = interface
    ['{D4E5F6A7-B8C9-0123-DEF0-234567890123}']

    // Gestão de handlers
    function RegisterHandler(const AHandler: IRabbitQueueHandler): IRabbitQueue;
    function UnregisterHandler(const AHandlerName: string): IRabbitQueue;

    // Operações de fila
    function Enqueue(const AQueueName, ABody: string;
      const APriority: TQueuePriority = qpNormal): IRabbitQueue;
    procedure Dequeue(const AQueueName: string);
    procedure Purge(const AQueueName: string);

    // Ciclo de vida
    procedure Start;
    procedure Stop;

    // Eventos de fila
    procedure SetOnEnqueue(const AEvent: TOnEnqueue);
    procedure SetOnDequeue(const AEvent: TOnDequeue);
    procedure SetOnQueueEmpty(const AEvent: TOnQueueEmpty);
    procedure SetOnQueueError(const AEvent: TOnQueueError);

    // Eventos de processamento
    procedure SetOnBeforeProcess(const AEvent: TOnBeforeProcess);
    procedure SetOnAfterProcess(const AEvent: TOnAfterProcess);
    procedure SetOnProcessError(const AEvent: TOnProcessError);

    // Fluent — configurações
    function WithQueue(const AQueueName: string): IRabbitQueue;
    function WithPrefetch(const ACount: Integer): IRabbitQueue;
  end;

  // ──────────────────────────────────────────────
  //  Factory
  // ──────────────────────────────────────────────

  /// <summary>
  ///   Factory para criação das instâncias principais.
  /// </summary>
  IRabbitQueueFactory = interface
    ['{E5F6A7B8-C9D0-1234-EF01-345678901234}']
    function CreateQueue(
      const AConfig: TRabbitConnectionConfig): IRabbitQueue;
    function CreateHandler(
      const AHandlerName: string;
      const AQueueName: string;
      const AExecuteProc: TFunc<TQueueItemInfo, TProcessResult>
    ): IRabbitQueueHandler;
  end;

implementation

end.
