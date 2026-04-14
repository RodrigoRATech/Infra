unit Infra.Data.Connector.Zeus.ConfigConnection;

interface

uses System.SysUtils,

     Infra.Data.Connector.Interfaces,
     Infra.Data.Connector.Types,
     ZConnection;

type
   IZeusConnectionConfig = interface
      ['{EEFE6200-B7D3-493A-A14B-9F066E1D9208}']
      function Server( aValue:String):IZeusConnectionConfig;
      function Port( aValue:Integer):IZeusConnectionConfig;
      function DataBase( aValue:String):IZeusConnectionConfig;
      function UserName( aValue:String):IZeusConnectionConfig;
      function Password( aValue:String):IZeusConnectionConfig;
      function LibraryLocation( aValue:string):IZeusConnectionConfig;

      function Configure:IZeusConnectionConfig;
   end;

   TFBConnectionConfig = class( TInterfacedObject, IZeusConnectionConfig)
   private
      [weak]
      FConnection:IDataConnection;
      FServer:String;
      FPort:Integer;
      FDataBase:String;
      FUserName:String;
      FPassword:String;
      FLibraryLocation:string;

   public
      constructor Create( aConnection:IDataConnection);
      destructor Destroy;override;
      class function New( aConnection:IDataConnection):IZeusConnectionConfig;

      function Server( aValue:String):IZeusConnectionConfig;
      function Port( aValue:Integer):IZeusConnectionConfig;
      function DataBase( aValue:String):IZeusConnectionConfig;
      function UserName( aValue:String):IZeusConnectionConfig;
      function Password( aValue:String):IZeusConnectionConfig;
      function LibraryLocation( aValue:string):IZeusConnectionConfig;

      function Configure:IZeusConnectionConfig;
   end;

   TMySQLConnectionConfig = class( TInterfacedObject, IZeusConnectionConfig)
   private
      [weak]
      FConnection:IDataConnection;
      FServer:String;
      FPort:Integer;
      FDataBase:String;
      FUserName:String;
      FPassword:String;
      FLibraryLocation:string;

   public
      constructor Create( aConnection:IDataConnection);
      destructor Destroy;override;
      class function New( aConnection:IDataConnection):IZeusConnectionConfig;

      function Server( aValue:String):IZeusConnectionConfig;
      function Port( aValue:Integer):IZeusConnectionConfig;
      function DataBase( aValue:String):IZeusConnectionConfig;
      function UserName( aValue:String):IZeusConnectionConfig;
      function Password( aValue:String):IZeusConnectionConfig;
      function LibraryLocation( aValue:string):IZeusConnectionConfig;

      function Configure:IZeusConnectionConfig;
   end;

   TSQLiteConnectionConfig = class( TInterfacedObject, IZeusConnectionConfig)
   private
      [weak]
      FConnection:IDataConnection;
      FServer:String;
      FPort:Integer;
      FDataBase:String;
      FUserName:String;
      FPassword:String;
      FLibraryLocation:string;

   public
      constructor Create( aConnection:IDataConnection);
      destructor Destroy;override;
      class function New( aConnection:IDataConnection):IZeusConnectionConfig;

      function Server( aValue:String):IZeusConnectionConfig;
      function Port( aValue:Integer):IZeusConnectionConfig;
      function DataBase( aValue:String):IZeusConnectionConfig;
      function UserName( aValue:String):IZeusConnectionConfig;
      function Password( aValue:String):IZeusConnectionConfig;
      function LibraryLocation( aValue:string):IZeusConnectionConfig;

      function Configure:IZeusConnectionConfig;
   end;

implementation

{ TFBConnectionConfig }

function TFBConnectionConfig.Configure: IZeusConnectionConfig;
begin
   Result := Self;

   with TzConnection( FConnection.Component) do
   begin
      Protocol        := 'firebird';

      if FConnection.Server.IsEmpty then
         HostName   := FServer
      else HostName := FConnection.Server;

      if FConnection.Port > 0 then
         Port   := FPort
      else Port := FConnection.Port;

      if FConnection.UserName.IsEmpty then
         User   := FUserName
      else User := FConnection.UserName;

      if FConnection.Password.IsEmpty then
         Password   := FPassword
      else Password := FConnection.Password;

      if FConnection.DataBase.IsEmpty then
         Database   := FDataBase
      else Database := FConnection.DataBase;

      if FConnection.LibraryLocation.IsEmpty then
         LibraryLocation   := FLibraryLocation
      else LibraryLocation := FConnection.LibraryLocation;
   end;
end;

constructor TFBConnectionConfig.Create( aConnection: IDataConnection);
begin
   FConnection := aConnection;
end;

function TFBConnectionConfig.DataBase(aValue: String): IZeusConnectionConfig;
begin
   Result := Self;
   FDataBase := aValue;
end;

destructor TFBConnectionConfig.Destroy;
begin

  inherited;
end;

