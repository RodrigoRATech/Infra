unit Infra.ORM.Core.Persistence.Validador;

{
  Responsabilidade:
    Validação leve de entidades antes da persistência.
    Verifica campos obrigatórios e tamanhos máximos.
    Falha rápida sem ir ao banco.
}

interface

uses
  System.SysUtils,
  System.Rtti,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions;

type

  TValidadorEntidade = class
  strict private
    procedure ValidarCampoObrigatorio(
      AMetadado: IOrmMetadadoEntidade;
      AProp: IOrmMetadadoPropriedade;
      const AValor: TValue);

    procedure ValidarTamanhoString(
      AMetadado: IOrmMetadadoEntidade;
      AProp: IOrmMetadadoPropriedade;
      const AValor: TValue);

  public
    // Valida entidade completa — lança EOrmValidacaoExcecao na primeira falha
    procedure Validar(
      AMetadado: IOrmMetadadoEntidade;
      AEntidade: TObject);

    // Validação apenas das chaves — usado antes de operações por ID
    procedure ValidarChaves(
      AMetadado: IOrmMetadadoEntidade;
      AEntidade: TObject);
  end;

implementation

{ TValidadorEntidade }

procedure TValidadorEntidade.Validar(
  AMetadado: IOrmMetadadoEntidade;
  AEntidade: TObject);
var
  LProp: IOrmMetadadoPropriedade;
  LValor: TValue;
begin
  if not Assigned(AEntidade) then
    raise EOrmValidacaoExcecao.Create(
      AMetadado.NomeClasse,
      'Entidade não pode ser nil para persistência.');

  for LProp in AMetadado.PropriedadesPersistidas do
  begin
    // Não validar chaves autoincremento — banco gera
    if LProp.EhChavePrimaria and LProp.EhAutoIncremento then
      Continue;

    LValor := LProp.ObterValor(AEntidade);

    if LProp.EhObrigatorio then
      ValidarCampoObrigatorio(AMetadado, LProp, LValor);

    if LProp.Tamanho > 0 then
      ValidarTamanhoString(AMetadado, LProp, LValor);
  end;
end;

procedure TValidadorEntidade.ValidarChaves(
  AMetadado: IOrmMetadadoEntidade;
  AEntidade: TObject);
var
  LChave: IOrmMetadadoPropriedade;
  LValor: TValue;
begin
  if not Assigned(AEntidade) then
    raise EOrmValidacaoExcecao.Create(
      AMetadado.NomeClasse,
      'Entidade não pode ser nil ao validar chaves.');

  for LChave in AMetadado.Chaves do
  begin
    if LChave.EhAutoIncremento then
      Continue;

    LValor := LChave.ObterValor(AEntidade);

    if LValor.IsEmpty then
      raise EOrmValidacaoExcecao.Create(
        AMetadado.NomeClasse,
        LChave.Nome,
        Format(
          'Chave primária "%s" não pode estar vazia para esta operação.',
          [LChave.NomeColuna]));
  end;
end;

procedure TValidadorEntidade.ValidarCampoObrigatorio(
  AMetadado: IOrmMetadadoEntidade;
  AProp: IOrmMetadadoPropriedade;
  const AValor: TValue);
var
  LEhVazio: Boolean;
begin
  LEhVazio := AValor.IsEmpty;

  if not LEhVazio then
  begin
    case AValor.Kind of
      tkString, tkUString, tkWString, tkLString:
        LEhVazio := AValor.AsString.Trim.IsEmpty;
      tkInteger:
        LEhVazio := False; // 0 é válido para obrigatório
      tkInt64:
        LEhVazio := False;
    end;
  end;

  if LEhVazio then
    raise EOrmValidacaoExcecao.Create(
      AMetadado.NomeClasse,
      AProp.Nome,
      Format('O campo "%s" é obrigatório e não pode ser vazio.',
        [AProp.NomeColuna]));
end;

procedure TValidadorEntidade.ValidarTamanhoString(
  AMetadado: IOrmMetadadoEntidade;
  AProp: IOrmMetadadoPropriedade;
  const AValor: TValue);
var
  LTexto: string;
begin
  if not (AValor.Kind in
    [tkString, tkUString, tkWString, tkLString]) then
    Exit;

  LTexto := AValor.AsString;

  if Length(LTexto) > AProp.Tamanho then
    raise EOrmValidacaoExcecao.Create(
      AMetadado.NomeClasse,
      AProp.Nome,
      Format(
        'O campo "%s" excede o tamanho máximo permitido ' +
        '(%d caracteres). Valor atual: %d caracteres.',
        [AProp.NomeColuna, AProp.Tamanho, Length(LTexto)]));
end;

end.
