program RabbitQueueDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.JSON,
  RabbitQueue,
  RabbitQueue.Interfaces,
  RabbitQueue.Interfaces.Events,
  RabbitQueue.Factory,
  RabbitQueue.Handlers.Base;

var
  Queue: TRabbitQueue;
  Config: IConnectionConfig;

procedure SetupEventHandlers;
begin
  // Eventos de conexão
  Queue.Events.OnConnected(
    procedure(Args: TConnectionEventArgs)
    begin
      WriteLn(Format('[%s] Conectado a %s:%d', 
        [FormatDateTime('hh:nn:ss', Args.Timestamp), Args.Host, Args.Port]));
    end
  );
  
  Queue.Events.OnDisconnected(
    procedure(Args: TConnectionEventArgs)
    begin
      WriteLn(Format('[%s] Desconectado', [FormatDateTime('hh:nn:ss', Args.Timestamp)]));
    end
  );
  
  Queue.Events.OnConnectionError(
    procedure(Args: TConnectionEventArgs)
    begin
      WriteLn(Format('[ERRO] Conexão: %s', [Args.ErrorMessage]));
    end
  );
  
  // Eventos de mensagem
  Queue.Events.OnBeforeEnqueue(
    procedure(Args: TMessageEventArgs)
    begin
      WriteLn(Format('[ENQUEUE] Enviando: %s', [Args.Message.MessageId]));
    end
  );
  
  Queue.Events.OnAfterEnqueue(
    procedure(Args: TMessageEventArgs)
    begin
      WriteLn(Format('[ENQUEUE] Enviado: %s', [Args.Message.MessageId]));
    end
  );
  
  // Eventos de processamento
  Queue.Events.OnBeforeProcessing(
    procedure(Args: TProcessingEventArgs)
    begin
      WriteLn(Format('[PROCESS] Iniciando: %s', [Args.Message.MessageId]));
    end
  );
  
  Queue.Events.OnAfterProcessing(
    procedure(Args: TProcessingEventArgs)
    begin
      WriteLn(Format('[PROCESS] Concluído: %s em %dms', 
        [Args.Message.MessageId, Args.ElapsedMs]));
    end
  );
  
  Queue.Events.OnProcessingError(
    procedure(Args: TProcessingEventArgs)
    begin
      WriteLn(Format('[ERRO] Processamento: %s - %s', 
        [Args.Message.MessageId, Args.ErrorMessage]));
    end
  );
  
  // Eventos de fila
  Queue.Events.OnQueueCreated(
    procedure(Args: TQueueEventArgs)
    begin
      WriteLn(Format('[QUEUE] Fila criada: %s', [Args.QueueName]));
    end
  );
end;

procedure RegisterHandlers;
begin
  // Handler para pedidos (routing key = 'order')
  Queue.RegisterHandler(
    TRabbitQueueFactory.CreateRoutingKeyHandler(
      'OrderHandler',
      'order',
      function(Context: IProcessingContext): TProcessResult
      var
        LJson: TJSONObject;
      begin
        WriteLn('  -> Processando pedido...');
        
        try
          LJson := TJSONObject.ParseJSONValue(Context.Message.Body) as TJSONObject;
          if Assigned(LJson) then
          begin
            try
              WriteLn(Format('     Pedido ID: %s', [LJson.GetValue<string>('orderId', 'N/A')]));
              WriteLn(Format('     Valor: R$ %.2f', [LJson.GetValue<Double>('amount', 0)]));
            finally
              LJson.Free;
            end;
          end;
          
          Result := prSuccess;
        except
          on E: Exception do
          begin
            WriteLn(Format('     Erro: %s', [E.Message]));
            Result := prRetry;
          end;
        end;
      end,
      100 // Alta prioridade
    )
  );
  
  // Handler para notificações (routing key = 'notification')
  Queue.RegisterHandler(
    TRabbitQueueFactory.CreateRoutingKeyHandler(
      'NotificationHandler',
      'notification',
      function(Context: IProcessingContext): TProcessResult
      begin
        WriteLn('  -> Enviando notificação...');
        WriteLn(Format('     Conteúdo: %s', [Context.Message.Body]));
        Result := prSuccess;
      end,
      50 // Prioridade média
    )
  );
  
  // Handler padrão (catch-all)
  Queue.RegisterHandler(
    TRabbitQueueFactory.CreateDelegateHandler(
      'DefaultHandler',
      function(Context: IProcessingContext): Boolean
      begin
        Result := True; // Aceita todas as mensagens
      end,
      function(Context: IProcessingContext): TProcessResult
      begin
        WriteLn('  -> Handler padrão');
        WriteLn(Format('     Body: %s', [Context.Message.Body]));
        Result := prSuccess;
      end,
      0 // Baixa prioridade
    )
  );
end;

procedure SendTestMessages;
var
  LMessage: IRabbitMessage;
begin
  WriteLn('');
  WriteLn('=== Enviando mensagens de teste ===');
  WriteLn('');
  
  // Mensagem de pedido
  LMessage := TRabbitQueueFactory.CreateMessage('{"orderId": "12345", "amount": 199.90}');
  LMessage.RoutingKey := 'order';
  Queue.Enqueue(LMessage);
  
  // Mensagem de notificação
  LMessage := TRabbitQueueFactory.CreateMessage('Bem-vindo ao sistema!');
  LMessage.RoutingKey := 'notification';
  Queue.Enqueue(LMessage);
  
  // Mensagem genérica
  Queue.Enqueue('Esta é uma mensagem simples');
end;

begin
  try
    WriteLn('=================================');
    WriteLn('   RabbitQueue Demo - Delphi     ');
    WriteLn('=================================');
    WriteLn('');
    
    // Configurar conexão
    Config := TRabbitQueueFactory.CreateConfig;
    Config.Host := 'localhost';
    Config.Port := 61613;
    Config.Username := 'guest';
    Config.Password := 'guest';
    Config.MaxRetries := 3;
    
    // Criar instância da fila
    Queue := TRabbitQueue.Create('demo-queue', Config);
    try
      // Configurar eventos
      SetupEventHandlers;
      
      // Registrar handlers
      RegisterHandlers;
      
      // Inicializar
      Queue.Initialize;
      
      // Enviar mensagens de teste
      SendTestMessages;
      
      // Iniciar consumo
      WriteLn('');
      WriteLn('=== Iniciando consumo ===');
      WriteLn('Pressione ENTER para parar...');
      WriteLn('');
      
      Queue.StartConsuming;
      
      // Aguardar input
      ReadLn;
      
      // Parar consumo
      Queue.StopConsuming;
      
      // Finalizar
      Queue.Finalize;
      
    finally
      Queue.Free;
    end;
    
    WriteLn('');
    WriteLn('Programa finalizado.');
    
  except
    on E: Exception do
    begin
      WriteLn('ERRO: ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
