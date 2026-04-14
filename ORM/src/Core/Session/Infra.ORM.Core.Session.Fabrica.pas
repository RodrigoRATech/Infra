unit Infra.ORM.Core.Session.Fabrica;

{
  Responsabilidade:
    Fábrica de sessões ORM.
    Ponto de configuração e entrada da aplicação no ORM.
    Deve ser configurada uma vez no bootstrap e reutilizada.

    É thread-safe para criar sessões concorrentemente.
    Cada sessão criada é independente e isolada.
}

interface

uses
  System.SysUtils,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions,
  Infra.ORM.Core.Logging.Contrato,
  Infra.ORM.Core.Events.Contratos,
  Infra.ORM.Core.Metadata.Cache,
  Infra.ORM.Core.Session.Sessao;

type

  // ---------------------------------------------------------------------------
  // Builder de configuração da fábrica
  // ---------------------------------------------------------------------------
  TOrmFabricaSessaoBuilder = class;

  TOrmFabricaSessao = class(TInterfacedObject, IOrmFabricaSessao)
  strict private
    FFabricaConexao: IOrmFabricaConexao;
    FDialeto: IOrmDialeto;
    FLogger: IOrmLogger;
    FDespachante: IOrmDespachante;
    FProvedorIdentidade: IOrmProvedorIdentidade;

  public
    constructor Create(
      AFabricaConexao: IOrmFabricaConexao;
      ADialeto: IOrmDialeto;
      ALogger: IOrmLogger;
      ADespachante: IOrmDespachante;
      AProvedorIdentidade: IOrmProvedorIdentidade);

    // IOrmFabricaSessao
    function CriarSessao: IOrmSessao;

    // Entrada para o builder fluente
    class function Configurar: TOrmFabricaSessaoBuilder;
  end;

  // ---------------------------------------------------------------------------
  // Builder fluente para configuração da fábrica
  // ---------------------------------------------------------------------------
  TOrmFabricaSessaoBuilder = class
  strict private
    FFabricaConexao: IOrmFabricaConexao;
    FDialeto: IOrmDialeto;
    FLogger: IOrmLogger;
    FDespachante: IOrmDespachante;
    FProvedorIdentidade: IOrmProvedorIdentidade;

  public
    function UsarConexao(
      AFabrica: IOrmFabricaConexao): TOrmFabricaSessaoBuilder;

    function UsarDialeto(
      ADialeto: IOrmDialeto): TOrmFabricaSessaoBuilder;

    function UsarLogger(
      ALogger: IOrmLogger): TOrmFabricaSessaoBuilder;

    function UsarDespachante(
      ADespachante: IOrmDespachante): TOrmFabricaSessaoBuilder;

    function UsarProvedorIdentidade(
      AProvedor: IOrmProvedorIdentidade): TOrmFabricaSessaoBuilder;

    function Construir: IOrmFabricaSessao;
  end;

implementation

{ TOrmFabricaSessao }

constructor TOrmFabricaSessao.Create(
  AFabricaConexao: IOrmFabricaConexao;
  ADialeto: IOrmDialeto;
  ALogger: IOrmLogger;
  ADespachante: IOrmDespachante;
  AProvedorIdentidade: IOrmProvedorIdentidade);
begin
  inherited Create;

  if not Assigned(AFabricaConexao) then
    raise EOrmConfiguracaoExcecao.Create(
      'FabricaConexao é obrigatória na configuração do ORM.');

  if not Assigned(ADialeto) then
    raise EOrmConfiguracaoExcecao.Create(
      'Dialeto é obrigatório na configuração do ORM.');

  FFabricaConexao     := AFabricaConexao;
  FDialeto            := ADialeto;
  FLogger             := ALogger ?? TLoggerNulo.Create;
  FDespachante        := ADespachante;
  FProvedorIdentidade := AProvedorIdentidade;
end;

function TOrmFabricaSessao.CriarSessao: IOrmSessao;
var
  LConexao: IOrmConexao;
begin
  // Cada sessão recebe sua própria conexão física — nunca compartilhada
  LConexao := FFabricaConexao.CriarConexao;

  Result := TOrmSessao.Create(
    LConexao,
    FDialeto,
    FLogger,
    FDespachante,
    FProvedorIdentidade);
end;

class function TOrmFabricaSessao.Configurar: TOrmFabricaSessaoBuilder;
begin
  Result := TOrmFabricaSessaoBuilder.Create;
end;

{ TOrmFabricaSessaoBuilder }

function TOrmFabricaSessaoBuilder.UsarConexao(
  AFabrica: IOrmFabricaConexao): TOrmFabricaSessaoBuilder;
begin
  FFabricaConexao := AFabrica;
  Result := Self;
end;

function TOrmFabricaSessaoBuilder.UsarDialeto(
  ADialeto: IOrmDialeto): TOrmFabricaSessaoBuilder;
begin
  FDialeto := ADialeto;
  Result := Self;
end;

function TOrmFabricaSessaoBuilder.UsarLogger(
  ALogger: IOrmLogger): TOrmFabricaSessaoBuilder;
begin
  FLogger := ALogger;
  Result := Self;
end;

function TOrmFabricaSessaoBuilder.UsarDespachante(
  ADespachante: IOrmDespachante): TOrmFabricaSessaoBuilder;
begin
  FDespachante := ADespachante;
  Result := Self;
end;

function TOrmFabricaSessaoBuilder.UsarProvedorIdentidade(
  AProvedor: IOrmProvedorIdentidade): TOrmFabricaSessaoBuilder;
begin
  FProvedorIdentidade := AProvedor;
  Result := Self;
end;

function TOrmFabricaSessaoBuilder.Construir: IOrmFabricaSessao;
begin
  Result := TOrmFabricaSessao.Create(
    FFabricaConexao,
    FDialeto,
    FLogger,
    FDespachante,
    FProvedorIdentidade);
end;

end.
