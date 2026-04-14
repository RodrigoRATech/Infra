program Exemplo01_CRUD_Basico;

{$APPTYPE CONSOLE}

{
  Exemplo 01 — CRUD Básico
  Demonstra: INSERT com autoincremento, SELECT por ID,
             UPDATE, DELETE e Listar.
  Banco: Firebird
}

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Rtti,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Mapping.Atributos,
  Infra.ORM.Core.Session.Fabrica,
  Infra.ORM.FireDAC.Configuracao,
  Infra.ORM.FireDAC.Fabrica,
  Infra.ORM.Firebird.Dialeto;

// ── Entidade ──────────────────────────────────────────────────────────────────
type

  [Tabela('EX_CLIENTES')]
  TCliente = class
  private
    FId: Int64;
    FNome: string;
    FEmail: string;
    FSaldo: Double;
    FAtivo: Boolean;
    FCriadoEm: TDateTime;
    FAtualizadoEm: TDateTime;
  public
    [ChavePrimaria]
    [AutoIncremento]
    [Coluna('ID')]
    property Id: Int64 read FId write FId;

    [Coluna('NOME')]
    [Obrigatorio]
    [Tamanho(150)]
    property Nome: string read FNome write FNome;

    [Coluna('EMAIL')]
    [Tamanho(200)]
    property Email: string read FEmail write FEmail;

    [Coluna('SALDO')]
    [Precisao(18, 2)]
    property Saldo: Double read FSaldo write FSaldo;

    [Coluna('ATIVO')]
    property Ativo: Boolean read FAtivo write FAtivo;

    [Coluna('CRIADO_EM')]
    [CriadoEm]
    [SomenteLeitura]
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;

    [Coluna('ATUALIZADO_EM')]
    [AtualizadoEm]
    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;
  end;

// ── Bootstrap ─────────────────────────────────────────────────────────────────
var
  GFabrica: IOrmFabricaSessao;

procedure Inicializar;
var
  LConfig: TConfiguracaoConexao;
  LFabricaConexao: IOrmFabricaConexao;
  LDialeto: IOrmDialeto;
begin
  LConfig := TConfiguracaoFirebird.Criar
    .Servidor('localhost')
    .BancoDados('C:\ORM\exemplos.fdb')
    .Usuario('SYSDBA')
    .Senha('masterkey')
    .Charset('UTF8')
    .Construir;

  LFabricaConexao := TFabricaConexaoFireDAC.Create(LConfig);
  LDialeto        := TDialetoFirebird.Create;

  GFabrica := TOrmFabricaSessao.Configurar
    .UsarConexao(LFabricaConexao)
    .UsarDialeto(LDialeto)
    .Construir;
end;

// ── Operações CRUD ────────────────────────────────────────────────────────────

procedure DemonstrarInsert;
var
  LSessao: IOrmSessao;
  LTransacao: IOrmTransacao;
  LCliente: TCliente;
begin
  Writeln('');
  Writeln('── INSERT ──────────────────────────────────────────');

  LSessao  := GFabrica.CriarSessao;
  LCliente := TCliente.Create;
  try
    LCliente.Nome  := 'Rodrigo Goiânia';
    LCliente.Email := 'rodrigo@exemplo.com.br';
    LCliente.Saldo := 1500.00;
    LCliente.Ativo := True;

    LTransacao := LSessao.IniciarTransacao;
    try
      LSessao.Inserir(LCliente);
      LTransacao.Commit;

      Writeln(Format('  ✓ Cliente inserido: Id=%d | CriadoEm=%s',
        [LCliente.Id, DateTimeToStr(LCliente.CriadoEm)]));
    except
      LTransacao.Rollback;
      raise;
    end;
  finally
    LCliente.Free;
  end;
end;

procedure DemonstrarSelectPorId(AId: Int64);
var
  LSessao: IOrmSessao;
  LCliente: TCliente;
begin
  Writeln('');
  Writeln('── SELECT POR ID ────────────────────────────────────');

  LSessao  := GFabrica.CriarSessao;
  LCliente := LSessao.BuscarPorId<TCliente>(TValue.From<Int64>(AId));

  if Assigned(LCliente) then
  begin
    try
      Writeln(Format('  ✓ Encontrado: Id=%d | Nome=%s | Email=%s',
        [LCliente.Id, LCliente.Nome, LCliente.Email]));
      Writeln(Format('    Saldo=%.2f | Ativo=%s | AtualizadoEm=%s',
        [LCliente.Saldo, BoolToStr(LCliente.Ativo, True),
         DateTimeToStr(LCliente.AtualizadoEm)]));
    finally
      LCliente.Free;
    end;
  end
  else
    Writeln(Format('  ✗ Id=%d não encontrado.', [AId]));
