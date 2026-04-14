unit Infra.ORM.Scaffolding.Mapeador.Tipo;

{
  Responsabilidade:
    Mapeia tipos SQL (string) → TTipoColuna → tipo Delphi.
    Centraliza toda a lógica de conversão de tipos entre bancos.
}

interface

uses
  System.SysUtils,
  Infra.ORM.Core.Common.Tipos;

type

  TResultadoMapeamento = record
    TipoColuna: TTipoColuna;
    TipoDelphiStr: string;   // ex: 'string', 'Integer', 'Double'
    AtributoTipo: string;    // ex: '[tcString]'
    Aviso: string;           // preenchido quando mapeamento é impreciso
  end;

  TMappeadorTipo = class
  strict private
    class function MapearFirebird(
      const ATipoSQL: string;
      APrecisao, AEscala: Integer): TResultadoMapeamento; static;

    class function MapearMySQL(
      const ATipoSQL: string;
      APrecisao, AEscala: Integer): TResultadoMapeamento; static;

    class function ResultadoString(
      ATamanho: Integer): TResultadoMapeamento; static;

    class function ResultadoPadrao(
      const AAviso: string): TResultadoMapeamento; static;

  public
    class function Mapear(
      ATipoBanco: TTipoBancoDados;
      const ATipoSQL: string;
      APrecisao, AEscala: Integer): TResultadoMapeamento; static;

    // Detecta se um campo é UUID/GUID candidato
    class function EhCandidatoUUID(
      const ANomeColuna, ATipoSQL: string;
      APrecisao: Integer): Boolean; static;
  end;

implementation

{ TMappeadorTipo }

class function TMappeadorTipo.ResultadoString(
  ATamanho: Integer): TResultadoMapeamento;
begin
  Result.TipoColuna    := tcString;
  Result.TipoDelphiStr := 'string';
  Result.AtributoTipo  := '';
  Result.Aviso         := '';
end;

class function TMappeadorTipo.ResultadoPadrao(
  const AAviso: string): TResultadoMapeamento;
begin
  Result.TipoColuna    := tcString;
  Result.TipoDelphiStr := 'string';
  Result.AtributoTipo  := '';
  Result.Aviso         := AAviso;
end;

class function TMappeadorTipo.Mapear(
  ATipoBanco: TTipoBancoDados;
  const ATipoSQL: string;
  APrecisao, AEscala: Integer): TResultadoMapeamento;
begin
  case ATipoBanco of
    tbFirebird:         Result := MapearFirebird(ATipoSQL, APrecisao, AEscala);
    tbMySQL, tbMariaDB: Result := MapearMySQL(ATipoSQL, APrecisao, AEscala);
  else
    Result := ResultadoPadrao(
      Format('Banco %d não mapeado — usando string', [Ord(ATipoBanco)]));
  end;
end;

class function TMappeadorTipo.MapearFirebird(
  const ATipoSQL: string;
  APrecisao, AEscala: Integer): TResultadoMapeamento;
var
  LTipo: string;
begin
  LTipo := ATipoSQL.Trim.ToUpper;

  if (LTipo = 'SHORT') or (LTipo = 'SMALLINT') then
  begin
    Result.TipoColuna    := tcInteger;
    Result.TipoDelphiStr := 'Integer';
    Result.Aviso         := '';
  end
  else if (LTipo = 'LONG') or (LTipo = 'INTEGER') then
  begin
    Result.TipoColuna    := tcInteger;
    Result.TipoDelphiStr := 'Integer';
    Result.Aviso         := '';
  end
  else if (LTipo = 'INT64') or (LTipo = 'BIGINT') then
  begin
    Result.TipoColuna    := tcInt64;
    Result.TipoDelphiStr := 'Int64';
    Result.Aviso         := '';
  end
  else if LTipo = 'FLOAT' then
  begin
    Result.TipoColuna    := tcFloat;
    Result.TipoDelphiStr := 'Double';
    Result.Aviso         := '';
  end
  else if (LTipo = 'DOUBLE') or (LTipo = 'DOUBLE PRECISION') then
  begin
    Result.TipoColuna    := tcFloat;
    Result.TipoDelphiStr := 'Double';
    Result.Aviso         := '';
  end
  else if (LTipo = 'NUMERIC') or (LTipo = 'DECIMAL') then
  begin
    if AEscala > 0 then
    begin
      Result.TipoColuna    := tcDecimal;
      Result.TipoDelphiStr := 'Double';
    end
    else
    begin
      Result.TipoColuna    := tcInt64;
      Result.TipoDelphiStr := 'Int64';
    end;
    Result.Aviso := '';
  end
  else if LTipo = 'DATE' then
  begin
    Result.TipoColuna    := tcData;
    Result.TipoDelphiStr := 'TDate';
    Result.Aviso         := '';
  end
  else if LTipo = 'TIME' then
  begin
    Result.TipoColuna    := tcHora;
    Result.TipoDelphiStr := 'TTime';
    Result.Aviso         := '';
  end
  else if (LTipo = 'TIMESTAMP') or (LTipo = 'TIMESTAMP WITH TIME ZONE') then
  begin
    Result.TipoColuna    := tcDataHora;
    Result.TipoDelphiStr := 'TDateTime';
    Result.Aviso         := '';
  end
  else if (LTipo = 'BOOLEAN') or (LTipo = 'BOOL') then
  begin
    Result.TipoColuna    := tcBoolean;
    Result.TipoDelphiStr := 'Boolean';
    Result.Aviso         := '';
  end
  else if (LTipo = 'VARCHAR') or (LTipo = 'VARYING') or
          (LTipo = 'CHAR') then
  begin
    Result := ResultadoString(APrecisao);
  end
  else if LTipo = 'CLOB' then
  begin
    Result.TipoColuna    := tcClob;
    Result.TipoDelphiStr := 'string';
    Result.Aviso         := '';
  end
  else if LTipo = 'BLOB' then
  begin
    Result.TipoColuna    := tcBlob;
    Result.TipoDelphiStr := 'TBytes';
    Result.Aviso         := '';
  end
  else
    Result := ResultadoPadrao(
      Format('Tipo Firebird "%s" não mapeado — usando string', [LTipo]));
