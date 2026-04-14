unit Infra.ORM.Core.Exceptions;

{
  Responsabilidade:
    Hierarquia completa de exceções do ORM.
    Toda falha interna deve ser representada por uma destas classes,
    permitindo tratamento granular por contexto.

    Regra: preservar sempre a exceção original como InnerException
    e registrar em log antes de propagar.
}

interface

uses
  System.SysUtils;

type

  // ---------------------------------------------------------------------------
  // Raiz de todas as exceções do ORM
  // Permite captura genérica: except on E: EOrmExcecao do
  // ---------------------------------------------------------------------------
  EOrmExcecao = class(Exception)
  private
    FExcecaoInterna: Exception;
    FContexto: string;
  public
    constructor Create(const AMensagem: string); overload;
    constructor Create(const AMensagem: string;
      AExcecaoInterna: Exception); overload;
    constructor CreateFmt(const AFormato: string;
      const AArgs: array of const); overload;
    constructor CreateFmt(const AFormato: string;
      const AArgs: array of const;
      AExcecaoInterna: Exception); overload;

    property ExcecaoInterna: Exception read FExcecaoInterna;
    property Contexto: string read FContexto write FContexto;
  end;

  // ---------------------------------------------------------------------------
  // Erros relacionados a mapeamento de entidades e atributos
  // ---------------------------------------------------------------------------
  EOrmMapeamentoExcecao = class(EOrmExcecao)
  private
    FNomeEntidade: string;
    FNomePropriedade: string;
  public
    constructor Create(const ANomeEntidade, AMensagem: string); overload;
    constructor Create(const ANomeEntidade, ANomePropriedade,
      AMensagem: string); overload;

    property NomeEntidade: string read FNomeEntidade;
    property NomePropriedade: string read FNomePropriedade;
  end;

  // ---------------------------------------------------------------------------
  // Erros relacionados a leitura e processamento de metadados via RTTI
  // ---------------------------------------------------------------------------
  EOrmMetadadoExcecao = class(EOrmExcecao)
  private
    FTipoClasse: string;
  public
    constructor Create(const ATipoClasse, AMensagem: string); overload;
    constructor Create(const ATipoClasse, AMensagem: string;
      AExcecaoInterna: Exception); overload;

    property TipoClasse: string read FTipoClasse;
  end;

  // ---------------------------------------------------------------------------
  // Erros de conexão com banco de dados
  // ---------------------------------------------------------------------------
  EOrmConexaoExcecao = class(EOrmExcecao)
  private
    FStringConexao: string;
  public
    constructor Create(const AMensagem: string;
      AExcecaoInterna: Exception = nil); overload;
    constructor Create(const AStringConexao, AMensagem: string;
      AExcecaoInterna: Exception = nil); overload;

    property StringConexao: string read FStringConexao;
  end;

  // ---------------------------------------------------------------------------
  // Erros de transação (begin, commit, rollback)
  // ---------------------------------------------------------------------------
  EOrmTransacaoExcecao = class(EOrmExcecao)
  public
    constructor Create(const AMensagem: string;
      AExcecaoInterna: Exception = nil);
  end;

  // ---------------------------------------------------------------------------
  // Erros na execução de comandos SQL
  // ---------------------------------------------------------------------------
  EOrmComandoExcecao = class(EOrmExcecao)
  private
    FSQL: string;
  public
    constructor Create(const ASQL, AMensagem: string;
      AExcecaoInterna: Exception = nil);

    property SQL: string read FSQL;
  end;

  // ---------------------------------------------------------------------------
  // Erros na construção ou execução de consultas
  // ---------------------------------------------------------------------------
  EOrmConsultaExcecao = class(EOrmExcecao)
  private
    FNomeEntidade: string;
  public
    constructor Create(const ANomeEntidade, AMensagem: string;
      AExcecaoInterna: Exception = nil);

    property NomeEntidade: string read FNomeEntidade;
  end;

  // ---------------------------------------------------------------------------
  // Erros na persistência (insert, update, delete)
  // ---------------------------------------------------------------------------
  EOrmPersistenciaExcecao = class(EOrmExcecao)
  private
    FNomeEntidade: string;
    FOperacao: string;
  public
    constructor Create(const ANomeEntidade, AOperacao,
      AMensagem: string; AExcecaoInterna: Exception = nil);

    property NomeEntidade: string read FNomeEntidade;
    property Operacao: string read FOperacao;
  end;

  // ---------------------------------------------------------------------------
  // Erro em interceptador de eventos
  // ---------------------------------------------------------------------------
  EOrmInterceptadorExcecao = class(EOrmExcecao)
  public
    constructor Create(
      const ANomeInterceptador: string;
      const AMensagem: string;
      AInnerException: Exception = nil); reintroduce;
  end;

  // ---------------------------------------------------------------------------
  // Sinaliza que DELETE deve ser convertido em soft delete (UPDATE)
  // Lançada intencionalmente pelo TInterceptadorAuditoria
  // Capturada pelo TExecutorPersistencia para trocar a operação
  // ---------------------------------------------------------------------------
  EOrmSoftDeleteExcecao = class(EOrmExcecao)
  public
    constructor Create(
      const ANomeClasse: string;
      const AMensagem: string); reintroduce;
  end;

  // ---------------------------------------------------------------------------
  // Erro de concorrência — nenhuma linha afetada pelo UPDATE
  // Indica que o registro foi modificado ou excluído por outra sessão
  // ---------------------------------------------------------------------------
  EOrmConcorrenciaExcecao = class(EOrmExcecao)
  public
    NomeEntidade: string;
    ValorChave: string;

    constructor Create(
      const ANomeEntidade: string;
      const AValorChave: string); reintroduce;
  end;
  // ---------------------------------------------------------------------------
  // Erros de validação de entidade antes de persistir
  // ---------------------------------------------------------------------------
  EOrmValidacaoExcecao = class(EOrmExcecao)
  private
    FNomeEntidade: string;
    FCampo: string;
  public
    constructor Create(const ANomeEntidade, ACampo,
      AMensagem: string); overload;
    constructor Create(const ANomeEntidade,
      AMensagem: string); overload;

    property NomeEntidade: string read FNomeEntidade;
    property Campo: string read FCampo;
  end;

  // ---------------------------------------------------------------------------
  // Erros de configuração/setup do ORM
  // ---------------------------------------------------------------------------
  EOrmConfiguracaoExcecao = class(EOrmExcecao)
  public
    constructor Create(const AMensagem: string);
  end;

  // ---------------------------------------------------------------------------
  // Erros relacionados ao dialeto SQL
  // ---------------------------------------------------------------------------
  EOrmDialetoExcecao = class(EOrmExcecao)
  private
    FNomeDialeto: string;
  public
    constructor Create(const ANomeDialeto, AMensagem: string;
      AExcecaoInterna: Exception = nil);

    property NomeDialeto: string read FNomeDialeto;
  end;

  // ---------------------------------------------------------------------------
  // Erros relacionados a geradores de valor (UUID, GUID, etc)
  // ---------------------------------------------------------------------------
  EOrmGeradorExcecao = class(EOrmExcecao)
  public
    constructor Create(const AMensagem: string;
      AExcecaoInterna: Exception = nil);
  end;

