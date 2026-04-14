unit Exemplo04.UnitOfWork;

{
  Exemplo 04 — Unit of Work
  Demonstra: agrupamento de múltiplas operações em uma
  única transação com rollback automático em caso de falha.
  Padrão UoW: confirmação explícita ao final ou rollback
  automático ao sair do escopo.
}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions;

type

  // ---------------------------------------------------------------------------
  // Interface do Unit of Work
  // ---------------------------------------------------------------------------
  IOrmUnitOfWork = interface
    ['{F3A4B5C6-D7E8-9012-F012-345678901CDE}']
    procedure Confirmar;
    procedure Desfazer;
    function EstaAtivo: Boolean;
    property Sessao: IOrmSessao read GetSessao;
  end;

  // ---------------------------------------------------------------------------
  // Implementação — wrapper sobre transação ORM
  // ---------------------------------------------------------------------------
  TOrmUnitOfWork = class(TInterfacedObject, IOrmUnitOfWork)
  strict private
    FSessao: IOrmSessao;
    FTransacao: IOrmTransacao;
    FConfirmado: Boolean;
    FAtivo: Boolean;

    function GetSessao: IOrmSessao;
  public
    constructor Create(ASessao: IOrmSessao);
    destructor Destroy; override;

    procedure Confirmar;
    procedure Desfazer;
    function EstaAtivo: Boolean;
    property Sessao: IOrmSessao read GetSessao;
  end;

  // ---------------------------------------------------------------------------
  // Entidades para o exemplo
  // ---------------------------------------------------------------------------
  [Tabela('EX_CONTAS')]
  TConta = class
  private
    FId: Int64;
    FProprietario: string;
    FSaldo: Double;
    FAtualizadoEm: TDateTime;
  public
    [ChavePrimaria] [AutoIncremento] [Coluna('ID')]
    property Id: Int64 read FId write FId;
    [Coluna('PROPRIETARIO')] [Obrigatorio] [Tamanho(150)]
    property Proprietario: string read FProprietario write FProprietario;
    [Coluna('SALDO')] [Precisao(18,2)]
    property Saldo: Double read FSaldo write FSaldo;
    [Coluna('ATUALIZADO_EM')] [AtualizadoEm]
    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;
  end;

  [Tabela('EX_TRANSACOES')]
  TTransacaoFinanceira = class
  private
    FId: Int64;
    FContaOrigemId: Int64;
    FContaDestinoId: Int64;
    FValor: Double;
    FDescricao: string;
    FCriadoEm: TDateTime;
  public
    [ChavePrimaria] [AutoIncremento] [Coluna('ID')]
    property Id: Int64 read FId write FId;
    [Coluna('CONTA_ORIGEM_ID')] [Obrigatorio]
    property ContaOrigemId: Int64 read FContaOrigemId write FContaOrigemId;
    [Coluna('CONTA_DESTINO_ID')] [Obrigatorio]
    property ContaDestinoId: Int64 read FContaDestinoId write FContaDestinoId;
    [Coluna('VALOR')] [Precisao(18,2)]
    property Valor: Double read FValor write FValor;
    [Coluna('DESCRICAO')] [Tamanho(300)]
    property Descricao: string read FDescricao write FDescricao;
    [Coluna('CRIADO_EM')] [CriadoEm] [SomenteLeitura]
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
  end;

  // ---------------------------------------------------------------------------
  // Serviço de transferência — usa Unit of Work
  // ---------------------------------------------------------------------------
  TServicoTransferencia = class
  strict private
    FFabrica: IOrmFabricaSessao;
  public
    constructor Create(AFabrica: IOrmFabricaSessao);

    procedure Transferir(
      AIdOrigem, AIdDestino: Int64;
      AValor: Double;
      const ADescricao: string);
  end;

implementation

{ TOrmUnitOfWork }

constructor TOrmUnitOfWork.Create(ASessao: IOrmSessao);
begin
  inherited Create;

  if not Assigned(ASessao) then
    raise Exception.Create('Sessão não pode ser nil no Unit of Work.');

  FSessao    := ASessao;
  FTransacao := ASessao.IniciarTransacao;
  FConfirmado := False;
  FAtivo      := True;
end;

