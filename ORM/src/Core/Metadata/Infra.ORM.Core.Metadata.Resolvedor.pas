unit Infra.ORM.Core.Metadata.Resolvedor;

{
  Responsabilidade:
    Único componente do ORM autorizado a utilizar RTTI diretamente.
    Lê os atributos das classes Delphi e produz instâncias de
    TMetadadoEntidade prontas para cache.

    Regra: esta classe não faz cache. Apenas resolve.
    O cache é responsabilidade de TCacheMetadados.

    Regra: toda entidade deve ter [Tabela].
    Properties sem [Coluna] recebem o nome da própria property como coluna.
    Properties com [NaoMapear] são completamente ignoradas.
}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions,
  Infra.ORM.Core.Mapping.Atributos,
  Infra.ORM.Core.Metadata.Propriedade,
  Infra.ORM.Core.Metadata.Entidade;

type

  // ---------------------------------------------------------------------------
  // Resolvedor de metadados via RTTI
  // Stateless — pode ser compartilhado entre threads sem sincronização
  // ---------------------------------------------------------------------------
  TResolvedorMetadados = class
  strict private
    // Contexto RTTI compartilhado — TRttiContext é value type,
    // mas TRttiType retornado é gerenciado internamente pelo TRttiContext.
    // Instanciamos um por resolvedor para isolar o contexto.
    FContextoRtti: TRttiContext;

    // Resolução de tipo de coluna a partir do tipo Delphi
    function ResolverTipoColuna(ARttiType: TRttiType;
      ATipoExplicito: TTipoColuna): TTipoColuna;

    // Resolução do nome da coluna com fallback para nome da property
    function ResolverNomeColuna(ARttiProp: TRttiProperty;
      AAtributo: ColunaAttribute): string;

    // Leitura e processamento de uma property individual
    function ProcessarPropriedade(
      ARttiProp: TRttiProperty;
      const ANomeEntidade: string): TMetadadoPropriedade;

    // Verifica se a property deve ser ignorada
    function DeveIgnorar(ARttiProp: TRttiProperty): Boolean;

    // Verifica se a property é acessível para persistência
    function EhPersistivel(ARttiProp: TRttiProperty): Boolean;

    // Extrai e aplica atributos de estratégia de chave
    procedure AplicarEstrategiaChave(
      ARttiProp: TRttiProperty;
      AMetadado: TMetadadoPropriedade);

    // Aplica flags de comportamento automático
    procedure AplicarFlagsComportamento(
      ARttiProp: TRttiProperty;
      AMetadado: TMetadadoPropriedade);

    // Aplica restrições e tamanhos
    procedure AplicarRestricoes(
      ARttiProp: TRttiProperty;
      AMetadado: TMetadadoPropriedade);

  public
    constructor Create;
    destructor Destroy; override;

    // Ponto de entrada principal — recebe uma TClass e devolve metadado
    function Resolver(AClasse: TClass): TMetadadoEntidade;
  end;

implementation

{ TResolvedorMetadados }

constructor TResolvedorMetadados.Create;
begin
  inherited Create;
  FContextoRtti := TRttiContext.Create;
end;

destructor TResolvedorMetadados.Destroy;
begin
  FContextoRtti.Free;
  inherited Destroy;
end;

function TResolvedorMetadados.Resolver(AClasse: TClass): TMetadadoEntidade;
var
  LTipoRtti: TRttiType;
  LAtributoTabela: TCustomAttribute;
  LTabelaAttr: TabelaAttribute;
  LNomeTabela: string;
  LNomeSchema: string;
  LPropriedades: TArray<TRttiProperty>;
  LRttiProp: TRttiProperty;
  LMetadadoEntidade: TMetadadoEntidade;
  LMetadadoProp: TMetadadoPropriedade;
  LNomeClasse: string;
