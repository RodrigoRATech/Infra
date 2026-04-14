unit Infra.Types;

interface

uses System.SysUtils, System.Variants,
     System.JSON, System.TypInfo,
     System.Generics.Collections;

const
   TIMEOUT_REQUEST = 5000;

type
   TUUIDStr = type string;
   TUTCDateTime = type TDateTime;
   TDataType = ( dtDB, dtRest);
   TDataEngine = ( deFiredac, deZeus);
   TDataManager = ( dmFirebird, dmInterbase, dmMySQL, dmSQLite);
   TUserAuthType = ( uatNone, uatBasic, uatBearer, uatOAuth, uatOAuth2, uatAWS);
   TFeatureKind = ( fkCRUD, fkReport, fkAction, fkViewer, fkList, fkCustom);
   TFeaturePermissions = ( fpInsert, fpUpdate, fpDelete, fpExecute, fpPrint, fpView, ftAcess);
   TFeaturePermissionsSet = set of TFeaturePermissions;
   TUserProfileKind = ( upkAdministrator, upkkOperator);
   TMessageType = ( mtDefault, mtError, mtWarning, mtInformation);
   TMappingSource = ( msParams, msQuerys, msBody, msEntity);
   TMappingSourceSet = set of TMappingSource;
   TEnvironmentType = (envDevelopment, envStaging, envProduction);

   TMaskKind = ( mkSemMascara, mkPersonalizado, mkCNPJ, mkCPF, mkInscricaoEstadual,
                 mkCNPJorCPF, mkTelefoneFixo, mkCelular, mkValor,
                 mkMoeda, mkCEP, mkData, mkHora, mkHoraMin, mkDataHora,
                 mkPeso, mkTelefone);

   TIntervalType = ( itDayly, itWeekly, itMonthly, itHalfYearly, itYearly);
   TCharPosition = ( cpLeft, cpRight);
   TVariantArray<T> = array of T;
   TOnProcess = TProc;
   TOnMessage = procedure ( aMessage:String) of object;
   TEventListener = reference to procedure(const AText: string);
   TEventSubscribeListener = reference to procedure ( const aID:String; const aEvent:String);
   TEventListenerError = reference to procedure(const AException: Exception; var AForceDisconnect: Boolean);
   TSystemActions = ( saView, saBrowser, saFind, saSearch, saInsert, saUpdate, saDelete, saOption, saInserOrUpdate, saDeleteOrUpdate);
   TSecurityResource = ( srAll, srSearch, srFind, srInsert, srUpdate,
                         srCustomUpdate, srDelete,
                         srFirst, srNext, srLast, srPrior, srSync);
   TSecurityResourceSet = set of TSecurityResource;
   TRequestType = ( rtExecute, rtInsert, rtUpdate, rtDelete, rtFind, rtSearch, rtPrint);
   TOnExecuteRequest = procedure( aRequest:TRequestType; aValue:String) of object;

   TNotifyChannelType = ( ncLocal, ncSystem, ncPush, ncMail, ncSMS, ncWhatsApp, ncTelegram);
   TNotifyContextType = ( ctPublic, ctPrivate, ctRestricted, ctProfile);
   TNotifyMessageType = ( nmCredentials, nmUserInfo, nmMessage);
   TNotifyActionType  = ( naNone, naConnection, naDisconnection, naRegister, naUnregister,
                          naView, naOpen, naClose, naRefresh, naLock, naUnlock,
                          naNotify, naRequest, naResponse, naWarning, naInformation, naError);


   TSetNotifyChannelType = set of TNotifyChannelType;
   TSetNotifyContextType = set of TNotifyContextType;
   TSetNotifyMessageType = set of TNotifyMessageType;
   TSetNotifyActionType  = set of TNotifyActionType;

   TCompareOperator = ( coEqual, coBiggerThen, coBigger, coLessThen,
                        coLess, coDiferent, coBetween, coIn, coNotIn);
   TLogicalOperator = ( loNone, loAnd, loOr, loXor);

   TFindValuesInfo = record
      Value:Variant;
      Size:Integer;
      CompareOperator:TCompareOperator;
      LogicalOperator:TLogicalOperator;

      function IsArray:Boolean;
   end;

   TPagination = record
      Page: Integer;
      PageSize: Integer;
      TotalItems: Int64;
      TotalPages: Integer;

      constructor Create(APage, APageSize: Integer);
      procedure Calculate(ATotalItems: Int64);
      function Offset: Integer;
   end;

   {***************************************************************************************}
   IEvTecladoNumerico = interface
      ['{F96E069D-1AFB-4F3C-84C2-16E77D4866F6}']
      procedure SetChamador( aValue:String);
      procedure SetCampo( aValue:String);
      procedure SetValor( aValue:Double);
      procedure SetDados( aValue:String);
      procedure SetTecla( aValue:Integer);

      function GetChamador:String;
      function GetCampo:String;
      function GetValor:Double;
      function GetDados:String;
      function GetTecla:Integer;

      property Chamador:string read GetChamador write SetChamador;
      property Campo:String    read GetCampo    write SetCampo;
      property Valor:Double    read GetValor    write SetValor;
      property Dados:String    read GetDados    write SetDados;
      property Tecla:Integer   read GetTecla    write SetTecla;
   end;

   TEvTecladoNumerico = class( TInterfacedObject, IEvTecladoNumerico)
   private
      FChamador:String;
      FCampo:String;
      FValor:Double;
      FDados:String;
      FTecla:Integer;

      procedure SetChamador( aValue:String);
      procedure SetCampo( aValue:String);
      procedure SetValor( aValue:Double);
      procedure SetDados( aValue:String);
      procedure SetTecla( aValue:Integer);

      function GetChamador:String;
      function GetCampo:String;
      function GetValor:Double;
      function GetDados:String;
      function GetTecla:Integer;

   public
      constructor Create;
      destructor Destroy;override;
      class function New:IEvTecladoNumerico;

      property Chamador:string read GetChamador write SetChamador;
      property Campo:String    read GetCampo    write SetCampo;
      property Valor:Double    read GetValor    write SetValor;
      property Dados:String    read GetDados    write SetDados;
      property Tecla:Integer   read GetTecla    write SetTecla;
   end;

   {***************************************************************************************}
   IInfraEntity<T> = interface
      function Entity:T;
   end;
   {***************************************************************************************}

   /// <summary>
   /// Status de operações assíncronas
   /// </summary>
   TRequestStatus = ( rsIdle, rsLoading, rsSuccess, rsError, rsCancelled);

   /// <summary>
   /// Resultado genérico para operações que podem falhar
   /// Implementa o padrão Result/Either para tratamento funcional de erros
   /// </summary>
   TResult<T> = record
   private
     FValue: T;
     FError: string;
     FIsSuccess: Boolean;
     FStatusCode: Integer;
   public
     class function Success(const AValue: T; AStatusCode: Integer = 200): TResult<T>; static;
     class function Failure(const AError: string; AStatusCode: Integer = 0): TResult<T>; static;

     function IsSuccess: Boolean;
     function IsFailure: Boolean;
     function Value: T;
     function Error: string;
     function StatusCode: Integer;

     /// <summary>
     /// Executa ação se sucesso, retorna self para encadeamento
     /// </summary>
     function OnSuccess(const AProc: TProc<T>): TResult<T>;

     /// <summary>
     /// Executa ação se falha, retorna self para encadeamento
     /// </summary>
     function OnFailure(const AProc: TProc<string>): TResult<T>;
   end;

   /// <summary>
   /// Parâmetros de paginação para lazy load
   /// </summary>
   TPaginationParams = record
     Page: Integer;
     PageSize: Integer;
     TotalPages: Integer;
     TotalItems: Integer;
     HasMore: Boolean;

     class function Create(APage, APageSize: Integer): TPaginationParams; static;
     function NextPage: TPaginationParams;
     procedure UpdateFromResponse(ATotalItems: Integer);
   end;

   /// <summary>
   /// Resposta paginada genérica
   /// </summary>
   TPagedResponse<T> = record
     Items: TArray<T>;
     Pagination: TPaginationParams;

     class function Create(const AItems: TArray<T>; const APagination: TPaginationParams): TPagedResponse<T>; static;
   end;

   /// <summary>
   /// Callback genérico para operações assíncronas
   /// </summary>
   TAsyncCallback<T> = reference to procedure(const AResult: TResult<T>);

   /// <summary>
   /// Callback para progresso de operações
   /// </summary>
   TProgressCallback = reference to procedure(AProgress: Integer; const AMessage: string);

   /// <summary>
   /// Token de cancelamento para operações assíncronas
   /// </summary>
   ICancellationToken = interface
     ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
     function IsCancelled: Boolean;
     procedure Cancel;
     procedure Reset;
   end;

   TCancellationToken = class(TInterfacedObject, ICancellationToken)
   private
     FCancelled: Boolean;
   public
     constructor Create;
     function IsCancelled: Boolean;
     procedure Cancel;
     procedure Reset;
   end;