destructor TOrmUnitOfWork.Destroy;
begin
  // Rollback automático se não confirmado
  if FAtivo and not FConfirmado then
  begin
    try
      FTransacao.Rollback;
    except
      // Silencioso no destructor
    end;
  end;
  FTransacao := nil;
  FSessao    := nil;
  inherited Destroy;
end;

function TOrmUnitOfWork.GetSessao: IOrmSessao;
begin
  Result := FSessao;
end;

procedure TOrmUnitOfWork.Confirmar;
begin
  if not FAtivo then
    raise Exception.Create('Unit of Work já foi encerrado.');

  FTransacao.Commit;
  FConfirmado := True;
  FAtivo      := False;
end;

procedure TOrmUnitOfWork.Desfazer;
begin
  if not FAtivo then
    raise Exception.Create('Unit of Work já foi encerrado.');

  FTransacao.Rollback;
  FAtivo := False;
end;

function TOrmUnitOfWork.EstaAtivo: Boolean;
begin
  Result := FAtivo;
end;

{ TServicoTransferencia }

constructor TServicoTransferencia.Create(AFabrica: IOrmFabricaSessao);
begin
  inherited Create;
  FFabrica := AFabrica;
end;

procedure TServicoTransferencia.Transferir(
  AIdOrigem, AIdDestino: Int64;
  AValor: Double;
  const ADescricao: string);
var
  LUoW: TOrmUnitOfWork;
  LOrigem: TConta;
  LDestino: TConta;
  LTransacao: TTransacaoFinanceira;
begin
  if AValor <= 0 then
    raise Exception.Create('Valor de transferência deve ser positivo.');

  if AIdOrigem = AIdDestino then
    raise Exception.Create('Conta de origem e destino não podem ser iguais.');

  // Cria sessão e inicia Unit of Work
  LUoW := TOrmUnitOfWork.Create(FFabrica.CriarSessao);
  try
    // Busca as contas
    LOrigem  := LUoW.Sessao.BuscarPorId<TConta>(
      TValue.From<Int64>(AIdOrigem));
    LDestino := LUoW.Sessao.BuscarPorId<TConta>(
      TValue.From<Int64>(AIdDestino));
    try
      if not Assigned(LOrigem) then
        raise Exception.CreateFmt(
          'Conta de origem Id=%d não encontrada.', [AIdOrigem]);

      if not Assigned(LDestino) then
        raise Exception.CreateFmt(
          'Conta de destino Id=%d não encontrada.', [AIdDestino]);

      if LOrigem.Saldo < AValor then
        raise Exception.CreateFmt(
          'Saldo insuficiente. Disponível: R$ %.2f | Solicitado: R$ %.2f',
          [LOrigem.Saldo, AValor]);

      // Debita origem e credita destino
      LOrigem.Saldo  := LOrigem.Saldo - AValor;
      LDestino.Saldo := LDestino.Saldo + AValor;

      // Registra a transação financeira
      LTransacao              := TTransacaoFinanceira.Create;
      LTransacao.ContaOrigemId := AIdOrigem;
      LTransacao.ContaDestinoId := AIdDestino;
      LTransacao.Valor         := AValor;
      LTransacao.Descricao     := ADescricao;
      try
        // Três operações — atomicamente na mesma transação
        LUoW.Sessao.Atualizar(LOrigem);
        LUoW.Sessao.Atualizar(LDestino);
        LUoW.Sessao.Inserir(LTransacao);

        // Confirma toda a unidade de trabalho
        LUoW.Confirmar;

        Writeln(Format(
          '  ✓ Transferência concluída: R$ %.2f de [%d] para [%d]',
          [AValor, AIdOrigem, AIdDestino]));
        Writeln(Format(
          '    Saldo origem:  R$ %.2f → R$ %.2f',
          [LOrigem.Saldo + AValor, LOrigem.Saldo]));
        Writeln(Format(
          '    Saldo destino: R$ %.2f → R$ %.2f',
          [LDestino.Saldo - AValor, LDestino.Saldo]));
      finally
        LTransacao.Free;
      end;
    finally
      LOrigem.Free;
      LDestino.Free;
    end;
  except
    on E: Exception do
    begin
      // Rollback automático pelo destructor se não confirmado
      Writeln(Format('  ✗ Transferência cancelada: %s', [E.Message]));
      raise;
    end;
  end;
  LUoW.Free;
end;

end.
