unit Infra.ORM.Core.Logging.Contrato;

{
  Responsabilidade:
    Contrato de integração com o sistema de log externo.
    O ORM não implementa logging — apenas consome esta interface.
    A implementação concreta é injetada no bootstrap da aplicação.

    Thread-safety: a implementação concreta deve garantir thread-safety.
    O ORM chama o logger de múltiplas threads sem sincronização própria.
}

interface

uses
  System.SysUtils,
  Infra.ORM.Core.Common.Tipos;

type

  // ---------------------------------------------------------------------------
  // Contrato principal do adapter de log
  // Adaptado para o módulo externo Logger do projeto Infra
  // ---------------------------------------------------------------------------
  IOrmLogger = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']

    // Registra mensagem no nível especificado
    procedure Log(
      ANivel: TNivelLog;
      const AMensagem: string;
      const AContexto: TContextoEstruturado = nil);

    // Atalhos por nível
    procedure Debug(
      const AMensagem: string;
      const AContexto: TContextoEstruturado = nil);

    procedure Informacao(
      const AMensagem: string;
      const AContexto: TContextoEstruturado = nil);

    procedure Aviso(
      const AMensagem: string;
      const AContexto: TContextoEstruturado = nil);

    procedure Erro(
      const AMensagem: string;
      AExcecao: Exception = nil;
      const AContexto: TContextoEstruturado = nil);

    procedure Fatal(
      const AMensagem: string;
      AExcecao: Exception = nil;
      const AContexto: TContextoEstruturado = nil);
  end;

  // ---------------------------------------------------------------------------
  // Logger nulo — implementação padrão quando nenhum logger é injetado.
  // Não faz nada. Evita verificações de nil em todo o código.
  // ---------------------------------------------------------------------------
  TLoggerNulo = class(TInterfacedObject, IOrmLogger)
  public
    procedure Log(
      ANivel: TNivelLog;
      const AMensagem: string;
      const AContexto: TContextoEstruturado = nil);

    procedure Debug(
      const AMensagem: string;
      const AContexto: TContextoEstruturado = nil);

    procedure Informacao(
      const AMensagem: string;
      const AContexto: TContextoEstruturado = nil);

    procedure Aviso(
      const AMensagem: string;
      const AContexto: TContextoEstruturado = nil);

    procedure Erro(
      const AMensagem: string;
      AExcecao: Exception = nil;
      const AContexto: TContextoEstruturado = nil);

    procedure Fatal(
      const AMensagem: string;
      AExcecao: Exception = nil;
      const AContexto: TContextoEstruturado = nil);
  end;

  // ---------------------------------------------------------------------------
  // Helper para construir contextos estruturados de forma fluente
  // Uso:
  //   TContextoLog.Novo
  //     .Add('entidade', 'TCliente')
  //     .Add('id', 42)
  //     .Construir
  // ---------------------------------------------------------------------------
  TContextoLog = record
  private
    FPares: TContextoEstruturado;
  public
    class function Novo: TContextoLog; static;

    function Add(const ANome: string; const AValor: string): TContextoLog; overload;
    function Add(const ANome: string; AValor: Integer): TContextoLog; overload;
    function Add(const ANome: string; AValor: Int64): TContextoLog; overload;
    function Add(const ANome: string; AValor: Boolean): TContextoLog; overload;
    function Add(const ANome: string; AValor: Double): TContextoLog; overload;

    function Construir: TContextoEstruturado;
  end;

  // ---------------------------------------------------------------------------
  // Logger que escreve no console — útil para exemplos e CLI
  // ---------------------------------------------------------------------------
  TLoggerConsole = class(TInterfacedObject, IOrmLogger)
  strict private
    FNivelMinimo: TNivelLog;
    function PrefixoNivel(ANivel: TNivelLog): string;
  public
    constructor Create(ANivelMinimo: TNivelLog = nlInformacao);
    procedure Debug(const AMensagem: string; const AContexto: string = '');
    procedure Informacao(const AMensagem: string; const AContexto: string = '');
    procedure Aviso(const AMensagem: string; const AContexto: string = '');
    procedure Erro(const AMensagem: string; AExcecao: Exception; const AContexto: string = '');
    procedure Fatal(const AMensagem: string; AExcecao: Exception; const AContexto: string = '');
  end;

implementation

uses
  System.Rtti;

{ TLoggerNulo }

procedure TLoggerNulo.Log(ANivel: TNivelLog; const AMensagem: string;
  const AContexto: TContextoEstruturado);
begin
  // intencionalmente vazio
end;

procedure TLoggerNulo.Debug(const AMensagem: string;
  const AContexto: TContextoEstruturado);
begin
  // intencionalmente vazio
end;

procedure TLoggerNulo.Informacao(const AMensagem: string;
  const AContexto: TContextoEstruturado);
begin
  // intencionalmente vazio
end;

procedure TLoggerNulo.Aviso(const AMensagem: string;
  const AContexto: TContextoEstruturado);
begin
  // intencionalmente vazio
end;

