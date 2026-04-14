unit Infra.ORM.Scaffolding.Gerador.Nome;

{
  Responsabilidade:
    Conversão de nomes SQL para convenção Delphi.
    SNAKE_CASE → PascalCase para classes e properties.
    Detecta e remove prefixos de tabela configurados.
    Escapa palavras reservadas Delphi.
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Character;

type

  TGeradorNome = class
  strict private
    FPrefixoClasse: string;
    FPrefixosTabela: TArray<string>;

    class function TokenParaPascalCase(const AToken: string): string; static;
    class function EhPalavraReservada(const ANome: string): Boolean; static;
    function RemoverPrefixoTabela(const ANomeTabela: string): string;

  public
    constructor Create(
      const APrefixoClasse: string = 'T';
      const APrefixosTabela: TArray<string> = nil);

    // CLIENTES → TClientes
    function NomeClasseParaTabela(const ANomeTabela: string): string;

    // NOME_COMPLETO → NomeCompleto
    function NomePropriedadeParaColuna(const ANomeColuna: string): string;

    // TClientes → Clientes (para nome da unit)
    function NomeUnitParaClasse(const ANomeClasse: string): string;

    // TClientes → fNomeCompleto (campo privado)
    function NomeCampoPrivado(const ANomePropriedade: string): string;
  end;

implementation

const
  PALAVRAS_RESERVADAS: array[0..79] of string = (
    'AND', 'ARRAY', 'AS', 'ASM', 'BEGIN', 'CASE', 'CLASS', 'CONST',
    'CONSTRUCTOR', 'DESTRUCTOR', 'DISPINTERFACE', 'DIV', 'DO', 'DOWNTO',
    'ELSE', 'END', 'EXCEPT', 'EXPORTS', 'FILE', 'FINALIZATION', 'FINALLY',
    'FOR', 'FUNCTION', 'GOTO', 'IF', 'IMPLEMENTATION', 'IN', 'INHERITED',
    'INITIALIZATION', 'INLINE', 'INTERFACE', 'IS', 'LABEL', 'LIBRARY',
    'MOD', 'NIL', 'NOT', 'OBJECT', 'OF', 'ON', 'OR', 'OUT', 'PACKED',
    'PROCEDURE', 'PROGRAM', 'PROPERTY', 'RAISE', 'RECORD', 'REPEAT',
    'RESOURCESTRING', 'SET', 'SHL', 'SHR', 'STRING', 'THEN', 'THREADVAR',
    'TO', 'TRY', 'TYPE', 'UNIT', 'UNTIL', 'USES', 'VAR', 'WHILE', 'WITH',
    'XOR', 'ABSOLUTE', 'ABSTRACT', 'ASSEMBLER', 'AUTOMATED', 'CDECL',
    'DEFAULT', 'DYNAMIC', 'EXPORT', 'EXTERNAL', 'FAR', 'FORWARD',
    'MESSAGE', 'NAME', 'NEAR', 'OVERLOAD', 'OVERRIDE', 'PASCAL',
    'PRIVATE', 'PROTECTED', 'PUBLIC', 'PUBLISHED', 'READ', 'VIRTUAL',
    'WRITE');

{ TGeradorNome }

constructor TGeradorNome.Create(
  const APrefixoClasse: string;
  const APrefixosTabela: TArray<string>);
begin
  inherited Create;
  FPrefixoClasse  := APrefixoClasse;
  FPrefixosTabela := APrefixosTabela;
end;

class function TGeradorNome.TokenParaPascalCase(
  const AToken: string): string;
begin
  if AToken.IsEmpty then
  begin
    Result := '';
    Exit;
  end;

  Result := AToken.ToLower;
  Result[1] := UpCase(Result[1]);
end;

class function TGeradorNome.EhPalavraReservada(
  const ANome: string): Boolean;
var
  LPalavra: string;
begin
  for LPalavra in PALAVRAS_RESERVADAS do
    if LPalavra = ANome.ToUpper then
    begin
      Result := True;
      Exit;
    end;
  Result := False;
end;

function TGeradorNome.RemoverPrefixoTabela(
  const ANomeTabela: string): string;
var
  LPrefixo: string;
  LNome: string;
begin
  LNome := ANomeTabela.ToUpper;

  for LPrefixo in FPrefixosTabela do
  begin
    if LNome.StartsWith(LPrefixo.ToUpper) then
    begin
      Result := ANomeTabela.Substring(Length(LPrefixo));
      Exit;
    end;
  end;

  Result := ANomeTabela;
end;

function TGeradorNome.NomeClasseParaTabela(
  const ANomeTabela: string): string;
var
  LNomeSemPrefixo: string;
  LTokens: TArray<string>;
  LToken: string;
  LNome: TStringBuilder;
begin
  LNomeSemPrefixo := RemoverPrefixoTabela(ANomeTabela);
  LTokens         := LNomeSemPrefixo.Split(['_']);

  LNome := TStringBuilder.Create;
  try
    LNome.Append(FPrefixoClasse);

    for LToken in LTokens do
    begin
      if not LToken.Trim.IsEmpty then
        LNome.Append(TokenParaPascalCase(LToken));
    end;

    Result := LNome.ToString;
  finally
    LNome.Free;
  end;
end;

function TGeradorNome.NomePropriedadeParaColuna(
  const ANomeColuna: string): string;
var
  LTokens: TArray<string>;
  LToken: string;
  LNome: TStringBuilder;
begin
  LTokens := ANomeColuna.Split(['_']);
  LNome   := TStringBuilder.Create;
  try
    for LToken in LTokens do
    begin
      if not LToken.Trim.IsEmpty then
        LNome.Append(TokenParaPascalCase(LToken));
    end;

    Result := LNome.ToString;

    // Escapa palavras reservadas com sufixo _
    if EhPalavraReservada(Result) then
      Result := Result + '_';
  finally
    LNome.Free;
  end;
end;

function TGeradorNome.NomeUnitParaClasse(
  const ANomeClasse: string): string;
begin
  // Remove o prefixo de classe para o nome da unit
  if ANomeClasse.StartsWith(FPrefixoClasse) then
    Result := ANomeClasse.Substring(Length(FPrefixoClasse))
  else
    Result := ANomeClasse;
end;

function TGeradorNome.NomeCampoPrivado(
  const ANomePropriedade: string): string;
begin
  if ANomePropriedade.IsEmpty then
  begin
    Result := 'F';
    Exit;
  end;

  // NomeCompleto → FNomeCompleto
  Result := 'F' + ANomePropriedade;
end;

end.