implementation

uses
  System.Math;

{ TFindValuesInfo }

function TFindValuesInfo.IsArray: Boolean;
Var LValue:TVarType;
begin
   LValue := System.Variants.VarType( Value);
   Result := LValue >= varArray;
end;

{ TEvTecladoNumerico }

constructor TEvTecladoNumerico.Create;
begin

end;

destructor TEvTecladoNumerico.Destroy;
begin

end;

function TEvTecladoNumerico.GetCampo: String;
begin
   Result := FCampo;
end;

function TEvTecladoNumerico.GetChamador: String;
begin
   Result := FChamador;
end;

function TEvTecladoNumerico.GetDados: String;
begin
   Result := FDados;
end;

function TEvTecladoNumerico.GetTecla: Integer;
begin
   Result := FTecla;
end;

function TEvTecladoNumerico.GetValor: Double;
begin
   Result := FValor;
end;

class function TEvTecladoNumerico.New: IEvTecladoNumerico;
begin
   Result := Self.Create;
end;

procedure TEvTecladoNumerico.SetCampo(aValue: String);
begin
   FCampo := aValue;
end;

procedure TEvTecladoNumerico.SetChamador(aValue: String);
begin
   FChamador := aValue;
end;

procedure TEvTecladoNumerico.SetDados(aValue: String);
begin
   FDados := aValue;
