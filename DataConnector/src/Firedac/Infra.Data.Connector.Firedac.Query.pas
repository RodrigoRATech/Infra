unit Infra.Data.Connector.Firedac.Query;

interface

uses Infra.Data.Connector.Interfaces,
     Infra.Data.Connector.Firedac.Connection,

     System.Classes,

     Data.DB,
     FireDAC.Comp.Client,
     FireDAC.Stan.Param,
     FireDAC.DatS,
     FireDAC.DApt.Intf,
     FireDAC.DApt,
     FireDAC.Comp.DataSet;

Type
   TDataQueryFiredac = class(TInterfacedObject, IDataQuery)
   private
      FConnection:IDataConnection;

      FQuery:TFDQuery;
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
     Infra.Data.Connector.Firedac.Query.Detail;

{ TSimpleQuery<T> }

function TDataQueryFiredac.Close: IDataQuery;
begin
   Result := Self;
   FQuery.Close;
   FDetails.Close;
end;

function TDataQueryFiredac.Connection: IDataConnection;
begin
   Result := FConnection;
end;

constructor TDataQueryFiredac.Create( aConnection:IDataConnection);
begin
   FConnection := aConnection;

   if Assigned( FConnection) then
   begin
      if not FConnection.Connection.Connected then
         FConnection.Connect;

      FQuery := TFDQuery.Create(nil);
      FQuery.Connection := TFDConnection( FConnection.Connection);

      FDetails := TDataQueryDetailLstFiredac.New( Self);
   end;
end;

function TDataQueryFiredac.DataSet: TDataSet;
begin
   Result := TDataSet( FQuery);
end;

destructor TDataQueryFiredac.Destroy;
begin
   FreeAndNil(FQuery);

  if Assigned(FParams) then
     FreeAndNil(FParams);

  inherited;
end;

function TDataQueryFiredac.Details: IDataQueryDetailLst;
begin
   Result := FDetails;
end;

function TDataQueryFiredac.ExecSQL: IDataQuery;
begin
   Result := Self;

   if FQuery.SQL.Text <> EmptyStr then
   begin
      if Assigned(FParams) then
         FQuery.Params.Assign(FParams);

      //FQuery.ResourceOptions.CmdExecMode := amAsync
      //FQuery.Command.State = csExecuting

      FQuery.Prepare;
      FQuery.ExecSQL;

      if Assigned(FParams) then
        FreeAndNil(FParams);
   end;
end;

class function TDataQueryFiredac.New( aConnection:IDataConnection): IDataQuery;
begin
   Result := Self.Create( aConnection);
end;

function TDataQueryFiredac.Open: IDataQuery;
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

function TDataQueryFiredac.Open(aSQL: String): IDataQuery;
begin
   Result := Self;
   Close;
   FQuery.Open(aSQL);
   FDetails.Open;
end;

function TDataQueryFiredac.Params: TParams;
begin
   if not Assigned(FParams) then
   begin
      FParams := TParams.Create(nil);
      FParams.Assign(FQuery.Params);
   end;

   Result := FParams;
end;

function TDataQueryFiredac.SQL: TStrings;
begin
   Result := FQuery.SQL;
end;

end.
