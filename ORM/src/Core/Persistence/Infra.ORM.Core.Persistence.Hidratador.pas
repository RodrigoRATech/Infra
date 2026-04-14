unit Infra.ORM.Core.Persistence.Hidratador;

{
  Responsabilidade:
    Materializa entidades Delphi a partir de um IOrmLeitorDados.
    Usa metadados para mapear colunas → properties.
    Completamente desacoplado do provider de banco.
}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions,
  Infra.ORM.Core.Logging.Contrato;

type

  THidratador = class
  strict private
    FLogger: IOrmLogger;

    procedure HidratarPropriedade(
      AEntidade: TObject;
      AProp: IOrmMetadadoPropriedade;
      ALeitor: IOrmLeitorDados);

    function ConverterValor(
      const AValorBruto: TValue;
      AProp: IOrmMetadadoPropriedade): TValue;

  public
    constructor Create(ALogger: IOrmLogger);

    // Hidratar uma única entidade a partir do leitor posicionado
    function Hidratar<T: class, constructor>(
      AMetadado: IOrmMetadadoEntidade;
      ALeitor: IOrmLeitorDados): T;

    // Hidratar lista completa até EhFim
    function HidratarLista<T: class, constructor>(
      AMetadado: IOrmMetadadoEntidade;
      ALeitor: IOrmLeitorDados): TObjectList<T>;
  end;

implementation

{ THidratador }

constructor THidratador.Create(ALogger: IOrmLogger);
begin
  inherited Create;

  if Assigned(ALogger) then
    FLogger := ALogger
  else
    FLogger := TLoggerNulo.Create;
end;

function THidratador.Hidratar<T>(
  AMetadado: IOrmMetadadoEntidade;
  ALeitor: IOrmLeitorDados): T;
var
  LEntidade: T;
  LProp: IOrmMetadadoPropriedade;
begin
  LEntidade := T.Create;
  try
    for LProp in AMetadado.Propriedades do
    begin
      // Não tentar hidratar props sem coluna mapeada no resultado
      try
        HidratarPropriedade(LEntidade, LProp, ALeitor);
      except
        on E: Exception do
          FLogger.Aviso(
            Format('Falha ao hidratar propriedade "%s" — ignorada',
              [LProp.NomeColuna]),
            TContextoLog.Novo
              .Add('entidade', AMetadado.NomeClasse)
              .Add('coluna', LProp.NomeColuna)
              .Add('erro', E.Message)
              .Construir);
      end;
    end;
    Result := LEntidade;
  except
    LEntidade.Free;
    raise;
  end;
end;

function THidratador.HidratarLista<T>(
  AMetadado: IOrmMetadadoEntidade;
  ALeitor: IOrmLeitorDados): TObjectList<T>;
var
  LLista: TObjectList<T>;
  LEntidade: T;
begin
  LLista := TObjectList<T>.Create(True);
  try
    while ALeitor.Proximo do
    begin
      LEntidade := Hidratar<T>(AMetadado, ALeitor);
      LLista.Add(LEntidade);
    end;
    Result := LLista;
  except
    LLista.Free;
    raise;
  end;
end;

procedure THidratador.HidratarPropriedade(
  AEntidade: TObject;
  AProp: IOrmMetadadoPropriedade;
  ALeitor: IOrmLeitorDados);
var
  LValorBruto: TValue;
  LValorConvertido: TValue;
begin
  if ALeitor.EhNulo(AProp.NomeColuna) then
  begin
    // Valor nulo — não define nada, mantém default do constructor
    Exit;
  end;

  LValorBruto      := ALeitor.ObterValor(AProp.NomeColuna);
  LValorConvertido := ConverterValor(LValorBruto, AProp);

  AProp.DefinirValor(AEntidade, LValorConvertido);
end;

function THidratador.ConverterValor(
  const AValorBruto: TValue;
  AProp: IOrmMetadadoPropriedade): TValue;
begin
  // A conversão de tipo é responsabilidade do provider (IOrmLeitorDados)
  // que já devolve o tipo correto via ObterValor.
  // Aqui fazemos apenas ajustes finos quando necessário.
  Result := AValorBruto;
end;

end.
