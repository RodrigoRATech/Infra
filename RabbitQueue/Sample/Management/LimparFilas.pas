procedure LimparFilas;
var
  LService: TRabbitMQManagementService;
  LResult: TBatchOperationResult;
begin
  LService := TRabbitMQManagementService.Create(
    TRabbitManagementConfig.Default);
  try
    // Purge específico
    LService.PurgeQueue('app.orders');

    // Purge em lote
    LResult := LService.PurgeQueues(['app.orders', 'app.payments', 'app.logs']);
    Writeln(LResult.Summary);

    // Purge por filtro (todas com prefixo 'temp.')
    var LFilter := TQueueDiscoveryFilter.None;
    LFilter.Prefix := 'temp.';
    LService.PurgeByFilter(LFilter);
  finally
    LService.Free;
  end;
end;
