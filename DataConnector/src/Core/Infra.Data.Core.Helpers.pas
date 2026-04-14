unit Infra.Data.Core.Helpers;

interface

uses System.SysUtils,
     System.StrUtils,
     Infra.Data.Core.Types;

type
   THelperDataType = record helper for TDataType
      procedure FromStr( aValue:String);
      function ToString:String;
   end;

   TDataComponentHelper = record helper for TDataComponent
      function ToString:String;
      procedure FromString( aValue:String);
   end;

   TDatabaseManagerHelper = record helper for TDatabaseManager
      function ToString:String;
      procedure FromString( aValue:String);
   end;

   TClientCacheHelper = record helper for TClientCache
      function ToString:String;
      procedure FromString( aValue:String);
   end;

implementation

{ TDataType }

procedure THelperDataType.FromStr(aValue: String);
begin
   case AnsiIndexStr( AnsiLowerCase( aValue), [ AnsiLowerCase( 'Rest'),
                                                AnsiLowerCase( 'DataBase')]) of
      0:Self := dtRest;
      1:Self := dtDataBase;
   end;
end;

function THelperDataType.ToString: String;
begin
   case Self of
      dtRest    :Result := 'Rest';
      dtDataBase:Result := 'DataBase';
   end;
end;

{ TDataEngineHelper }

procedure TDataComponentHelper.FromString(aValue: String);
begin
   case AnsiIndexStr( AnsiLowerCase( aValue), [ AnsiLowerCase( 'Firedac'),
                                                AnsiLowerCase( 'Zeus')]) of
      0:Self := dcFiredac;
      1:Self := dcZeus;
   end;
end;

function TDataComponentHelper.ToString: String;
begin
   case Self of
      dcFiredac:Result := 'Firedac';
      dcZeus   :Result := 'Zeus';
   end;
end;

{ TDatabaseManagerHelper }

procedure TDatabaseManagerHelper.FromString(aValue: String);
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

function TDatabaseManagerHelper.ToString: String;
begin
   case Self of
      dmFirebird :Result := 'Firebird';
      dmInterbase:Result := 'Interbase';
      dmMySQL    :Result := 'MySQL';
      dmSQLite   :Result := 'SQLite';
   end;
end;

{ TClientCacheHelper }

procedure TClientCacheHelper.FromString(aValue: String);
begin
   case AnsiIndexStr( AnsiLowerCase( aValue), [ AnsiLowerCase( 'None'),
                                                AnsiLowerCase( 'DataBase'),
                                                AnsiLowerCase( 'Memory'),
                                                AnsiLowerCase( 'Hybrid')]) of
      0:Self := ccNone;
      1:Self := ccDataBase;
      2:Self := ccMemory;
      3:Self := ccHybrid;
   end;
end;

function TClientCacheHelper.ToString: String;
begin
   case Self of
      ccNone    :Result := 'None';
      ccDataBase:Result := 'DataBase';
      ccMemory  :Result := 'Memory';
      ccHybrid  :Result := 'Hybrid';
   end;
end;

end.
