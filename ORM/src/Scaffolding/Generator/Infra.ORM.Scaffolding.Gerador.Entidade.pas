unit Infra.ORM.Scaffolding.Gerador.Entidade;

{
  Responsabilidade:
    Gera o conteúdo completo de uma unit Delphi (.pas)
    a partir de um IOrmTabelaSchema.
    Produz: unit, uses, type, class com atributos, properties.
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Logging.Contrato,
  Infra.ORM.Scaffolding.Schema.Contratos,
  Infra.ORM.Scaffolding.Mapeador.Tipo,
  Infra.ORM.Scaffolding.Gerador.Nome,
  Infra.ORM.Scaffolding.Configuracao;

type

  TResultadoGeracaoEntidade = record
    NomeArquivo: string;      // ex: Model.Clientes.pas
    NomeUnit: string;         // ex: Model.Clientes
    NomeClasse: string;       // ex: TClientes
    ConteudoPas: string;      // código-fonte Delphi completo
    Avisos: TArray<string>;   // avisos gerados (tipos não mapeados, etc.)
    Sucesso: Boolean;
    MensagemErro: string;
  end;

  TGeradorEntidade = class
  strict private
    FConfig: TConfiguracaoScaffolding;
    FGeradorNome: TGeradorNome;
    FLogger: IOrmLogger;

    // Detectores de campos especiais
    function DetectarAtributosEspeciais(
      const ANomeColuna: string;
      AColuna: IOrmColunaSchema): TArray<string>;

    function DetectarTipoPropriedade(
      AColuna: IOrmColunaSchema): TResultadoMapeamento;

    // Geradores de seções da unit
    function GerarCabecalho(
      const ANomeUnit, ANomeTabela, ANomeClasse: string): string;

    function GerarSecaoInterface(
      const ANomeClasse: string;
      ATabela: IOrmTabelaSchema;
      var AAvisos: TArray<string>): string;

    function GerarCamposPrivados(
      ATabela: IOrmTabelaSchema): string;

    function GerarProperties(
      ATabela: IOrmTabelaSchema;
      var AAvisos: TArray<string>): string;

    function GerarAtributosColuna(
      AColuna: IOrmColunaSchema;
      const ANomePropriedade: string): string;

    function GerarSecaoImplementacao: string;
    function GerarRodape: string;

    procedure AdicionarAviso(
      var AAvisos: TArray<string>;
      const AAviso: string);

    function GerarPrefixoUnitModel: string;

  public
    constructor Create(
      const AConfig: TConfiguracaoScaffolding;
      ALogger: IOrmLogger);

    destructor Destroy; override;

    function Gerar(
      ATabela: IOrmTabelaSchema): TResultadoGeracaoEntidade;
  end;

implementation

{ TGeradorEntidade }

constructor TGeradorEntidade.Create(
  const AConfig: TConfiguracaoScaffolding;
  ALogger: IOrmLogger);
begin
  inherited Create;

  FConfig      := AConfig;
  FLogger      := ALogger ?? TLoggerNulo.Create;
  FGeradorNome := TGeradorNome.Create(
    AConfig.PrefixoClasse,
    AConfig.PrefixosTabela);
end;

destructor TGeradorEntidade.Destroy;
begin
  FGeradorNome.Free;
  inherited Destroy;
end;

procedure TGeradorEntidade.AdicionarAviso(
  var AAvisos: TArray<string>;
  const AAviso: string);
var
  LIndice: Integer;
begin
  LIndice := Length(AAvisos);
  SetLength(AAvisos, LIndice + 1);
  AAvisos[LIndice] := AAviso;
end;

function TGeradorEntidade.GerarPrefixoUnitModel: string;
begin
  if FConfig.PrefixoUnitModel.Trim.IsEmpty then
    Result := ''
  else
    Result := FConfig.PrefixoUnitModel.TrimRight(['.']) + '.';
end;

function TGeradorEntidade.DetectarTipoPropriedade(
  AColuna: IOrmColunaSchema): TResultadoMapeamento;
begin
  Result := TMappeadorTipo.Mapear(
    FConfig.TipoBanco,
    AColuna.TipoSQL,
    AColuna.TamanhoPrecisao,
    AColuna.TamanhoEscala);
end;

function TGeradorEntidade.DetectarAtributosEspeciais(
  const ANomeColuna: string;
  AColuna: IOrmColunaSchema): TArray<string>;
var
  LNome: string;
  LAtrs: TArray<string>;
  LContador: Integer;

  procedure Adicionar(const AAtributo: string);
  begin
    SetLength(LAtrs, LContador + 1);
    LAtrs[LContador] := AAtributo;
    Inc(LContador);
  end;

begin
  LNome     := ANomeColuna.ToUpper;
  LContador := 0;

  // Campos de auditoria detectados por nome convencional
  if (LNome = 'CRIADO_EM')     or (LNome = 'CREATED_AT')  then Adicionar('[CriadoEm]');
  if (LNome = 'ATUALIZADO_EM') or (LNome = 'UPDATED_AT')  then Adicionar('[AtualizadoEm]');
  if (LNome = 'DELETADO_EM')   or (LNome = 'DELETED_AT')  then Adicionar('[DeletadoEm]');
  if (LNome = 'CRIADO_POR')    or (LNome = 'CREATED_BY')  then Adicionar('[CriadoPor]');
  if (LNome = 'ATUALIZADO_POR')or (LNome = 'UPDATED_BY')  then Adicionar('[AtualizadoPor]');
  if (LNome = 'VERSAO')        or (LNome = 'VERSION')      then Adicionar('[VersaoConcorrencia]');
  if (LNome = 'TENANT_ID')                                 then Adicionar('[TenantId]');

  // Soft delete via coluna ATIVO/ACTIVE (detecta Boolean)
  if ((LNome = 'ATIVO') or (LNome = 'ACTIVE')) and
     (AColuna.TipoSQL.ToUpper.Contains('BOOL') or
      AColuna.TipoSQL.ToUpper.Contains('TINYINT')) then
    Adicionar('{Considere [SoftDeleteBooleano] se aplicável}');

  Result := Copy(LAtrs, 0, LContador);
end;

function TGeradorEntidade.GerarAtributosColuna(
  AColuna: IOrmColunaSchema;
  const ANomePropriedade: string): string;
var
  LSB: TStringBuilder;
  LMapeamento: TResultadoMapeamento;
  LEhUUID: Boolean;
  LAtrsEspeciais: TArray<string>;
  LAtr: string;
begin
  LSB := TStringBuilder.Create;
  try
    LMapeamento := DetectarTipoPropriedade(AColuna);
    LEhUUID     := TMappeadorTipo.EhCandidatoUUID(
      AColuna.NomeColuna, AColuna.TipoSQL, AColuna.TamanhoPrecisao);

    // Chave primária
    if AColuna.EhChavePrimaria then
    begin
      LSB.AppendLine('    [ChavePrimaria]');

      if AColuna.EhAutoIncremento then
        LSB.AppendLine('    [AutoIncremento]')
      else if LEhUUID then
        LSB.AppendLine('    [UuidV7Generator]');
    end;

    // Coluna mapeada
    LSB.AppendLine(Format('    [Coluna(''%s'')]', [AColuna.NomeColuna]));

    // Obrigatório (not null e não é PK autoincremento)
    if not AColuna.Nullable and
       not (AColuna.EhChavePrimaria and AColuna.EhAutoIncremento) then
      LSB.AppendLine('    [Obrigatorio]');

    // Tamanho para strings
    if (LMapeamento.TipoColuna = tcString) and
       (AColuna.TamanhoPrecisao > 0) and
       (AColuna.TamanhoPrecisao <= 32000) then
      LSB.AppendLine(
        Format('    [Tamanho(%d)]', [AColuna.TamanhoPrecisao]));

    // Precisão para decimais
    if (LMapeamento.TipoColuna in [tcDecimal]) and
       (AColuna.TamanhoPrecisao > 0) then
      LSB.AppendLine(Format('    [Precisao(%d, %d)]',
        [AColuna.TamanhoPrecisao, AColuna.TamanhoEscala]));

    // Atributos especiais detectados por nome
    LAtrsEspeciais := DetectarAtributosEspeciais(
      AColuna.NomeColuna, AColuna);
    for LAtr in LAtrsEspeciais do
      LSB.AppendLine(Format('    %s', [LAtr]));

    // SomenteLeitura para campos de auditoria de data/criação
    if AColuna.NomeColuna.ToUpper.Contains('CRIADO_EM') or
       AColuna.NomeColuna.ToUpper.Contains('CREATED_AT') then
      LSB.AppendLine('    [SomenteLeitura]');

    Result := LSB.ToString.TrimRight;
  finally
    LSB.Free;
  end;
end;

function TGeradorEntidade.GerarCamposPrivados(
  ATabela: IOrmTabelaSchema): string;
var
  LSB: TStringBuilder;
  LColuna: IOrmColunaSchema;
  LNomeProp: string;
  LMapeamento: TResultadoMapeamento;
begin
  LSB := TStringBuilder.Create;
  try
    for LColuna in ATabela.Colunas do
    begin
      LNomeProp   := FGeradorNome.NomePropriedadeParaColuna(
        LColuna.NomeColuna);
      LMapeamento := DetectarTipoPropriedade(LColuna);

      LSB.AppendLine(Format('    F%s: %s;',
        [LNomeProp, LMapeamento.TipoDelphiStr]));
    end;

    Result := LSB.ToString.TrimRight;
  finally
    LSB.Free;
  end;
end;

function TGeradorEntidade.GerarProperties(
  ATabela: IOrmTabelaSchema;
  var AAvisos: TArray<string>): string;
var
  LSB: TStringBuilder;
  LColuna: IOrmColunaSchema;
  LNomeProp: string;
  LMapeamento: TResultadoMapeamento;
  LAtributos: string;
begin
  LSB := TStringBuilder.Create;
  try
    for LColuna in ATabela.Colunas do
    begin
      LNomeProp   := FGeradorNome.NomePropriedadeParaColuna(
        LColuna.NomeColuna);
      LMapeamento := DetectarTipoPropriedade(LColuna);

      // Registra avisos de mapeamento impreciso
      if not LMapeamento.Aviso.IsEmpty then
        AdicionarAviso(AAvisos,
          Format('[%s.%s] %s',
            [ATabela.NomeTabela, LColuna.NomeColuna, LMapeamento.Aviso]));

      // Gera atributos
      LAtributos := GerarAtributosColuna(LColuna, LNomeProp);

      // Linha em branco separadora entre properties
      LSB.AppendLine('');
      LSB.AppendLine(LAtributos);

      // Declaração da property
      LSB.AppendLine(
        Format('    property %s: %s read F%s write F%s;',
          [LNomeProp, LMapeamento.TipoDelphiStr,
           LNomeProp, LNomeProp]));
    end;

    Result := LSB.ToString;
  finally
    LSB.Free;
  end;
end;

function TGeradorEntidade.GerarCabecalho(
  const ANomeUnit, ANomeTabela, ANomeClasse: string): string;
var
  LSB: TStringBuilder;
begin
  LSB := TStringBuilder.Create;
  try
    LSB.AppendLine(Format('unit %s;', [ANomeUnit]));
    LSB.AppendLine('');
    LSB.AppendLine('{');
    LSB.AppendLine(
      Format('  Entidade gerada automaticamente pelo Infra.ORM.Scaffolding', []));
    LSB.AppendLine(
      Format('  Tabela de origem: %s', [ANomeTabela]));
    LSB.AppendLine(
      Format('  Data de geração: %s', [DateTimeToStr(Now)]));
    LSB.AppendLine(
      '  ATENÇÃO: Alterações manuais serão perdidas na próxima regeneração.');
    LSB.AppendLine('}');
    LSB.AppendLine('');
    LSB.AppendLine('interface');
    LSB.AppendLine('');
    LSB.AppendLine('uses');
    LSB.AppendLine('  System.SysUtils,');

    // Inclui System.Classes apenas se houver tipo que precise
    LSB.AppendLine('  Infra.ORM.Core.Mapping.Atributos;');
    LSB.AppendLine('');
    LSB.AppendLine('type');
    LSB.AppendLine('');

    Result := LSB.ToString;
  finally
    LSB.Free;
  end;
end;

function TGeradorEntidade.GerarSecaoInterface(
  const ANomeClasse: string;
  ATabela: IOrmTabelaSchema;
  var AAvisos: TArray<string>): string;
var
  LSB: TStringBuilder;
begin
  LSB := TStringBuilder.Create;
  try
    // Atributo de tabela
    if ATabela.NomeSchema.Trim.IsEmpty then
      LSB.AppendLine(Format('  [Tabela(''%s'')]', [ATabela.NomeTabela]))
    else
      LSB.AppendLine(
        Format('  [Tabela(''%s'', ''%s'')]',
          [ATabela.NomeTabela, ATabela.NomeSchema]));

    // Aviso se não há PK
    if Length(ATabela.ChavesPrimarias) = 0 then
      AdicionarAviso(AAvisos,
        Format('ATENÇÃO: Tabela "%s" não possui chave primária detectada. ' +
               'Defina manualmente [ChavePrimaria].', [ATabela.NomeTabela]));

    // Declaração da classe
    LSB.AppendLine(
      Format('  %s = class', [ANomeClasse]));
    LSB.AppendLine('  strict private');
    LSB.AppendLine(GerarCamposPrivados(ATabela));
    LSB.AppendLine('  public');
    LSB.Append(GerarProperties(ATabela, AAvisos));
    LSB.AppendLine('  end;');
    LSB.AppendLine('');

    Result := LSB.ToString;
  finally
    LSB.Free;
  end;
end;

function TGeradorEntidade.GerarSecaoImplementacao: string;
begin
  Result :=
    'implementation' + sLineBreak +
    '' + sLineBreak;
end;

function TGeradorEntidade.GerarRodape: string;
begin
  Result := 'end.' + sLineBreak;
end;

function TGeradorEntidade.Gerar(
  ATabela: IOrmTabelaSchema): TResultadoGeracaoEntidade;
var
  LNomeClasse: string;
  LNomeUnit: string;
  LNomeArquivo: string;
  LSB: TStringBuilder;
  LAvisos: TArray<string>;
begin
  Result.Sucesso := False;
  try
    LNomeClasse  := FGeradorNome.NomeClasseParaTabela(ATabela.NomeTabela);
    LNomeUnit    := GerarPrefixoUnitModel +
      FGeradorNome.NomeUnitParaClasse(LNomeClasse);
    LNomeArquivo := LNomeUnit + '.pas';
    LAvisos      := nil;

    FLogger.Debug(Format('Gerando entidade: %s → %s',
      [ATabela.NomeTabela, LNomeClasse]));

    LSB := TStringBuilder.Create;
    try
      LSB.Append(GerarCabecalho(LNomeUnit, ATabela.NomeTabela, LNomeClasse));
      LSB.Append(GerarSecaoInterface(LNomeClasse, ATabela, LAvisos));
      LSB.Append(GerarSecaoImplementacao);
      LSB.Append(GerarRodape);

      Result.NomeArquivo  := LNomeArquivo;
      Result.NomeUnit     := LNomeUnit;
      Result.NomeClasse   := LNomeClasse;
      Result.ConteudoPas  := LSB.ToString;
      Result.Avisos       := LAvisos;
      Result.Sucesso      := True;
    finally
      LSB.Free;
    end;
  except
    on E: Exception do
    begin
      Result.Sucesso      := False;
      Result.MensagemErro := E.Message;
      FLogger.Erro(
        Format('Falha ao gerar entidade para "%s"', [ATabela.NomeTabela]),
        E);
    end;
  end;
end;

end.
