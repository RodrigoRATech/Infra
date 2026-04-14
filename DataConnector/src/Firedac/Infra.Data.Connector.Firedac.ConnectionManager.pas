unit Infra.Data.Connector.Firedac.ConnectionManager;

interface

uses System.SysUtils,

     FireDAC.Comp.Client,
     FireDAC.Stan.Def,
     FireDAC.Stan.Async,

     Data.DB,

     PoolManager,
     Infra.Data.Connector.Firedac.Connection;

type
   TDataConnectionManagerFiredac = class( TPoolManager<TFDConnection>)
   private
      class var FConnectionManager:TDataConnectionManagerFiredac;

   public
      class function GetInstance:TDataConnectionManagerFiredac;
      class Destructor UnInitialize;

      procedure DoGetInstance(var AInstance: TFDConnection; var AInstanceOwner: Boolean); override;

   end;

implementation

{ TDataConnectionManagerFiredac }

procedure TDataConnectionManagerFiredac.DoGetInstance(
  var AInstance: TFDConnection; var AInstanceOwner: Boolean);
begin
   AInstance := TFDConnection.Create( nil);
   AInstanceOwner := True;
end;

class function TDataConnectionManagerFiredac.GetInstance: TDataConnectionManagerFiredac;
begin
   if not Assigned( FConnectionManager) then
   begin
      FConnectionManager := TDataConnectionManagerFiredac.Create( true);
      FConnectionManager.SetMaxIdleSeconds( 10);
      FConnectionManager.SetMinPoolCount( 5);

      FConnectionManager.Start;
   end;

   Result := FConnectionManager;
end;

class destructor TDataConnectionManagerFiredac.UnInitialize;
begin
   FConnectionManager.Free;
end;

end.
