uses
  RabbitQueue.Factory,
  RabbitQueue.Interfaces,
  RabbitQueue.Types,
  RabbitQueue.Handler.Base;

// ─── Handler especializado (via herança) ───────────────────────────────────

type
  TEmailNotificationHandler = class(TRabbitQueueHandlerBase)
  strict protected
    function DoExecute(const AItem: TQueueItemInfo): TProcessResult; override;
    procedure DoBeforeExecute(const AItem: TQueueItemInfo); override;
    procedure DoAfterExecute(const AItem: TQueueItemInfo;
      const AResult: TProcessResult); override;
  end;

function TEmailNotificationHandler.DoExecute(
  const AItem: TQueueItemInfo): TProcessResult;
begin
  // Lógica de envio de e-mail...
  Writeln('[EMAIL] Processando: ' + AItem.Body);
  Result := prSuccess;
end;

procedure TEmailNotificationHandler.DoBeforeExecute(
  const AItem: TQueueItemInfo);
begin
  Writeln('[EMAIL] Iniciando processamento: ' + AItem.MessageId);
end;

procedure TEmailNotificationHandler.DoAfterExecute(
  const AItem: TQueueItemInfo;
  const AResult: TProcessResult);
begin
  Writeln('[EMAIL] Finalizado. Resultado: ' + Ord(AResult).ToString);
end;

// ─── Configuração e uso ────────────────────────────────────────────────────

var
  LConfig : TRabbitConnectionConfig;
  LQueue  : IRabbitQueue;
  LFactory: IRabbitQueueFactory;
begin
  LFactory := TRabbitQueueFactory.Instance;

  // Configuração de conexão
  LConfig          := TRabbitConnectionConfig.Default;
  LConfig.Host     := 'meu-rabbit.server.com';
  LConfig.Username := 'admin';
  LConfig.Password := 'secret';
  LConfig.MaxRetries := 3;

  // Criação e configuração fluente
  LQueue := LFactory.CreateQueue(LConfig)
    .WithQueue('fila.email')
    .WithQueue('fila.sms')
    .WithPrefetch(5);

  // Registrar handler concreto
  LQueue.RegisterHandler(
    TEmailNotificationHandler.Create('EmailHandler', 'fila.email')
  );

  // Registrar handler anônimo (para SMS)
  LQueue.RegisterHandler(
    LFactory.CreateHandler(
      'SmsHandler',
      'fila.sms',
      function(AItem: TQueueItemInfo): TProcessResult
      begin
        Writeln('[SMS] Enviando para: ' + AItem.Body);
        Result := prSuccess;
      end
    )
  );

  // ── Eventos de fila ─────────────────────────────
  LQueue.SetOnEnqueue(procedure(const AItem: TQueueItemInfo)
  begin
    Writeln('[EVENTO] Enfileirado: ' + AItem.Queue + ' | ' + AItem.Body);
  end);

  LQueue.SetOnDequeue(procedure(const AItem: TQueueItemInfo)
  begin
    Writeln('[EVENTO] Desenfileirado: ' + AItem.MessageId);
  end);

  LQueue.SetOnQueueEmpty(procedure(const AQueueName: string)
  begin
    Writeln('[EVENTO] Fila vazia: ' + AQueueName);
  end);

  LQueue.SetOnQueueError(procedure(const AQueueName: string;
    const AError: Exception)
  begin
    Writeln('[ERRO] Fila: ' + AQueueName + ' | ' + AError.Message);
  end);

  // ── Eventos de processamento ─────────────────────
  LQueue.SetOnBeforeProcess(procedure(const AItem: TQueueItemInfo)
  begin
    Writeln('[PRÉ] Processando: ' + AItem.MessageId);
  end);

  LQueue.SetOnAfterProcess(procedure(const AItem: TQueueItemInfo;
    const AResult: TProcessResult)
  begin
    Writeln('[PÓS] Concluído: ' + AItem.MessageId);
  end);

  LQueue.SetOnProcessError(procedure(const AItem: TQueueItemInfo;
    const AError: Exception; var AShouldRequeue: Boolean)
  begin
    Writeln('[FALHA] ' + AItem.MessageId + ': ' + AError.Message);
    AShouldRequeue := AItem.RetryCount < 3;
  end);

  // ── Publicar mensagens ───────────────────────────
  LQueue.Enqueue('fila.email', '{"to":"user@mail.com","subject":"Bem-vindo"}')
        .Enqueue('fila.sms', '{"phone":"+5562999999999","msg":"Código: 1234"}',
                 qpHigh);

  // ── Iniciar consumer em background ──────────────
  LQueue.Start;

  Writeln('Worker ativo. Pressione ENTER para parar...');
  Readln;

  LQueue.Stop;
end;
