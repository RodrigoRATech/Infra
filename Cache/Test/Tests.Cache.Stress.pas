unit Tests.Cache.Stress;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Classes, System.SyncObjs,
  System.Diagnostics, System.Generics.Collections,
  Cache.Interfaces, Cache.Fallback;

type
  [TestFixture]
  TStressTest = class
  private
    FFallback: TMemoryFallbackCache;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('10Threads_1000Ops', '10,1000')]
    [TestCase('50Threads_5000Ops', '50,5000')]
    [TestCase('100Threads_10000Ops', '100,10000')]
    procedure Test_Concurrent_ReadWrite(const AThreadCount, AOpsPerThread: Integer);

    [Test]
    procedure Test_Concurrent_ReadWrite_NoDeadlock;

    [Test]
    procedure Test_Concurrent_Mixed_Operations;

    [Test]
    procedure Test_High_Volume_Sequential;
  end;

implementation

{ TStressTest }

procedure TStressTest.Setup;
begin
  FFallback := TMemoryFallbackCache.Create(50000);
end;

procedure TStressTest.TearDown;
begin
  FFallback.Free;
end;

procedure TStressTest.Test_Concurrent_ReadWrite(const AThreadCount, AOpsPerThread: Integer);
var
  LThreads: TList<TThread>;
  LErrors: Integer;
  LStopwatch: TStopwatch;
  I: Integer;
begin
  LErrors := 0;
  LThreads := TList<TThread>.Create;
  try
    LStopwatch := TStopwatch.StartNew;

    for I := 0 to AThreadCount - 1 do
    begin
      LThreads.Add(TThread.CreateAnonymousThread(
        procedure
        var
          J: Integer;
          LValue: string;
          LThreadId: string;
        begin
          LThreadId := TThread.Current.ThreadID.ToString;
          try
            for J := 0 to AOpsPerThread - 1 do
            begin
              FFallback.Put('key_' + LThreadId + '_' + J.ToString,
                'value_' + J.ToString, 300);
              FFallback.Get('key_' + LThreadId + '_' + J.ToString, LValue);
            end;
          except
            TInterlocked.Increment(LErrors);
          end;
        end
      ));
    end;

    // Inicia todas as threads
    for var LThread in LThreads do
    begin
      LThread.FreeOnTerminate := False;
      LThread.Start;
    end;

    // Aguarda conclusão
    for var LThread in LThreads do
    begin
      LThread.WaitFor;
      LThread.Free;
    end;

    LStopwatch.Stop;

    Assert.AreEqual(0, LErrors,
      Format('Houve %d erros em %d threads x %d operações. Tempo: %dms',
        [LErrors, AThreadCount, AOpsPerThread, LStopwatch.ElapsedMilliseconds]));
  finally
    LThreads.Free;
  end;
end;

procedure TStressTest.Test_Concurrent_ReadWrite_NoDeadlock;
var
  LThreads: TList<TThread>;
  LFinished: Integer;
  LStopwatch: TStopwatch;
  LTimeout: Boolean;
  I: Integer;
const
  THREAD_COUNT = 20;
  OPS_COUNT = 2000;
  TIMEOUT_MS = 30000; // 30 segundos
begin
  LFinished := 0;
  LTimeout := False;
  LThreads := TList<TThread>.Create;
  try
    LStopwatch := TStopwatch.StartNew;

    for I := 0 to THREAD_COUNT - 1 do
    begin
      LThreads.Add(TThread.CreateAnonymousThread(
        procedure
        var
          J: Integer;
          LVal: string;
        begin
          for J := 0 to OPS_COUNT - 1 do
          begin
            // Mistura operações para maximizar contenção
            FFallback.Put('shared_key_' + (J mod 100).ToString, 'data', 60);
            FFallback.Get('shared_key_' + (J mod 100).ToString, LVal);
            FFallback.Exists('shared_key_' + (J mod 100).ToString);
            if J mod 50 = 0 then
              FFallback.Remove('shared_key_' + (J mod 100).ToString);
          end;
          TInterlocked.Increment(LFinished);
        end
      ));
    end;

    for var LThread in LThreads do
    begin
      LThread.FreeOnTerminate := False;
      LThread.Start;
    end;

    // Espera com timeout para detectar deadlock
    while (LFinished < THREAD_COUNT) and (LStopwatch.ElapsedMilliseconds < TIMEOUT_MS) do
      Sleep(100);

    LTimeout := LFinished < THREAD_COUNT;

    for var LThread in LThreads do
    begin
      if not LTimeout then
        LThread.WaitFor;
      LThread.Free;
    end;

    LStopwatch.Stop;

    Assert.IsFalse(LTimeout,
      Format('DEADLOCK detectado! Apenas %d/%d threads finalizaram em %dms',
        [LFinished, THREAD_COUNT, LStopwatch.ElapsedMilliseconds]));
  finally
    LThreads.Free;
  end;
end;

procedure TStressTest.Test_Concurrent_Mixed_Operations;
var
  LThreads: TList<TThread>;
  LErrors: Integer;
  I: Integer;
const
  THREAD_COUNT = 30;
begin
  LErrors := 0;
  LThreads := TList<TThread>.Create;
  try
    for I := 0 to THREAD_COUNT - 1 do
    begin
      LThreads.Add(TThread.CreateAnonymousThread(
        procedure
        var
          J: Integer;
          LVal: string;
        begin
          try
            for J := 0 to 500 do
            begin
              case J mod 5 of
                0: FFallback.Put('mix_' + J.ToString, 'val', 120);
                1: FFallback.Get('mix_' + J.ToString, LVal);
                2: FFallback.Exists('mix_' + J.ToString);
                3: FFallback.Remove('mix_' + J.ToString);
                4: FFallback.Count;
              end;
            end;
          except
            TInterlocked.Increment(LErrors);
          end;
        end
      ));
    end;

    for var LThread in LThreads do
    begin
      LThread.FreeOnTerminate := False;
      LThread.Start;
    end;

    for var LThread in LThreads do
    begin
      LThread.WaitFor;
      LThread.Free;
    end;

    Assert.AreEqual(0, LErrors, Format('%d erros em operações mistas concorrentes', [LErrors]));
  finally
    LThreads.Free;
  end;
end;

procedure TStressTest.Test_High_Volume_Sequential;
var
  LStopwatch: TStopwatch;
  I: Integer;
  LVal: string;
const
  TOTAL_OPS = 100000;
begin
  LStopwatch := TStopwatch.StartNew;

  for I := 0 to TOTAL_OPS - 1 do
  begin
    FFallback.Put('seq_' + I.ToString, 'data_' + I.ToString, 300);
  end;

  for I := 0 to TOTAL_OPS - 1 do
  begin
    FFallback.Get('seq_' + I.ToString, LVal);
  end;

  LStopwatch.Stop;

  Assert.IsTrue(LStopwatch.ElapsedMilliseconds < 30000,
    Format('Operações sequenciais (2x%d) demoraram %dms (limite: 30s)',
      [TOTAL_OPS, LStopwatch.ElapsedMilliseconds]));
end;

initialization
  TDUnitX.RegisterTestFixture(TStressTest);

end.
