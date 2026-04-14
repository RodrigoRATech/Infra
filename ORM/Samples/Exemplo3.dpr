unit Exemplo03.Repositorio;

{
  Exemplo 03 — Repositório Genérico
  Demonstra: padrão Repository sobre a sessão ORM.
  O repositório encapsula consultas específicas da entidade,
  mantendo a camada de domínio desacoplada do ORM.
}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts;

type

  // ---------------------------------------------------------------------------
  // Repositório genérico — CRUD básico para qualquer entidade
  // ---------------------------------------------------------------------------
  IRepositorio<T: class, constructor> = interface
    ['{D1E2F3A4-B5C6-7890-DEF0-123456789ABC}']
    function BuscarPorId(const AId: TValue): T;
    function Listar: TObjectList<T>;
    procedure Inserir(AEntidade: T);
    procedure Atualizar(AEntidade: T);
    procedure Deletar(AEntidade: T);
    function Consultar: IOrmConsulta<T>;
  end;

  TRepositorioBase<T: class, constructor> = class(
    TInterfacedObject, IRepositorio<T>)
  strict protected
    FSessao: IOrmSessao;
  public
    constructor Create(ASessao: IOrmSessao);
    function BuscarPorId(const AId: TValue): T;
    function Listar: TObjectList<T>;
    procedure Inserir(AEntidade: T);
    procedure Atualizar(AEntidade: T);
    procedure Deletar(AEntidade: T);
    function Consultar: IOrmConsulta<T>;
  end;

  // ---------------------------------------------------------------------------
  // Entidade de domínio (sem atributos ORM — separação limpa)
  // ---------------------------------------------------------------------------
  TClienteDominio = class
  private
    FId: Int64;
    FNome: string;
    FEmail: string;
    FSaldo: Double;
    FAtivo: Boolean;
  public
    property Id: Int64 read FId write FId;
    property Nome: string read FNome write FNome;
    property Email: string read FEmail write FEmail;
    property Saldo: Double read FSaldo write FSaldo;
    property Ativo: Boolean read FAtivo write FAtivo;

    // Factory method — regras de negócio
    class function Novo(
      const ANome, AEmail: string;
      ASaldo: Double): TClienteDominio;

    procedure Creditar(AValor: Double);
    procedure Debitar(AValor: Double);
    procedure Ativar;
    procedure Desativar;
  end;

  // ---------------------------------------------------------------------------
  // Repositório específico de clientes com queries de negócio
  // ---------------------------------------------------------------------------
  IRepositorioCliente = interface(IRepositorio<TClienteDominio>)
    ['{E2F3A4B5-C6D7-8901-EF01-234567890BCD}']
    function BuscarPorEmail(const AEmail: string): TClienteDominio;
    function ListarAtivos: TObjectList<TClienteDominio>;
    function ListarComSaldoMinimo(ASaldo: Double): TObjectList<TClienteDominio>;
    function ExisteEmail(const AEmail: string): Boolean;
    function TotalAtivos: Int64;
  end;

  TRepositorioCliente = class(
    TRepositorioBase<TClienteDominio>, IRepositorioCliente)
  public
    function BuscarPorEmail(const AEmail: string): TClienteDominio;
    function ListarAtivos: TObjectList<TClienteDominio>;
    function ListarComSaldoMinimo(ASaldo: Double): TObjectList<TClienteDominio>;
    function ExisteEmail(const AEmail: string): Boolean;
    function TotalAtivos: Int64;
  end;

implementation

{ TRepositorioBase<T> }

constructor TRepositorioBase<T>.Create(ASessao: IOrmSessao);
begin
  inherited Create;

  if not Assigned(ASessao) then
    raise Exception.Create(
      'Sessão não pode ser nil no repositório.');

  FSessao := ASessao;
end;

function TRepositorioBase<T>.BuscarPorId(const AId: TValue): T;
begin
  Result := FSessao.BuscarPorId<T>(AId);
end;

function TRepositorioBase<T>.Listar: TObjectList<T>;
begin
  Result := FSessao.Listar<T>;
end;

procedure TRepositorioBase<T>.Inserir(AEntidade: T);
begin
  FSessao.Inserir(AEntidade);
end;

procedure TRepositorioBase<T>.Atualizar(AEntidade: T);
begin
  FSessao.Atualizar(AEntidade);
end;

procedure TRepositorioBase<T>.Deletar(AEntidade: T);
begin
  FSessao.Deletar(AEntidade);
end;

function TRepositorioBase<T>.Consultar: IOrmConsulta<T>;
begin
  Result := FSessao.Consultar<T>;
end;

{ TClienteDominio }

class function TClienteDominio.Novo(
  const ANome, AEmail: string;
  ASaldo: Double): TClienteDominio;
begin
  if ANome.Trim.IsEmpty then
    raise Exception.Create('Nome do cliente é obrigatório.');

  if ASaldo < 0 then
    raise Exception.Create('Saldo inicial não pode ser negativo.');

  Result        := TClienteDominio.Create;
  Result.FNome  := ANome.Trim;
  Result.FEmail := AEmail.Trim.ToLower;
  Result.FSaldo := ASaldo;
  Result.FAtivo := True;
end;

procedure TClienteDominio.Creditar(AValor: Double);
begin
  if AValor <= 0 then
    raise Exception.Create('Valor de crédito deve ser positivo.');
  FSaldo := FSaldo + AValor;
end;

procedure TClienteDominio.Debitar(AValor: Double);
begin
  if AValor <= 0 then
    raise Exception.Create('Valor de débito deve ser positivo.');
  if AValor > FSaldo then
    raise Exception.Create(
      Format('Saldo insuficiente. Saldo: %.2f | Débito: %.2f',
        [FSaldo, AValor]));
  FSaldo := FSaldo - AValor;
end;

procedure TClienteDominio.Ativar;
begin
  FAtivo := True;
end;

procedure TClienteDominio.Desativar;
begin
  FAtivo := False;
end;

{ TRepositorioCliente }

function TRepositorioCliente.BuscarPorEmail(
  const AEmail: string): TClienteDominio;
begin
  Result := Consultar
    .Onde('EMAIL', ofIgual, TValue.From<string>(AEmail.ToLower))
    .PrimeiroOuNulo;
end;

function TRepositorioCliente.ListarAtivos: TObjectList<TClienteDominio>;
begin
  Result := Consultar
    .Onde('ATIVO', ofIgual, TValue.From<Boolean>(True))
    .OrdenarPor('NOME')
    .Listar;
end;

function TRepositorioCliente.ListarComSaldoMinimo(
  ASaldo: Double): TObjectList<TClienteDominio>;
begin
  Result := Consultar
    .Onde('ATIVO', ofIgual, TValue.From<Boolean>(True))
    .E('SALDO', ofMaiorOuIgual, TValue.From<Double>(ASaldo))
    .OrdenarPor('SALDO', doDescendente)
    .Listar;
end;

function TRepositorioCliente.ExisteEmail(const AEmail: string): Boolean;
begin
  Result := Consultar
    .Onde('EMAIL', ofIgual, TValue.From<string>(AEmail.ToLower))
    .Existe;
end;

function TRepositorioCliente.TotalAtivos: Int64;
begin
  Result := Consultar
    .Onde('ATIVO', ofIgual, TValue.From<Boolean>(True))
    .Contar;
end;

end.
