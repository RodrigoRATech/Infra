unit Infra.ORM.Core.Events.Registro;

{
  Responsabilidade:
    Tipos de dados dos eventos ORM.
    Serialização leve de valores para auditoria.
    Sem dependência de banco ou provider.
}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.DateUtils,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos;

type

  // ---------------------------------------------------------------------------
  // Entrada de detalhe de auditoria — par coluna/valor serializado
  // ---------------------------------------------------------------------------
  TEntradaAuditoria = record
    Coluna: string;
    Valor: string;

    class function Criar(
      const AColuna, AValor: string): TEntradaAuditoria; static;
  end;

  TListaEntradaAuditoria = TArray<TEntradaAuditoria>;

  // ---------------------------------------------------------------------------
  // Serializador leve de TValue para string legível
  // ---------------------------------------------------------------------------
  TSerializadorValor = class
  public
    class function Serializar(const AValor: TValue): string; static;
    class function SerializarLista(
      const AValores: TValoresChave): string; static;
    class function SerializarEntidade(
      AMetadado: IInterface;
      AEntidade: TObject): TListaEntradaAuditoria; static;
  end;

  // ---------------------------------------------------------------------------
  // Builder de contexto de log estruturado
  // (completando a implementação referenciada nas entregas anteriores)
  // ---------------------------------------------------------------------------
  TContextoLog = record
  private
    FEntradas: TArray<TPair<string, string>>;
  public
    class function Novo: TContextoLog; static;
    function Add(const AChave, AValor: string): TContextoLog; overload;
    function Add(const AChave: string; AValor: Integer): TContextoLog; overload;
    function Add(const AChave: string; AValor: Int64): TContextoLog; overload;
    function Add(const AChave: string; AValor: Boolean): TContextoLog; overload;
    function Construir: string;
  end;

implementation

{ TEntradaAuditoria }

class function TEntradaAuditoria.Criar(
  const AColuna, AValor: string): TEntradaAuditoria;
begin
  Result.Coluna := AColuna;
  Result.Valor  := AValor;
end;

{ TSerializadorValor }

class function TSerializadorValor.Serializar(const AValor: TValue): string;
begin
  if AValor.IsEmpty then
  begin
    Result := 'null';
    Exit;
  end;

  case AValor.Kind of
    tkString, tkUString, tkWString, tkLString, tkChar, tkWChar:
      Result := '"' + AValor.AsString + '"';

    tkInteger:
      Result := IntToStr(AValor.AsInteger);

    tkInt64:
      Result := IntToStr(AValor.AsInt64);

    tkFloat:
      begin
        if AValor.TypeInfo = TypeInfo(TDateTime) then
          Result := '"' + DateTimeToStr(AValor.AsType<TDateTime>) + '"'
        else if AValor.TypeInfo = TypeInfo(TDate) then
          Result := '"' + DateToStr(AValor.AsType<TDate>) + '"'
        else
          Result := FloatToStr(AValor.AsExtended);
      end;

    tkEnumeration:
      begin
        if AValor.TypeInfo = TypeInfo(Boolean) then
          Result := BoolToStr(AValor.AsBoolean, True).ToLower
        else
          Result := IntToStr(AValor.AsOrdinal);
      end;

    tkRecord:
      Result := '"' + AValor.ToString + '"';

  else
    Result := '"' + AValor.ToString + '"';
  end;
end;

class function TSerializadorValor.SerializarLista(
  const AValores: TValoresChave): string;
var
  LSB: TStringBuilder;
  LIndice: Integer;
begin
  if Length(AValores) = 0 then
  begin
    Result := '[]';
    Exit;
  end;

  LSB := TStringBuilder.Create;
  try
    LSB.Append('[');
    for LIndice := 0 to High(AValores) do
    begin
      if LIndice > 0 then LSB.Append(', ');
      LSB.Append(Serializar(AValores[LIndice]));
    end;
    LSB.Append(']');
    Result := LSB.ToString;
  finally
    LSB.Free;
  end;
end;

class function TSerializadorValor.SerializarEntidade(
  AMetadado: IInterface;
  AEntidade: TObject): TListaEntradaAuditoria;
var
  LMetadado: IOrmMetadadoEntidade;
  LProps: TArray<IOrmMetadadoPropriedade>;
  LProp: IOrmMetadadoPropriedade;
  LIndice: Integer;
begin
  Result := nil;

  if not Assigned(AEntidade) then
    Exit;

  if not Supports(AMetadado, IOrmMetadadoEntidade, LMetadado) then
    Exit;

  LProps := LMetadado.Propriedades;
  SetLength(Result, Length(LProps));
  LIndice := 0;

  for LProp in LProps do
  begin
    try
      Result[LIndice] := TEntradaAuditoria.Criar(
        LProp.NomeColuna,
        Serializar(LProp.ObterValor(AEntidade)));
      Inc(LIndice);
    except
      // Ignora falha de leitura de property individual
    end;
  end;

  SetLength(Result, LIndice);
end;

{ TContextoLog }

class function TContextoLog.Novo: TContextoLog;
begin
  Result.FEntradas := nil;
end;

function TContextoLog.Add(
  const AChave, AValor: string): TContextoLog;
var
  LIndice: Integer;
begin
  LIndice := Length(FEntradas);
  SetLength(FEntradas, LIndice + 1);
  FEntradas[LIndice] := TPair<string, string>.Create(AChave, AValor);
  Result := Self;
end;

function TContextoLog.Add(
  const AChave: string; AValor: Integer): TContextoLog;
begin
  Result := Add(AChave, IntToStr(AValor));
end;

function TContextoLog.Add(
  const AChave: string; AValor: Int64): TContextoLog;
begin
  Result := Add(AChave, IntToStr(AValor));
end;

function TContextoLog.Add(
  const AChave: string; AValor: Boolean): TContextoLog;
begin
  Result := Add(AChave, BoolToStr(AValor, True).ToLower);
end;

function TContextoLog.Construir: string;
var
  LSB: TStringBuilder;
  LPar: TPair<string, string>;
  LPrimeiro: Boolean;
begin
  if Length(FEntradas) = 0 then
  begin
    Result := '{}';
    Exit;
  end;

  LSB      := TStringBuilder.Create;
  LPrimeiro := True;
  try
    LSB.Append('{');
    for LPar in FEntradas do
    begin
      if not LPrimeiro then LSB.Append(', ');
      LSB.Append('"');
      LSB.Append(LPar.Key);
      LSB.Append('": "');
      LSB.Append(LPar.Value);
      LSB.Append('"');
      LPrimeiro := False;
    end;
    LSB.Append('}');
    Result := LSB.ToString;
  finally
    LSB.Free;
  end;
end;

end.
