unit Infra.ORM.MySQL.Dialeto;

{
  Responsabilidade:
    Implementação do dialeto SQL para MySQL 5.7+ e MariaDB 10.3+.
    Encapsula particularidades: quoting com backtick,
    paginação LIMIT/OFFSET, LAST_INSERT_ID() para chave gerada,
    sem suporte a RETURNING.
}

interface

uses
  System.SysUtils,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions;

type

  TDialetoMySQL = class(TInterfacedObject, IOrmDialeto)
  public
    function TipoBanco: TTipoBancoDados;
    function Quotar(const ANome: string): string;
    function QuotarTabela(const ANome, ASchema: string): string;
    function AplicarPaginacao(
      const ASQL: string;
      AOffset, ALimit: Integer): string;
    function SQLChaveGerada: string;
    function SQLExiste(
      const ATabela, AColunaChave: string): string;
    function PrefixoParametro: string;
    function SuportaReturning: Boolean;
    function ClausulaReturning(const AColuna: string): string;
  end;

  // ---------------------------------------------------------------------------
  // Alias para MariaDB — comportamento idêntico ao MySQL no MVP
  // ---------------------------------------------------------------------------
  TDialetoMariaDB = class(TDialetoMySQL)
  public
    function TipoBanco: TTipoBancoDados;
  end;

implementation

{ TDialetoMySQL }

function TDialetoMySQL.TipoBanco: TTipoBancoDados;
begin
  Result := TTipoBancoDados.tbMySQL;
end;

function TDialetoMySQL.Quotar(const ANome: string): string;
begin
  // MySQL/MariaDB usa backtick para identificadores
  if ANome.IsEmpty then
    raise EOrmDialetoExcecao.Create('MySQL',
      'Nome de identificador não pode ser vazio.');

  Result := '`' + ANome.Trim + '`';
end;

function TDialetoMySQL.QuotarTabela(
  const ANome, ASchema: string): string;
begin
  if ANome.IsEmpty then
    raise EOrmDialetoExcecao.Create('MySQL',
      'Nome da tabela não pode ser vazio.');

  if ASchema.Trim.IsEmpty then
    Result := Quotar(ANome)
  else
    // MySQL usa schema como database prefix: `schema`.`tabela`
    Result := Quotar(ASchema) + '.' + Quotar(ANome);
end;

function TDialetoMySQL.AplicarPaginacao(
  const ASQL: string;
  AOffset, ALimit: Integer): string;
begin
  {
    MySQL/MariaDB — sintaxe LIMIT/OFFSET:
      SELECT * FROM TABELA LIMIT 10 OFFSET 20
  }
  if AOffset < 0 then AOffset := 0;
  if ALimit  < 1 then ALimit  := 10;

  Result := Format('%s LIMIT %d OFFSET %d',
    [ASQL.TrimRight, ALimit, AOffset]);
end;

function TDialetoMySQL.SQLChaveGerada: string;
begin
  // MySQL não suporta RETURNING — usa função específica
  // Deve ser executado na mesma conexão/sessão imediatamente após INSERT
  Result := 'SELECT LAST_INSERT_ID()';
end;

function TDialetoMySQL.SQLExiste(
  const ATabela, AColunaChave: string): string;
begin
  Result := Format(
    'SELECT 1 FROM %s WHERE %s = %s%s LIMIT 1',
    [Quotar(ATabela),
     Quotar(AColunaChave),
     PrefixoParametro,
     AColunaChave.ToLower]);
end;

function TDialetoMySQL.PrefixoParametro: string;
begin
  // MySQL via FireDAC usa ':' como prefixo de parâmetro nomeado
  Result := PREFIXO_PARAMETRO;
end;

function TDialetoMySQL.SuportaReturning: Boolean;
begin
  // MySQL/MariaDB não suporta RETURNING no INSERT
  Result := False;
end;

function TDialetoMySQL.ClausulaReturning(const AColuna: string): string;
begin
  // MySQL não suporta — nunca deve ser chamado
  raise EOrmDialetoExcecao.Create('MySQL',
    'MySQL/MariaDB não suporta cláusula RETURNING. ' +
    'Use SQLChaveGerada() após o INSERT.');
end;

{ TDialetoMariaDB }

function TDialetoMariaDB.TipoBanco: TTipoBancoDados;
begin
  Result := TTipoBancoDados.tbMariaDB;
end;

end.
