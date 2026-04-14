unit Infra.Data.Connector.Firedac.ConfigConnection;

interface

uses System.SysUtils,

     Infra.Data.Connector.Interfaces,
     Infra.Data.Connector.Types,

     FireDAC.Comp.Client;

type
   IFiredacConnectionConfig = interface
      ['{EEFE6200-B7D3-493A-A14B-9F066E1D9208}']
      function Server( aValue:String):IFiredacConnectionConfig;
      function Port( aValue:Integer):IFiredacConnectionConfig;
      function DataBase( aValue:String):IFiredacConnectionConfig;
      function UserName( aValue:String):IFiredacConnectionConfig;
      function Password( aValue:String):IFiredacConnectionConfig;
      function LibraryLocation( aValue:string):IFiredacConnectionConfig;

      function Configure:IFiredacConnectionConfig;
   end;

   TFBConnectionConfig = class( TInterfacedObject, IFiredacConnectionConfig)
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
      class function New( aConnection:IDataConnection):IFiredacConnectionConfig;

      function Server( aValue:String):IFiredacConnectionConfig;
      function Port( aValue:Integer):IFiredacConnectionConfig;
      function DataBase( aValue:String):IFiredacConnectionConfig;
      function UserName( aValue:String):IFiredacConnectionConfig;
      function Password( aValue:String):IFiredacConnectionConfig;
      function LibraryLocation( aValue:string):IFiredacConnectionConfig;

      function Configure:IFiredacConnectionConfig;
   end;

   TMySQLConnectionConfig = class( TInterfacedObject, IFiredacConnectionConfig)
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
      class function New( aConnection:IDataConnection):IFiredacConnectionConfig;

      function Server( aValue:String):IFiredacConnectionConfig;
      function Port( aValue:Integer):IFiredacConnectionConfig;
      function DataBase( aValue:String):IFiredacConnectionConfig;
      function UserName( aValue:String):IFiredacConnectionConfig;
      function Password( aValue:String):IFiredacConnectionConfig;
      function LibraryLocation( aValue:string):IFiredacConnectionConfig;

      function Configure:IFiredacConnectionConfig;
   end;

   TSQLiteConnectionConfig = class( TInterfacedObject, IFiredacConnectionConfig)
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
      class function New( aConnection:IDataConnection):IFiredacConnectionConfig;

      function Server( aValue:String):IFiredacConnectionConfig;
      function Port( aValue:Integer):IFiredacConnectionConfig;
      function DataBase( aValue:String):IFiredacConnectionConfig;
      function UserName( aValue:String):IFiredacConnectionConfig;
      function Password( aValue:String):IFiredacConnectionConfig;
      function LibraryLocation( aValue:string):IFiredacConnectionConfig;

      function Configure:IFiredacConnectionConfig;
   end;

implementation

{ TFBConnectionConfig }

function TFBConnectionConfig.Configure: IFiredacConnectionConfig;
begin
   Result := Self;

   with TFDConnection( FConnection.Connection) do
   begin
      DriverName      := 'FB';

      if FConnection.Server <> EmptyStr then
         FConnection.DataBase( FConnection.Server +':'+ FConnection.DataBase);

      Params.DriverID := 'FB';

      if FConnection.UserName.IsEmpty then
         Params.UserName   := FUserName
      else Params.UserName := FConnection.UserName;

      if FConnection.Password.IsEmpty then
         Params.Password   := FPassword
      else Params.Password := FConnection.Password;

      if FConnection.DataBase.IsEmpty then
         Params.Database   := FDataBase
      else Params.Database := FConnection.DataBase;

      if FConnection.LibraryLocation.IsEmpty then
         if not FLibraryLocation.IsEmpty then
            FConnection.LibraryLocation( FLibraryLocation);

      Params.AddPair( 'CharacterSet', 'WIN1252');
   end;
end;

constructor TFBConnectionConfig.Create( aConnection: IDataConnection);
begin
   FConnection := aConnection;
end;

function TFBConnectionConfig.DataBase(aValue: String): IFiredacConnectionConfig;
begin
   Result := Self;
   FDataBase := aValue;
end;

destructor TFBConnectionConfig.Destroy;
begin

  inherited;
end;

function TFBConnectionConfig.LibraryLocation(aValue: string): IFiredacConnectionConfig;
begin
   Result := Self;
   FLibraryLocation := aValue;
end;

