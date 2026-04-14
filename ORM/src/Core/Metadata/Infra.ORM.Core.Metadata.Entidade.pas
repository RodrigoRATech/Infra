unit Infra.ORM.Core.Metadata.Entidade;

{
  Responsabilidade:
    Implementação concreta de IOrmMetadadoEntidade.
    Agrega todos os metadados de uma entidade mapeada:
    tabela, schema, propriedades, chaves, flags de comportamento.

    Regra: imutável após construção. Toda mutação acontece
    apenas durante o processo de resolução interno.
    O acesso público é somente leitura via interface.
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions,
  Infra.ORM.Core.Metadata.Propriedade;

type

  // ---------------------------------------------------------------------------
  // Implementação concreta de IOrmMetadadoEntidade
  // ---------------------------------------------------------------------------
  TMetadadoEntidade = class(TInterfacedObject, IOrmMetadadoEntidade)
  strict private
    FNomeClasse: string;
    FNomeTabela: string;
    FNomeSchema: string;
    FNomeQualificado: string;
    FPossuiSoftDelete: Boolean;
    FPossuiCriadoEm: Boolean;
    FPossuiAtualizadoEm: Boolean;
    FPossuiVersao: Boolean;

    // Listas com ownership — este objeto possui as instâncias
    FTodasPropriedades: TObjectList<TMetadadoPropriedade>;

    // Índices auxiliares — sem ownership, apenas referências
    FChaves: TList<TMetadadoPropriedade>;
    FPropsPersistidas: TList<TMetadadoPropriedade>;

    // Mapa de lookup por nome de coluna e nome de property
    FMapaPorColuna: TDictionary<string, TMetadadoPropriedade>;
    FMapaPorNome: TDictionary<string, TMetadadoPropriedade>;

    procedure ReconstruirIndices;
    function ResolverNomeQualificado: string;
  public
    constructor Create(
      const ANomeClasse: string;
      const ANomeTabela: string;
      const ANomeSchema: string);

    destructor Destroy; override;

    // Método de construção interno — chamado apenas pelo resolvedor
    procedure AdicionarPropriedade(APropriedade: TMetadadoPropriedade);
    procedure Finalizar;

    // IOrmMetadadoEntidade
    function NomeClasse: string;
    function NomeTabela: string;
    function NomeSchema: string;
    function NomeQualificado: string;
    function Propriedades: TArray<IOrmMetadadoPropriedade>;
    function Chaves: TArray<IOrmMetadadoPropriedade>;
    function PropriedadesPersistidas: TArray<IOrmMetadadoPropriedade>;
    function PropriedadePorColuna(
      const ANomeColuna: string): IOrmMetadadoPropriedade;
    function PropriedadePorNome(
      const ANome: string): IOrmMetadadoPropriedade;
    function PossuiSoftDelete: Boolean;
    function PossuiCriadoEm: Boolean;
    function PossuiAtualizadoEm: Boolean;
    function PossuiVersao: Boolean;
  end;

implementation

{ TMetadadoEntidade }

constructor TMetadadoEntidade.Create(
  const ANomeClasse: string;
  const ANomeTabela: string;
  const ANomeSchema: string);
begin
  inherited Create;

  if ANomeClasse.IsEmpty then
    raise EOrmMetadadoExcecao.Create(
      'TMetadadoEntidade', 'Nome da classe não pode ser vazio.');

  if ANomeTabela.IsEmpty then
    raise EOrmMapeamentoExcecao.Create(
      ANomeClasse,
      'Nome da tabela não informado. Verifique o atributo [Tabela].');

  FNomeClasse    := ANomeClasse;
  FNomeTabela    := ANomeTabela;
  FNomeSchema    := ANomeSchema;

  FTodasPropriedades := TObjectList<TMetadadoPropriedade>.Create(True);
  FChaves            := TList<TMetadadoPropriedade>.Create;
  FPropsPersistidas  := TList<TMetadadoPropriedade>.Create;

  FMapaPorColuna := TDictionary<string, TMetadadoPropriedade>.Create(
    TIStringEqualityComparer.Create);

  FMapaPorNome := TDictionary<string, TMetadadoPropriedade>.Create(
    TIStringEqualityComparer.Create);

  FPossuiSoftDelete    := False;
  FPossuiCriadoEm      := False;
  FPossuiAtualizadoEm  := False;
  FPossuiVersao        := False;
end;

destructor TMetadadoEntidade.Destroy;
begin
  // FChaves e FPropsPersistidas são referências — não possuem ownership
  FMapaPorColuna.Free;
  FMapaPorNome.Free;
  FChaves.Free;
  FPropsPersistidas.Free;
  // FTodasPropriedades possui ownership — libera os objetos
  FTodasPropriedades.Free;
  inherited Destroy;
end;

procedure TMetadadoEntidade.AdicionarPropriedade(
  APropriedade: TMetadadoPropriedade);
begin
  if not Assigned(APropriedade) then
    raise EOrmMetadadoExcecao.Create(
      FNomeClasse, 'Propriedade não pode ser nil.');

  FTodasPropriedades.Add(APropriedade);
end;

procedure TMetadadoEntidade.Finalizar;
var
  LProp: TMetadadoPropriedade;
begin
  // Constrói índices e ordena chaves compostas
  FChaves.Clear;
  FPropsPersistidas.Clear;
  FMapaPorColuna.Clear;
  FMapaPorNome.Clear;

  for LProp in FTodasPropriedades do
  begin
    // Índice por coluna (case-insensitive)
    FMapaPorColuna.AddOrSetValue(
      LProp.NomeColuna.ToUpper, LProp);

    // Índice por nome de property
    FMapaPorNome.AddOrSetValue(
      LProp.Nome.ToUpper, LProp);

    // Lista de propriedades persistidas (não somente-leitura)
    if not LProp.EhSomenteLeitura then
      FPropsPersistidas.Add(LProp);

    // Lista de chaves
    if LProp.EhChavePrimaria then
      FChaves.Add(LProp);

    // Flags de comportamento automático
    if LProp.EhCriadoEm then
      FPossuiCriadoEm := True;

    if LProp.EhAtualizadoEm then
      FPossuiAtualizadoEm := True;

    if LProp.EhDeletadoEm then
      FPossuiSoftDelete := True;

    if LProp.EhVersao then
      FPossuiVersao := True;
  end;

  // Ordenar chaves compostas pela ordem declarada no atributo
  FChaves.Sort(
    TComparer<TMetadadoPropriedade>.Construct(
      function(const A, B: TMetadadoPropriedade): Integer
      begin
        Result := A.OrdemChave - B.OrdemChave;
      end
    )
  );

  // Valida: toda entidade precisa de ao menos uma chave primária
  if FChaves.Count = 0 then
    raise EOrmMapeamentoExcecao.Create(
      FNomeClasse,
      'Nenhuma chave primária encontrada. ' +
      'Adicione o atributo [ChavePrimaria] a pelo menos uma propriedade.');

  FNomeQualificado := ResolverNomeQualificado;
end;

procedure TMetadadoEntidade.ReconstruirIndices;
begin
  Finalizar;
end;

function TMetadadoEntidade.ResolverNomeQualificado: string;
begin
  if FNomeSchema.IsEmpty then
    Result := FNomeTabela
  else
    Result := FNomeSchema + '.' + FNomeTabela;
end;

function TMetadadoEntidade.NomeClasse: string;
begin
  Result := FNomeClasse;
end;

function TMetadadoEntidade.NomeTabela: string;
begin
  Result := FNomeTabela;
end;

function TMetadadoEntidade.NomeSchema: string;
begin
  Result := FNomeSchema;
end;

function TMetadadoEntidade.NomeQualificado: string;
begin
  Result := FNomeQualificado;
end;

function TMetadadoEntidade.Propriedades: TArray<IOrmMetadadoPropriedade>;
var
  LIndice: Integer;
begin
  SetLength(Result, FTodasPropriedades.Count);
  for LIndice := 0 to FTodasPropriedades.Count - 1 do
    Result[LIndice] := FTodasPropriedades[LIndice];
end;

function TMetadadoEntidade.Chaves: TArray<IOrmMetadadoPropriedade>;
var
  LIndice: Integer;
begin
  SetLength(Result, FChaves.Count);
  for LIndice := 0 to FChaves.Count - 1 do
    Result[LIndice] := FChaves[LIndice];
end;

function TMetadadoEntidade.PropriedadesPersistidas: TArray<IOrmMetadadoPropriedade>;
var
  LIndice: Integer;
begin
  SetLength(Result, FPropsPersistidas.Count);
  for LIndice := 0 to FPropsPersistidas.Count - 1 do
    Result[LIndice] := FPropsPersistidas[LIndice];
end;

function TMetadadoEntidade.PropriedadePorColuna(
  const ANomeColuna: string): IOrmMetadadoPropriedade;
var
  LProp: TMetadadoPropriedade;
begin
  if FMapaPorColuna.TryGetValue(ANomeColuna.ToUpper, LProp) then
    Result := LProp
  else
    Result := nil;
end;

function TMetadadoEntidade.PropriedadePorNome(
  const ANome: string): IOrmMetadadoPropriedade;
var
  LProp: TMetadadoPropriedade;
begin
  if FMapaPorNome.TryGetValue(ANome.ToUpper, LProp) then
    Result := LProp
  else
    Result := nil;
end;

function TMetadadoEntidade.PossuiSoftDelete: Boolean;
begin
  Result := FPossuiSoftDelete;
end;

function TMetadadoEntidade.PossuiCriadoEm: Boolean;
begin
  Result := FPossuiCriadoEm;
end;

function TMetadadoEntidade.PossuiAtualizadoEm: Boolean;
begin
  Result := FPossuiAtualizadoEm;
end;

function TMetadadoEntidade.PossuiVersao: Boolean;
begin
  Result := FPossuiVersao;
end;

end.
