unit Infra.ORM.Core.Metadata.Propriedade;

{
  Responsabilidade:
    Implementação concreta de IOrmMetadadoPropriedade.
    Encapsula todos os metadados de uma property mapeada,
    incluindo accessor RTTI cacheado para leitura/escrita de valores.

    Regra: esta classe é construída pelo resolvedor e é imutável
    após a construção. O accessor RTTI é cacheado na instância.
}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions;

type

  // ---------------------------------------------------------------------------
  // Implementação concreta de IOrmMetadadoPropriedade
  // ---------------------------------------------------------------------------
  TMetadadoPropriedade = class(TInterfacedObject, IOrmMetadadoPropriedade)
  strict private
    FNome: string;
    FNomeColuna: string;
    FTipoColuna: TTipoColuna;
    FTamanho: Integer;
    FPrecisao: Integer;
    FEscala: Integer;
    FEhChavePrimaria: Boolean;
    FEhNulavel: Boolean;
    FEhSomenteLeitura: Boolean;
    FEhObrigatorio: Boolean;
    FEhAutoIncremento: Boolean;
    FEstrategiaChave: TEstategiaChave;
    FOrdemChave: Integer;
    FEhCriadoEm: Boolean;
    FEhAtualizadoEm: Boolean;
    FEhCriadoPor: Boolean;
    FEhAtualizadoPor: Boolean;
    FEhDeletadoEm: Boolean;
    FEhVersao: Boolean;
    FEhTenantId: Boolean;

    // Accessor RTTI cacheado — nunca nulo após construção bem-sucedida
    FRttiProperty: TRttiProperty;

  public
    constructor Create(
      ARttiProperty: TRttiProperty;
      const ANomeColuna: string;
      ATipoColuna: TTipoColuna;
      ATamanho, APrecisao, AEscala: Integer;
      AEhNulavel: Boolean);

    // IOrmMetadadoPropriedade
    function Nome: string;
    function NomeColuna: string;
    function TipoColuna: TTipoColuna;
    function Tamanho: Integer;
    function Precisao: Integer;
    function Escala: Integer;
    function EhChavePrimaria: Boolean;
    function EhNulavel: Boolean;
    function EhSomenteLeitura: Boolean;
    function EhObrigatorio: Boolean;
    function EhAutoIncremento: Boolean;
    function EstrategiaChave: TEstategiaChave;
    function OrdemChave: Integer;
    function ObterValor(AInstancia: TObject): TValue;
    procedure DefinirValor(AInstancia: TObject; const AValor: TValue);

    // Flags de rastreamento (preenchidos pelo resolvedor)
    property EhCriadoEm: Boolean read FEhCriadoEm write FEhCriadoEm;
    property EhAtualizadoEm: Boolean read FEhAtualizadoEm write FEhAtualizadoEm;
    property EhCriadoPor: Boolean read FEhCriadoPor write FEhCriadoPor;
    property EhAtualizadoPor: Boolean read FEhAtualizadoPor write FEhAtualizadoPor;
    property EhDeletadoEm: Boolean read FEhDeletadoEm write FEhDeletadoEm;
    property EhVersao: Boolean read FEhVersao write FEhVersao;
    property EhTenantId: Boolean read FEhTenantId write FEhTenantId;

    // Escrita dos flags de chave (pelo resolvedor)
    procedure DefinirComoChavePrimaria(AOrdem: Integer;
      AEstrategia: TEstategiaChave; AAutoIncremento: Boolean);

    procedure DefinirComoSomenteLeitura;
    procedure DefinirComoObrigatorio;
  end;

implementation

{ TMetadadoPropriedade }

constructor TMetadadoPropriedade.Create(
  ARttiProperty: TRttiProperty;
  const ANomeColuna: string;
  ATipoColuna: TTipoColuna;
  ATamanho, APrecisao, AEscala: Integer;
  AEhNulavel: Boolean);
