procedure RemoverFilasTemporarias;
var
  LService: TRabbitMQManagementService;
  LFilter: TQueueDiscoveryFilter;
begin
  LService := TRabbitMQManagementService.Create(
    TRabbitManagementConfig.Default);
  try
    // Delete por filtro
    LFilter := TQueueDiscoveryFilter.None;
    LFilter.Prefix := 'temp.';
    LFilter.OnlyDurable := False;

    var LResult := LService.DeleteByFilter(LFilter);
    Writeln(LResult.Summary);
  finally
    LService.Free;
  end;
end;
