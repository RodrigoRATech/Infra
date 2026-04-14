unit Infra.ORM.Core.Generators.Contratos;

{
  Responsabilidade:
    Contratos e implementações para geração de valores de chave primária.
    Suporta: Autoincremento (banco), GUID e UUID v7 (aplicação).

    UUID v7 é a estratégia recomendada para sistemas distribuídos
    por ser time-ordered, reduzindo fragmentação de índice B-Tree.
}

interface

uses
  System.SysUtils,
  System.SyncObjs,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Exceptions;

type

  // ---------------------------------------------------------------------------
  // Contrato base para qualquer gerador de valor de chave
  // ---------------------------------------------------------------------------
  IOrmGeradorValor = interface
    ['{A7B8C9D0-E1F2-3456-0123-567890123456}']

    // Gera um novo valor. Retorna como string para compatibilidade genérica.
    // A conversão para o tipo da property é feita pelo hidratador.
    function Gerar: string;

    // Retorna a estratégia que este gerador implementa
    function Estrategia: TEstategiaChave;

    // Indica se o valor deve ser gerado antes de enviar ao banco
    // False = banco gera (autoincremento)
    // True  = aplicação gera (GUID, UUID v7)
    function GerarNaAplicacao: Boolean;
  end;

  // ---------------------------------------------------------------------------
  // Gerador de GUID no formato padrão Windows {XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}
  // ---------------------------------------------------------------------------
  TGeradorGuid = class(TInterfacedObject, IOrmGeradorValor)
  public
    function Gerar: string;
    function Estrategia: TEstategiaChave;
    function GerarNaAplicacao: Boolean;
  end;

  // ---------------------------------------------------------------------------
  // Gerador de UUID v7 — Time-Ordered UUID
  //
  // Especificação RFC 9562 (UUID v7):
  //   - 48 bits: timestamp Unix em milissegundos
  //   - 4 bits: versão (0111 = 7)
  //   - 12 bits: sequência aleatória (sub-ms)
  //   - 2 bits: variante (10)
  //   - 62 bits: aleatório
  //
  // Vantagens:
  //   - Ordenável por tempo de criação
  //   - Reduz fragmentação de índice vs UUID v4
  //   - Gerado na aplicação — sem roundtrip ao banco
  //   - Adequado para sistemas distribuídos
  // ---------------------------------------------------------------------------
  TGeradorUuidV7 = class(TInterfacedObject, IOrmGeradorValor)
  private
    FCritico: TCriticalSection;
    FUltimoTimestamp: Int64;
    FSequencia: Word;

    function ObterTimestampMs: Int64;
    function FormatarUuid(const ABytes: TBytes): string;
  public
    constructor Create;
    destructor Destroy; override;

    function Gerar: string;
    function Estrategia: TEstategiaChave;
    function GerarNaAplicacao: Boolean;
  end;

  // ---------------------------------------------------------------------------
  // Gerador nulo — para campos autoincremento (banco gera o valor)
  // ---------------------------------------------------------------------------
  TGeradorAutoIncremento = class(TInterfacedObject, IOrmGeradorValor)
  public
    function Gerar: string;
    function Estrategia: TEstategiaChave;
    function GerarNaAplicacao: Boolean;
  end;

  // ---------------------------------------------------------------------------
  // Fábrica de geradores — retorna o gerador correto por estratégia
  // ---------------------------------------------------------------------------
  TFabricaGeradores = class
  private
    class var FGeradorGuid: IOrmGeradorValor;
    class var FGeradorUuidV7: IOrmGeradorValor;
    class var FGeradorAutoInc: IOrmGeradorValor;
    class var FCritico: TCriticalSection;
  public
    class constructor Create;
    class destructor Destroy;

    class function ObterGerador(
      AEstrategia: TEstategiaChave): IOrmGeradorValor;
  end;

implementation

uses
  System.Math,
  System.DateUtils;

{ TGeradorGuid }

function TGeradorGuid.Gerar: string;
var
  LGuid: TGUID;
begin
  if CreateGUID(LGuid) <> S_OK then
    raise EOrmGeradorExcecao.Create('Falha ao gerar GUID.');

  Result := GUIDToString(LGuid);
end;

function TGeradorGuid.Estrategia: TEstategiaChave;
begin
  Result := ecGuid;
end;

function TGeradorGuid.GerarNaAplicacao: Boolean;
begin
  Result := True;
end;

{ TGeradorUuidV7 }

constructor TGeradorUuidV7.Create;
begin
  inherited Create;
  FCritico := TCriticalSection.Create;
  FUltimoTimestamp := 0;
  FSequencia := 0;
end;

destructor TGeradorUuidV7.Destroy;
begin
  FCritico.Free;
  inherited Destroy;
end;

function TGeradorUuidV7.ObterTimestampMs: Int64;
begin
  // Milliseconds desde Unix Epoch (1970-01-01)
  Result := DateTimeToUnix(Now, False) * 1000 +
    MilliSecondOf(Now);
end;

