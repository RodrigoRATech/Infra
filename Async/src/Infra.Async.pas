unit Infra.Async;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Threading,
  System.TimeSpan,
  System.Rtti,
  System.TypInfo,
  Infra.Async.Interfaces,
  Infra.Async.CancellationToken;

type
  ICancellationToken = Infra.Async.Interfaces.ICancellationToken;
  IAsyncTask = Infra.Async.Interfaces.IAsyncTask;
  TCancellationToken  = Infra.Async.CancellationToken.TCancellationTokenSource;
  TCancellationTokenSource = Infra.Async.CancellationToken.TCancellationTokenSource;

  /// <summary>
  /// Classe genérica que representa uma tarefa assíncrona com um resultado do tipo T.
  /// Herda diretamente de TTask para garantir total compatibilidade com a Biblioteca Paralela do Delphi.
  /// Orquestra o pipeline de execução, incluindo encadeamento, cancelamento e callbacks da thread principal.
  /// </summary>
  /// <typeparam name="T">The type of the result produced by this task.</typeparam>
  TAsyncTask<T> = class(TTask, IAsyncTask)
  private
    FOnBeforeWork: TProc;
    FWork: TFunc<T>;
    FOnComplete: TProc<T>;
    FOnCancel: TProc;
    FOnException: TProc<Exception>;
    FToken: ICancellationToken;
    FSyncComplete: Boolean;
    FSyncException: Boolean;

    procedure InternalCheckCancel;
    procedure RunPipeline;
  public
    constructor Create(const AWork: TFunc<T>;
      const OnBeforeWork: TProc;
      const OnComplete: TProc<T>;
      const OnCancel: TProc;
      const OnException: TProc<Exception>;
      const AToken: ICancellationToken = nil;
      const SyncComplete: Boolean = True;
      const SyncException: Boolean = True);
    destructor Destroy; override;
  end;

  /// <summary>
  /// Registro do Fluent Builder para configurar um pipeline de operações assíncronas.
  /// Permite encadear etapas, definir callbacks e lidar com cancelamentos antes de iniciar a execução.
  /// </summary>
  /// <typeparam name="T">The type of the result passed through the current stage of the pipeline.</typeparam>
  TAsyncBuilder<T> = record
  private
    FOnBeforeWork: TProc;
    FWork: TFunc<T>;
    FOnComplete: TProc<T>;
    FOnCancel: TProc;
    FOnException: TProc<Exception>;
    FToken: ICancellationToken;
    FSyncComplete: Boolean;
    FSyncException: Boolean;

  public
    constructor Create(const AWork: TFunc<T>; const AToken: ICancellationToken = nil);

    function OnBeforeWork(const AProc: TProc): TAsyncBuilder<T>;
    function ThenBy<U>(const AFunc: TFunc<T, U>): TAsyncBuilder<U>; overload;
    function ThenBy(const AProc: TProc<T>): TAsyncBuilder<T>; overload;
    function OnComplete(const AProc: TProc<T>): TAsyncBuilder<T>;
    function OnCompleteAsync(const AProc: TProc<T>): TAsyncBuilder<T>;
    function OnCancel( const AProc: TProc):TAsyncBuilder<T>;
    function OnException(const AProc: TProc<Exception>): TAsyncBuilder<T>;
    function OnExceptionAsync(const AProc: TProc<Exception>): TAsyncBuilder<T>;
    function WithCancellation(const AToken: ICancellationToken): TAsyncBuilder<T>;
    function Start: IAsyncTask;
    function Await: T;
  end;

  TAsyncTask = record
  public
    class function Run<T>(const AFunc: TFunc<T>): TAsyncBuilder<T>; overload; static;
    class function Run(const AProc: TProc): TAsyncBuilder<Boolean>; overload; static;
  end;

implementation

{ TAsyncTask<T> }

constructor TAsyncTask<T>.Create(const AWork: TFunc<T>;
  const OnBeforeWork: TProc;
  const OnComplete: TProc<T>;
  const OnCancel: TProc;
  const OnException: TProc<Exception>;
  const AToken: ICancellationToken;
  const SyncComplete: Boolean;
  const SyncException: Boolean);
begin
  FOnBeforeWork := OnBeforeWork;
  FWork := AWork;
  FOnComplete := OnComplete;
  FOnCancel := OnCancel;
  FOnException := OnException;
  FToken := AToken;
  FSyncComplete := SyncComplete;
  FSyncException := SyncException;

  inherited Create(
    nil,                    // Sender
    nil,                    // Event
    procedure
    begin
      RunPipeline;
    end,                    // AProc
    TThreadPool.Default,    // APool (Passa explicitamente o Pool Default de threads do sistema)
    nil,                    // AParent
    [],                     // CreateFlags
    nil                     // AParentControlFlag
  );
end;

destructor TAsyncTask<T>.Destroy;
begin
  inherited;
end;

procedure TAsyncTask<T>.InternalCheckCancel;
var LOnCancel: TProc;
begin
   if (FToken <> nil) and (FToken.IsCancellationRequested) then
   begin
      LOnCancel := FOnCancel;
      if Assigned( LOnCancel) then
         TThread.Queue( nil, procedure
         begin
            LOnCancel;
         end)
      else FToken.ThrowIfCancellationRequested;
   end;
end;

procedure TAsyncTask<T>.RunPipeline;
var
  Res: T;
  LOnComplete: TProc<T>;
  LOnException: TProc<Exception>;
  CapturedException: TObject;

