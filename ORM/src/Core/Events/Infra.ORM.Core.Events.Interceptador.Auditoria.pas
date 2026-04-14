unit Infra.ORM.Core.Events.Interceptador.Auditoria;

{
  Responsabilidade:
    Interceptador que preenche automaticamente campos de auditoria
    antes da operação de persistência e implementa soft-delete.

    Campos gerenciados:
      [CriadoEm]      → preenchido no INSERT
      [AtualizadoEm]  → preenchido no INSERT e UPDATE
      [CriadoPor]     → preenchido no INSERT
      [AtualizadoPor] → preenchido no INSERT e UPDATE
      [DeletadoEm]    → transforma DELETE em UPDATE (soft delete)
      [Versao]        → incrementa a cada UPDATE (controle de concorrência)
      [TenantId]      → preenchido com o tenant do contexto
}

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.Rtti,
  Infra.ORM.Core.Common.Tipos,
  Infra.ORM.Core.Contracts,
  Infra.ORM.Core.Exceptions,
  Infra.ORM.Core.Logging.Contrato,
  Infra.ORM.Core.Events.Contratos,
  Infra.ORM.Core.Events.Interceptador.Nulo;

type

  TInterceptadorAuditoria = class(TInterceptadorNulo)
  strict private
    FProvedorIdentidade: IOrmProvedorIdentidade;
    FProvedorTenant: IOrmProvedorTenant;
    FLogger: IOrmLogger;

    procedure PreencherCriadoEm(
      AProp: IOrmMetadadoPropriedade;
      AEntidade: TObject);

    procedure PreencherAtualizadoEm(
      AProp: IOrmMetadadoPropriedade;
      AEntidade: TObject);

    procedure PreencherCriadoPor(
      AProp: IOrmMetadadoPropriedade;
      AEntidade: TObject);

    procedure PreencherAtualizadoPor(
      AProp: IOrmMetadadoPropriedade;
      AEntidade: TObject);

    procedure PreencherVersao(
      AProp: IOrmMetadadoPropriedade;
      AEntidade: TObject);

    procedure PreencherTenantId(
      AProp: IOrmMetadadoPropriedade;
      AEntidade: TObject);

    procedure AplicarSoftDelete(
      AMetadado: IOrmMetadadoEntidade;
      AEntidade: TObject);

  public
    constructor Create(
      AProvedorIdentidade: IOrmProvedorIdentidade;
      ALogger: IOrmLogger;
      AProvedorTenant: IOrmProvedorTenant = nil);

    function Nome: string; override;

    procedure Antes(
      AOperacao: TOperacaoOrm;
      AMetadado: IOrmMetadadoEntidade;
      AEntidade: TObject); override;

    procedure Depois(
      AOperacao: TOperacaoOrm;
      AMetadado: IOrmMetadadoEntidade;
      AEntidade: TObject;
      ASucesso: Boolean); override;
  end;

implementation

{ TInterceptadorAuditoria }

constructor TInterceptadorAuditoria.Create(
  AProvedorIdentidade: IOrmProvedorIdentidade;
  ALogger: IOrmLogger;
  AProvedorTenant: IOrmProvedorTenant);
begin
  inherited Create;
  FProvedorIdentidade := AProvedorIdentidade;
  FProvedorTenant     := AProvedorTenant;
  FLogger             := ALogger ?? TLoggerNulo.Create;
end;

function TInterceptadorAuditoria.Nome: string;
begin
  Result := 'InterceptadorAuditoria';
end;

procedure TInterceptadorAuditoria.PreencherCriadoEm(
  AProp: IOrmMetadadoPropriedade;
  AEntidade: TObject);
var
  LValorAtual: TValue;
begin
  LValorAtual := AProp.ObterValor(AEntidade);

  // Só preenche se ainda não estiver definido
  if (not LValorAtual.IsEmpty) and (LValorAtual.AsType<TDateTime> > 0) then
    Exit;

  AProp.DefinirValor(AEntidade, TValue.From<TDateTime>(Now));
end;

procedure TInterceptadorAuditoria.PreencherAtualizadoEm(
  AProp: IOrmMetadadoPropriedade;
  AEntidade: TObject);
begin
  // Sempre atualiza
  AProp.DefinirValor(AEntidade, TValue.From<TDateTime>(Now));
end;

procedure TInterceptadorAuditoria.PreencherCriadoPor(
  AProp: IOrmMetadadoPropriedade;
  AEntidade: TObject);
var
  LValorAtual: TValue;
  LIdentidade: string;
begin
  LValorAtual := AProp.ObterValor(AEntidade);

  if (not LValorAtual.IsEmpty) and
     not LValorAtual.AsString.Trim.IsEmpty then
    Exit;

  LIdentidade := '';
  if Assigned(FProvedorIdentidade) then
    LIdentidade := FProvedorIdentidade.ObterIdentidade;

  AProp.DefinirValor(AEntidade, TValue.From<string>(LIdentidade));
end;

procedure TInterceptadorAuditoria.PreencherAtualizadoPor(
  AProp: IOrmMetadadoPropriedade;
  AEntidade: TObject);
var
  LIdentidade: string;