function TGeradorUuidV7.FormatarUuid(const ABytes: TBytes): string;
begin
  // Formato: xxxxxxxx-xxxx-7xxx-yxxx-xxxxxxxxxxxx
  Result := Format(
    '%s%s%s%s%s%s%s%s-%s%s%s%s-%s%s%s%s-%s%s%s%s-%s%s%s%s%s%s%s%s%s%s%s%s',
    [
      IntToHex(ABytes[0],  2), IntToHex(ABytes[1],  2),
      IntToHex(ABytes[2],  2), IntToHex(ABytes[3],  2),
      IntToHex(ABytes[4],  2), IntToHex(ABytes[5],  2),
      IntToHex(ABytes[6],  2), IntToHex(ABytes[7],  2),
      IntToHex(ABytes[8],  2), IntToHex(ABytes[9],  2),
      IntToHex(ABytes[10], 2), IntToHex(ABytes[11], 2),
      IntToHex(ABytes[12], 2), IntToHex(ABytes[13], 2),
      IntToHex(ABytes[14], 2), IntToHex(ABytes[15], 2)
    ]
  );

  // Formatar corretamente com hifens
  Result :=
    Copy(Result, 1,  8) + '-' +
    Copy(Result, 9,  4) + '-' +
    Copy(Result, 13, 4) + '-' +
    Copy(Result, 17, 4) + '-' +
    Copy(Result, 21, 12);
end;

function TGeradorUuidV7.Gerar: string;
var
  LTimestamp: Int64;
  LBytes: TBytes;
  LSeq: Word;
begin
  FCritico.Acquire;
  try
    LTimestamp := ObterTimestampMs;

    // Garantia de monotonicidade
    if LTimestamp <= FUltimoTimestamp then
    begin
      LTimestamp := FUltimoTimestamp;
      Inc(FSequencia);
      if FSequencia > $FFF then
      begin
        Inc(LTimestamp);
        FSequencia := 0;
      end;
    end
    else
    begin
      FSequencia := Random($FFF) and $FF;
    end;

    FUltimoTimestamp := LTimestamp;
    LSeq := FSequencia;
  finally
    FCritico.Release;
  end;

  SetLength(LBytes, 16);

  // Bytes 0-5: timestamp (48 bits)
  LBytes[0] := (LTimestamp shr 40) and $FF;
  LBytes[1] := (LTimestamp shr 32) and $FF;
  LBytes[2] := (LTimestamp shr 24) and $FF;
  LBytes[3] := (LTimestamp shr 16) and $FF;
  LBytes[4] := (LTimestamp shr  8) and $FF;
  LBytes[5] :=  LTimestamp         and $FF;

  // Byte 6: versão 7 (0111xxxx) + 4 bits superiores da sequência
  LBytes[6] := $70 or ((LSeq shr 8) and $0F);

  // Byte 7: 8 bits inferiores da sequência
  LBytes[7] := LSeq and $FF;

  // Bytes 8-15: aleatório (62 bits) com variante RFC 4122 (10xxxxxx)
  LBytes[8]  := $80 or (Random($3F));
  LBytes[9]  := Random($FF);
  LBytes[10] := Random($FF);
  LBytes[11] := Random($FF);
  LBytes[12] := Random($FF);
  LBytes[13] := Random($FF);
  LBytes[14] := Random($FF);
  LBytes[15] := Random($FF);

  Result := FormatarUuid(LBytes);
end;

function TGeradorUuidV7.Estrategia: TEstategiaChave;
begin
  Result := ecUuidV7;
end;

function TGeradorUuidV7.GerarNaAplicacao: Boolean;
begin
  Result := True;
end;

{ TGeradorAutoIncremento }

function TGeradorAutoIncremento.Gerar: string;
begin
  // Banco é responsável pela geração.
  // Este gerador não produz valor — retorna vazio.
  Result := string.Empty;
end;

function TGeradorAutoIncremento.Estrategia: TEstategiaChave;
begin
  Result := ecAutoIncremento;
end;

function TGeradorAutoIncremento.GerarNaAplicacao: Boolean;
begin
  Result := False;
end;

{ TFabricaGeradores }

class constructor TFabricaGeradores.Create;
begin
  FCritico := TCriticalSection.Create;
  FGeradorGuid    := nil;
  FGeradorUuidV7  := nil;
  FGeradorAutoInc := nil;
end;

class destructor TFabricaGeradores.Destroy;
begin
  FGeradorGuid    := nil;
  FGeradorUuidV7  := nil;
  FGeradorAutoInc := nil;
  FCritico.Free;
end;

class function TFabricaGeradores.ObterGerador(
  AEstrategia: TEstategiaChave): IOrmGeradorValor;
begin
  FCritico.Acquire;
  try
    case AEstrategia of
      ecGuid:
        begin
          if not Assigned(FGeradorGuid) then
            FGeradorGuid := TGeradorGuid.Create;
          Result := FGeradorGuid;
        end;

      ecUuidV7:
        begin
          if not Assigned(FGeradorUuidV7) then
            FGeradorUuidV7 := TGeradorUuidV7.Create;
          Result := FGeradorUuidV7;
        end;

      ecAutoIncremento, ecNenhuma:
        begin
          if not Assigned(FGeradorAutoInc) then
            FGeradorAutoInc := TGeradorAutoIncremento.Create;
          Result := FGeradorAutoInc;
        end;
    else
      raise EOrmGeradorExcecao.CreateFmt(
        'Estratégia de geração não suportada: %d',
        [Ord(AEstrategia)]);
    end;
  finally
    FCritico.Release;
  end;
end;

end.
