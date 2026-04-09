program LoggerDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.JSON,
  Logger.Types,
  Logger.Interfaces,
  Logger.Facade,
  Logger.Factory;

var
  Logger: ILogger;
  EmailHandler, PushHandler: ILogHandler;
  ExtraData: TJSONObject;
begin
  try
    // Opção 1: Usar Singleton
    Logger := TLogger.Instance;

    // Registra handler de arquivo (padrão)
    Logger.RegisterHandler(
      TLoggerFactory.CreateFileHandler('C:\Logs\app.log')
    );

    // Registra handler de email (apenas Warning e Error)
    EmailHandler := TLoggerFactory.CreateEmailHandler(
      'smtp.gmail.com',
      587,
      'user@gmail.com',
      'password',
      'noreply@myapp.com',
      ['admin@myapp.com', 'dev@myapp.com'],
      True,
      [llWarning, llError]
    );
    Logger.RegisterHandler(EmailHandler);

    // Registra handler de push notification (apenas Error)
    PushHandler := TLoggerFactory.CreatePushHandler(
      'https://fcm.googleapis.com/fcm/send',
      'YOUR_API_KEY',
      'MyApplication',
      30000,
      [llError]
    );
    Logger.RegisterHandler(PushHandler);

    // Logs simples
    Logger.Debug('Iniciando aplicação', 'Startup');
    Logger.Info('Usuário conectou', 'Auth');
    Logger.Warning('Memória baixa', 'System');
    Logger.Error('Falha na conexão com banco', 'Database');

    // Log com dados extras
    ExtraData := TJSONObject.Create;
    try
      ExtraData.AddPair('user_id', TJSONNumber.Create(123));
      ExtraData.AddPair('action', 'login');
      ExtraData.AddPair('ip', '192.168.1.100');
      
      Logger.Log(llInformation, 'Login realizado com sucesso', 'Auth', ExtraData);
    finally
      ExtraData.Free;
    end;

    // Aguarda processamento
    Logger.Flush;

    WriteLn('Logs enviados com sucesso!');
    
    // Opção 2: Criar instância própria
    // var MyLogger := TLoggerFactory.CreateDefaultLogger;
    // MyLogger.Info('Minha mensagem');

  except
    on E: Exception do
      WriteLn('Erro: ', E.Message);
  end;

  ReadLn;
end.
