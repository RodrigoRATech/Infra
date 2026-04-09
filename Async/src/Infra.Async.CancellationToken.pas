unit Infra.Async.CancellationToken;

interface

uses System.classes, System.SyncObjs,
     System.SysUtils,

     Infra.Async.Interfaces;


type
  TCancellationToken = class(TInterfacedObject, ICancellationToken)
  strict private
    FCancellationEvent: TEvent;
    FIsCancellationRequestedFunc: TFunc<Boolean>;

  public
    constructor Create(IsCancellationRequestedFunc: TFunc<Boolean>; CancellationEvent: TEvent);

    function GetIsCancellationRequested: Boolean;
    function WaitForCancellation(Timeout: Cardinal): TWaitResult;
    procedure ThrowIfCancellationRequested;

    property IsCancellationRequested: Boolean read GetIsCancellationRequested;
  end;

  TCancellationTokenSource = class
  strict private
    FIsCancellationRequested: Boolean;
    FEvent: TEvent;
    FToken: ICancellationToken;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Cancel;
    procedure Reset;
    function GetToken: ICancellationToken;
    property IsCancellationRequested: Boolean read FIsCancellationRequested;
    property Token: ICancellationToken read GetToken;

  end;

implementation

{ TCancellationTokenSource }

constructor TCancellationTokenSource.Create;
begin
  inherited Create;
  FIsCancellationRequested := False;
  FEvent := TEvent.Create(nil, True, False, '');

  FToken := TCancellationToken.Create(
    function: Boolean
    begin
      Result := FIsCancellationRequested;
    end,
    FEvent);
end;

destructor TCancellationTokenSource.Destroy;
begin
  Cancel;
  FEvent.Free;

  inherited;
end;

procedure TCancellationTokenSource.Reset;
begin
  FIsCancellationRequested := False
end;

procedure TCancellationTokenSource.Cancel;
begin
  if not FIsCancellationRequested then
  begin
    FIsCancellationRequested := True;
    FEvent.SetEvent;
  end;
end;

function TCancellationTokenSource.GetToken: ICancellationToken;
begin
  Result := FToken;
end;

{ TCancellationToken }

constructor TCancellationToken.Create(IsCancellationRequestedFunc:
  TFunc<Boolean>; CancellationEvent: TEvent);
begin
  inherited Create;
  FIsCancellationRequestedFunc := IsCancellationRequestedFunc;
  FCancellationEvent := CancellationEvent;
end;

function TCancellationToken.GetIsCancellationRequested: Boolean;
begin
  Result := FIsCancellationRequestedFunc();
end;

procedure TCancellationToken.ThrowIfCancellationRequested;
begin
  if (not Assigned(Self)) or GetIsCancellationRequested then
    raise EOperationCancelled.Create('Operação cancelada!');
end;

function TCancellationToken.WaitForCancellation(Timeout: Cardinal): TWaitResult;
begin
  Result := FCancellationEvent.WaitFor(Timeout);
end;

end.
