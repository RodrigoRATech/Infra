program JsonSchemaDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  JsonSchema;

var
  Schema: TJsonSchemaBuilder;
  SchemaJson: string;
  Errors: TArray<string>;
  TestJson: string;
  Error: string;
begin
  try
    // Criando um schema completo para cadastro de pessoa
    Schema := NewJsonSchema
      .Id('https://example.com/person.schema.json')
      .Title('Pessoa')
      .Description('Schema para validação de dados de pessoa')
      .AdditionalProperties(False);
    
    try
      // Propriedades básicas
      Schema
        .AddString('nome')
          .Description('Nome completo da pessoa')
          .MinLength(3)
          .MaxLength(100)
          .Required
        .&End;
      
      // Email com validação
      Schema
        .AddString('email')
          .Description('Endereço de e-mail')
          .AsEmail
          .Required
        .&End;
      
      // CPF brasileiro
      Schema
        .AddString('cpf')
          .Description('CPF do cidadão')
          .AsCPF
          .Required
        .&End;
      
      // Telefone brasileiro
      Schema
        .AddString('telefone')
          .Description('Telefone de contato')
          .AsPhoneBR
        .&End;
      
      // CEP
      Schema
        .AddString('cep')
          .Description('Código postal')
          .AsZipCodeBR
        .&End;
      
      // Idade com range
      Schema
        .AddInteger('idade')
          .Description('Idade em anos')
          .Minimum(0)
          .Maximum(150)
          .Required
        .&End;
      
      // Salário com validação numérica
      Schema
        .AddNumber('salario')
          .Description('Salário mensal')
          .Minimum(0)
          .ExclusiveMaximum(1000000)
        .&End;
      
      // Status como enum
      Schema
        .AddString('status')
          .Description('Status do cadastro')
          .Enum(['ativo', 'inativo', 'pendente'])
          .DefaultValue('pendente')
          .Required
        .&End;
      
      // Data de nascimento
      Schema
        .AddTimestamp('dataNascimento')
          .Description('Data de nascimento')
          .AsDateOnly
          .Required
        .&End;
      
      // Data de criação em GMT
      Schema
        .AddTimestamp('createdAt')
          .Description('Data de criação do registro')
          .AsDateTimeGMT
        .&End;
      
      // Flag booleana
      Schema
        .AddBoolean('newsletter')
          .Description('Aceita receber newsletter')
          .DefaultValue(False)
        .&End;
      
      // Array de tags
      Schema
        .AddArray('tags')
          .Description('Tags associadas')
          .MinItems(1)
          .MaxItems(10)
          .ItemsString
            .MinLength(2)
            .MaxLength(20)
          .&End
        .&End;
      
      // Objeto aninhado - Endereço
      Schema
        .AddObject('endereco')
          .Description('Endereço completo')
          .AdditionalProperties(False)
          .AddString('logradouro')
            .Required
            .MinLength(5)
          .&End
          .AddString('numero')
            .Required
          .&End
          .AddString('complemento')
          .&End
          .AddString('bairro')
            .Required
          .&End
          .AddString('cidade')
            .Required
          .&End
          .AddString('estado')
            .Required
            .MinLength(2)
            .MaxLength(2)
          .&End
        .&End;
      
      // Gera o schema JSON
      SchemaJson := Schema.ToJSON(True);
      WriteLn('=== JSON SCHEMA GERADO ===');
      WriteLn(SchemaJson);
      WriteLn;
      
      // Teste de validação - JSON válido
      TestJson := '{' +
        '"nome": "João da Silva",' +
        '"email": "joao@email.com",' +
        '"cpf": "123.456.789-00",' +
        '"telefone": "(62) 99999-8888",' +
        '"cep": "74000-000",' +
        '"idade": 30,' +
        '"salario": 5000.50,' +
        '"status": "ativo",' +
        '"dataNascimento": "1994-05-15",' +
        '"createdAt": "2024-01-15T10:30:00Z",' +
        '"newsletter": true,' +
        '"tags": ["developer", "delphi"],' +
        '"endereco": {' +
          '"logradouro": "Rua das Flores",' +
          '"numero": "123",' +
          '"bairro": "Centro",' +
          '"cidade": "Goiânia",' +
          '"estado": "GO"' +
        '}' +
      '}';
      
      WriteLn('=== TESTE DE VALIDAÇÃO (JSON VÁLIDO) ===');
      if Schema.Validate(TestJson, Errors) then
        WriteLn('✓ JSON válido!')
      else
      begin
        WriteLn('✗ JSON inválido:');
        for Error in Errors do
          WriteLn('  - ', Error);
      end;
      WriteLn;
      
      // Teste com JSON inválido
      TestJson := '{' +
        '"nome": "Jo",' +                       // Muito curto
        '"email": "email-invalido",' +          // Email inválido
        '"cpf": "123",' +                       // CPF inválido
        '"idade": 200,' +                       // Fora do range
        '"status": "desconhecido",' +           // Não está no enum
        '"dataNascimento": "15/05/1994"' +      // Formato errado
      '}';
      
      WriteLn('=== TESTE DE VALIDAÇÃO (JSON INVÁLIDO) ===');
      if Schema.Validate(TestJson, Errors) then
        WriteLn('✓ JSON válido!')
      else
      begin
        WriteLn('✗ JSON inválido - Erros encontrados:');
        for Error in Errors do
          WriteLn('  - ', Error);
      end;
      
    finally
      Schema.Free;
    end;
    
    WriteLn;
    WriteLn('Pressione ENTER para sair...');
    ReadLn;
    
  except
    on E: Exception do
      WriteLn('Erro: ', E.Message);
  end;
end.