begin
  LIdentidade := '';
  if Assigned(FProvedorIdentidade) then
    LIdentidade := FProvedorIdentidade.ObterIdentidade;

  AProp.DefinirValor(AEntidade, TValue.From<string>(LIdentidade));
end;

procedure TInterceptadorAuditoria.PreencherVersao(
  AProp: IOrmMetadadoPropriedade;
  AEntidade: TObject);
var
  LVersaoAtual: Int64;
begin
  LVersaoAtual := 0;
  try
    LVersaoAtual := AProp.ObterValor(AEntidade).AsInt64;
  except
    // Versão não legível — inicia em 0
  end;
  AProp.DefinirValor(AEntidade, TValue.From<Int64>(LVersaoAtual + 1));
end;

procedure TInterceptadorAuditoria.PreencherTenantId(
  AProp: IOrmMetadadoPropriedade;
  AEntidade: TObject);
var
  LValorAtual: TValue;
  LTenantId: string;
begin
  if not Assigned(FProvedorTenant) then
    Exit;

  LValorAtual := AProp.ObterValor(AEntidade);

  // Só preenche se ainda não estiver definido
  if (not LValorAtual.IsEmpty) and
     not LValorAtual.AsString.Trim.IsEmpty then
    Exit;

  LTenantId := FProvedorTenant.ObterTenantId;
  AProp.DefinirValor(AEntidade, TValue.From<string>(LTenantId));
end;

procedure TInterceptadorAuditoria.AplicarSoftDelete(
  AMetadado: IOrmMetadadoEntidade;
  AEntidade: TObject);
var
  LProp: IOrmMetadadoPropriedade;
begin
  // Localiza campo [DeletadoEm]
  for LProp in AMetadado.Propriedades do
  begin
    if LProp.EhDeletadoEm then
    begin
      // Preenche o timestamp de deleção lógica
      AProp.DefinirValor(AEntidade, TValue.From<TDateTime>(Now));

      FLogger.Debug(
        'Soft delete aplicado — campo DeletadoEm preenchido',
        TContextoLog.Novo
          .Add('entidade', AMetadado.NomeClasse)
          .Add('coluna', LProp.NomeColuna)
          .Construir);
      Break;
    end;
  end;
end;

procedure TInterceptadorAuditoria.Antes(
  AOperacao: TOperacaoOrm;
  AMetadado: IOrmMetadadoEntidade;
  AEntidade: TObject);
var
  LProp: IOrmMetadadoPropriedade;
begin
  if not Assigned(AEntidade) then
    Exit;

  for LProp in AMetadado.Propriedades do
  begin
    try
      case AOperacao of

        ooInserir:
          begin
            if LProp.EhCriadoEm     then PreencherCriadoEm(LProp, AEntidade);
            if LProp.EhAtualizadoEm then PreencherAtualizadoEm(LProp, AEntidade);
            if LProp.EhCriadoPor    then PreencherCriadoPor(LProp, AEntidade);
            if LProp.EhAtualizadoPor then PreencherAtualizadoPor(LProp, AEntidade);
            if LProp.EhTenantId     then PreencherTenantId(LProp, AEntidade);
          end;

        ooAtualizar:
          begin
            if LProp.EhAtualizadoEm  then PreencherAtualizadoEm(LProp, AEntidade);
            if LProp.EhAtualizadoPor then PreencherAtualizadoPor(LProp, AEntidade);
            if LProp.EhVersao        then PreencherVersao(LProp, AEntidade);
          end;

        ooDeletar:
          begin
            // Soft delete: apenas se houver campo [DeletadoEm]
            if AMetadado.PossuiSoftDelete and LProp.EhDeletadoEm then
            begin
              PreencherAtualizadoEm(LProp, AEntidade);

              // Aqui lançamos exceção especial que o executor reconhece
              // para trocar DELETE por UPDATE
              raise EOrmSoftDeleteExcecao.Create(
                AMetadado.NomeClasse,
                'Entidade possui [DeletadoEm] — operação será convertida ' +
                'para soft delete (UPDATE).');
            end;
          end;

      end;
    except
      on E: EOrmSoftDeleteExcecao do
        raise; // Propaga intencionalmente — executor trata
      on E: Exception do
        FLogger.Aviso(
          Format('Falha ao preencher campo automático "%s" — ignorada',
            [LProp.Nome]),
          TContextoLog.Novo
            .Add('entidade', AMetadado.NomeClasse)
            .Add('campo', LProp.Nome)
            .Add('operacao', Ord(AOperacao))
            .Add('erro', E.Message)
            .Construir);
    end;
  end;
end;

procedure TInterceptadorAuditoria.Depois(
  AOperacao: TOperacaoOrm;
  AMetadado: IOrmMetadadoEntidade;
  AEntidade: TObject;
  ASucesso: Boolean);
begin
  // Log de confirmação — útil para rastreabilidade
  if ASucesso and (AOperacao in [ooInserir, ooAtualizar, ooDeletar]) then
    FLogger.Debug(
      Format('Interceptador de auditoria confirmou %s',
        [AMetadado.NomeClasse]),
      TContextoLog.Novo
        .Add('operacao', Ord(AOperacao))
        .Add('sucesso', ASucesso)
        .Construir);
end;

end.
