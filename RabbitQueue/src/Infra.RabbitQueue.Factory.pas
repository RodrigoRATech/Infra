unit Infra.RabbitQueue.Factory;

interface

uses
  Infra.RabbitQueue.Interfaces,
  Infra.RabbitQueue.Types,
  Infra.RabbitQueue.Core,
  Infra.RabbitQueue.Handler.Base,
  System.SysUtils;

type
  /// <summary>
  ///   Factory para criação das instâncias de fila e handlers.
  ///   Centraliza e simplifica a criação dos objetos principais.
  ///   Padrão Factory Method.
  /// </summary>
  TRabbitQueueFactory = class(TInterfacedObject, IRabbitQueueFactory)
  public
    /// <summary>
    ///   Cria uma nova instância da fila RabbitMQ com a configuração
    ///   fornecida.
    /// </summary>
    function CreateQueue(
      const AConfig: TRabbitConnectionConfig): IRabbitQueue;

    /// <summary>
    ///   Cria um handler anônimo via closure. Ideal para handlers simples.
    /// </summary>
    function CreateHandler(
      const AHandlerName : string;
      const AQueueName   : string;
      const AExecuteProc : TFunc<TQueueItemInfo, TProcessResult>
    ): IRabbitQueueHandler;

    /// <summary>
    ///   Acesso estático ao factory — Singleton leve.
    /// </summary>
    class function Instance: IRabbitQueueFactory;
  end;

implementation

var
  GFactory: IRabbitQueueFactory;

{ TRabbitQueueFactory }

class function TRabbitQueueFactory.Instance: IRabbitQueueFactory;
begin
  if not Assigned(GFactory) then
    GFactory := TRabbitQueueFactory.Create;
  Result := GFactory;
end;

function TRabbitQueueFactory.CreateQueue(
  const AConfig: TRabbitConnectionConfig): IRabbitQueue;
begin
  Result := TRabbitQueue.Create(AConfig);
end;

function TRabbitQueueFactory.CreateHandler(
  const AHandlerName : string;
  const AQueueName   : string;
  const AExecuteProc : TFunc<TQueueItemInfo, TProcessResult>
): IRabbitQueueHandler;
begin
  Result := TRabbitAnonymousHandler.Create(
    AHandlerName,
    AQueueName,
    AExecuteProc
  );
end;

initialization
  GFactory := nil;

finalization
  GFactory := nil;

end.
