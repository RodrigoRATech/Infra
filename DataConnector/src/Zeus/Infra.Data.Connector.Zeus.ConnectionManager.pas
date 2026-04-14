unit Infra.Data.Connector.Zeus.ConnectionManager;

interface

uses System.SysUtils,

     ZConnection,
     Data.DB,

     PoolManager,
     Infra.Data.Connector.Zeus.Connection;

type
   TDataConnectionManagerZeus = class( TPoolManager<TZConnection>)
   private
      class var FConnectionManager:TDataConnectionManagerZeus;

   public
      class function GetInstance:TDataConnectionManagerZeus;
      class Destructor UnInitialize;

      procedure DoGetInstance(var AInstance: TZConnection; var AInstanceOwner: Boolean); override;

   end;

implementation

{ TDataConnectionManagerZeus }

procedure TDataConnectionManagerZeus.DoGetInstance(
  var AInstance: TZConnection; var AInstanceOwner: Boolean);
begin
   AInstance := TZConnection.Create( nil);
   AInstanceOwner := True;
end;

class function TDataConnectionManagerZeus.GetInstance: TDataConnectionManagerZeus;
begin
   if not Assigned( FConnectionManager) then
   begin
      FConnectionManager := TDataConnectionManagerZeus.Create( true);
      FConnectionManager.SetMaxIdleSeconds( 10);
      FConnectionManager.SetMinPoolCount( 5);

      FConnectionManager.Start;
   end;

   Result := FConnectionManager;
end;

class destructor TDataConnectionManagerZeus.UnInitialize;
begin
   FConnectionManager.Terminate;
end;

end.
