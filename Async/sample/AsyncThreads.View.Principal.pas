unit AsyncThreads.View.Principal;

interface

uses
  System.SysUtils, System.Types,
  System.UITypes, System.Classes,
  System.Variants, System.SyncObjs,

  FMX.Types, FMX.Controls,
  FMX.Forms, FMX.Graphics,
  FMX.Dialogs,
  FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo,

  Infra.Async;

type
  TForm1 = class(TForm)
    Iniciar: TButton;
    btnCancelar: TButton;
    Memo1: TMemo;
    procedure IniciarClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    CT: TCancellationTokenSource;
    procedure OnBeforeExecute;
    procedure OnExecute;
    procedure OnComplete( aValue:Boolean);
    procedure OnCancel;
    procedure OnException( e:Exception);

  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure TForm1.IniciarClick(Sender: TObject);
begin
   CT := TCancellationTokenSource.Create;

   TAsyncTask
      .Run( OnExecute)
      .WithCancellation( CT.Token)
      .OnBeforeWork( OnBeforeExecute)
      .OnCancel( OnCancel)
      .OnComplete( OnComplete)
      .OnException( OnException)
      .Start;
end;

procedure TForm1.OnBeforeExecute;
begin
   TThread.Queue( nil, procedure
   begin
      memo1.lines.add( DateTimeToStr( Now) + ' - Começar o processamento');
   end);
end;

procedure TForm1.OnCancel;
begin
  if not Application.Terminated then
  begin
     memo1.lines.add( DateTimeToStr( Now) + ' - Processo cancelado pelo usuário.');
     FreeAndNil( CT);
  end;
end;

procedure TForm1.OnComplete(aValue: Boolean);
begin
   ShowMessage('Processamento finalizado');
end;

procedure TForm1.OnException(e: Exception);
begin
   if E is EOperationCancelled then
      ShowMessage('Task was cancelled!')
   else ShowMessage('Error: ' + E.Message);
end;

procedure TForm1.OnExecute;
var eEvent : TWaitResult;
begin
  while not CT.IsCancellationRequested do
  begin
    eEvent := CT.Token.WaitForCancellation( 5000);

    case eEvent of
       wrSignaled:CT.Cancel;
       wrTimeout:begin
         CT.Reset;

         TThread.Queue( nil, procedure
         begin
            memo1.lines.add( DateTimeToStr( Now) + ' - Processamento realizado');
         end);
       end;
    end;
  end;
end;

procedure TForm1.btnCancelarClick(Sender: TObject);
begin
   CT.Cancel;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
   ReportMemoryLeaksOnShutdown := true;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
   if Assigned( CT) then
   begin
      CT.Cancel;
      CT.Free;
   end;
end;

end.