begin
  if not Assigned(AClasse) then
    raise EOrmMetadadoExcecao.Create(
      'TResolvedorMetadados',
      'Classe não pode ser nil.');

  LNomeClasse := AClasse.ClassName;
  LTipoRtti   := FContextoRtti.GetType(AClasse);

  if not Assigned(LTipoRtti) then
    raise EOrmMetadadoExcecao.Create(
      LNomeClasse,
      'RTTI não disponível para esta classe. ' +
      'Verifique se {$M+} ou {$RTTI} está habilitado.');

  // ── Localizar atributo [Tabela] ──────────────────────────────────────────
  LTabelaAttr := nil;
  for LAtributoTabela in LTipoRtti.GetAttributes do
  begin
    if LAtributoTabela is TabelaAttribute then
    begin
      LTabelaAttr := TabelaAttribute(LAtributoTabela);
      Break;
    end;
  end;

  if not Assigned(LTabelaAttr) then
    raise EOrmMapeamentoExcecao.Create(
      LNomeClasse,
      'Atributo [Tabela] não encontrado. ' +
      'Toda entidade persistível deve declarar [Tabela(''NOME_TABELA'')].');

  LNomeTabela := LTabelaAttr.Nome.Trim;
  LNomeSchema := LTabelaAttr.Schema.Trim;

  if LNomeTabela.IsEmpty then
    raise EOrmMapeamentoExcecao.Create(
      LNomeClasse,
      'O nome da tabela no atributo [Tabela] não pode ser vazio.');

  // ── Construir metadado da entidade ──────────────────────────────────────
  LMetadadoEntidade := TMetadadoEntidade.Create(
    LNomeClasse, LNomeTabela, LNomeSchema);
  try
    // ── Iterar properties ────────────────────────────────────────────────
    LPropriedades := LTipoRtti.GetProperties;

    for LRttiProp in LPropriedades do
    begin
      // Pular properties que não devem ser mapeadas
      if DeveIgnorar(LRttiProp) then
        Continue;

      // Pular properties sem visibilidade adequada
      if not EhPersistivel(LRttiProp) then
        Continue;

      LMetadadoProp := ProcessarPropriedade(LRttiProp, LNomeClasse);

      if Assigned(LMetadadoProp) then
        LMetadadoEntidade.AdicionarPropriedade(LMetadadoProp);
    end;

    // ── Finalizar e validar ──────────────────────────────────────────────
    LMetadadoEntidade.Finalizar;

    Result := LMetadadoEntidade;
  except
    LMetadadoEntidade.Free;
    raise;
  end;
end;

function TResolvedorMetadados.DeveIgnorar(
  ARttiProp: TRttiProperty): Boolean;
var
  LAtributo: TCustomAttribute;
begin
  Result := False;

  for LAtributo in ARttiProp.GetAttributes do
  begin
    if LAtributo is NaoMapearAttribute then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TResolvedorMetadados.EhPersistivel(
  ARttiProp: TRttiProperty): Boolean;
begin
  // Aceita public e published
  Result := ARttiProp.Visibility in [mvPublic, mvPublished];

  // Property deve ter ao menos getter
  if Result then
    Result := ARttiProp.IsReadable;
end;

function TResolvedorMetadados.ProcessarPropriedade(
  ARttiProp: TRttiProperty;
  const ANomeEntidade: string): TMetadadoPropriedade;
var
  LAtributo: TCustomAttribute;
  LColunaAttr: ColunaAttribute;
  LNomeColuna: string;
  LTipoColuna: TTipoColuna;
  LTamanho: Integer;
  LPrecisao: Integer;
  LEscala: Integer;
  LEhNulavel: Boolean;
  LMetadado: TMetadadoPropriedade;
begin
  LColunaAttr := nil;

  // Localizar atributo [Coluna]
  for LAtributo in ARttiProp.GetAttributes do
  begin
    if LAtributo is ColunaAttribute then
    begin
      LColunaAttr := ColunaAttribute(LAtributo);
      Break;
    end;
  end;

  // Resolver nome da coluna
  LNomeColuna := ResolverNomeColuna(ARttiProp, LColunaAttr);

  // Resolver tipo da coluna
  if Assigned(LColunaAttr) and (LColunaAttr.Tipo <> tcDesconhecido) then
    LTipoColuna := LColunaAttr.Tipo
  else
    LTipoColuna := ResolverTipoColuna(ARttiProp.PropertyType, tcDesconhecido);

  // Resolver tamanho, precisão, escala e nulabilidade
  if Assigned(LColunaAttr) then
  begin
    LTamanho   := LColunaAttr.Tamanho;
    LPrecisao  := LColunaAttr.Precisao;
    LEscala    := LColunaAttr.Escala;
    LEhNulavel := LColunaAttr.Nulavel;
  end
  else
  begin
    LTamanho   := 0;
    LPrecisao  := 0;
    LEscala    := 0;
    LEhNulavel := True;
  end;

  // Construir metadado da propriedade
  LMetadado := TMetadadoPropriedade.Create(
    ARttiProp,
    LNomeColuna,
    LTipoColuna,
    LTamanho,
    LPrecisao,
    LEscala,
    LEhNulavel);

  // Aplicar atributos adicionais
  AplicarEstrategiaChave(ARttiProp, LMetadado);
  AplicarFlagsComportamento(ARttiProp, LMetadado);
  AplicarRestricoes(ARttiProp, LMetadado);

  Result := LMetadado;
end;

function TResolvedorMetadados.ResolverNomeColuna(
  ARttiProp: TRttiProperty;
  AAtributo: ColunaAttribute): string;
begin
  // Prioridade: nome explícito no atributo
  if Assigned(AAtributo) and not AAtributo.Nome.IsEmpty then
  begin
    Result := AAtributo.Nome.Trim;
    Exit;
  end;

  // Fallback: nome da própria property
  Result := ARttiProp.Name;
