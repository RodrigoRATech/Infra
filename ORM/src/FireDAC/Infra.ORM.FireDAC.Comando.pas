unit Infra.ORM.FireDAC.Comando;

{
  Responsabilidade:
    Implementação de IOrmComando sobre TFDQuery do FireDAC.
    Gerencia SQL, parâmetros tipados, preparação e execução.
    Cada instância representa um único comando SQL.
}

interface

uses
  System.SysUtils,
  System.Rtti,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  FireDAC.Stan.Intf,
  Data.DB,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions;

type

  TComandoFireDAC = class(TInterfacedObject, IOrmComando)
  strict private
    FQuery: TFDQuery;

    // Mapeia TTipoColuna para TFDDataType
    function MapearTipoFDAC(ATipo: TTipoColuna): TFieldType;

    // Aplica valor tipado ao parâmetro FireDAC
    procedure AplicarValorParametro(
      AParam: TFDParam;
      const AValor: TValue;
      ATipo: TTipoColuna);

  public
    constructor Create(AConexao: TFDConnection);
    destructor Destroy; override;

    procedure DefinirSQL(const ASQL: string);
    function ObterSQL: string;

    procedure AdicionarParametro(
      const ANome: string;
      const AValor: TValue;
      ATipo: TTipoColuna = tcDesconhecido);

    procedure LimparParametros;

    function ExecutarSemRetorno: Integer;
    function ExecutarEscalar: TValue;
    function ExecutarConsulta: IOrmLeitorDados;

    procedure Preparar;
  end;

implementation

uses
  Infra.ORM.FireDAC.Leitor;

{ TComandoFireDAC }

constructor TComandoFireDAC.Create(AConexao: TFDConnection);
begin
  inherited Create;

  if not Assigned(AConexao) then
    raise EOrmComandoExcecao.Create('',
      'TFDConnection não pode ser nil no comando FireDAC.');

  FQuery            := TFDQuery.Create(nil);
  FQuery.Connection := AConexao;

  // Garante que o FireDAC não faz fetch automático de todos os registros
  FQuery.FetchOptions.Mode    := fmOnDemand;
  FQuery.FetchOptions.RowsetSize := 50;
  FQuery.ResourceOptions.SilentMode := True;
end;

destructor TComandoFireDAC.Destroy;
begin
  if FQuery.Active then
    FQuery.Close;
  FQuery.Free;
  inherited Destroy;
end;

procedure TComandoFireDAC.DefinirSQL(const ASQL: string);
begin
  if FQuery.Active then
    FQuery.Close;
  FQuery.SQL.Text := ASQL;
end;

function TComandoFireDAC.ObterSQL: string;
begin
  Result := FQuery.SQL.Text;
end;

procedure TComandoFireDAC.Preparar;
begin
  try
    FQuery.Prepare;
  except
    on E: Exception do
      raise EOrmComandoExcecao.Create(
        FQuery.SQL.Text,
        Format('Falha ao preparar comando FireDAC: %s', [E.Message]), E);
  end;
end;

procedure TComandoFireDAC.LimparParametros;
begin
  FQuery.Params.Clear;
end;

function TComandoFireDAC.MapearTipoFDAC(ATipo: TTipoColuna): TFieldType;
begin
  case ATipo of
    tcString:   Result := ftWideString;
    tcInteger:  Result := ftInteger;
    tcInt64:    Result := ftLargeint;
    tcFloat:    Result := ftFloat;
    tcDecimal:  Result := ftBCD;
    tcBoolean:  Result := ftBoolean;
    tcData:     Result := ftDate;
    tcDataHora: Result := ftDateTime;
    tcHora:     Result := ftTime;
    tcGuid:     Result := ftGuid;
    tcUuid:     Result := ftWideString;
    tcBlob:     Result := ftBlob;
    tcClob:     Result := ftMemo;
  else
    Result := ftUnknown;
  end;
end;

procedure TComandoFireDAC.AplicarValorParametro(
  AParam: TFDParam;
  const AValor: TValue;
  ATipo: TTipoColuna);