implementation

{ EOrmExcecao }

constructor EOrmExcecao.Create(const AMensagem: string);
begin
  inherited Create(AMensagem);
  FExcecaoInterna := nil;
  FContexto := string.Empty;
end;

constructor EOrmExcecao.Create(const AMensagem: string;
  AExcecaoInterna: Exception);
begin
  inherited Create(AMensagem);
  FExcecaoInterna := AExcecaoInterna;
  FContexto := string.Empty;
end;

constructor EOrmExcecao.CreateFmt(const AFormato: string;
  const AArgs: array of const);
begin
  inherited CreateFmt(AFormato, AArgs);
  FExcecaoInterna := nil;
  FContexto := string.Empty;
end;

constructor EOrmExcecao.CreateFmt(const AFormato: string;
  const AArgs: array of const; AExcecaoInterna: Exception);
begin
  inherited CreateFmt(AFormato, AArgs);
  FExcecaoInterna := AExcecaoInterna;
  FContexto := string.Empty;
end;

{ EOrmMapeamentoExcecao }

constructor EOrmMapeamentoExcecao.Create(const ANomeEntidade,
  AMensagem: string);
begin
  inherited CreateFmt('[Mapeamento] Entidade: %s → %s',
    [ANomeEntidade, AMensagem]);
  FNomeEntidade := ANomeEntidade;
  FNomePropriedade := string.Empty;
end;

constructor EOrmMapeamentoExcecao.Create(const ANomeEntidade,
  ANomePropriedade, AMensagem: string);
begin
  inherited CreateFmt('[Mapeamento] Entidade: %s | Propriedade: %s → %s',
    [ANomeEntidade, ANomePropriedade, AMensagem]);
  FNomeEntidade := ANomeEntidade;
  FNomePropriedade := ANomePropriedade;
end;

{ EOrmMetadadoExcecao }

constructor EOrmMetadadoExcecao.Create(const ATipoClasse,
  AMensagem: string);
begin
  inherited CreateFmt('[Metadado] Tipo: %s → %s',
    [ATipoClasse, AMensagem]);
  FTipoClasse := ATipoClasse;
end;

constructor EOrmMetadadoExcecao.Create(const ATipoClasse,
  AMensagem: string; AExcecaoInterna: Exception);