function TFBConnectionConfig.LibraryLocation(aValue: string): IZeusConnectionConfig;
begin
   Result := Self;
   FLibraryLocation := aValue;
end;

class function TFBConnectionConfig.New( aConnection: IDataConnection): IZeusConnectionConfig;
begin
   Result := Self.Create( aConnection);
end;

function TFBConnectionConfig.Password(aValue: String): IZeusConnectionConfig;
begin
   Result := Self;
   FPassword := aValue;
end;

function TFBConnectionConfig.Port(aValue: Integer): IZeusConnectionConfig;
begin
   Result := Self;
   FPort := aValue;
end;

function TFBConnectionConfig.Server(aValue: String): IZeusConnectionConfig;
begin
   Result := Self;
   FServer := aValue;
end;

function TFBConnectionConfig.UserName(aValue: String): IZeusConnectionConfig;
begin
   Result := Self;
   FUserName := aValue;
end;

{ TMySQLConnectionConfig }

function TMySQLConnectionConfig.Configure: IZeusConnectionConfig;
begin
   Result := Self;

   with TzConnection( FConnection.Component) do
   begin
      Protocol        := 'mysql';

      if FConnection.Server.IsEmpty then
         HostName   := FServer
      else HostName := FConnection.Server;

      if FConnection.Port > 0 then
         Port   := FPort
      else Port := FConnection.Port;

      if FConnection.UserName.IsEmpty then
         User   := FUserName
      else User := FConnection.UserName;

      if FConnection.Password.IsEmpty then
         Password   := FPassword
      else Password := FConnection.Password;

      if FConnection.DataBase.IsEmpty then
         Database   := FDataBase
      else Database := FConnection.DataBase;

      if FConnection.LibraryLocation.IsEmpty then
         LibraryLocation   := FLibraryLocation
      else LibraryLocation := FConnection.LibraryLocation;
   end;
end;

constructor TMySQLConnectionConfig.Create( aConnection: IDataConnection);
begin
   FConnection := aConnection;
end;

function TMySQLConnectionConfig.DataBase(aValue: String): IZeusConnectionConfig;
begin
   Result := Self;
   FDataBase := aValue;
end;

destructor TMySQLConnectionConfig.Destroy;
begin

  inherited;
end;

function TMySQLConnectionConfig.LibraryLocation(aValue: string): IZeusConnectionConfig;
begin
   Result := Self;
   FLibraryLocation := aValue;
end;

class function TMySQLConnectionConfig.New( aConnection: IDataConnection): IZeusConnectionConfig;
begin
   Result := Self.Create( aConnection);
end;

function TMySQLConnectionConfig.Password(aValue: String): IZeusConnectionConfig;
begin
   Result := Self;
   FPassword := aValue;
end;

function TMySQLConnectionConfig.Port(aValue: Integer): IZeusConnectionConfig;
begin
   Result := Self;
   FPort := aValue;
end;

function TMySQLConnectionConfig.Server(aValue: String): IZeusConnectionConfig;
begin
   Result := Self;
   FServer := aValue;
end;

function TMySQLConnectionConfig.UserName(aValue: String): IZeusConnectionConfig;
begin
   Result := Self;
   FUserName := aValue;
end;

{ TSQLiteConnectionConfig }

function TSQLiteConnectionConfig.Configure: IZeusConnectionConfig;
begin
   Result := Self;

   with TzConnection( FConnection.Component) do
   begin
      LoginPrompt  := False;
      Protocol     := 'sqlite';
      Database     := FConnection.DataBase;
   end;
end;

constructor TSQLiteConnectionConfig.Create(aConnection: IDataConnection);
begin
   FConnection := aConnection;
end;

function TSQLiteConnectionConfig.DataBase(aValue: String): IZeusConnectionConfig;
begin
   Result := Self;
   FDataBase := aValue;
end;

destructor TSQLiteConnectionConfig.Destroy;
begin

  inherited;
end;

function TSQLiteConnectionConfig.LibraryLocation(aValue: string): IZeusConnectionConfig;
begin
   Result := Self;
   FLibraryLocation := aValue;
end;

class function TSQLiteConnectionConfig.New( aConnection: IDataConnection): IZeusConnectionConfig;
begin
   Result := Self.Create( aConnection);
end;

function TSQLiteConnectionConfig.Password(aValue: String): IZeusConnectionConfig;
begin
   Result := Self;
   FPassword := aValue;
end;

function TSQLiteConnectionConfig.Port(aValue: Integer): IZeusConnectionConfig;
begin
   Result := Self;
   FPort := aValue;
end;

function TSQLiteConnectionConfig.Server(aValue: String): IZeusConnectionConfig;
begin
   Result := Self;
   FServer := aValue;
end;

function TSQLiteConnectionConfig.UserName(aValue: String): IZeusConnectionConfig;
begin
   Result := Self;
   FUserName := aValue;
end;

end.