begin
  try
    try
      // 1. Checa o cancelamento da Thread pelo processo padrão
      if GetStatus = TTaskStatus.Canceled then Exit;

      // 2. Antes de Executar a inicialização verifica se a Thread foi cancelada via token
      InternalCheckCancel;

      // 3. Callback para executar algo antes de começar o processamento principal
      if Assigned(FOnBeforeWork) then
         FOnBeforeWork;

      // 4. Antes de Executar o processamento principal verifica se a Thread foi cancelada via token
      InternalCheckCancel;

      // 5. Execução principal da Thread
      Res := Default(T);
      if Assigned(FWork) then
        Res := FWork();

      // 6. Depois da execução principal verifica se o cancelamento foi solicitado via token
      InternalCheckCancel;

      // 7. Chama callback para depois da execução do processo princial
      if (FToken <> nil) and (not FToken.IsCancellationRequested) then
      begin
        LOnComplete := FOnComplete;
        if Assigned(LOnComplete) then
        begin
          if FSyncComplete then
          begin
            TThread.Queue(nil,
              procedure
              begin
                LOnComplete(Res);
              end);
          end
          else
          begin
            LOnComplete(Res);
          end;
        end;
      end;
    except
      on E: Exception do
      begin
        LOnException := FOnException;

        // 8. Chama callback de exceções e para cancelamento quando não informado callback específico
        if Assigned(LOnException) then
        begin
          if FSyncException then
          begin
            CapturedException := AcquireExceptionObject;

            TThread.Queue(nil,
              procedure
              begin
                try
                  if CapturedException is Exception then
                    LOnException(Exception(CapturedException));
                finally
                  CapturedException.Free;
                end;
              end);
          end
          else LOnException(E);
        end;
      end;
    end;
  except
  end;
end;

{ TAsyncBuilder<T> }

constructor TAsyncBuilder<T>.Create(const AWork: TFunc<T>; const AToken: ICancellationToken);
begin
  FOnBeforeWork := nil;
  FWork := AWork;
  FOnComplete := nil;
  FOnCancel := nil;
  FOnException := nil;
  FToken := AToken;
  FSyncComplete := True;
  FSyncException := True;
end;

function TAsyncBuilder<T>.ThenBy<U>(const AFunc: TFunc<T, U>): TAsyncBuilder<U>;
var
  LPrevious: TFunc<T>;
begin
  LPrevious := FWork;
  Result := TAsyncBuilder<U>.Create(
    function: U
    begin
      var Input := LPrevious();
      Result := AFunc(Input);
    end,
    FToken
  );
end;

function TAsyncBuilder<T>.ThenBy(const AProc: TProc<T>): TAsyncBuilder<T>;
var
  LPrevious: TFunc<T>;
begin
  LPrevious := FWork;
  Result := TAsyncBuilder<T>.Create(
    function: T
    begin
      Result := LPrevious();
      AProc(Result);
    end,
    FToken
  );
end;

function TAsyncBuilder<T>.OnBeforeWork(const AProc: TProc): TAsyncBuilder<T>;
begin
  FOnBeforeWork := AProc;
  Result := Self;
end;

function TAsyncBuilder<T>.OnCancel(const AProc: TProc): TAsyncBuilder<T>;
begin
  FOnCancel := AProc;
  FSyncComplete := false;
  FSyncException := false;
  Result := Self;
end;

function TAsyncBuilder<T>.OnComplete(const AProc: TProc<T>): TAsyncBuilder<T>;
begin
  FOnComplete := AProc;
  FSyncComplete := True;
  Result := Self;
end;

function TAsyncBuilder<T>.OnCompleteAsync(const AProc: TProc<T>): TAsyncBuilder<T>;
begin
  FOnComplete := AProc;
  FSyncComplete := False;
  Result := Self;
end;

function TAsyncBuilder<T>.OnException(const AProc: TProc<Exception>): TAsyncBuilder<T>;
begin
  FOnException := AProc;
  FSyncException := True;
  Result := Self;
end;

function TAsyncBuilder<T>.OnExceptionAsync(const AProc: TProc<Exception>): TAsyncBuilder<T>;
begin
  FOnException := AProc;
  FSyncException := False;
  Result := Self;
end;

function TAsyncBuilder<T>.WithCancellation(const AToken: ICancellationToken): TAsyncBuilder<T>;
begin
  FToken := AToken;
  Result := Self;
end;

function TAsyncBuilder<T>.Await: T;
begin
  if (FToken <> nil) and (FToken.IsCancellationRequested) then
    FToken.ThrowIfCancellationRequested;

  if Assigned(FWork) then
    Result := FWork()
  else
    Result := Default(T);

  if (FToken <> nil) and (FToken.IsCancellationRequested) then
    FToken.ThrowIfCancellationRequested;
end;

function TAsyncBuilder<T>.Start: IAsyncTask;
begin
  var Task := TAsyncTask<T>.Create(FWork, FOnBeforeWork, FOnComplete, FOnCancel, FOnException, FToken, FSyncComplete, FSyncException);

  Task.Start;
  Result := Task;
end;

{ TAsyncTask }

class function TAsyncTask.Run<T>(const AFunc: TFunc<T>): TAsyncBuilder<T>;
begin
  Result := TAsyncBuilder<T>.Create(AFunc, nil);
end;

class function TAsyncTask.Run(const AProc: TProc): TAsyncBuilder<Boolean>;
begin
  Result := TAsyncBuilder<Boolean>.Create(
    function: Boolean
    begin
      AProc();
      Result := True;
    end,
    nil);
end;

end.