begin
  inherited CreateFmt('[Metadado] Tipo: %s → %s',
    [ATipoClasse, AMensagem], AExcecaoInterna);
  FTipoClasse := ATipoClasse;
end;

{ EOrmConexaoExcecao }

constructor EOrmConexaoExcecao.Create(const AMensagem: string;
  AExcecaoInterna: Exception);
begin
  inherited Create(Format('[Conexão] %s', [AMensagem]), AExcecaoInterna);
  FStringConexao := string.Empty;
end;

constructor EOrmConexaoExcecao.Create(const AStringConexao,
  AMensagem: string; AExcecaoInterna: Exception);
begin
  inherited Create(Format('[Conexão] %s', [AMensagem]), AExcecaoInterna);
  FStringConexao := AStringConexao;
end;

{ EOrmTransacaoExcecao }

constructor EOrmTransacaoExcecao.Create(const AMensagem: string;
  AExcecaoInterna: Exception);
begin
  inherited Create(Format('[Transação] %s', [AMensagem]), AExcecaoInterna);
end;

{ EOrmComandoExcecao }

constructor EOrmComandoExcecao.Create(const ASQL, AMensagem: string;
  AExcecaoInterna: Exception);
begin
  inherited Create(Format('[Comando] %s', [AMensagem]), AExcecaoInterna);
  FSQL := ASQL;
end;

{ EOrmConsultaExcecao }

constructor EOrmConsultaExcecao.Create(const ANomeEntidade,
  AMensagem: string; AExcecaoInterna: Exception);
begin
  inherited CreateFmt('[Consulta] Entidade: %s → %s',
    [ANomeEntidade, AMensagem], AExcecaoInterna);
  FNomeEntidade := ANomeEntidade;
end;

{ EOrmPersistenciaExcecao }

constructor EOrmPersistenciaExcecao.Create(const ANomeEntidade,
  AOperacao, AMensagem: string; AExcecaoInterna: Exception);
begin
  inherited CreateFmt('[Persistência] Entidade: %s | Operação: %s → %s',
    [ANomeEntidade, AOperacao, AMensagem], AExcecaoInterna);
  FNomeEntidade := ANomeEntidade;
  FOperacao := AOperacao;
end;

{ EOrmInterceptadorExcecao }

constructor EOrmInterceptadorExcecao.Create(
  const ANomeInterceptador: string;
  const AMensagem: string;
  AInnerException: Exception);
begin
  inherited Create('Interceptador[' + ANomeInterceptador + ']', AMensagem);
end;

{ EOrmSoftDeleteExcecao }

constructor EOrmSoftDeleteExcecao.Create(
  const ANomeClasse: string;
  const AMensagem: string);
begin
  inherited Create(ANomeClasse, AMensagem);
end;


{ EOrmConcorrenciaExcecao }

constructor EOrmConcorrenciaExcecao.Create(
  const ANomeEntidade: string;
  const AValorChave: string);
begin
  NomeEntidade := ANomeEntidade;
  ValorChave   := AValorChave;
  inherited Create(
    ANomeEntidade,
    Format(
      'Nenhuma linha afetada ao atualizar "%s" com chave "%s". ' +
      'O registro pode ter sido modificado ou excluído por outra sessão.',
      [ANomeEntidade, AValorChave]));
end;

{ EOrmValidacaoExcecao }

constructor EOrmValidacaoExcecao.Create(const ANomeEntidade,
  ACampo, AMensagem: string);
begin
  inherited CreateFmt('[Validação] Entidade: %s | Campo: %s → %s',
    [ANomeEntidade, ACampo, AMensagem]);
  FNomeEntidade := ANomeEntidade;
  FCampo := ACampo;
end;

constructor EOrmValidacaoExcecao.Create(const ANomeEntidade,
  AMensagem: string);
begin
  inherited CreateFmt('[Validação] Entidade: %s → %s',
    [ANomeEntidade, AMensagem]);
  FNomeEntidade := ANomeEntidade;
  FCampo := string.Empty;
end;

{ EOrmConfiguracaoExcecao }

constructor EOrmConfiguracaoExcecao.Create(const AMensagem: string);
begin
  inherited Create(Format('[Configuração] %s', [AMensagem]));
end;

{ EOrmDialetoExcecao }

constructor EOrmDialetoExcecao.Create(const ANomeDialeto,
  AMensagem: string; AExcecaoInterna: Exception);
begin
  inherited CreateFmt('[Dialeto] %s → %s',
    [ANomeDialeto, AMensagem], AExcecaoInterna);
  FNomeDialeto := ANomeDialeto;
end;

{ EOrmGeradorExcecao }

constructor EOrmGeradorExcecao.Create(const AMensagem: string;
  AExcecaoInterna: Exception);
begin
  inherited Create(Format('[Gerador] %s', [AMensagem]), AExcecaoInterna);
end;

end.
