unit Infra.ORM.Scaffolding.Executor;

{
  Responsabilidade:
    Orquestra todo o processo de scaffolding:
    leitura do schema → geração de código → escrita/retorno.
    Suporta filtros de tabelas, dry-run e progress callback.
}

interface

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Logging.Contrato,
  Infra.ORM.Scaffolding.Schema.Contratos,
  Infra.ORM.Scaffolding.Schema.Firebird,
  Infra.ORM.Scaffolding.Schema.MySQL,
  Infra.ORM.Scaffolding.Gerador.Entidade,
  Infra.ORM.Scaffolding.Configuracao;

type

  TResultadoScaffolding = record
    TotalTabelas: Integer;
    TotalGeradas: Integer;
    TotalPuladas: Integer;
    TotalErros: Integer;
    Arquivos: TArray<string>;
    ArquivosComAviso: TArray<string>;
    Erros: TArray<string>;
    // Modo RetornarStrings
    Conteudos: TDictionary<string, string>; // NomeArquivo → ConteudoPas
  end;

  TExecutorScaffolding = class
  strict private
    FConexao: IOrmConexao;
    FLogger: IOrmLogger;
    FConfig: TConfiguracaoScaffolding;

    function CriarLeitorSchema: IOrmLeitorSchema;
    function FiltrarTabelas(
      const ATabelas: TArray<IOrmTabelaSchema>): TArray<IOrmTabelaSchema>;
    function DevePularTabela(const ANomeTabela: string): Boolean;
    function DeveIncluirTabela(const ANomeTabela: string): Boolean;

    procedure EscreverArquivo(
      const ANomeArquivo, AConteudo: string);

    procedure ImprimirDryRun(
      const ANomeArquivo, AConteudo: string);

  public
    constructor Create(
      AConexao: IOrmConexao;
      const AConfig: TConfiguracaoScaffolding;
      ALogger: IOrmLogger);

    function Executar(
      AProgresso: TProgressoScaffolding = nil): TResultadoScaffolding;
  end;

implementation

{ TExecutorScaffolding }

constructor TExecutorScaffolding.Create(
  AConexao: IOrmConexao;
  const AConfig: TConfiguracaoScaffolding;
  ALogger: IOrmLogger);
begin
  inherited Create;

  if not Assigned(AConexao) then
    raise EOrmConexaoExcecao.Create(
      'Conexão não pode ser nil no executor de scaffolding.');

  FConexao := AConexao;
  FConfig  := AConfig;
  FLogger  := ALogger ?? TLoggerNulo.Create;
end;

function TExecutorScaffolding.CriarLeitorSchema: IOrmLeitorSchema;
begin
  case FConfig.TipoBanco of
    tbFirebird:
      Result := TLeitorSchemaFirebird.Create(FConexao, FLogger);

    tbMySQL, tbMariaDB:
      Result := TLeitorSchemaMySQL.Create(
        FConexao, FLogger, FConfig.NomeDatabase);
  else
    raise EOrmConfiguracaoExcecao.Create(
      Format('Banco de dados não suportado pelo scaffolding: %d',
        [Ord(FConfig.TipoBanco)]));
  end;
end;

function TExecutorScaffolding.DeveIncluirTabela(
  const ANomeTabela: string): Boolean;
var
  LNome: string;
begin
  if Length(FConfig.TabelasIncluidas) = 0 then
  begin
    Result := True;
    Exit;
  end;

  LNome := ANomeTabela.ToUpper;
  for var LIncluida in FConfig.TabelasIncluidas do
    if LIncluida.ToUpper = LNome then
    begin
      Result := True;
      Exit;
    end;

  Result := False;
end;

function TExecutorScaffolding.DevePularTabela(
  const ANomeTabela: string): Boolean;
var
  LNome: string;
begin
  LNome := ANomeTabela.ToUpper;

  // Tabelas de sistema sempre puladas
  if LNome.StartsWith('RDB$') or
     LNome.StartsWith('MON$') or
     LNome.StartsWith('ORM_') then
  begin
    Result := True;
    Exit;
  end;

  // Lista de exclusão configurada
  for var LExcluida in FConfig.TabelasExcluidas do
    if LExcluida.ToUpper = LNome then
    begin
      Result := True;
      Exit;
    end;

  Result := False;
end;

function TExecutorScaffolding.FiltrarTabelas(
  const ATabelas: TArray<IOrmTabelaSchema>): TArray<IOrmTabelaSchema>;
var
  LFiltradas: TArray<IOrmTabelaSchema>;
  LContador: Integer;
  LTabela: IOrmTabelaSchema;
begin
  LContador := 0;

  for LTabela in ATabelas do
  begin
    if DevePularTabela(LTabela.NomeTabela) then
      Continue;
    if not DeveIncluirTabela(LTabela.NomeTabela) then
      Continue;

    SetLength(LFiltradas, LContador + 1);
    LFiltradas[LContador] := LTabela;
    Inc(LContador);
  end;

  Result := LFiltradas;
