unit Infra.Data.Connector.Firedac.Helper;

interface

uses System.SysUtils,
     System.StrUtils,

     Infra.Data.Core.Types,
     Infra.Data.Connector.Types,
     Infra.Data.Connector.Interfaces,
     Infra.Data.Connector.Firedac.Drivers,
     Infra.Data.Connector.Firedac.ConfigConnection;

type
   TFiredacConnectorHelper = record helper for TDatabaseManager
      function Driver:IFiredacDriverConnection;
      procedure Configure( aValue:IDataConnection);
      function ToString:String;
      procedure FromString( aValue:String);
   end;

implementation

{ TFiredacConnectorHelper }

procedure TFiredacConnectorHelper.Configure( aValue:IDataConnection);
begin
   case Self of
      dmFirebird :TFBConnectionConfig.New( aValue).Configure;
      dmInterbase:;
      dmMySQL    :TMySQLConnectionConfig.New( aValue).Configure;
      dmSQLite   :TSQLiteConnectionConfig.New( aValue).Configure;
   end;
end;

function TFiredacConnectorHelper.Driver: IFiredacDriverConnection;
begin
   case Self of
      {$IFDEF MSWINDOWS}
      dmFirebird :Result := TFBDriverConnection.New;
      dmInterbase:;
      dmMySQL    :Result := TMySQLDriverConnection.New;
      {$ENDIF}
      dmSQLite   :Result := TSQLiteDriverConnection.New;
   end;
end;

procedure TFiredacConnectorHelper.FromString(aValue: String);
begin
   case AnsiIndexStr( AnsiLowerCase( aValue), [ AnsiLowerCase( 'Firebird'),
                                                AnsiLowerCase( 'Interbase'),
                                                AnsiLowerCase( 'MySQL'),
                                                AnsiLowerCase( 'SQLite')]) of
      0:Self := dmFirebird;
      1:Self := dmInterbase;
      2:Self := dmMySQL;
      3:Self := dmSQLite;
   end;
end;

function TFiredacConnectorHelper.ToString: String;
begin
   case Self of
      dmFirebird :Result := 'Firebird';
      dmInterbase:Result := 'Interbase';
      dmMySQL    :Result := 'MySQL';
      dmSQLite   :Result := 'SQLite';
   end;
end;

end.
