unit Infra.Data.Connector.Firedac.Query.Detail;

interface

uses Infra.Data.Connector.Interfaces,
     Infra.Data.Connector.Firedac.Connection,

     System.SysUtils,
     System.Classes,
     System.Generics.Collections,

     Data.DB,
     FireDAC.Comp.Client,
     FireDAC.Stan.Param,
     FireDAC.DatS,
     FireDAC.DApt.Intf,
     FireDAC.DApt,
     FireDAC.Comp.DataSet;

type
   TDataQueryDetailFiredac = class( TInterfacedObject, IDataQueryDetail)
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

   TDataQueryDetailLstFiredac = class( TInterfacedObject, IDataQueryDetailLst)
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

uses Infra.Data.Connector.Firedac.Query;

{ TDataQueryDetailFiredac }

function TDataQueryDetailFiredac.&end: IDataQueryDetailLst;
begin
   Result := FOwner;
end;

constructor TDataQueryDetailFiredac.Create(aOwner: IDataQueryDetailLst);
begin
   FOwner      := aOwner;
   FData       := TDataQueryFiredac.New( aOwner.Parent.Connection);
   FDataSource := TDataSource.Create( nil);
   FDataSource.DataSet := aOwner.Parent.DataSet;

   TFDQuery( FData.DataSet).MasterSource := FDataSource;
end;

function TDataQueryDetailFiredac.Data: IDataQuery;
begin
   Result := FData;
end;

destructor TDataQueryDetailFiredac.Destroy;
begin
   FreeAndNil( FDataSource);
   inherited;
end;

function TDataQueryDetailFiredac.DetailFields(aValue: String): IDataQueryDetail;
begin
   Result := Self;
   FDetailFields := aValue;
   TFDQuery( FData.DataSet).DetailFields := aValue;
end;

function TDataQueryDetailFiredac.IndexFields(aValue: String): IDataQueryDetail;
begin
   Result := Self;
   FIndexFields := aValue;
   TFDQuery( FData.DataSet).IndexFieldNames := aValue;
end;

function TDataQueryDetailFiredac.MasterFields(aValue: String): IDataQueryDetail;
begin
   Result := Self;
   FMasterFields := aValue;
   TFDQuery( FData.DataSet).MasterFields := aValue;
end;

function TDataQueryDetailFiredac.Name(aValue: String): IDataQueryDetail;
begin
   Result := Self;
   FName := aValue;
   FData.DataSet.Name := FName;
end;

class function TDataQueryDetailFiredac.New(
  aOwner: IDataQueryDetailLst): IDataQueryDetail;
begin
   Result := Self.Create( aOwner);
end;

{ TDataQueryDetailLstFiredac }

function TDataQueryDetailLstFiredac.Add(aValue: IDataQueryDetail): IDataQueryDetailLst;
begin
   Result := Self;
   FList.Add( aValue);
end;

function TDataQueryDetailLstFiredac.Clear: IDataQueryDetailLst;
begin
   Result := Self;

   FList.Clear;
   FList.TrimExcess;
end;

function TDataQueryDetailLstFiredac.Close: IDataQueryDetailLst;
begin
   Result := Self;

   for var i:integer := 0 to Pred( FList.Count) do
      FList.Items[ i].Data.Close;
end;

function TDataQueryDetailLstFiredac.Count: Integer;
begin
   Result := FList.Count;
end;

constructor TDataQueryDetailLstFiredac.Create(aOwner: IDataQuery);
begin
   FOwner := aOwner;
   FList  := TList<IDataQueryDetail>.Create;
end;

function TDataQueryDetailLstFiredac.Delete(aIndex: Integer): IDataQueryDetailLst;
begin
   Result := Self;
   FList.Delete( aIndex);
end;

destructor TDataQueryDetailLstFiredac.Destroy;
begin
   FreeAndNil( FList);
   inherited;
end;

function TDataQueryDetailLstFiredac.Details(aIndex: Integer): IDataQueryDetail;
begin
   Result := FList.Items[ aIndex];
end;

class function TDataQueryDetailLstFiredac.New(aOwner: IDataQuery): IDataQueryDetailLst;
begin
   Result := Self.Create( aOwner);
end;

function TDataQueryDetailLstFiredac.NewDetail: IDataQueryDetail;
Var LData:IDataQueryDetail;
begin
   LData := TDataQueryDetailFiredac.New( Self);
   FList.Add( LData);
   Result := LData;
end;

function TDataQueryDetailLstFiredac.Open: IDataQueryDetailLst;
Var LQuery:TFDQuery;
    LMaster:TFDQuery;
begin
   Result := Self;

   for var i:integer := 0 to Pred( FList.Count) do
   begin
      LMaster := TFDQuery( FOwner.DataSet);
      LQuery  := TFDQuery( FList.Items[ i].Data.DataSet);

      for var j:integer := 0 to Pred( LQuery.Params.Count) do
         LQuery.params.Items[ j].Value := LMaster.FieldByName( LQuery.params.Items[ j].Name).Value;

      LQuery.Open;
   end;
end;

function TDataQueryDetailLstFiredac.Parent: IDataQuery;
begin
   Result := FOwner;
end;

end.
