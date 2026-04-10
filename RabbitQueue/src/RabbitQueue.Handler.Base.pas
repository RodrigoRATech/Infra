unit RabbitQueue.Handler.Base;

interface

uses
  RabbitQueue.Interfaces,
  RabbitQueue.Types,
  System.SysUtils;

type
  /// <summary>
  ///   Classe base para handlers. Utilize herança para criar
  ///   handlers especializados com comportamento padrão garantido.
  ///   Aplica o padrão Template Method.
  /// </summary>
  TRabbitQueueHandlerBase = class abstract(TInterfacedObject,
    IRabbitQueueHandler)
  strict private
    FHandlerName : string;
    FQueueName   : string;
  strict protected
    /// <summary>Implementação obrigatória pelo handler concreto</summary>
    function DoExecute(const AItem: TQueueItemInfo): TProcessResult; virtual; abstract;

    /// <summary>Hook: executado antes do DoExecute (opcional)</summary>
    procedure DoBeforeExecute(const AItem: TQueueItemInfo); virtual;

    /// <summary>Hook: executado após o DoExecute (opcional)</summary>
    procedure DoAfterExecute(const AItem: TQueueItemInfo;
      const AResult: TProcessResult); virtual;

    /// <summary>Hook: tratamento de erros interno (opcional)</summary>
    function DoHandleError(const AItem: TQueueItemInfo;
      const AError: Exception): TProcessResult; virtual;
  public
    constructor Create(const AHandlerName, AQueueName: string);

    // IRabbitQueueHandler
    function GetHandlerName: string;
    function CanHandle(const AQueueName: string): Boolean; virtual;
    function Execute(const AItem: TQueueItemInfo): TProcessResult;
  end;

  /// <summary>
  ///   Handler anônimo — permite criar handlers via closure/lambda,
  ///   útil para cenários simples sem necessidade de herança.
  ///   Aplica o padrão Strategy.
  /// </summary>
  TRabbitAnonymousHandler = class(TRabbitQueueHandlerBase)
  strict private
    FExecuteFunc: TFunc<TQueueItemInfo, TProcessResult>;
  strict protected
    function DoExecute(const AItem: TQueueItemInfo): TProcessResult; override;
  public
    constructor Create(
      const AHandlerName : string;
      const AQueueName   : string;
      const AExecuteFunc : TFunc<TQueueItemInfo, TProcessResult>
    );
  end;

implementation

{ TRabbitQueueHandlerBase }

constructor TRabbitQueueHandlerBase.Create(const AHandlerName,
  AQueueName: string);
begin
  inherited Create;
  FHandlerName := AHandlerName;
  FQueueName   := AQueueName;
end;

function TRabbitQueueHandlerBase.GetHandlerName: string;
begin
  Result := FHandlerName;
end;

function TRabbitQueueHandlerBase.CanHandle(const AQueueName: string): Boolean;
begin
  Result := SameText(FQueueName, AQueueName);
end;

function TRabbitQueueHandlerBase.Execute(
  const AItem: TQueueItemInfo): TProcessResult;
begin
  DoBeforeExecute(AItem);
  try
    Result := DoExecute(AItem);
    DoAfterExecute(AItem, Result);
  except
    on E: Exception do
      Result := DoHandleError(AItem, E);
  end;
end;

procedure TRabbitQueueHandlerBase.DoBeforeExecute(
  const AItem: TQueueItemInfo);
begin
  // Hook — sobrescrever quando necessário
end;

procedure TRabbitQueueHandlerBase.DoAfterExecute(const AItem: TQueueItemInfo;
  const AResult: TProcessResult);
begin
  // Hook — sobrescrever quando necessário
end;

function TRabbitQueueHandlerBase.DoHandleError(const AItem: TQueueItemInfo;
  const AError: Exception): TProcessResult;
begin
  Result := prFailure;
end;

{ TRabbitAnonymousHandler }

constructor TRabbitAnonymousHandler.Create(const AHandlerName,
  AQueueName: string;
  const AExecuteFunc: TFunc<TQueueItemInfo, TProcessResult>);
begin
  inherited Create(AHandlerName, AQueueName);
  if not Assigned(AExecuteFunc) then
    raise EQueueHandlerException.Create(
      'TRabbitAnonymousHandler: AExecuteFunc não pode ser nil.');
  FExecuteFunc := AExecuteFunc;
end;

function TRabbitAnonymousHandler.DoExecute(
  const AItem: TQueueItemInfo): TProcessResult;
begin
  Result := FExecuteFunc(AItem);
end;

end.
