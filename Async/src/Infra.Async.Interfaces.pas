unit Infra.Async.Interfaces;

interface

uses System.classes, System.SyncObjs,
     System.SysUtils, System.Threading;


type
  ICancellationToken = interface(IInterface)
    ['{CEDD7864-C15C-4254-8BFE-2ED82023FDAD}']

    function GetIsCancellationRequested: Boolean;
    property IsCancellationRequested: Boolean read GetIsCancellationRequested;
    procedure ThrowIfCancellationRequested;
    function WaitForCancellation(Timeout: Cardinal = INFINITE): TWaitResult;
  end;

  IAsyncTask = interface(ITask)
    ['{88997766-5544-3322-1100-AABBCCDDEE00}']

  end;

implementation

end.
