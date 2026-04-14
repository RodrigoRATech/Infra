unit Infra.Data.Connector.Zeus.Helper;

interface

uses  System.SysUtils,
      System.StrUtils,

      Infra.Data.Core.Types,
      Infra.Data.Connector.Types,
      Infra.Data.Connector.Interfaces,
      Infra.Data.Connector.Zeus.ConfigConnection;

type
   TZeusConnectorHelper = record helper for TDatabaseManager
      function ToString:String;
      procedure FromString( aValue:String);
      procedure Configure( aValue:IDataConnection);
   end;

implementation

{ TZeusConnectorHelper }

procedure TZeusConnectorHelper.Configure( aValue:IDataConnection);
begin
   case Self of
      dmFirebird :TFBConnectionConfig.New( aValue).Configure;
      dmInterbase:;
      dmMySQL    :TMySQLConnectionConfig.New( aValue).Configure;
      dmSQLite   :TSQLiteConnectionConfig.New( aValue).Configure;
   end;
end;

procedure TZeusConnectorHelper.FromString(aValue: String);
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

function TZeusConnectorHelper.ToString: String;
begin
   case Self of
      dmFirebird :Result := 'Firebird';
      dmInterbase:Result := 'Interbase';
      dmMySQL    :Result := 'MySQL';
      dmSQLite   :Result := 'SQLite';
   end;
end;

end.
