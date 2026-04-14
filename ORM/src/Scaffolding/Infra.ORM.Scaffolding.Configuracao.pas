unit Infra.ORM.Scaffolding.Configuracao;

{
  Responsabilidade:
    Configuração tipada do scaffolding com builder fluente.
}

interface

uses
  System.SysUtils,
  Infra.ORM.Core.Common.Tipos;

type

  TModoEscrita = (meEscreverArquivos, meDryRun, meRetornarStrings);

  TConfiguracaoScaffolding = record
    // Banco
    TipoBanco: TTipoBancoDados;
    NomeDatabase: string;   // usado pelo leitor MySQL

    // Geração
    PrefixoClasse: string;         // padrão: 'T'
    PrefixoUnitModel: string;      // ex: 'Model' → unit Model.Clientes
    PrefixosTabela: TArray<string>;// ex: ['TB_', 'TBL_'] → removidos do nome

    // Filtros
    TabelasIncluidas: TArray<string>;  // vazio = todas
    TabelasExcluidas: TArray<string>;  // lista de exclusão

    // Escrita
    Modo: TModoEscrita;
    DiretorioSaida: string;
    SobrescreverExistente: Boolean;

    class function Padrao(ATipoBanco: TTipoBancoDados): TConfiguracaoScaffolding; static;
    procedure Validar;
  end;

  // ---------------------------------------------------------------------------
  // Builder fluente
  // ---------------------------------------------------------------------------
  TConfiguracaoScaffoldingBuilder = class
  strict private
    FConfig: TConfiguracaoScaffolding;
  public
    constructor Create(ATipoBanco: TTipoBancoDados);

    function PrefixoClasse(const AValor: string): TConfiguracaoScaffoldingBuilder;
    function PrefixoUnitModel(const AValor: string): TConfiguracaoScaffoldingBuilder;
    function AdicionarPrefixoTabela(const APrefixo: string): TConfiguracaoScaffoldingBuilder;
    function IncluirApenas(const ATabelas: TArray<string>): TConfiguracaoScaffoldingBuilder;
    function Excluir(const ATabelas: TArray<string>): TConfiguracaoScaffoldingBuilder;
    function NomeDatabase(const AValor: string): TConfiguracaoScaffoldingBuilder;
    function DiretorioSaida(const AValor: string): TConfiguracaoScaffoldingBuilder;
    function SobrescreverExistente(AValor: Boolean = True): TConfiguracaoScaffoldingBuilder;
    function ModoDryRun: TConfiguracaoScaffoldingBuilder;
    function ModoRetornarStrings: TConfiguracaoScaffoldingBuilder;

    function Construir: TConfiguracaoScaffolding;
  end;

implementation

{ TConfiguracaoScaffolding }

class function TConfiguracaoScaffolding.Padrao(
  ATipoBanco: TTipoBancoDados): TConfiguracaoScaffolding;
begin
  Result.TipoBanco            := ATipoBanco;
  Result.NomeDatabase         := '';
  Result.PrefixoClasse        := 'T';
  Result.PrefixoUnitModel     := 'Model';
  Result.PrefixosTabela       := nil;
  Result.TabelasIncluidas     := nil;
  Result.TabelasExcluidas     := nil;
  Result.Modo                 := meEscreverArquivos;
  Result.DiretorioSaida       := '.\Model';
  Result.SobrescreverExistente := False;
end;

procedure TConfiguracaoScaffolding.Validar;
begin
  if (Modo = meEscreverArquivos) and DiretorioSaida.Trim.IsEmpty then
    raise Exception.Create(
      'DiretorioSaida é obrigatório no modo EscreverArquivos.');
end;

{ TConfiguracaoScaffoldingBuilder }

constructor TConfiguracaoScaffoldingBuilder.Create(ATipoBanco: TTipoBancoDados);
begin
  inherited Create;
  FConfig := TConfiguracaoScaffolding.Padrao(ATipoBanco);
end;

function TConfiguracaoScaffoldingBuilder.PrefixoClasse(
  const AValor: string): TConfiguracaoScaffoldingBuilder;
begin
  FConfig.PrefixoClasse := AValor;
  Result := Self;
end;

function TConfiguracaoScaffoldingBuilder.PrefixoUnitModel(
  const AValor: string): TConfiguracaoScaffoldingBuilder;
begin
  FConfig.PrefixoUnitModel := AValor;
  Result := Self;
end;

function TConfiguracaoScaffoldingBuilder.AdicionarPrefixoTabela(
  const APrefixo: string): TConfiguracaoScaffoldingBuilder;
var
  LIndice: Integer;
begin
  LIndice := Length(FConfig.PrefixosTabela);
  SetLength(FConfig.PrefixosTabela, LIndice + 1);
  FConfig.PrefixosTabela[LIndice] := APrefixo;
  Result := Self;
end;

function TConfiguracaoScaffoldingBuilder.IncluirApenas(
  const ATabelas: TArray<string>): TConfiguracaoScaffoldingBuilder;
begin
  FConfig.TabelasIncluidas := ATabelas;
  Result := Self;
end;

function TConfiguracaoScaffoldingBuilder.Excluir(
  const ATabelas: TArray<string>): TConfiguracaoScaffoldingBuilder;
begin
  FConfig.TabelasExcluidas := ATabelas;
  Result := Self;
end;

function TConfiguracaoScaffoldingBuilder.NomeDatabase(
  const AValor: string): TConfiguracaoScaffoldingBuilder;
begin
  FConfig.NomeDatabase := AValor;
  Result := Self;
end;

function TConfiguracaoScaffoldingBuilder.DiretorioSaida(
  const AValor: string): TConfiguracaoScaffoldingBuilder;
begin
  FConfig.DiretorioSaida := AValor;
  Result := Self;
end;

function TConfiguracaoScaffoldingBuilder.SobrescreverExistente(
  AValor: Boolean): TConfiguracaoScaffoldingBuilder;
begin
  FConfig.SobrescreverExistente := AValor;
  Result := Self;
end;

function TConfiguracaoScaffoldingBuilder.ModoDryRun: TConfiguracaoScaffoldingBuilder;
begin
  FConfig.Modo := meDryRun;
  Result := Self;
end;

function TConfiguracaoScaffoldingBuilder.ModoRetornarStrings: TConfiguracaoScaffoldingBuilder;
begin
  FConfig.Modo := meRetornarStrings;
  Result := Self;
end;

function TConfiguracaoScaffoldingBuilder.Construir: TConfiguracaoScaffolding;
begin
  FConfig.Validar;
  Result := FConfig;
end;

end.