procedure TLoggerNulo.Erro(const AMensagem: string;
  AExcecao: Exception; const AContexto: TContextoEstruturado);
begin
  // intencionalmente vazio
end;

procedure TLoggerNulo.Fatal(const AMensagem: string;
  AExcecao: Exception; const AContexto: TContextoEstruturado);
begin
  // intencionalmente vazio
end;

{ TContextoLog }

class function TContextoLog.Novo: TContextoLog;
begin
  SetLength(Result.FPares, 0);
end;

function TContextoLog.Add(const ANome: string;
  const AValor: string): TContextoLog;
var
  LIndice: Integer;
begin
  LIndice := Length(FPares);
  SetLength(FPares, LIndice + 1);
  FPares[LIndice] := TParNomeValor.Create(ANome, TValue.From<string>(AValor));
  Result := Self;
end;

function TContextoLog.Add(const ANome: string;
  AValor: Integer): TContextoLog;
var
  LIndice: Integer;
begin
  LIndice := Length(FPares);
  SetLength(FPares, LIndice + 1);
  FPares[LIndice] := TParNomeValor.Create(ANome, TValue.From<Integer>(AValor));
  Result := Self;
end;

function TContextoLog.Add(const ANome: string;
  AValor: Int64): TContextoLog;
var
  LIndice: Integer;
begin
  LIndice := Length(FPares);
  SetLength(FPares, LIndice + 1);
  FPares[LIndice] := TParNomeValor.Create(ANome, TValue.From<Int64>(AValor));
  Result := Self;
end;

function TContextoLog.Add(const ANome: string;
  AValor: Boolean): TContextoLog;
var
  LIndice: Integer;
begin
  LIndice := Length(FPares);
  SetLength(FPares, LIndice + 1);
  FPares[LIndice] := TParNomeValor.Create(ANome, TValue.From<Boolean>(AValor));
  Result := Self;
end;

function TContextoLog.Add(const ANome: string;
  AValor: Double): TContextoLog;
var
  LIndice: Integer;
begin
  LIndice := Length(FPares);
  SetLength(FPares, LIndice + 1);
  FPares[LIndice] := TParNomeValor.Create(ANome, TValue.From<Double>(AValor));
  Result := Self;
end;

function TContextoLog.Construir: TContextoEstruturado;
begin
  Result := FPares;
end;

{ TLoggerConsole }

constructor TLoggerConsole.Create(ANivelMinimo: TNivelLog);
begin
  inherited Create;
  FNivelMinimo := ANivelMinimo;
end;

function TLoggerConsole.PrefixoNivel(ANivel: TNivelLog): string;
begin
  case ANivel of
    nlDebug:      Result := '[DEBUG]';
    nlInformacao: Result := '[INFO ]';
    nlAviso:      Result := '[AVISO]';
    nlErro:       Result := '[ERRO ]';
    nlFatal:      Result := '[FATAL]';
  else
    Result := '[?????]';
  end;
end;

procedure TLoggerConsole.Debug(const AMensagem, AContexto: string);
begin
  if FNivelMinimo <= nlDebug then
    Writeln(Format('%s %s %s %s',
      [FormatDateTime('hh:nn:ss.zzz', Now),
       PrefixoNivel(nlDebug), AMensagem, AContexto]));
end;

procedure TLoggerConsole.Informacao(const AMensagem, AContexto: string);
begin
  if FNivelMinimo <= nlInformacao then
    Writeln(Format('%s %s %s %s',
      [FormatDateTime('hh:nn:ss.zzz', Now),
       PrefixoNivel(nlInformacao), AMensagem, AContexto]));
end;

procedure TLoggerConsole.Aviso(const AMensagem, AContexto: string);
begin
  if FNivelMinimo <= nlAviso then
    Writeln(Format('%s %s %s %s',
      [FormatDateTime('hh:nn:ss.zzz', Now),
       PrefixoNivel(nlAviso), AMensagem, AContexto]));
end;

procedure TLoggerConsole.Erro(
  const AMensagem: string;
  AExcecao: Exception;
  const AContexto: string);
var
  LMsg: string;
begin
  if FNivelMinimo <= nlErro then
  begin
    LMsg := AMensagem;
    if Assigned(AExcecao) then
      LMsg := LMsg + ' | ' + AExcecao.ClassName + ': ' + AExcecao.Message;
    Writeln(Format('%s %s %s %s',
      [FormatDateTime('hh:nn:ss.zzz', Now),
       PrefixoNivel(nlErro), LMsg, AContexto]));
  end;
end;

procedure TLoggerConsole.Fatal(
  const AMensagem: string;
  AExcecao: Exception;
  const AContexto: string);
var
  LMsg: string;
begin
  LMsg := AMensagem;
  if Assigned(AExcecao) then
    LMsg := LMsg + ' | ' + AExcecao.ClassName + ': ' + AExcecao.Message;
  Writeln(Format('%s %s %s %s',
    [FormatDateTime('hh:nn:ss.zzz', Now),
     PrefixoNivel(nlFatal), LMsg, AContexto]));
end;

end.
