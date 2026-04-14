unit Infra.ORM.Firebird.Dialeto;

{
  Responsabilidade:
    Implementação do dialeto SQL para Firebird 2.5+.
    Encapsula todas as particularidades de sintaxe do Firebird:
    quoting ANSI com aspas duplas, paginação ROWS..TO,
    RETURNING para recuperação de chave gerada,
    e prefixo de parâmetro padrão.
}

interface

uses
  System.SysUtils,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions;

type

  TDialetoFirebird = class(TInterfacedObject, IOrmDialeto)
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

implementation

{ TDialetoFirebird }

function TDialetoFirebird.TipoBanco: TTipoBancoDados;
begin
  Result := TTipoBancoDados.tbFirebird;
end;

function TDialetoFirebird.Quotar(const ANome: string): string;
begin
  // Firebird usa aspas duplas para identificadores ANSI
  // Preserva case-sensitivity quando quotado
  if ANome.IsEmpty then
    raise EOrmDialetoExcecao.Create('Firebird',
      'Nome de identificador não pode ser vazio.');

  Result := '"' + ANome.Trim + '"';
end;

function TDialetoFirebird.QuotarTabela(
  const ANome, ASchema: string): string;
begin
  if ANome.IsEmpty then
    raise EOrmDialetoExcecao.Create('Firebird',
      'Nome da tabela não pode ser vazio.');

  if ASchema.Trim.IsEmpty then
    Result := Quotar(ANome)
  else
    Result := Quotar(ASchema) + '.' + Quotar(ANome);
end;

function TDialetoFirebird.AplicarPaginacao(
  const ASQL: string;
  AOffset, ALimit: Integer): string;
var
  LInicio: Integer;
  LFim: Integer;
begin
  {
    Firebird 2.5+ — sintaxe ROWS:
      SELECT * FROM TABELA ROWS 11 TO 20
      (offset 10, limit 10 → linhas 11 até 20)

    Firebird 2.5 também suporta:
      SELECT FIRST :limit SKIP :offset * FROM TABELA
    Usamos ROWS..TO por ser mais expressivo.
  }
  if AOffset < 0 then AOffset := 0;
  if ALimit  < 1 then ALimit  := 10;

  LInicio := AOffset + 1;
  LFim    := AOffset + ALimit;

  Result := Format('%s ROWS %d TO %d', [ASQL.TrimRight, LInicio, LFim]);
end;

function TDialetoFirebird.SQLChaveGerada: string;
begin
  // No Firebird usamos RETURNING diretamente no INSERT.
  // Este método é chamado apenas quando SuportaReturning = False,
  // o que nunca ocorre no Firebird. Mantemos para completude do contrato.
  Result := 'SELECT GEN_ID(GEN_ID_GENERATOR, 0) FROM RDB$DATABASE';
end;

function TDialetoFirebird.SQLExiste(
  const ATabela, AColunaChave: string): string;
begin
  Result := Format(
    'SELECT 1 FROM %s WHERE %s = %s%s',
    [Quotar(ATabela),
     Quotar(AColunaChave),
     PrefixoParametro,
     AColunaChave.ToLower]);
end;

function TDialetoFirebird.PrefixoParametro: string;
begin
  // Firebird via FireDAC usa ':' como prefixo de parâmetro nomeado
  Result := PREFIXO_PARAMETRO;
end;

function TDialetoFirebird.SuportaReturning: Boolean;
begin
  // Firebird suporta RETURNING nativamente desde a versão 2.1
  Result := True;
end;

function TDialetoFirebird.ClausulaReturning(const AColuna: string): string;
begin
  if AColuna.IsEmpty then
    raise EOrmDialetoExcecao.Create('Firebird',
      'Nome da coluna não pode ser vazio na cláusula RETURNING.');

  Result := Format(' RETURNING %s', [Quotar(AColuna)]);
end;

end.