begin
  inherited Create;

  if not Assigned(ARttiProperty) then
    raise EOrmMetadadoExcecao.Create(
      'TMetadadoPropriedade',
      'TRttiProperty não pode ser nil na construção do metadado.');

  FRttiProperty      := ARttiProperty;
  FNome              := ARttiProperty.Name;
  FNomeColuna        := ANomeColuna;
  FTipoColuna        := ATipoColuna;
  FTamanho           := ATamanho;
  FPrecisao          := APrecisao;
  FEscala            := AEscala;
  FEhNulavel         := AEhNulavel;
  FEhChavePrimaria   := False;
  FEhSomenteLeitura  := False;
  FEhObrigatorio     := False;
  FEhAutoIncremento  := False;
  FEstrategiaChave   := ecNenhuma;
  FOrdemChave        := 0;
  FEhCriadoEm        := False;
  FEhAtualizadoEm    := False;
  FEhCriadoPor       := False;
  FEhAtualizadoPor   := False;
  FEhDeletadoEm      := False;
  FEhVersao          := False;
  FEhTenantId        := False;
end;

procedure TMetadadoPropriedade.DefinirComoChavePrimaria(
  AOrdem: Integer;
  AEstrategia: TEstategiaChave;
  AAutoIncremento: Boolean);
begin
  FEhChavePrimaria  := True;
  FOrdemChave       := AOrdem;
  FEstrategiaChave  := AEstrategia;
  FEhAutoIncremento := AAutoIncremento;
  // Chave primária nunca é nulável
  FEhNulavel        := False;
end;

procedure TMetadadoPropriedade.DefinirComoSomenteLeitura;
begin
  FEhSomenteLeitura := True;
end;

procedure TMetadadoPropriedade.DefinirComoObrigatorio;
begin
  FEhObrigatorio := True;
end;

function TMetadadoPropriedade.Nome: string;
begin
  Result := FNome;
end;

function TMetadadoPropriedade.NomeColuna: string;
begin
  Result := FNomeColuna;
end;

function TMetadadoPropriedade.TipoColuna: TTipoColuna;
begin
  Result := FTipoColuna;
end;

function TMetadadoPropriedade.Tamanho: Integer;
begin
  Result := FTamanho;
end;

function TMetadadoPropriedade.Precisao: Integer;
begin
  Result := FPrecisao;
end;

function TMetadadoPropriedade.Escala: Integer;
begin
  Result := FEscala;
end;

function TMetadadoPropriedade.EhChavePrimaria: Boolean;
begin
  Result := FEhChavePrimaria;
end;

function TMetadadoPropriedade.EhNulavel: Boolean;
begin
  Result := FEhNulavel;
end;

function TMetadadoPropriedade.EhSomenteLeitura: Boolean;
begin
  Result := FEhSomenteLeitura;
end;

function TMetadadoPropriedade.EhObrigatorio: Boolean;
begin
  Result := FEhObrigatorio;
end;

function TMetadadoPropriedade.EhAutoIncremento: Boolean;
begin
  Result := FEhAutoIncremento;
end;

function TMetadadoPropriedade.EstrategiaChave: TEstategiaChave;
begin
  Result := FEstrategiaChave;
end;

function TMetadadoPropriedade.OrdemChave: Integer;
begin
  Result := FOrdemChave;
end;

function TMetadadoPropriedade.ObterValor(AInstancia: TObject): TValue;
begin
  if not Assigned(AInstancia) then
    raise EOrmMetadadoExcecao.Create(
      FNome,
      'Instância não pode ser nil ao obter valor de propriedade.');
  try
    Result := FRttiProperty.GetValue(AInstancia);
  except
    on E: Exception do
      raise EOrmMetadadoExcecao.Create(
        FNome,
        Format('Falha ao obter valor da propriedade "%s": %s',
          [FNome, E.Message]),
        E);
  end;
end;

procedure TMetadadoPropriedade.DefinirValor(AInstancia: TObject;
  const AValor: TValue);
begin
  if not Assigned(AInstancia) then
    raise EOrmMetadadoExcecao.Create(
      FNome,
      'Instância não pode ser nil ao definir valor de propriedade.');

  if FEhSomenteLeitura then
    raise EOrmMetadadoExcecao.Create(
      FNome,
      Format('A propriedade "%s" é somente leitura e não pode ser alterada.',
        [FNome]));
  try
    FRttiProperty.SetValue(AInstancia, AValor);
  except
    on E: Exception do
      raise EOrmMetadadoExcecao.Create(
        FNome,
        Format('Falha ao definir valor da propriedade "%s": %s',
          [FNome, E.Message]),
        E);
  end;
end;

end.
