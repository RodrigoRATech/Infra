unit Infra.ORM.FireDAC.Leitor;

{
  Responsabilidade:
    Implementação de IOrmLeitorDados sobre TFDQuery do FireDAC.
    Abstrai a navegação e leitura tipada de resultados de consulta.
    Sem estado externo — posição controlada pelo TFDQuery interno.
}

interface

uses
  System.SysUtils,
  System.Rtti,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  Data.DB,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions;

type

  TLeitorFireDAC = class(TInterfacedObject, IOrmLeitorDados)
  strict private
    FQuery: TFDQuery;
    FOwnsQuery: Boolean;

    function CampoOuNulo(
      const AColuna: string): TField;

  public
    constructor Create(AQuery: TFDQuery; AOwnsQuery: Boolean = True);
    destructor Destroy; override;

    function Proximo: Boolean;
    function EhFim: Boolean;
    function NomeColunas: TArray<string>;

    function ObterString(const AColuna: string): string;
    function ObterInteger(const AColuna: string): Integer;
    function ObterInt64(const AColuna: string): Int64;
    function ObterDouble(const AColuna: string): Double;
    function ObterBoolean(const AColuna: string): Boolean;
    function ObterDateTime(const AColuna: string): TDateTime;
    function ObterGuid(const AColuna: string): TGUID;
    function ObterValor(const AColuna: string): TValue;
    function EhNulo(const AColuna: string): Boolean;
  end;

implementation

{ TLeitorFireDAC }

constructor TLeitorFireDAC.Create(
  AQuery: TFDQuery; AOwnsQuery: Boolean);
begin
  inherited Create;

  if not Assigned(AQuery) then
    raise EOrmComandoExcecao.Create('',
      'TFDQuery não pode ser nil no leitor FireDAC.');

  FQuery      := AQuery;
  FOwnsQuery  := AOwnsQuery;
end;

destructor TLeitorFireDAC.Destroy;
begin
  if FOwnsQuery then
    FQuery.Free;
  inherited Destroy;
end;

function TLeitorFireDAC.CampoOuNulo(
  const AColuna: string): TField;
begin
  Result := FQuery.FindField(AColuna);
end;

function TLeitorFireDAC.Proximo: Boolean;
begin
  if FQuery.Bof then
  begin
    // Primeiro acesso — já posicionado no primeiro registro pelo Open
    Result := not FQuery.IsEmpty;
    if Result and FQuery.Bof then
      FQuery.First;
  end
  else
  begin
    FQuery.Next;
    Result := not FQuery.Eof;
  end;
end;

function TLeitorFireDAC.EhFim: Boolean;
begin
  Result := FQuery.Eof;
end;

function TLeitorFireDAC.NomeColunas: TArray<string>;
var
  LIndice: Integer;
begin
  SetLength(Result, FQuery.FieldCount);
  for LIndice := 0 to FQuery.FieldCount - 1 do
    Result[LIndice] := FQuery.Fields[LIndice].FieldName;
end;

function TLeitorFireDAC.EhNulo(const AColuna: string): Boolean;
var
  LCampo: TField;
begin
  LCampo := CampoOuNulo(AColuna);
  Result := not Assigned(LCampo) or LCampo.IsNull;
end;

function TLeitorFireDAC.ObterString(const AColuna: string): string;
var
  LCampo: TField;
begin
  LCampo := CampoOuNulo(AColuna);
  if not Assigned(LCampo) or LCampo.IsNull then
    Result := string.Empty
  else
    Result := LCampo.AsString;
end;

function TLeitorFireDAC.ObterInteger(const AColuna: string): Integer;
var
  LCampo: TField;
begin
  LCampo := CampoOuNulo(AColuna);
  if not Assigned(LCampo) or LCampo.IsNull then
    Result := 0
  else
    Result := LCampo.AsInteger;
end;

function TLeitorFireDAC.ObterInt64(const AColuna: string): Int64;
var
  LCampo: TField;
begin
  LCampo := CampoOuNulo(AColuna);
  if not Assigned(LCampo) or LCampo.IsNull then
    Result := 0
  else
    Result := LCampo.AsLargeInt;
end;

function TLeitorFireDAC.ObterDouble(const AColuna: string): Double;
var
  LCampo: TField;
begin
  LCampo := CampoOuNulo(AColuna);
  if not Assigned(LCampo) or LCampo.IsNull then
    Result := 0.0
  else
    Result := LCampo.AsFloat;
end;

function TLeitorFireDAC.ObterBoolean(const AColuna: string): Boolean;
var
  LCampo: TField;
begin
  LCampo := CampoOuNulo(AColuna);
  if not Assigned(LCampo) or LCampo.IsNull then
    Result := False
  else
    Result := LCampo.AsBoolean;
end;

function TLeitorFireDAC.ObterDateTime(const AColuna: string): TDateTime;
var
  LCampo: TField;
begin
  LCampo := CampoOuNulo(AColuna);
  if not Assigned(LCampo) or LCampo.IsNull then
    Result := 0
  else
    Result := LCampo.AsDateTime;
end;

function TLeitorFireDAC.ObterGuid(const AColuna: string): TGUID;
var
  LTexto: string;
begin
  LTexto := ObterString(AColuna);
  if LTexto.IsEmpty then
    Result := TGUID.Empty
  else
    Result := TGUID.Create(LTexto);
end;

function TLeitorFireDAC.ObterValor(const AColuna: string): TValue;
var
  LCampo: TField;
begin
  LCampo := CampoOuNulo(AColuna);

  if not Assigned(LCampo) or LCampo.IsNull then
  begin
    Result := TValue.Empty;
    Exit;
  end;

  case LCampo.DataType of
    ftString, ftWideString, ftMemo, ftWideMemo:
      Result := TValue.From<string>(LCampo.AsString);

    ftSmallint, ftWord, ftInteger, ftAutoInc:
      Result := TValue.From<Integer>(LCampo.AsInteger);

    ftLargeint:
      Result := TValue.From<Int64>(LCampo.AsLargeInt);

    ftFloat, ftCurrency, ftBCD, ftFMTBcd:
      Result := TValue.From<Double>(LCampo.AsFloat);

    ftBoolean:
      Result := TValue.From<Boolean>(LCampo.AsBoolean);

    ftDate, ftTime, ftDateTime, ftTimeStamp:
      Result := TValue.From<TDateTime>(LCampo.AsDateTime);

    ftGuid:
      Result := TValue.From<string>(LCampo.AsString);

    ftBlob, ftGraphic, ftVarBytes, ftBytes:
      Result := TValue.From<string>(LCampo.AsString);
  else
    Result := TValue.From<string>(LCampo.AsString);
  end;
end;

end.