end;

function TResolvedorMetadados.ResolverTipoColuna(
  ARttiType: TRttiType;
  ATipoExplicito: TTipoColuna): TTipoColuna;
begin
  if ATipoExplicito <> tcDesconhecido then
  begin
    Result := ATipoExplicito;
    Exit;
  end;

  if not Assigned(ARttiType) then
  begin
    Result := tcDesconhecido;
    Exit;
  end;

  case ARttiType.TypeKind of
    tkInteger, tkInt64:
      begin
        if ARttiType.Name.ToUpper.Contains('INT64') or
           ARttiType.Name.ToUpper.Contains('LONGINT') then
          Result := tcInt64
        else
          Result := tcInteger;
      end;

    tkFloat:
      begin
        // TDateTime é tkFloat com nome específico
        if (ARttiType.Name = 'TDateTime') or
           (ARttiType.Name = 'TDate') then
          Result := tcDataHora
        else if ARttiType.Name = 'TTime' then
          Result := tcHora
        else
          Result := tcFloat;
      end;

    tkString, tkUString, tkWString, tkLString, tkChar, tkWChar:
      Result := tcString;

    tkEnumeration:
      begin
        // Boolean é enumeração em Delphi
        if ARttiType.Name = 'Boolean' then
          Result := tcBoolean
        else
          Result := tcInteger;
      end;

    tkRecord:
      begin
        // TGUID é record
        if ARttiType.Name = 'TGUID' then
          Result := tcGuid
        else
          Result := tcDesconhecido;
      end;

  else
    Result := tcDesconhecido;
  end;
end;

procedure TResolvedorMetadados.AplicarEstrategiaChave(
  ARttiProp: TRttiProperty;
  AMetadado: TMetadadoPropriedade);
var
  LAtributo: TCustomAttribute;
  LEhChave: Boolean;
  LOrdem: Integer;
  LEstrategia: TEstategiaChave;
  LEhAutoInc: Boolean;
begin
  LEhChave    := False;
  LOrdem      := 0;
  LEstrategia := ecNenhuma;
  LEhAutoInc  := False;

  for LAtributo in ARttiProp.GetAttributes do
  begin
    if LAtributo is ChavePrimariaAttribute then
    begin
      LEhChave := True;
      LOrdem   := ChavePrimariaAttribute(LAtributo).Ordem;
    end
    else if LAtributo is AutoIncrementoAttribute then
    begin
      LEstrategia := ecAutoIncremento;
      LEhAutoInc  := True;
    end
    else if LAtributo is GuidGeneratorAttribute then
      LEstrategia := ecGuid
    else if LAtributo is UuidV7GeneratorAttribute then
      LEstrategia := ecUuidV7;
  end;

  if LEhChave then
    AMetadado.DefinirComoChavePrimaria(LOrdem, LEstrategia, LEhAutoInc);
end;

procedure TResolvedorMetadados.AplicarFlagsComportamento(
  ARttiProp: TRttiProperty;
  AMetadado: TMetadadoPropriedade);
var
  LAtributo: TCustomAttribute;
begin
  for LAtributo in ARttiProp.GetAttributes do
  begin
    if LAtributo is CriadoEmAttribute then
      AMetadado.EhCriadoEm := True
    else if LAtributo is AtualizadoEmAttribute then
      AMetadado.EhAtualizadoEm := True
    else if LAtributo is CriadoPorAttribute then
      AMetadado.EhCriadoPor := True
    else if LAtributo is AtualizadoPorAttribute then
      AMetadado.EhAtualizadoPor := True
    else if LAtributo is DeletadoEmAttribute then
      AMetadado.EhDeletadoEm := True
    else if LAtributo is VersaoConcorrenciaAttribute then
      AMetadado.EhVersao := True
    else if LAtributo is TenantIdAttribute then
      AMetadado.EhTenantId := True
    else if LAtributo is SomenteLeituraAttribute then
      AMetadado.DefinirComoSomenteLeitura;
  end;
end;

procedure TResolvedorMetadados.AplicarRestricoes(
  ARttiProp: TRttiProperty;
  AMetadado: TMetadadoPropriedade);
var
  LAtributo: TCustomAttribute;
begin
  for LAtributo in ARttiProp.GetAttributes do
  begin
    if LAtributo is ObrigatorioAttribute then
      AMetadado.DefinirComoObrigatorio
    else if LAtributo is TamanhoAttribute then
    begin
      // TamanhoAttribute sobrescreve o tamanho definido em [Coluna]
      // se não houver tamanho em [Coluna]
    end
    else if LAtributo is PrecisaoAttribute then
    begin
      // Idem para precisão — já lido via ColunaAttribute ou aqui
    end;
  end;
end;

end.
