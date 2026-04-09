unit Cache.Middleware.Horse;

interface

uses
  Horse, System.SysUtils,
  Cache.Interfaces;

type
  /// <summary>
  ///   Middleware para Horse que intercepta requisições GET.
  ///   Se o cache contém a resposta, retorna imediatamente;
  ///   caso contrário, deixa o fluxo seguir e salva o resultado no cache.
  /// </summary>
  TCacheMiddleware = class
  private
    class var FCacheManager: ICacheManager;
    class var FDefaultTTL: Integer;
    class function GenerateCacheKey(AReq: THorseRequest): string;
  public
    class procedure Initialize(ACacheManager: ICacheManager; ADefaultTTL: Integer = 300);
    class procedure Middleware(AReq: THorseRequest; ARes: THorseResponse;
      ANext: TProc);

    /// Retorna a callback no formato THorseCallback para registro direto
    class function New(ACacheManager: ICacheManager;
      ADefaultTTL: Integer = 300): THorseCallback;
  end;

implementation

uses
  System.NetEncoding, System.Hash, Web.HTTPApp;

{ TCacheMiddleware }

class function TCacheMiddleware.GenerateCacheKey(AReq: THorseRequest): string;
var
  LRawPath: string;
  LQuery: string;
begin
  LRawPath := AReq.RawWebRequest.PathInfo;
  LQuery := AReq.RawWebRequest.Query;

  if not LQuery.IsEmpty then
    Result := 'horse:' + THashMD5.GetHashString(LRawPath + '?' + LQuery)
  else
    Result := 'horse:' + THashMD5.GetHashString(LRawPath);
end;

class procedure TCacheMiddleware.Initialize(ACacheManager: ICacheManager;
  ADefaultTTL: Integer);
begin
  FCacheManager := ACacheManager;
  FDefaultTTL := ADefaultTTL;
end;

class procedure TCacheMiddleware.Middleware(AReq: THorseRequest;
  ARes: THorseResponse; ANext: TProc);
var
  LCacheKey: string;
  LCachedValue: string;
  LMethod: string;
begin
  if not Assigned(FCacheManager) then
  begin
    ANext();
    Exit;
  end;

  // Só intercepta GET
  LMethod := AReq.RawWebRequest.Method;
  if not SameText(LMethod, 'GET') then
  begin
    ANext();
    Exit;
  end;

  LCacheKey := GenerateCacheKey(AReq);

  // Tenta recuperar do cache
  if FCacheManager.GetString(LCacheKey, LCachedValue) then
  begin
    ARes.Send(LCachedValue).ContentType('application/json').Status(200);
    Exit;
  end;

  // Cache miss: deixa o fluxo seguir
  ANext();

  // Após o handler, captura a resposta e salva no cache
  try
    LCachedValue := ARes.Content;
    if (not LCachedValue.IsEmpty) and
       (ARes.RawWebResponse.StatusCode >= 200) and
       (ARes.RawWebResponse.StatusCode < 300) then
    begin
      FCacheManager.PutString(LCacheKey, LCachedValue, FDefaultTTL);
    end;
  except
    // Não interrompe o fluxo por falha no cache
  end;
end;

class function TCacheMiddleware.New(ACacheManager: ICacheManager;
  ADefaultTTL: Integer): THorseCallback;
begin
  Initialize(ACacheManager, ADefaultTTL);
  Result := Middleware;
end;

end.
