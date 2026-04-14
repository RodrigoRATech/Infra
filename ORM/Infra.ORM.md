# Infra.ORM

ORM para **Delphi 12 Athens** com suporte a **Firebird** e **MySQL/MariaDB**.

## Instalação

1. Compile os packages na ordem:
   ```
   Infra.ORM.Core.dpk
   Infra.ORM.FireDAC.dpk
   Infra.ORM.Scaffolding.dpk
   ```
2. Adicione o diretório `src/` ao Library Path do Delphi.
3. Adicione as referências nos seus projetos via `requires`.

---

## Início Rápido

### 1. Defina a entidade

```delphi
[Tabela('CLIENTES')]
TCliente = class
private
  FId: Int64;
  FNome: string;
  FCriadoEm: TDateTime;
public
  [ChavePrimaria] [AutoIncremento] [Coluna('ID')]
  property Id: Int64 read FId write FId;

  [Coluna('NOME')] [Obrigatorio] [Tamanho(150)]
  property Nome: string read FNome write FNome;

  [Coluna('CRIADO_EM')] [CriadoEm] [SomenteLeitura]
  property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
end;
```

### 2. Configure o ORM

```delphi
var LConfig := TConfiguracaoFirebird.Criar
  .Servidor('localhost')
  .BancoDados('C:\sistema.fdb')
  .Usuario('SYSDBA')
  .Senha('masterkey')
  .Construir;

var GFabrica := TOrmFabricaSessao.Configurar
  .UsarConexao(TFabricaConexaoFireDAC.Create(LConfig))
  .UsarDialeto(TDialetoFirebird.Create)
  .Construir;
```

### 3. Use

```delphi
var LSessao := GFabrica.CriarSessao;

// INSERT
var LCliente := TCliente.Create;
LCliente.Nome := 'Rodrigo';
var LTrans := LSessao.IniciarTransacao;
try
  LSessao.Inserir(LCliente);
  LTrans.Commit;
except
  LTrans.Rollback; raise;
end;

// SELECT
var LBuscado := LSessao.BuscarPorId<TCliente>(TValue.From<Int64>(1));

// Query fluente
var LAtivos := LSessao.Consultar<TCliente>
  .Onde('ATIVO', ofIgual, TValue.From<Boolean>(True))
  .OrdenarPor('NOME')
  .Pular(0).Pegar(10)
  .Listar;
```

---

## Atributos de Mapeamento

| Atributo | Descrição |
|---|---|
| `[Tabela('NOME')]` | Nome da tabela no banco |
| `[Coluna('NOME')]` | Nome da coluna no banco |
| `[ChavePrimaria]` | Define a chave primária |
| `[AutoIncremento]` | PK gerada pelo banco |
| `[UuidV7Generator]` | PK UUID v7 gerada pelo ORM |
| `[Obrigatorio]` | Campo NOT NULL validado antes do INSERT |
| `[Tamanho(N)]` | Tamanho máximo de string |
| `[Precisao(P, E)]` | Precisão e escala para decimais |
| `[CriadoEm]` | Preenchido automaticamente no INSERT |
| `[AtualizadoEm]` | Preenchido no INSERT e UPDATE |
| `[CriadoPor]` | Identidade do criador |
| `[AtualizadoPor]` | Identidade do último atualizador |
| `[DeletadoEm]` | Soft delete — DELETE vira UPDATE |
| `[VersaoConcorrencia]` | Incrementado a cada UPDATE |
| `[TenantId]` | Preenchido pelo provedor de tenant |
| `[SomenteLeitura]` | Ignorado em INSERT/UPDATE |
| `[Ignorar]` | Não mapeado para o banco |

---

## Operadores de Filtro

| Operador | SQL gerado |
|---|---|
| `ofIgual` | `= :p` |
| `ofDiferente` | `<> :p` |
| `ofMaior` | `> :p` |
| `ofMenor` | `< :p` |
| `ofMaiorOuIgual` | `>= :p` |
| `ofMenorOuIgual` | `<= :p` |
| `ofContem` | `LIKE '%v%'` |
| `ofIniciacom` | `LIKE 'v%'` |
| `ofTerminaCom` | `LIKE '%v'` |
| `ofNulo` | `IS NULL` |
| `ofNaoNulo` | `IS NOT NULL` |
| `ofEm` | `IN (...)` |
| `ofNaoEm` | `NOT IN (...)` |

---

## Scaffolding

```bash
ScaffoldingCLI.exe \
  --banco=Firebird \
  --banco-dados=C:\sistema.fdb \
  --usuario=SYSDBA \
  --senha=masterkey \
  --prefixo-tabela=TB_ \
  --destino=.\src\Model \
  --prefixo-unit=Model
```

---

## Suporte a Bancos

| Banco | Versão | Paginação | RETURNING | Pool |
|---|---|---|---|---|
| Firebird | 2.5+ | `ROWS N TO M` | ✓ | Via FireDAC |
| MySQL | 5.7+ | `LIMIT N OFFSET M` | ✗ | Via FireDAC |
| MariaDB | 10.3+ | `LIMIT N OFFSET M` | ✗ | Via FireDAC |
