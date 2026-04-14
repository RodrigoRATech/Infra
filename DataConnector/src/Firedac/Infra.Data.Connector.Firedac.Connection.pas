unit Infra.Data.Connector.Firedac.Connection;

interface

uses System.SysUtils,
     System.Classes,

     Infra.Data.Core.Types,
     Infra.Data.Connector.Interfaces,
     Infra.Data.Connector.Types,
     Infra.Data.Connector.Firedac.Drivers,
     Infra.Data.Connector.Firedac.ConfigConnection,
     Infra.Data.Connector.Firedac.Helper,

     FireDAC.Comp.Client,
     FireDAC.Stan.Def,
     FireDAC.Stan.Async,

     Data.DB,
     PoolManager;

type
   TDataConnectionFiredac = class( TInterfacedObject, IDataConnection)
   private
      FConexaoItem:TPoolItem<TFDConnection>;
      FConexao:TFDConnection;

      FLibraryLocation:string;
      FManager:TDatabaseManager;
      FDriver:IFiredacDriverConnection;
      FServer:String;
      FPort:Integer;
      FDataBase:String;
      FUserName:String;
      FPassword:String;

   public
      constructor Create;
      destructor Destroy; override;
      class function New:IDataConnection;

      function DataComponent:TDataComponent;
      function DataManager( aValue:TDatabaseManager):IDataConnection;overload;
      function Server( aValue:String):IDataConnection;overload;
      function Port( aValue:Integer):IDataConnection;overload;
      function DataBase( aValue:String):IDataConnection;overload;
      function UserName( aValue:String):IDataConnection;overload;
      function Password( aValue:String):IDataConnection;overload;
      function LibraryLocation( aValue:string):IDataConnection;overload;

      function DataManager:TDatabaseManager;overload;
      function Server:String;overload;
      function Port:Integer;overload;
      function DataBase:String;overload;
      function UserName:String;overload;
      function Password:String;overload;
      function LibraryLocation:string;overload;

      function Connect:IDataConnection;
      function Disconnect:IDataConnection;
      function Connection:TCustomConnection;
      function Component:TComponent;
   end;

implementation

uses Infra.Data.Connector.Firedac.ConnectionManager;

{ TDataConnectionFiredac }

function TDataConnectionFiredac.Component: TComponent;
begin
   Result := FConexao;
end;

function TDataConnectionFiredac.Connect: IDataConnection;
Var lMessage:String;
begin
   Result := Self;
   FDriver := FManager.Driver;
   FManager.Configure( Self);

   try
      FConexao.Connected := true;
   except
      on e:exception do
         lMessage := e.Message;
   end;
end;

function TDataConnectionFiredac.Connection: TCustomConnection;
begin
   Result := FConexao;
end;

function TDataConnectionFiredac.DataManager( aValue: TDatabaseManager): IDataConnection;
begin
   Result := Self;
   FManager := aValue;
end;

function TDataConnectionFiredac.DataManager: TDatabaseManager;
begin
   Result := FManager;
end;

constructor TDataConnectionFiredac.Create;
begin
   FConexaoItem  :=  TDataConnectionManagerFiredac.GetInstance.TryGetItem;
   FConexao := FConexaoItem.Acquire;
   FConexao.LoginPrompt := False;
end;

function TDataConnectionFiredac.DataBase: String;
begin
   Result := FDatabase;
end;

function TDataConnectionFiredac.DataComponent: TDataComponent;
begin
   Result := dcFiredac;
end;

function TDataConnectionFiredac.DataBase( aValue: String): IDataConnection;
begin
   Result := Self;
   FDatabase := aValue;
end;

destructor TDataConnectionFiredac.Destroy;
begin
   FConexaoItem.Release;
   inherited;
end;

function TDataConnectionFiredac.Disconnect: IDataConnection;
begin
   Result := Self;
   FConexao.Connected := false;
end;

function TDataConnectionFiredac.LibraryLocation: string;
begin
   Result := FLibraryLocation;
end;

function TDataConnectionFiredac.LibraryLocation( aValue: string): IDataConnection;
begin
   Result := Self;
   FLibraryLocation := aValue;
end;

class function TDataConnectionFiredac.New: IDataConnection;
begin
   Result := Self.Create;
end;

function TDataConnectionFiredac.Password: String;
begin
   Result := FPassword;
end;

function TDataConnectionFiredac.Password( aValue: String): IDataConnection;
begin
   Result := Self;
   FPassword := aValue;
end;

function TDataConnectionFiredac.Port( aValue: Integer): IDataConnection;
begin
   Result := Self;
   FPort := aValue;
end;

function TDataConnectionFiredac.Port: Integer;
begin
   Result := FPort;
end;

function TDataConnectionFiredac.Server: String;
begin
   Result := FServer;
end;

function TDataConnectionFiredac.Server( aValue: String): IDataConnection;
begin
   Result := Self;
   FServer := aValue;
end;

function TDataConnectionFiredac.UserName( aValue: String): IDataConnection;
begin
   Result := Self;
   FUserName := aValue;
end;

function TDataConnectionFiredac.UserName: String;
begin
   Result := FUserName;
end;

end.
