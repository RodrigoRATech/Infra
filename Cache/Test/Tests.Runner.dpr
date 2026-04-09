program Tests.Runner;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}

{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  Tests.Cache.Config in 'Tests.Cache.Config.pas',
  Tests.Cache.Serializer in 'Tests.Cache.Serializer.pas',
  Tests.Cache.Stress in 'Tests.Cache.Stress.pas',
  Cache.Config in '..\src\Cache.Config.pas',
  Cache.Interfaces in '..\src\Cache.Interfaces.pas',
  Cache.Serializer in '..\src\Cache.Serializer.pas',
  Cache.Fallback in '..\src\Cache.Fallback.pas',
  Cache.Strategy.Redis in '..\src\Cache.Strategy.Redis.pas',
  Cache.Manager in '..\src\Cache.Manager.pas',
  Cache.Monitor in '..\src\Cache.Monitor.pas',
  Cache.Factory in '..\src\Cache.Factory.pas',
  Cache.Middleware.Horse in '..\src\Cache.Middleware.Horse.pas';

var
  LRunner: ITestRunner;
  LResults: IRunResults;
  LLogger: ITestLogger;
  LNUnitLogger: ITestLogger;
begin
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
  Exit;
  {$ENDIF}

  try
    TDUnitX.CheckCommandLine;
    LRunner := TDUnitX.CreateRunner;
    LRunner.UseRTTI := True;

    LLogger := TDUnitXConsoleLogger.Create(True);
    LRunner.AddLogger(LLogger);

    LNUnitLogger := TDUnitXXMLNUnitFileLogger.Create(
      TDUnitX.Options.XMLOutputFile);
    LRunner.AddLogger(LNUnitLogger);
    LRunner.FailsOnNoAsserts := False;

    LResults := LRunner.Execute;

    {$IFNDEF CI}
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Pressione ENTER para sair...');
      System.Readln;
    end;
    {$ENDIF}

    System.ExitCode := Ord(not LResults.AllPassed);
  except
    on E: Exception do
    begin
      System.Writeln(E.ClassName, ': ', E.Message);
      System.ExitCode := 1;
    end;
  end;
end.
