unit Infra.Data.Connector.Zeus.Query.Detail;

interface


uses Infra.Data.Connector.Interfaces,
     Infra.Data.Connector.Zeus.Connection,

     System.SysUtils,
     System.Classes,
     System.Generics.Collections,

     Data.DB,

     ZConnection,
     ZDataset;

type
   TDataQueryDetailZeus = class( TInterfacedObject, IDataQueryDetail)
   private
      [weak]
      FOwner:IDataQueryDetailLst;
      FData:IDataQuery;
      FDataSource:TDataSource;

      FName:String;
      FMasterFields:String;
      FDetailFields:String;
      FIndexFields:String;

   public
      constructor Create( aOwner:IDataQueryDetailLst);
      destructor Destroy;override;
      class function New( aOwner:IDataQueryDetailLst):IDataQueryDetail;

      function Name( aValue:String):IDataQueryDetail;
      function MasterFields( aValue:String):IDataQueryDetail;
      function DetailFields( aValue:String):IDataQueryDetail;
      function IndexFields( aValue:String):IDataQueryDetail;

      function Data:IDataQuery;
      function &end:IDataQueryDetailLst;

   end;

   TDataQueryDetailLstZeus = class( TInterfacedObject, IDataQueryDetailLst)
   private
      [weak]
      FOwner:IDataQuery;
      FList:TList<IDataQueryDetail>;

   public
      constructor Create( aOwner:IDataQuery);
      destructor Destroy;override;
      class function New( aOwner:IDataQuery):IDataQueryDetailLst;

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

implementation

uses Infra.Data.Connector.Zeus.Query;

{ TDataQueryDetailZeus }

function TDataQueryDetailZeus.&end: IDataQueryDetailLst;
begin
   Result := FOwner;
end;

constructor TDataQueryDetailZeus.Create(aOwner: IDataQueryDetailLst);
begin
   FOwner      := aOwner;
   FData       := TDataQueryZeus.New( aOwner.Parent.Connection);
   FDataSource := TDataSource.Create( nil);
   FDataSource.DataSet := TzQuery( aOwner.Parent.DataSet);

   TzQuery( FData.DataSet).MasterSource := FDataSource;
end;

function TDataQueryDetailZeus.Data: IDataQuery;
begin
   Result := FData;
end;

destructor TDataQueryDetailZeus.Destroy;
begin
   FreeAndNil( FDataSource);
   inherited;
end;

function TDataQueryDetailZeus.DetailFields(aValue: String): IDataQueryDetail;
begin
   Result := Self;
   FDetailFields := aValue;
   TzQuery( FData.DataSet).LinkedFields := aValue;
end;

function TDataQueryDetailZeus.IndexFields(aValue: String): IDataQueryDetail;
begin
   Result := Self;
   FIndexFields := aValue;
   TzQuery( FData.DataSet).IndexFieldNames := aValue;
end;

function TDataQueryDetailZeus.MasterFields(aValue: String): IDataQueryDetail;
begin
   Result := Self;
   FMasterFields := aValue;
   TzQuery( FData.DataSet).MasterFields := aValue;
end;

function TDataQueryDetailZeus.Name(aValue: String): IDataQueryDetail;
begin
   Result := Self;
   FName := aValue;
   FData.DataSet.Name := FName;
end;

class function TDataQueryDetailZeus.New(
  aOwner: IDataQueryDetailLst): IDataQueryDetail;
begin
   Result := Self.Create( aOwner);
end;

{ TDataQueryDetailLstZeus }

function TDataQueryDetailLstZeus.Add(aValue: IDataQueryDetail): IDataQueryDetailLst;
begin
   Result := Self;
   FList.Add( aValue);
end;

function TDataQueryDetailLstZeus.Clear: IDataQueryDetailLst;
begin
   Result := Self;

   FList.Clear;
   FList.TrimExcess;
end;

function TDataQueryDetailLstZeus.Close: IDataQueryDetailLst;
begin
   Result := Self;

   for var i:integer := 0 to Pred( FList.Count) do
      FList.Items[ i].Data.Close;
end;

function TDataQueryDetailLstZeus.Count: Integer;
begin
   Result := FList.Count;
end;

constructor TDataQueryDetailLstZeus.Create(aOwner: IDataQuery);
begin
   FOwner := aOwner;
   FList  := TList<IDataQueryDetail>.Create;
end;

function TDataQueryDetailLstZeus.Delete(aIndex: Integer): IDataQueryDetailLst;
begin
   Result := Self;
   FList.Delete( aIndex);
end;

destructor TDataQueryDetailLstZeus.Destroy;
begin
   FreeAndNil( FList);
   inherited;
end;

function TDataQueryDetailLstZeus.Details(aIndex: Integer): IDataQueryDetail;
begin
   Result := FList.Items[ aIndex];
end;

class function TDataQueryDetailLstZeus.New(aOwner: IDataQuery): IDataQueryDetailLst;
begin
   Result := Self.Create( aOwner);
end;

function TDataQueryDetailLstZeus.NewDetail: IDataQueryDetail;
Var LData:IDataQueryDetail;
begin
   LData := TDataQueryDetailZeus.New( Self);
   FList.Add( LData);
   Result := LData;
end;

function TDataQueryDetailLstZeus.Open: IDataQueryDetailLst;
Var LQuery:TzQuery;
    LMaster:TzQuery;
begin
   Result := Self;

   for var i:integer := 0 to Pred( FList.Count) do
   begin
      LMaster := TZQuery( FOwner.DataSet);
      LQuery  := TZQuery( FList.Items[ i].Data.DataSet);

      for var j:integer := 0 to Pred( LQuery.Params.Count) do
         LQuery.params.Items[ j].Value := LMaster.FieldByName( LQuery.params.Items[ j].Name).Value;

      LQuery.Open;
   end;
end;

function TDataQueryDetailLstZeus.Parent: IDataQuery;
begin
   Result := FOwner;
end;

end.
