unit Model.Clientes;

{
  Entidade gerada automaticamente pelo Infra.ORM.Scaffolding
  Tabela de origem: CLIENTES
  Data de geração: 12/04/2026 10:59:19
  ATENÇÃO: Alterações manuais serão perdidas na próxima regeneração.
}

interface

uses
  System.SysUtils,
  Infra.ORM.Core.Mapping.Atributos;

type

  [Tabela('CLIENTES')]
  TClientes = class
  strict private
    FId: Integer;
    FNome: string;
    FEmail: string;
    FCriadoEm: TDateTime;
    FAtualizadoEm: TDateTime;
  public

    [ChavePrimaria]
    [AutoIncremento]
    [Coluna('ID')]
    property Id: Integer read FId write FId;

    [Coluna('NOME')]
    [Obrigatorio]
    [Tamanho(150)]
    property Nome: string read FNome write FNome;

    [Coluna('EMAIL')]
    [Tamanho(200)]
    property Email: string read FEmail write FEmail;

    [Coluna('CRIADO_EM')]
    [CriadoEm]
    [SomenteLeitura]
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;

    [Coluna('ATUALIZADO_EM')]
    [AtualizadoEm]
    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;

  end;

implementation

end.
