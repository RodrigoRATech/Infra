program AsyncThreads;

uses
  System.StartUpCopy,
  FMX.Forms,
  AsyncThreads.View.Principal in 'AsyncThreads.View.Principal.pas' {Form1},
  Infra.Async.Interfaces in '..\Infra.Async.Interfaces.pas',
  Infra.Async.CancellationToken in '..\Infra.Async.CancellationToken.pas',
  Infra.Async in '..\Infra.Async.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
