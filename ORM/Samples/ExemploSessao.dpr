program ExemploSessao;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Mapping.Atributos,
  Infra.ORM.Core.Session.Fabrica,
  Infra.ORM.Core.Metadata.Cache;

// ── Bootstrap (feito uma vez na inicialização da aplicação) ─────────────────
var
  GFabrica: IOrmFabricaSessao;

procedure ConfigurarORM;
begin
  // Nesta fase, a fábrica de conexão e dialeto virão da Entrega 5
  // (FireDAC + Dialeto Firebird/MySQL).
  // Aqui mostramos o uso conceitual com a API já definida.

  GFabrica := TOrmFabricaSessao.Configurar
    .UsarConexao(MinhaFabricaFireDAC)     // Entrega 5
    .UsarDialeto(MeuDialetoFirebird)      // Entrega 5
    .UsarLogger(MeuLogger)               // seu módulo externo
    .Construir;
end;

// ── Exemplo de CRUD em uma operação de serviço ───────────────────────────────
procedure ExemploInserirCliente;
var
  LSessao: IOrmSessao;
  LTransacao: IOrmTransacao;
  LCliente: TCliente;
begin
  LSessao := GFabrica.CriarSessao;

  LTransacao := LSessao.IniciarTransacao;
  try
    LCliente       := TCliente.Create;
    LCliente.Nome  := 'Rodrigo';
    LCliente.Email := 'rodrigo@exemplo.com.br';

    LSessao.Inserir(LCliente);
    // LCliente.Id agora tem o valor gerado pelo banco

    LTransacao.Commit;
    Writeln('Cliente inserido com ID: ', LCliente.Id);
  except
    LTransacao.Rollback;
    raise;
  end;
end;

// ── Uso com chave simples ────────────────────────────────────────────────────
procedure ExemploBuscarEAtualizar;
var
  LSessao: IOrmSessao;
  LTransacao: IOrmTransacao;
  LCliente: TCliente;
begin
  LSessao := GFabrica.CriarSessao;

  // Busca sem transação (somente leitura)
  LCliente := LSessao.BuscarPorId<TCliente>(TValue.From<Int64>(42));

  if Assigned(LCliente) then
  begin
    LTransacao := LSessao.IniciarTransacao;
    try
      LCliente.Nome := 'Rodrigo Atualizado';
      LSessao.Atualizar(LCliente);
      LTransacao.Commit;
    except
      LTransacao.Rollback;
      raise;
    end;
  end;
end;

// ── Uso com chave composta ───────────────────────────────────────────────────
procedure ExemploChaveComposta;
var
  LSessao: IOrmSessao;
  LItem: TItemPedido;
  LChave: TValoresChave;
begin
  LSessao := GFabrica.CriarSessao;

  // Chave composta: PedidoId + NumeroItem
  SetLength(LChave, 2);
  LChave[0] := TValue.From<string>('018f1a2b-3c4d-7e5f-8a9b-0c1d2e3f4a5b');
  LChave[1] := TValue.From<Integer>(1);

  LItem := LSessao.BuscarPorId<TItemPedido>(LChave);

  if Assigned(LItem) then
    Writeln('Item encontrado — Quantidade: ', LItem.Quantidade);
end;

// ── Listagem simples ─────────────────────────────────────────────────────────
procedure ExemploListar;
var
  LSessao: IOrmSessao;
  LClientes: TObjectList<TCliente>;
  LCliente: TCliente;
begin
  LSessao  := GFabrica.CriarSessao;
  LClientes := LSessao.Listar<TCliente>;
  try
    for LCliente in LClientes do
      Writeln(LCliente.Id, ' | ', LCliente.Nome);
  finally
    LClientes.Free;
  end;
end;

// ── SQL direto com hidratação ────────────────────────────────────────────────
procedure ExemploSQLDireto;
var
  LSessao: IOrmSessao;
  LClientes: TObjectList<TCliente>;
  LParametros: TArray<TParNomeValor>;
begin
  LSessao := GFabrica.CriarSessao;

  SetLength(LParametros, 1);
  LParametros[0] := TParNomeValor.Create(
    ':p_nome', TValue.From<string>('Rodrigo%'));

  LClientes := LSessao.ExecutarSQL<TCliente>(
    'SELECT * FROM CLIENTES WHERE NOME LIKE :p_nome ORDER BY NOME',
    LParametros);
  try
    for var LCliente in LClientes do
      Writeln(LCliente.Id, ' | ', LCliente.Nome);
  finally
    LClientes.Free;
  end;
end;

begin
  try
    ConfigurarORM;
    ExemploInserirCliente;
    ExemploBuscarEAtualizar;
    ExemploListar;
    ExemploSQLDireto;
  except
    on E: Exception do
      Writeln('ERRO: ', E.ClassName, ': ', E.Message);
  end;
  Readln;
end.