end;

procedure TExecutorScaffolding.EscreverArquivo(
  const ANomeArquivo, AConteudo: string);
var
  LCaminhoCompleto: string;
begin
  LCaminhoCompleto := TPath.Combine(
    FConfig.DiretorioSaida, ANomeArquivo);

  if TFile.Exists(LCaminhoCompleto) and
     not FConfig.SobrescreverExistente then
  begin
    FLogger.Aviso(
      Format('Arquivo já existe — pulado (configure SobrescreverExistente): %s',
        [LCaminhoCompleto]));
    Exit;
  end;

  TDirectory.CreateDirectory(FConfig.DiretorioSaida);

  TFile.WriteAllText(LCaminhoCompleto, AConteudo, TEncoding.UTF8);

  FLogger.Informacao(
    Format('Arquivo gerado: %s', [LCaminhoCompleto]));
end;

procedure TExecutorScaffolding.ImprimirDryRun(
  const ANomeArquivo, AConteudo: string);
begin
  Writeln('');
  Writeln(StringOfChar('─', 70));
  Writeln('ARQUIVO: ' + ANomeArquivo);
  Writeln(StringOfChar('─', 70));
  Writeln(AConteudo);
end;

function TExecutorScaffolding.Executar(
  AProgresso: TProgressoScaffolding): TResultadoScaffolding;
var
  LLeitor: IOrmLeitorSchema;
  LGerador: TGeradorEntidade;
  LTodasTabelas: TArray<IOrmTabelaSchema>;
  LTabelas: TArray<IOrmTabelaSchema>;
  LTabela: IOrmTabelaSchema;
  LResultado: TResultadoGeracaoEntidade;
  LIndice: Integer;
  LArquivos: TArray<string>;
  LArquivosAviso: TArray<string>;
  LErros: TArray<string>;
begin
  FLogger.Informacao('Iniciando scaffolding',
    TContextoLog.Novo
      .Add('banco', Ord(FConfig.TipoBanco))
      .Add('modo', Ord(FConfig.Modo))
      .Add('destino', FConfig.DiretorioSaida)
      .Construir);

  Result.Conteudos := TDictionary<string, string>.Create;

  LLeitor  := CriarLeitorSchema;
  LGerador := TGeradorEntidade.Create(FConfig, FLogger);
  try
    LTodasTabelas := LLeitor.LerTabelas;
    LTabelas      := FiltrarTabelas(LTodasTabelas);

    Result.TotalTabelas := Length(LTabelas);
    Result.TotalGeradas := 0;
    Result.TotalPuladas := 0;
    Result.TotalErros   := 0;

    FLogger.Informacao(
      Format('Scaffolding: %d tabelas encontradas, %d serão processadas',
        [Length(LTodasTabelas), Length(LTabelas)]));

    for LIndice := 0 to High(LTabelas) do
    begin
      LTabela := LTabelas[LIndice];

      if Assigned(AProgresso) then
        AProgresso(
          LTabela.NomeTabela,
          LIndice + 1,
          Length(LTabelas),
          Format('Gerando %s...', [LTabela.NomeTabela]));

      LResultado := LGerador.Gerar(LTabela);

      if not LResultado.Sucesso then
      begin
        Inc(Result.TotalErros);

        SetLength(LErros, Length(LErros) + 1);
        LErros[High(LErros)] :=
          Format('[%s] %s', [LTabela.NomeTabela, LResultado.MensagemErro]);
        Continue;
      end;

      // Registra avisos
      if Length(LResultado.Avisos) > 0 then
      begin
        SetLength(LArquivosAviso, Length(LArquivosAviso) + 1);
        LArquivosAviso[High(LArquivosAviso)] := LResultado.NomeArquivo;

        for var LAviso in LResultado.Avisos do
          FLogger.Aviso(LAviso);
      end;

      // Escrita / dry-run / coleta
      case FConfig.Modo of
        meEscreverArquivos:
          EscreverArquivo(LResultado.NomeArquivo, LResultado.ConteudoPas);

        meDryRun:
          ImprimirDryRun(LResultado.NomeArquivo, LResultado.ConteudoPas);

        meRetornarStrings:
          Result.Conteudos.AddOrSetValue(
            LResultado.NomeArquivo, LResultado.ConteudoPas);
      end;

      SetLength(LArquivos, Length(LArquivos) + 1);
      LArquivos[High(LArquivos)] := LResultado.NomeArquivo;
      Inc(Result.TotalGeradas);
    end;

    Result.Arquivos        := LArquivos;
    Result.ArquivosComAviso := LArquivosAviso;
    Result.Erros           := LErros;

    FLogger.Informacao(
      Format('Scaffolding concluído: %d geradas, %d erros',
        [Result.TotalGeradas, Result.TotalErros]));
  finally
    LGerador.Free;
  end;
end;

end.
