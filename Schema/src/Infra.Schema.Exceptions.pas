unit Infra.Schema.Exceptions;

interface

uses
  System.SysUtils;

type
  { Base de todas as exceções do módulo }
  ESchemaException = class(Exception);

  { Schema não encontrado em disco nem em cache }
  ESchemaNotFound = class(ESchemaException)
  public
    constructor Create(const ASchemaName: string);
  end;

  { Falha ao ler o arquivo de schema do disco }
  ESchemaLoadError = class(ESchemaException)
  public
    constructor Create(const ASchemaName, AReason: string);
  end;

  { Dados da requisição não são válidos de acordo com o schema }
  ESchemaValidationError = class(ESchemaException)
  private
    FErrors: string;
  public
    constructor Create(const ASchemaName, AErrors: string);
    property Errors: string read FErrors;
  end;

  { Configuração inválida ou ausente }
  ESchemaConfigError = class(ESchemaException)
  public
    constructor Create(const AReason: string);
  end;

implementation

{ ESchemaNotFound }

constructor ESchemaNotFound.Create(const ASchemaName: string);
begin
  inherited CreateFmt('Schema não encontrado: "%s"', [ASchemaName]);
end;

{ ESchemaLoadError }

constructor ESchemaLoadError.Create(const ASchemaName, AReason: string);
begin
  inherited CreateFmt('Erro ao carregar schema "%s": %s', [ASchemaName, AReason]);
end;

{ ESchemaValidationError }

constructor ESchemaValidationError.Create(const ASchemaName, AErrors: string);
begin
  FErrors := AErrors;
  inherited CreateFmt('Validação falhou para schema "%s": %s', [ASchemaName, AErrors]);
end;

{ ESchemaConfigError }

constructor ESchemaConfigError.Create(const AReason: string);
begin
  inherited CreateFmt('Configuração de schema inválida: %s', [AReason]);
end;

end.
