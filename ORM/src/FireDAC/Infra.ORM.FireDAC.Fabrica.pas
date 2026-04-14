unit Infra.ORM.FireDAC.Fabrica;

{
  Responsabilidade:
    Implementação de IOrmFabricaConexao para FireDAC.
    Cria conexões isoladas por sessão com a configuração fornecida.
    Thread-safe para criação concorrente de sessões.
}

interface

uses
  System.SysUtils,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions,
  Infra.ORM.FireDAC.Configuracao,
  Infra.ORM.FireDAC.Conexao;

type

  TFabricaConexaoFireDAC = class(TInterfacedObject, IOrmFabricaConexao)
  strict private
    FConfig: TConfiguracaoConexao;

  public
    // Recebe ownership da config
    constructor Create(AConfig: TConfiguracaoConexao);
    destructor Destroy; override;

    // IOrmFabricaConexao
    function CriarConexao: IOrmConexao;
    function TipoBanco: TTipoBancoDados;
  end;

implementation

{ TFabricaConexaoFireDAC }

constructor TFabricaConexaoFireDAC.Create(AConfig: TConfiguracaoConexao);
begin
  inherited Create;

  if not Assigned(AConfig) then
    raise EOrmConfiguracaoExcecao.Create(
      'Configuração não pode ser nil na fábrica FireDAC.');

  FConfig := AConfig;
end;

destructor TFabricaConexaoFireDAC.Destroy;
begin
  FConfig.Free;
  inherited Destroy;
end;

function TFabricaConexaoFireDAC.CriarConexao: IOrmConexao;
begin
  // Cada chamada cria uma conexão física independente
  // Thread-safe: sem estado compartilhado entre chamadas
  Result := TConexaoFireDAC.Create(FConfig);
end;

function TFabricaConexaoFireDAC.TipoBanco: TTipoBancoDados;
begin
  Result := FConfig.TipoBanco;
end;

end.
