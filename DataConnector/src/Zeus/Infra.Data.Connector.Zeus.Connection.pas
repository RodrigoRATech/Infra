unit Infra.Data.Connector.Zeus.Connection;

interface

uses System.SysUtils, System.Classes,

     Infra.Data.Core.Types,
     Infra.Data.Connector.Interfaces,
     Infra.Data.Connector.Types,
     Infra.Data.Connector.Zeus.Helper,
     Infra.Data.Connector.Zeus.ConfigConnection,

     Data.DB,

     PoolManager,
     ZConnection;

type
   TDataConnectionZeus = class( TInterfacedObject, IDataConnection)
   private
      FConexaoItem:TPoolItem<TZConnection>;
      FConexao:TZConnection;
      FDBManager:TDatabaseManager;
      FServer:String;
      FPort:Integer;
      FDataBase:String;
      FUserName:String;
      FPassword:String;
      FLibraryLocation:String;

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
      function Manager:TDatabaseManager;

      function Connect:IDataConnection;
      function Disconnect:IDataConnection;
      function Connection:TCustomConnection;
      function Component:TComponent;
   end;

implementation

uses Infra.Data.Connector.Zeus.ConnectionManager;

{ TDataConnectionZeus }

function TDataConnectionZeus.Component: TComponent;
begin
   Result := FConexao;
end;

function TDataConnectionZeus.Connect: IDataConnection;
Var lMessage:String;
begin
   Result := Self;
   FDBManager.Configure( Self);

   try
      FConexao.Connected := true;
   except
      on e:exception do
         lMessage := e.Message;
   end;
end;

function TDataConnectionZeus.Connection: TCustomConnection;
begin
   raise Exception.Create( 'Resource not valid');
end;

function TDataConnectionZeus.DataManager( aValue: TDatabaseManager): IDataConnection;
begin
   Result := Self;
   FDBManager := aValue;
end;

function TDataConnectionZeus.DataManager: TDatabaseManager;
begin
   Result := FDBManager;
end;

constructor TDataConnectionZeus.Create;
begin
   FConexaoItem  := TDataConnectionManagerZeus.GetInstance.TryGetItem;
   FConexao      := FConexaoItem.Acquire;
   FConexao.LoginPrompt := False;
end;

function TDataConnectionZeus.DataBase: String;
begin
   Result := FDatabase;
end;

function TDataConnectionZeus.DataComponent: TDataComponent;
begin
   Result := dcZeus;
end;

function TDataConnectionZeus.DataBase( aValue: String): IDataConnection;
begin
   Result := Self;
   FDatabase := aValue;
end;

destructor TDataConnectionZeus.Destroy;
begin
   FConexaoItem.Release;
   inherited;
end;

function TDataConnectionZeus.Disconnect: IDataConnection;
begin
   Result := Self;
   FConexao.Connected := false;
end;

function TDataConnectionZeus.LibraryLocation: string;
begin
   Result := FLibraryLocation;
end;

function TDataConnectionZeus.Manager: TDatabaseManager;
begin
   Result := FDBManager;
end;

function TDataConnectionZeus.LibraryLocation(aValue: string): IDataConnection;
begin
   Result := Self;
   FLibraryLocation := aValue;
end;

class function TDataConnectionZeus.New: IDataConnection;
begin
   Result := Self.Create;
end;

function TDataConnectionZeus.Password: String;
begin
   Result := FPassword;
end;

function TDataConnectionZeus.Password( aValue: String): IDataConnection;
begin
   Result := Self;
   FPassword := aValue;
end;

function TDataConnectionZeus.Port( aValue: Integer): IDataConnection;
begin
   Result := Self;
   FPort := aValue;
end;

function TDataConnectionZeus.Port: Integer;
begin
   Result := FPort;
end;

function TDataConnectionZeus.Server: String;
begin
   Result := FServer;
end;

function TDataConnectionZeus.Server( aValue: String): IDataConnection;
begin
   Result := Self;
   FServer := aValue;
end;

function TDataConnectionZeus.UserName( aValue: String): IDataConnection;
begin
   Result := Self;
   FUserName := aValue;
end;

function TDataConnectionZeus.UserName: String;
begin
   Result := FUserName;
end;

end.
