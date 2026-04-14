unit Infra.ORM.Scaffolding.Schema.Contratos;

{
  Responsabilidade:
    Contratos e modelos de dados do schema do banco.
    Agnóstico de banco — preenchido pelos leitores específicos.
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos;

type

  // ---------------------------------------------------------------------------
  // Modelo de uma coluna lida do schema do banco
  // ---------------------------------------------------------------------------
  IOrmColunaSchema = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function NomeColuna: string;
    function TipoSQL: string;
    function TamanhoPrecisao: Integer;
    function TamanhoEscala: Integer;
    function Nullable: Boolean;
    function EhChavePrimaria: Boolean;
    function EhAutoIncremento: Boolean;
    function ValorDefault: string;
    function Posicao: Integer;
  end;

  // ---------------------------------------------------------------------------
  // Modelo de uma tabela lida do schema do banco
  // ---------------------------------------------------------------------------
  IOrmTabelaSchema = interface
    ['{B2C3D4E5-F6A7-8901-BCDE-F12345678901}']
    function NomeTabela: string;
    function NomeSchema: string;
    function Colunas: TArray<IOrmColunaSchema>;
    function ChavesPrimarias: TArray<string>;
    function Descricao: string;
  end;

  // ---------------------------------------------------------------------------
  // Contrato do leitor de schema — implementado por banco
  // ---------------------------------------------------------------------------
  IOrmLeitorSchema = interface
    ['{C3D4E5F6-A7B8-9012-CDEF-123456789012}']
    function LerTabelas: TArray<IOrmTabelaSchema>;
    function LerTabela(const ANomeTabela: string): IOrmTabelaSchema;
    function ListarNomesTabelas: TArray<string>;
  end;

  // ---------------------------------------------------------------------------
  // Callback de progresso do scaffolding
  // ---------------------------------------------------------------------------
  TProgressoScaffolding = reference to procedure(
    const ATabela: string;
    AAtual, ATotal: Integer;
    const AMensagem: string);

  // ---------------------------------------------------------------------------
  // Implementações concretas dos modelos
  // ---------------------------------------------------------------------------
  TColunaSchema = class(TInterfacedObject, IOrmColunaSchema)
  public
    FNomeColuna: string;
    FTipoSQL: string;
    FTamanhoPrecisao: Integer;
    FTamanhoEscala: Integer;
    FNullable: Boolean;
    FEhChavePrimaria: Boolean;
    FEhAutoIncremento: Boolean;
    FValorDefault: string;
    FPosicao: Integer;

    function NomeColuna: string;
    function TipoSQL: string;
    function TamanhoPrecisao: Integer;
    function TamanhoEscala: Integer;
    function Nullable: Boolean;
    function EhChavePrimaria: Boolean;
    function EhAutoIncremento: Boolean;
    function ValorDefault: string;
    function Posicao: Integer;
  end;

  TTabelaSchema = class(TInterfacedObject, IOrmTabelaSchema)
  public
    FNomeTabela: string;
    FNomeSchema: string;
    FColunas: TArray<IOrmColunaSchema>;
    FChavesPrimarias: TArray<string>;
    FDescricao: string;

    function NomeTabela: string;
    function NomeSchema: string;
    function Colunas: TArray<IOrmColunaSchema>;
    function ChavesPrimarias: TArray<string>;
    function Descricao: string;
  end;

implementation

{ TColunaSchema }

function TColunaSchema.NomeColuna: string;      begin Result := FNomeColuna;      end;
function TColunaSchema.TipoSQL: string;         begin Result := FTipoSQL;          end;
function TColunaSchema.TamanhoPrecisao: Integer;begin Result := FTamanhoPrecisao;  end;
function TColunaSchema.TamanhoEscala: Integer;  begin Result := FTamanhoEscala;    end;
function TColunaSchema.Nullable: Boolean;       begin Result := FNullable;         end;
function TColunaSchema.EhChavePrimaria: Boolean;begin Result := FEhChavePrimaria;  end;
function TColunaSchema.EhAutoIncremento: Boolean;begin Result := FEhAutoIncremento; end;
function TColunaSchema.ValorDefault: string;    begin Result := FValorDefault;     end;
function TColunaSchema.Posicao: Integer;        begin Result := FPosicao;          end;

{ TTabelaSchema }

function TTabelaSchema.NomeTabela: string;              begin Result := FNomeTabela;      end;
function TTabelaSchema.NomeSchema: string;              begin Result := FNomeSchema;      end;
function TTabelaSchema.Colunas: TArray<IOrmColunaSchema>;begin Result := FColunas;        end;
function TTabelaSchema.ChavesPrimarias: TArray<string>; begin Result := FChavesPrimarias; end;
function TTabelaSchema.Descricao: string;               begin Result := FDescricao;       end;

end.