begin
  if AValor.IsEmpty then
  begin
    AParam.Clear;
    Exit;
  end;

  case ATipo of
    tcString, tcUuid, tcGuid:
      AParam.AsString := AValor.AsString;

    tcInteger:
      AParam.AsInteger := AValor.AsInteger;

    tcInt64:
      AParam.AsLargeInt := AValor.AsInt64;

    tcFloat:
      AParam.AsFloat := AValor.AsExtended;

    tcDecimal:
      AParam.AsBCD := AValor.AsExtended;

    tcBoolean:
      AParam.AsBoolean := AValor.AsBoolean;

    tcData, tcDataHora:
      AParam.AsDateTime := AValor.AsType<TDateTime>;

    tcHora:
      AParam.AsDateTime := AValor.AsType<TDateTime>;

    tcBlob, tcClob:
      AParam.AsString := AValor.AsString;
  else
    // tcDesconhecido — inferência automática pelo FireDAC
    begin
      case AValor.Kind of
        tkString, tkUString, tkWString:
          AParam.AsWideString := AValor.AsString;
        tkInteger:
          AParam.AsInteger := AValor.AsInteger;
        tkInt64:
          AParam.AsLargeInt := AValor.AsInt64;
        tkFloat:
          AParam.AsFloat := AValor.AsExtended;
        tkEnumeration:
          if AValor.TypeInfo = TypeInfo(Boolean) then
            AParam.AsBoolean := AValor.AsBoolean
          else
            AParam.AsInteger := AValor.AsOrdinal;
      else
        AParam.AsString := AValor.ToString;
      end;
    end;
  end;
end;

procedure TComandoFireDAC.AdicionarParametro(
  const ANome: string;
  const AValor: TValue;
  ATipo: TTipoColuna);
var
  LParam: TFDParam;
  LNomeLimpo: string;
begin
  // Remove o prefixo ':' se presente — FireDAC gerencia internamente
  LNomeLimpo := ANome;
  if LNomeLimpo.StartsWith(':') then
    LNomeLimpo := LNomeLimpo.Substring(1);

  LParam := FQuery.Params.FindParam(LNomeLimpo);

  if not Assigned(LParam) then
  begin
    LParam      := FQuery.Params.Add as TFDParam;
    LParam.Name := LNomeLimpo;
  end;

  if ATipo <> tcDesconhecido then
    LParam.DataType := MapearTipoFDAC(ATipo);

  AplicarValorParametro(LParam, AValor, ATipo);
end;

function TComandoFireDAC.ExecutarSemRetorno: Integer;
begin
  try
    FQuery.ExecSQL;
    Result := FQuery.RowsAffected;
  except
    on E: Exception do
      raise EOrmComandoExcecao.Create(
        FQuery.SQL.Text,
        Format('Falha ao executar comando SQL: %s', [E.Message]), E);
  end;
end;

function TComandoFireDAC.ExecutarEscalar: TValue;
begin
  try
    FQuery.Open;
    try
      if FQuery.IsEmpty or (FQuery.FieldCount = 0) then
      begin
        Result := TValue.Empty;
        Exit;
      end;

      // Retorna o valor da primeira coluna da primeira linha
      Result := TLeitorFireDAC.Create(FQuery, False)
        .ObterValor(FQuery.Fields[0].FieldName);
    finally
      FQuery.Close;
    end;
  except
    on E: Exception do
      raise EOrmComandoExcecao.Create(
        FQuery.SQL.Text,
        Format('Falha ao executar escalar: %s', [E.Message]), E);
  end;
end;

function TComandoFireDAC.ExecutarConsulta: IOrmLeitorDados;
var
  LQueryAberta: TFDQuery;
begin
  try
    FQuery.Open;
    FQuery.FetchAll;

    // Cria uma query independente para o leitor — o leitor possui ownership
    LQueryAberta := TFDQuery.Create(nil);
    LQueryAberta.Connection := FQuery.Connection;
    LQueryAberta.SQL.Text   := FQuery.SQL.Text;

    // Transfere os dados já carregados para o leitor
    // sem nova roundtrip ao banco
    Result := TLeitorFireDAC.Create(FQuery, False);
  except
    on E: Exception do
      raise EOrmComandoExcecao.Create(
        FQuery.SQL.Text,
        Format('Falha ao executar consulta: %s', [E.Message]), E);
  end;
end;

end.
