unit RabbitMQ.Management.Client;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.NetEncoding,
  System.Generics.Collections,
  RabbitMQ.Management.Types;

type
  /// <summary>
  /// Client HTTP para a RabbitMQ Management API.
  /// Responsabilidade única: fazer requisições HTTP e retornar JSON.
  /// Não contém lógica de negócio.
  /// </summary>
  TRabbitMQApiClient = class
  strict private
    FConfig: TRabbitManagementConfig;
    FHttpClient: THTTPClient;

    function CreateAuthHeader: string;
    function ExecuteGet(const AURL: string): IHTTPResponse;
    function ExecuteDelete(const AURL: string): IHTTPResponse;
    procedure ValidateResponse(const AResponse: IHTTPResponse;
      const AContext: string);
  public
    constructor Create(const AConfig: TRabbitManagementConfig);
    destructor Destroy; override;

    /// <summary>Testa conectividade com a Management API.</summary>
    function TestConnection: Boolean;

    /// <summary>Retorna o JSON bruto de todas as filas do vhost.</summary>
    function FetchQueuesJSON: TJSONArray;

    /// <summary>Retorna o JSON bruto de uma fila específica.</summary>
    function FetchQueueJSON(const AQueueName: string): TJSONObject;

    /// <summary>Faz purge (limpa mensagens) de uma fila via DELETE /contents.</summary>
    function PurgeQueue(const AQueueName: string): Boolean;

    /// <summary>Deleta uma fila inteira via DELETE.</summary>
    function DeleteQueue(const AQueueName: string): Boolean;

    property Config: TRabbitManagementConfig read FConfig;
  end;

implementation

{ TRabbitMQApiClient }

constructor TRabbitMQApiClient.Create(
  const AConfig: TRabbitManagementConfig);
begin
  inherited Create;
  FConfig := AConfig;
  FHttpClient := THTTPClient.Create;
  FHttpClient.ConnectionTimeout := AConfig.TimeoutMs;
  FHttpClient.ResponseTimeout := AConfig.TimeoutMs;
  FHttpClient.ContentType := 'application/json';
  FHttpClient.CustomHeaders['Authorization'] := CreateAuthHeader;
end;

destructor TRabbitMQApiClient.Destroy;
begin
  FHttpClient.Free;
  inherited;
end;

function TRabbitMQApiClient.CreateAuthHeader: string;
var
  LCredentials: string;
begin
  LCredentials := FConfig.User + ':' + FConfig.Password;
  Result := 'Basic ' + TNetEncoding.Base64.Encode(LCredentials);
end;

function TRabbitMQApiClient.ExecuteGet(const AURL: string): IHTTPResponse;
begin
  Result := FHttpClient.Get(AURL);
end;

function TRabbitMQApiClient.ExecuteDelete(const AURL: string): IHTTPResponse;
begin
  Result := FHttpClient.Delete(AURL);
end;

procedure TRabbitMQApiClient.ValidateResponse(
  const AResponse: IHTTPResponse; const AContext: string);
begin
  if AResponse.StatusCode >= 400 then
    raise Exception.CreateFmt(
      'RabbitMQ API error [%s]: HTTP %d - %s',
      [AContext, AResponse.StatusCode, AResponse.ContentAsString(TEncoding.UTF8)]);
end;

function TRabbitMQApiClient.TestConnection: Boolean;
var
  LResponse: IHTTPResponse;
begin
  Result := False;
  try
    LResponse := ExecuteGet(FConfig.BaseURL + '/api/overview');
    Result := LResponse.StatusCode = 200;
  except
    Result := False;
  end;
end;

function TRabbitMQApiClient.FetchQueuesJSON: TJSONArray;
var
  LResponse: IHTTPResponse;
  LValue: TJSONValue;
begin
  LResponse := ExecuteGet(FConfig.ApiQueuesURL);
  ValidateResponse(LResponse, 'FetchQueues');

  LValue := TJSONObject.ParseJSONValue(
    LResponse.ContentAsString(TEncoding.UTF8));

  if not (LValue is TJSONArray) then
  begin
    LValue.Free;
    raise Exception.Create('RabbitMQ API: resposta não é um JSON array');
  end;

  Result := TJSONArray(LValue);
end;

function TRabbitMQApiClient.FetchQueueJSON(
  const AQueueName: string): TJSONObject;
var
  LResponse: IHTTPResponse;
  LValue: TJSONValue;
begin
  LResponse := ExecuteGet(FConfig.ApiQueueURL(AQueueName));
  ValidateResponse(LResponse, 'FetchQueue(' + AQueueName + ')');

  LValue := TJSONObject.ParseJSONValue(
    LResponse.ContentAsString(TEncoding.UTF8));

  if not (LValue is TJSONObject) then
  begin
    LValue.Free;
    raise Exception.CreateFmt(
      'RabbitMQ API: resposta para fila "%s" não é JSON object', [AQueueName]);
  end;

  Result := TJSONObject(LValue);
end;

function TRabbitMQApiClient.PurgeQueue(const AQueueName: string): Boolean;
var
  LResponse: IHTTPResponse;
begin
  LResponse := ExecuteDelete(FConfig.ApiQueuePurgeURL(AQueueName));
  Result := LResponse.StatusCode = 204;
end;

function TRabbitMQApiClient.DeleteQueue(const AQueueName: string): Boolean;
var
  LResponse: IHTTPResponse;
begin
  LResponse := ExecuteDelete(FConfig.ApiQueueURL(AQueueName));
  Result := LResponse.StatusCode = 204;
end;

end.
