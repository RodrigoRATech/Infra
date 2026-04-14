unit Infra.Data.Connector.Interfaces;

interface

// Documentacao firedac
// http://docs.embarcadero.com/products/rad_studio/firedac/frames.html?frmname=topic&frmfile=Executing_Command.html
uses Data.DB, 
     System.Classes,

     Infra.Data.Core.Types,
     Infra.Data.Connector.Types;

type
  IDataQuery = interface;
  IDataQueryDetailLst = interface;
  IDataConnection = interface
    ['{ACCB041A-9A2E-4E57-B36C-2B2AA063B487}']
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

  IDataConnectionManager = interface
    ['{1250CC43-3D57-46A6-9986-D246560EC242}']
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
  end;

  IDataQueryDetail = interface
     ['{3F133D61-76D8-4FFA-A8F6-51D0B8434142}']
     function Name( aValue:String):IDataQueryDetail;
     function MasterFields( aValue:String):IDataQueryDetail;
     function DetailFields( aValue:String):IDataQueryDetail;
     function IndexFields( aValue:String):IDataQueryDetail;

     function Data:IDataQuery;
     function &end:IDataQueryDetailLst;
  end;

  IDataQueryDetailLst = interface
     ['{B67C41ED-8D8D-4B3F-96B6-FCEBD6963E9C}']
     function NewDetail:IDataQueryDetail;
     function Add( aValue:IDataQueryDetail):IDataQueryDetailLst;
     function Delete( aIndex:Integer):IDataQueryDetailLst;
     function Details( aIndex:Integer):IDataQueryDetail;
     function Clear:IDataQueryDetailLst;
     function Count:Integer;
     function Open:IDataQueryDetailLst;
     function Close:IDataQueryDetailLst;

     function Parent:IDataQuery;
  end;

  IDataQuery = interface
    ['{CD366C36-C03F-4692-B94B-33D53F78C876}']
    function Connection:IDataConnection;
    function SQL:TStrings;
    function Params:TParams;
    function ExecSQL:IDataQuery;
    function DataSet:TDataSet;
    function Open( aSQL:String):IDataQuery; overload;
    function Open:IDataQuery; overload;
    function Close:IDataQuery;
    function Details:IDataQueryDetailLst;
  end;

  IDataTable = interface
    ['{46326FE6-886B-4382-BF8D-B9760A019256}']
    function Table:TDataSet;
  end;

  IDataFactory = interface
    ['{CC75CE6F-6ACF-477C-A54F-9C363B9B9C59}']
    function Connection:IDataConnection;
    function Query( aConnection:IDataConnection): IDataQuery;
  end;

implementation

end.