class function TFBConnectionConfig.New( aConnection: IDataConnection): IFiredacConnectionConfig;
begin
   Result := Self.Create( aConnection);
end;

function TFBConnectionConfig.Password(aValue: String): IFiredacConnectionConfig;
begin
   Result := Self;
   FPassword := aValue;
end;

function TFBConnectionConfig.Port(aValue: Integer): IFiredacConnectionConfig;
begin
   Result := Self;
   FPort := aValue;
end;

function TFBConnectionConfig.Server(aValue: String): IFiredacConnectionConfig;
begin
   Result := Self;
   FServer := aValue;
end;

function TFBConnectionConfig.UserName(aValue: String): IFiredacConnectionConfig;
begin
   Result := Self;
   FUserName := aValue;
end;

{ TMySQLConnectionConfig }

function TMySQLConnectionConfig.Configure: IFiredacConnectionConfig;
begin
   Result := Self;

   with TFDConnection( FConnection.Connection) do
   begin
      DriverName      := 'MySQL';

      Params.Clear;
      Params.DriverID := 'MySQL';
      Params.Database := FConnection.DataBase;
      Params.UserName := FConnection.UserName;
      Params.Password := FConnection.Password;
      Params.Add( 'Port='+   FConnection.Port.ToString);
      Params.Add( 'Server='+ FConnection.Server);
   end;
end;

constructor TMySQLConnectionConfig.Create( aConnection: IDataConnection);
begin
   FConnection := aConnection;
end;

function TMySQLConnectionConfig.DataBase(aValue: String): IFiredacConnectionConfig;
begin
   Result := Self;
   FDataBase := aValue;
end;

destructor TMySQLConnectionConfig.Destroy;
begin

  inherited;
end;

function TMySQLConnectionConfig.LibraryLocation(aValue: string): IFiredacConnectionConfig;
begin
   Result := Self;
   FLibraryLocation := aValue;
end;

class function TMySQLConnectionConfig.New( aConnection: IDataConnection): IFiredacConnectionConfig;
begin
   Result := Self.Create( aConnection);
end;

function TMySQLConnectionConfig.Password(aValue: String): IFiredacConnectionConfig;
begin
   Result := Self;
   FPassword := aValue;
end;

function TMySQLConnectionConfig.Port(aValue: Integer): IFiredacConnectionConfig;
begin
   Result := Self;
   FPort := aValue;
end;

function TMySQLConnectionConfig.Server(aValue: String): IFiredacConnectionConfig;
begin
   Result := Self;
   FServer := aValue;
end;

function TMySQLConnectionConfig.UserName(aValue: String): IFiredacConnectionConfig;
begin
   Result := Self;
   FUserName := aValue;
end;

{ TSQLiteConnectionConfig }

function TSQLiteConnectionConfig.Configure: IFiredacConnectionConfig;
begin
   Result := Self;

   with TFDConnection( FConnection.Connection) do
   begin
      DriverName      := 'SQLite';

      Params.Clear;
      Params.DriverID := 'SQLite';
      Params.Database := FConnection.DataBase;
   end;
end;

constructor TSQLiteConnectionConfig.Create(aConnection: IDataConnection);
begin
   FConnection := aConnection;
   FConnection.DataBase( FDataBase);
end;

function TSQLiteConnectionConfig.DataBase(aValue: String): IFiredacConnectionConfig;
begin
   Result := Self;
   FDataBase := aValue;
end;

destructor TSQLiteConnectionConfig.Destroy;
begin

  inherited;
end;

function TSQLiteConnectionConfig.LibraryLocation(aValue: string): IFiredacConnectionConfig;
begin
   Result := Self;
   FLibraryLocation := aValue;
end;

class function TSQLiteConnectionConfig.New( aConnection: IDataConnection): IFiredacConnectionConfig;
begin
   Result := Self.Create( aConnection);
end;

function TSQLiteConnectionConfig.Password(aValue: String): IFiredacConnectionConfig;
begin
   Result := Self;
   FPassword := aValue;
end;

function TSQLiteConnectionConfig.Port(aValue: Integer): IFiredacConnectionConfig;
begin
   Result := Self;
   FPort := aValue;
end;

function TSQLiteConnectionConfig.Server(aValue: String): IFiredacConnectionConfig;
begin
   Result := Self;
   FServer := aValue;
end;

function TSQLiteConnectionConfig.UserName(aValue: String): IFiredacConnectionConfig;
begin
   Result := Self;
   FUserName := aValue;
end;

end.
