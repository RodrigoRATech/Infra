unit Infra.Data.Connector.Zeus.Query;

interface

uses Infra.Data.Connector.Interfaces,
     Infra.Data.Connector.Zeus.Connection,

     System.Classes,

     Data.DB,

     ZConnection,
     ZDataset;

Type
   TDataQueryZeus = class(TInterfacedObject, IDataQuery)
   private
      FConnection:IDataConnection;

      FQuery:TzQuery;
      FParams:TParams;
      FDetails:IDataQueryDetailLst;

   public
      constructor Create( aConnection:IDataConnection);
      destructor Destroy; override;
      class function New( aConnection:IDataConnection):IDataQuery;

      function Connection:IDataConnection;
      function SQL:TStrings;
      function Params:TParams;
      function ExecSQL:IDataQuery;
      function DataSet:TDataSet;
      function Open( aSQL:String):IDataQuery;overload;
      function Open:IDataQuery; overload;
      function Close:IDataQuery;
      function Details:IDataQueryDetailLst;

   end;

implementation

uses System.SysUtils,
     Infra.Data.Connector.Zeus.Query.Detail;

{ TSimpleQuery<T> }

function TDataQueryZeus.Close: IDataQuery;
begin
   Result := Self;
   FDetails.Close;
   FQuery.Close;
end;

function TDataQueryZeus.Connection: IDataConnection;
begin
   Result := FConnection;
end;

constructor TDataQueryZeus.Create( aConnection:IDataConnection);
begin
   FConnection := aConnection;

   if Assigned( FConnection) then
   begin
      if not TzConnection( FConnection.Component).Connected then
         FConnection.Connect;

      FQuery := TzQuery.Create(nil);
      FQuery.Connection := TzConnection( FConnection.Component);
      FDetails := TDataQueryDetailLstZeus.New( Self);
   end;
end;

function TDataQueryZeus.DataSet: TDataSet;
begin
   Result := TDataSet( FQuery);
end;

destructor TDataQueryZeus.Destroy;
begin
   FreeAndNil(FQuery);

  if Assigned(FParams) then
     FreeAndNil(FParams);

  inherited;
end;

function TDataQueryZeus.Details: IDataQueryDetailLst;
begin
   Result := FDetails;
end;

function TDataQueryZeus.ExecSQL: IDataQuery;
begin
   Result := Self;

   if FQuery.SQL.Text <> EmptyStr then
   begin
      if Assigned(FParams) then
         FQuery.Params.Assign(FParams);

      FQuery.Prepare;
      FQuery.ExecSQL;

      if Assigned(FParams) then
        FreeAndNil(FParams);
   end;
end;

class function TDataQueryZeus.New( aConnection:IDataConnection): IDataQuery;
begin
   Result := Self.Create( aConnection);
end;

function TDataQueryZeus.Open: IDataQuery;
begin
   Result := Self;
   Close;

   if Assigned(FParams) then
      FQuery.Params.Assign(FParams);

   FQuery.Prepare;
   FQuery.Open;

   FDetails.Open;

   if Assigned(FParams) then
      FreeAndNil(FParams);
end;

function TDataQueryZeus.Open(aSQL: String): IDataQuery;
begin
   Result := Self;
   Close;
   FQuery.SQL.Text := aSQL;
   FQuery.Open;
   FDetails.Open;
end;

function TDataQueryZeus.Params: TParams;
begin
   if not Assigned(FParams) then
   begin
      FParams := TParams.Create(nil);
      FParams.Assign(FQuery.Params);
   end;

   Result := FParams;
end;

function TDataQueryZeus.SQL: TStrings;
begin
   Result := FQuery.SQL;
end;

end.
