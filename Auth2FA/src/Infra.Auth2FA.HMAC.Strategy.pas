unit Infra.Auth2FA.HMAC.Strategy;

interface

uses
  System.SysUtils,
  System.Hash,
  Infra.Auth2FA.Interfaces;

type
  /// <summary>
  ///   Classe base abstrata para estratégias HMAC
  /// </summary>
  THMACStrategyBase = class abstract(TInterfacedObject, IHMACStrategy)
  public
    function ComputeHMAC(const AKey, AMessage: TBytes): TBytes; virtual; abstract;
    function GetAlgorithmName: string; virtual; abstract;
  end;

  /// <summary>
  ///   HMAC-SHA1 — Padrão do Google Authenticator (RFC 6238)
  /// </summary>
  THMACSHA1Strategy = class(THMACStrategyBase)
  public
    function ComputeHMAC(const AKey, AMessage: TBytes): TBytes; override;
    function GetAlgorithmName: string; override;
  end;

  /// <summary>
  ///   HMAC-SHA256
  /// </summary>
  THMACSHA256Strategy = class(THMACStrategyBase)
  public
    function ComputeHMAC(const AKey, AMessage: TBytes): TBytes; override;
    function GetAlgorithmName: string; override;
  end;

  /// <summary>
  ///   HMAC-SHA512
  /// </summary>
  THMACSHA512Strategy = class(THMACStrategyBase)
  public
    function ComputeHMAC(const AKey, AMessage: TBytes): TBytes; override;
    function GetAlgorithmName: string; override;
  end;

  /// <summary>
  ///   Factory para seleção do algoritmo HMAC (Factory Method)
  /// </summary>
  THMACStrategyFactory = class
  public
    class function CreateStrategy(const AAlgorithm: TTOTPAlgorithm): IHMACStrategy;
  end;

implementation

{ THMACSHA1Strategy }

function THMACSHA1Strategy.ComputeHMAC(const AKey, AMessage: TBytes): TBytes;
begin
  Result := THashSHA1.GetHMACAsBytes(AMessage, AKey);
end;

function THMACSHA1Strategy.GetAlgorithmName: string;
begin
  Result := 'SHA1';
end;

{ THMACSHA256Strategy }

function THMACSHA256Strategy.ComputeHMAC(const AKey, AMessage: TBytes): TBytes;
begin
  Result := THashSHA2.GetHMACAsBytes(AMessage, AKey, SHA256);
end;

function THMACSHA256Strategy.GetAlgorithmName: string;
begin
  Result := 'SHA256';
end;

{ THMACSHA512Strategy }

function THMACSHA512Strategy.ComputeHMAC(const AKey, AMessage: TBytes): TBytes;
begin
  Result := THashSHA2.GetHMACAsBytes(AMessage, AKey, SHA512);
end;

function THMACSHA512Strategy.GetAlgorithmName: string;
begin
  Result := 'SHA512';
end;

{ THMACStrategyFactory }

class function THMACStrategyFactory.CreateStrategy(
  const AAlgorithm: TTOTPAlgorithm): IHMACStrategy;
begin
  case AAlgorithm of
    taSHA1:   Result := THMACSHA1Strategy.Create;
    taSHA256: Result := THMACSHA256Strategy.Create;
    taSHA512: Result := THMACSHA512Strategy.Create;
  else
    raise EArgumentException.Create('Algoritmo HMAC não suportado');
  end;
end;

end.
