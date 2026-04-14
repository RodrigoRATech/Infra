unit Infra.Data.Connector.Firedac.Drivers;

interface

uses System.SysUtils,

     {$IFDEF MSWINDOWS}
     FireDAC.Phys.FB,
     FireDAC.Phys.FBDef,

     FireDAC.Phys.IBBase,
     FireDAC.Phys.IBDef,

     FireDAC.Phys.MySQL,
     FireDAC.Phys.MySQLDef,
     {$ENDIF}

     FireDAC.Phys.SQLite,
     FireDAC.Phys.SQLiteDef,

     FireDAC.FMXUI.Wait,
     FireDAC.Comp.UI;

type
   IFiredacDriverConnection = interface
      ['{82FABF50-E33C-4826-BF6E-EEA584D69A72}']
   end;

   {$IFDEF MSWINDOWS}
   TFBDriverConnection = class( TInterfacedObject, IFiredacDriverConnection)
   private
      FDriver:TFDPhysFBDriverLink;
      FCursor:TFDGUIxWaitCursor;

   public
      constructor Create;
      destructor Destroy;override;
      class function New:IFiredacDriverConnection;
   end;

   TMySQLDriverConnection = class( TInterfacedObject, IFiredacDriverConnection)
   private
      FDriver:TFDPhysMySQLDriverLink;
      FCursor: TFDGUIxWaitCursor;

   public
      constructor Create;
      destructor Destroy;override;
      class function New:IFiredacDriverConnection;
   end;
   {$ENDIF}

   TSQLiteDriverConnection = class( TInterfacedObject, IFiredacDriverConnection)
   private
      FDriver:TFDPhysSQLiteDriverLink;
      FCursor: TFDGUIxWaitCursor;

   public
      constructor Create;
      destructor Destroy;override;
      class function New:IFiredacDriverConnection;
   end;

implementation

{$IFDEF MSWINDOWS}
{ TFBDriverConnection }

constructor TFBDriverConnection.Create;
begin
   FDriver := TFDPhysFBDriverLink.Create( nil);
   FDriver.VendorLib := 'gds32.dll';
   FCursor := TFDGUIxWaitCursor.Create( nil);
end;

destructor TFBDriverConnection.Destroy;
begin
   FreeAndNil( FDriver);
   FreeAndNil( FCursor);
   inherited;
end;

class function TFBDriverConnection.New: IFiredacDriverConnection;
begin
   Result := Self.Create;
end;

{ TMySQLDriverConnection }

constructor TMySQLDriverConnection.Create;
begin
   FDriver := TFDPhysMySQLDriverLink.Create( nil);
   FDriver.VendorLib := 'libmysql.dll';
   FCursor := TFDGUIxWaitCursor.Create( nil);
end;

destructor TMySQLDriverConnection.Destroy;
begin
   FreeAndNil( FDriver);
   FreeAndNil( FCursor);
   inherited;
end;

class function TMySQLDriverConnection.New: IFiredacDriverConnection;
begin
   Result := Self.Create;
end;
{$ENDIF}

{ TSQLiteDriverConnection }

constructor TSQLiteDriverConnection.Create;
begin
   FDriver := TFDPhysSQLiteDriverLink.Create( nil);
   FCursor := TFDGUIxWaitCursor.Create( nil);
end;

destructor TSQLiteDriverConnection.Destroy;
begin
   FreeAndNil( FDriver);
   FreeAndNil( FCursor);
   inherited;
end;

class function TSQLiteDriverConnection.New: IFiredacDriverConnection;
begin
   Result := Self.Create;
end;

end.
