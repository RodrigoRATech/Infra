procedure IniciarMicroservico;
var
  LConfig: TRabbitManagementConfig;
  LStartup: TRabbitMQStartup;
  LResult: TStartupResult;
begin
  LConfig := TRabbitManagementConfig.Default;
  LConfig.Host := '192.168.1.100';
  LConfig.User := 'admin';
  LConfig.Password := 'secret';

  LStartup := TRabbitMQStartup.Create(LConfig);
  try
    LStartup.OnLog := procedure(const ALevel, AMsg, ACtx: string)
    begin
      Writeln(Format('[%s][%s] %s', [ALevel, ACtx, AMsg]));
    end;

    LStartup.Filter.Prefix := 'app.';   // só filas com prefixo app.
    LStartup.MaxRetries := 15;

    LResult := LStartup.ExecuteWithCallback(
      function(const AQueue: TRabbitQueueInfo): Boolean
      begin
        // Aqui você registra o consumer/handler para cada fila
        Writeln('Registrando consumer para: ' + AQueue.Name);
        Result := True;
      end);

    if not LResult.Success then
      raise Exception.Create('Falha no startup: ' + LResult.ErrorMessage);

  finally
    LStartup.Free;
  end;
end;
