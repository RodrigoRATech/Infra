unit Infra.Data.Connector.Factory;

interface

uses System.SysUtils,

     Infra.Data.Core.Types,
     Infra.Data.Core.Helpers,
     Infra.Data.Connector.Types,
     Infra.Data.Connector.Interfaces;

type
   TDataConnectFactory = class( TInterfacedObject, IDataFactory)
   private
      FComponent:TDataComponent;

   public
      constructor Create( aComponent:TDataComponent = dcFiredac);
      destructor Destroy;override;
      class function New( aComponent:TDataComponent = dcFiredac):IDataFactory;

      function Connection:IDataConnection;
      function Query( aConnection:IDataConnection): IDataQuery;
  end;

implementation

uses Infra.Data.Connector.Firedac.Connection,
     Infra.Data.Connector.Firedac.Query

     {$IFDEF MSWINDOWS},
     Infra.Data.Connector.Zeus.Connection,
     Infra.Data.Connector.Zeus.Query
     {$ENDIF}
     ;


{ TDataConnectFactory }

function TDataConnectFactory.Connection: IDataConnection;
begin
   Result := nil;

   case FComponent of
      dcFiredac:Result := TDataConnectionFiredac.New;
      {$IFDEF MSWINDOWS}
      dcZeus   :Result := TDataConnectionZeus.New;
      {$ENDIF}
   end;

   if not Assigned( Result) then
      raise Exception.Create( 'Create connection fail.');
end;

constructor TDataConnectFactory.Create( aComponent:TDataComponent = dcFiredac);
begin
   FComponent  := aComponent;
end;

destructor TDataConnectFactory.Destroy;
begin

  inherited;
end;

class function TDataConnectFactory.New( aComponent:TDataComponent = dcFiredac): IDataFactory;
begin
   Result := Self.Create( aComponent);
end;

function TDataConnectFactory.Query( aConnection: IDataConnection): IDataQuery;
begin
   case aConnection.DataComponent of
      dcFiredac:Result := TDataQueryFiredac.New( aConnection);
      {$IFDEF MSWINDOWS}
      dcZeus   :Result := TDataQueryZeus.New( aConnection);
      {$ENDIF}
   end;
end;

end.