end;

procedure TEvTecladoNumerico.SetTecla(aValue: Integer);
begin
   FTecla := aValue;
end;

procedure TEvTecladoNumerico.SetValor(aValue: Double);
begin
   FValor := aValue;
end;

{ TPagination }

procedure TPagination.Calculate(ATotalItems: Int64);
begin
   TotalItems := ATotalItems;

   if PageSize > 0 then
      TotalPages := Ceil(TotalItems / PageSize)
   else TotalPages := 0;
end;

constructor TPagination.Create(APage, APageSize: Integer);
begin
   if APage < 1 then APage := 1;
   if APageSize < 1 then APageSize := 10;
   if APageSize > 100 then APageSize := 100;

   Page := APage;
   PageSize := APageSize;
   TotalItems := 0;
   TotalPages := 0;
end;

function TPagination.Offset: Integer;
begin
   Result := (Page - 1) * PageSize;
end;

{ TResult<T> }

class function TResult<T>.Success(const AValue: T; AStatusCode: Integer): TResult<T>;
begin
  Result.FValue := AValue;
  Result.FError := '';
  Result.FIsSuccess := True;
  Result.FStatusCode := AStatusCode;
end;

class function TResult<T>.Failure(const AError: string; AStatusCode: Integer): TResult<T>;
begin
  Result.FValue := Default(T);
  Result.FError := AError;
  Result.FIsSuccess := False;
  Result.FStatusCode := AStatusCode;
end;

function TResult<T>.IsSuccess: Boolean;
begin
  Result := FIsSuccess;
end;

function TResult<T>.IsFailure: Boolean;
begin
  Result := not FIsSuccess;
end;

function TResult<T>.Value: T;
begin
  Result := FValue;
end;

function TResult<T>.Error: string;
begin
  Result := FError;
end;

function TResult<T>.StatusCode: Integer;
begin
  Result := FStatusCode;
end;

function TResult<T>.OnSuccess(const AProc: TProc<T>): TResult<T>;
begin
  Result := Self;
  if FIsSuccess and Assigned(AProc) then
    AProc(FValue);
end;

function TResult<T>.OnFailure(const AProc: TProc<string>): TResult<T>;
begin
  Result := Self;
  if (not FIsSuccess) and Assigned(AProc) then
    AProc(FError);
end;

{ TPaginationParams }

class function TPaginationParams.Create(APage, APageSize: Integer): TPaginationParams;
begin
  Result.Page := APage;
  Result.PageSize := APageSize;
  Result.TotalPages := 0;
  Result.TotalItems := 0;
  Result.HasMore := True;
end;

function TPaginationParams.NextPage: TPaginationParams;
begin
  Result := Self;
  Inc(Result.Page);
end;

procedure TPaginationParams.UpdateFromResponse(ATotalItems: Integer);
begin
  TotalItems := ATotalItems;
  if PageSize > 0 then
    TotalPages := (ATotalItems + PageSize - 1) div PageSize
  else
    TotalPages := 0;
  HasMore := Page < TotalPages;
end;

{ TPagedResponse<T> }

class function TPagedResponse<T>.Create(const AItems: TArray<T>;
  const APagination: TPaginationParams): TPagedResponse<T>;
begin
  Result.Items := AItems;
  Result.Pagination := APagination;
end;

{ TCancellationToken }

constructor TCancellationToken.Create;
begin
  inherited Create;
  FCancelled := False;
end;

function TCancellationToken.IsCancelled: Boolean;
begin
  Result := FCancelled;
end;

procedure TCancellationToken.Cancel;
begin
  FCancelled := True;
end;

procedure TCancellationToken.Reset;
begin
  FCancelled := False;
end;

end.