end;

procedure DemonstrarUpdate(AId: Int64);
var
  LSessao: IOrmSessao;
  LTransacao: IOrmTransacao;
  LCliente: TCliente;
begin
  Writeln('');
  Writeln('── UPDATE ──────────────────────────────────────────');

  LSessao  := GFabrica.CriarSessao;
  LCliente := LSessao.BuscarPorId<TCliente>(TValue.From<Int64>(AId));

  if not Assigned(LCliente) then
  begin
    Writeln(Format('  ✗ Cliente Id=%d não encontrado para atualização.', [AId]));
    Exit;
  end;

  try
    LCliente.Nome  := 'Rodrigo Atualizado';
    LCliente.Saldo := 2750.50;

    LTransacao := LSessao.IniciarTransacao;
    try
      LSessao.Atualizar(LCliente);
      LTransacao.Commit;

      Writeln(Format('  ✓ Cliente atualizado: Id=%d | Nome=%s | Saldo=%.2f',
        [LCliente.Id, LCliente.Nome, LCliente.Saldo]));
      Writeln(Format('    AtualizadoEm=%s',
        [DateTimeToStr(LCliente.AtualizadoEm)]));
    except
      LTransacao.Rollback;
      raise;
    end;
  finally
    LCliente.Free;
  end;
end;

procedure DemonstrarDelete(AId: Int64);
var
  LSessao: IOrmSessao;
  LTransacao: IOrmTransacao;
  LCliente: TCliente;
begin
  Writeln('');
  Writeln('── DELETE ──────────────────────────────────────────');

  LSessao  := GFabrica.CriarSessao;
  LCliente := LSessao.BuscarPorId<TCliente>(TValue.From<Int64>(AId));

  if not Assigned(LCliente) then
  begin
    Writeln(Format('  ✗ Cliente Id=%d não encontrado para deleção.', [AId]));
    Exit;
  end;

  try
    LTransacao := LSessao.IniciarTransacao;
    try
      LSessao.Deletar(LCliente);
      LTransacao.Commit;
      Writeln(Format('  ✓ Cliente Id=%d deletado com sucesso.', [AId]));
    except
      LTransacao.Rollback;
      raise;
    end;
  finally
    LCliente.Free;
  end;
end;

procedure DemonstrarListar;
var
  LSessao: IOrmSessao;
  LClientes: TObjectList<TCliente>;
  LCliente: TCliente;
begin
  Writeln('');
  Writeln('── LISTAR TODOS ─────────────────────────────────────');

  LSessao  := GFabrica.CriarSessao;
  LClientes := LSessao.Listar<TCliente>;
  try
    Writeln(Format('  Total: %d clientes', [LClientes.Count]));
    for LCliente in LClientes do
      Writeln(Format('    [%d] %-30s  %.2f',
        [LCliente.Id, LCliente.Nome, LCliente.Saldo]));
  finally
    LClientes.Free;
  end;
end;

// ── Entry Point ───────────────────────────────────────────────────────────────
var
  LIdInserido: Int64;

begin
  try
    Writeln('╔══════════════════════════════════════╗');
    Writeln('║  Infra.ORM — Exemplo 01: CRUD Básico ║');
    Writeln('╚══════════════════════════════════════╝');

    Inicializar;

    // Insere e captura o ID gerado
    var LSessaoTemp  := GFabrica.CriarSessao;
    var LClienteTemp := TCliente.Create;
    try
      LClienteTemp.Nome  := 'Rodrigo Goiânia';
      LClienteTemp.Email := 'rodrigo@exemplo.com.br';
      LClienteTemp.Saldo := 1500.00;
      LClienteTemp.Ativo := True;

      var LTrans := LSessaoTemp.IniciarTransacao;
      try
        LSessaoTemp.Inserir(LClienteTemp);
        LTrans.Commit;
        LIdInserido := LClienteTemp.Id;
      except
        LTrans.Rollback;
        raise;
      end;
    finally
      LClienteTemp.Free;
    end;

    Writeln(Format('  ✓ Inserido com Id=%d', [LIdInserido]));

    DemonstrarSelectPorId(LIdInserido);
    DemonstrarUpdate(LIdInserido);
    DemonstrarSelectPorId(LIdInserido); // Verifica atualização
    DemonstrarListar;
    DemonstrarDelete(LIdInserido);
    DemonstrarListar; // Confirma deleção

    Writeln('');
    Writeln('Exemplo 01 concluído com sucesso.');
  except
    on E: Exception do
    begin
      Writeln('');
      Writeln('ERRO: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  Readln;
end.
