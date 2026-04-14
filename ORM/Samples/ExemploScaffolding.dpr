program ExemploScaffolding;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.FireDAC.Configuracao,
  Infra.ORM.FireDAC.Conexao,
  Infra.ORM.Firebird.Dialeto,
  Infra.ORM.Scaffolding.Configuracao,
  Infra.ORM.Scaffolding.Executor;

procedure ExecutarScaffoldingFirebird;
var
  LConfigConexao: TConfiguracaoConexao;
  LConexao: IOrmConexao;
  LConfig: TConfiguracaoScaffolding;
  LExecutor: TExecutorScaffolding;
  LResultado: TResultadoScaffolding;
begin
  // ── Conexão ───────────────────────────────────────────────────────────────
  LConfigConexao := TConfiguracaoFirebird.Criar
    .Servidor('localhost')
    .BancoDados('C:\Dados\meu_sistema.fdb')
    .Usuario('SYSDBA')
    .Senha('masterkey')
    .Charset('UTF8')
    .Construir;

  LConexao := TConexaoFireDAC.Create(LConfigConexao);
  LConexao.Abrir;

  // ── Scaffolding ───────────────────────────────────────────────────────────
  LConfig := TConfiguracaoScaffoldingBuilder.Create(tbFirebird)
    .PrefixoClasse('T')
    .PrefixoUnitModel('Model')
    .AdicionarPrefixoTabela('TB_')
    .AdicionarPrefixoTabela('CAD_')
    .Excluir(['ORM_AUDITORIA', 'LOG_SISTEMA'])
    .DiretorioSaida('.\src\Model')
    .SobrescreverExistente(False)
    .Construir;

  LExecutor := TExecutorScaffolding.Create(LConexao, LConfig, nil);
  try
    LResultado := LExecutor.Executar(
      procedure(ATabela: string; AAtual, ATotal: Integer; AMensagem: string)
      begin
        Writeln(Format('[%d/%d] %s', [AAtual, ATotal, AMensagem]));
      end);

    // ── Resumo ─────────────────────────────────────────────────────────────
    Writeln('');
    Writeln('═══════════════ SCAFFOLDING CONCLUÍDO ═══════════════');
    Writeln(Format('  Tabelas encontradas : %d', [LResultado.TotalTabelas]));
    Writeln(Format('  Entidades geradas   : %d', [LResultado.TotalGeradas]));
    Writeln(Format('  Com avisos          : %d',
      [Length(LResultado.ArquivosComAviso)]));
    Writeln(Format('  Erros               : %d', [LResultado.TotalErros]));

    if Length(LResultado.Erros) > 0 then
    begin
      Writeln('');
      Writeln('ERROS:');
      for var LErro in LResultado.Erros do
        Writeln('  ✗ ' + LErro);
    end;

    if Length(LResultado.ArquivosComAviso) > 0 then
    begin
      Writeln('');
      Writeln('ARQUIVOS COM AVISOS (revisar manualmente):');
      for var LArq in LResultado.ArquivosComAviso do
        Writeln('  ⚠ ' + LArq);
    end;

  finally
    LExecutor.Free;
  end;
end;

// ── Dry-run — preview sem escrever arquivos ───────────────────────────────────
procedure ExecutarDryRun;
var
  LConfigConexao: TConfiguracaoConexao;
  LConexao: IOrmConexao;
  LConfig: TConfiguracaoScaffolding;
  LExecutor: TExecutorScaffolding;
begin
  LConfigConexao := TConfiguracaoFirebird.Criar
    .Servidor('localhost')
    .BancoDados('C:\Dados\meu_sistema.fdb')
    .Usuario('SYSDBA')
    .Senha('masterkey')
    .Construir;

  LConexao := TConexaoFireDAC.Create(LConfigConexao);
  LConexao.Abrir;

  // Tabela específica em dry-run
  LConfig := TConfiguracaoScaffoldingBuilder.Create(tbFirebird)
    .PrefixoUnitModel('Domain.Entities')
    .IncluirApenas(['CLIENTES', 'PEDIDOS', 'ITENS_PEDIDO'])
    .ModoDryRun  // imprime no console sem escrever
    .Construir;

  LExecutor := TExecutorScaffolding.Create(LConexao, LConfig, nil);
  try
    LExecutor.Executar;
  finally
    LExecutor.Free;
  end;
end;

begin
  try
    Writeln('=== Infra.ORM — Scaffolding ===');
    Writeln('');
    Writeln('1. Gerando entidades em .\src\Model...');
    ExecutarScaffoldingFirebird;
    Writeln('');
    Writeln('2. Dry-run de tabelas específicas...');
    ExecutarDryRun;
  except
    on E: Exception do
      Writeln('ERRO: ', E.ClassName, ': ', E.Message);
  end;
  Readln;
end.