end;

class function TMappeadorTipo.MapearMySQL(
  const ATipoSQL: string;
  APrecisao, AEscala: Integer): TResultadoMapeamento;
var
  LTipo: string;
begin
  LTipo := ATipoSQL.Trim.ToUpper;

  if (LTipo = 'TINYINT') or (LTipo = 'SMALLINT') or
     (LTipo = 'MEDIUMINT') or (LTipo = 'INT') or (LTipo = 'INTEGER') then
  begin
    Result.TipoColuna    := tcInteger;
    Result.TipoDelphiStr := 'Integer';
    Result.Aviso         := '';
  end
  else if LTipo = 'BIGINT' then
  begin
    Result.TipoColuna    := tcInt64;
    Result.TipoDelphiStr := 'Int64';
    Result.Aviso         := '';
  end
  else if (LTipo = 'FLOAT') or (LTipo = 'DOUBLE') or
          (LTipo = 'REAL') then
  begin
    Result.TipoColuna    := tcFloat;
    Result.TipoDelphiStr := 'Double';
    Result.Aviso         := '';
  end
  else if (LTipo = 'DECIMAL') or (LTipo = 'NUMERIC') then
  begin
    if AEscala > 0 then
    begin
      Result.TipoColuna    := tcDecimal;
      Result.TipoDelphiStr := 'Double';
    end
    else
    begin
      Result.TipoColuna    := tcInt64;
      Result.TipoDelphiStr := 'Int64';
    end;
    Result.Aviso := '';
  end
  else if LTipo = 'DATE' then
  begin
    Result.TipoColuna    := tcData;
    Result.TipoDelphiStr := 'TDate';
    Result.Aviso         := '';
  end
  else if LTipo = 'TIME' then
  begin
    Result.TipoColuna    := tcHora;
    Result.TipoDelphiStr := 'TTime';
    Result.Aviso         := '';
  end
  else if (LTipo = 'DATETIME') or (LTipo = 'TIMESTAMP') then
  begin
    Result.TipoColuna    := tcDataHora;
    Result.TipoDelphiStr := 'TDateTime';
    Result.Aviso         := '';
  end
  else if (LTipo = 'TINYINT') and (APrecisao = 1) then
  begin
    Result.TipoColuna    := tcBoolean;
    Result.TipoDelphiStr := 'Boolean';
    Result.Aviso         := '';
  end
  else if LTipo = 'BOOLEAN' then
  begin
    Result.TipoColuna    := tcBoolean;
    Result.TipoDelphiStr := 'Boolean';
    Result.Aviso         := '';
  end
  else if (LTipo = 'CHAR') or (LTipo = 'VARCHAR') or
          (LTipo = 'TINYTEXT') then
  begin
    Result := ResultadoString(APrecisao);
  end
  else if (LTipo = 'TEXT') or (LTipo = 'MEDIUMTEXT') or
          (LTipo = 'LONGTEXT') then
  begin
    Result.TipoColuna    := tcClob;
    Result.TipoDelphiStr := 'string';
    Result.Aviso         := '';
  end
  else if (LTipo = 'BLOB') or (LTipo = 'MEDIUMBLOB') or
          (LTipo = 'LONGBLOB') then
  begin
    Result.TipoColuna    := tcBlob;
    Result.TipoDelphiStr := 'TBytes';
    Result.Aviso         := '';
  end
  else
    Result := ResultadoPadrao(
      Format('Tipo MySQL "%s" não mapeado — usando string', [LTipo]));
end;

class function TMappeadorTipo.EhCandidatoUUID(
  const ANomeColuna, ATipoSQL: string;
  APrecisao: Integer): Boolean;
var
  LTipo: string;
  LNome: string;
begin
  LTipo := ATipoSQL.Trim.ToUpper;
  LNome := ANomeColuna.Trim.ToUpper;

  // VARCHAR(36) ou CHAR(36) com nome terminando em _ID ou chamado ID
  Result :=
    ((LTipo = 'VARCHAR') or (LTipo = 'CHAR') or (LTipo = 'VARYING')) and
    (APrecisao = 36) and
    (LNome.EndsWith('_ID') or (LNome = 'ID') or LNome.EndsWith('_UUID'));
end;

end.
