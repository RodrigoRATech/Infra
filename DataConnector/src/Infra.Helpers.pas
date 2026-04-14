unit Infra.Helpers;

interface

//http://devspace.tuttoilmondo.com.br/desenvolvimento/class-helpers-aumentando-a-produtividade-do-desenvolvimento-em-delphi/

uses Data.Db,

     System.Rtti,
     System.Variants,
     System.SysUtils,
     System.StrUtils,
     System.DateUtils,
     System.SysConst,
     System.TypInfo,
     System.JSON,
     System.Types,

     System.Character,
     System.NetEncoding,
     System.Classes,
     System.Hash,
     System.RegularExpressions,

     XML.XMLIntf,
     XML.XMLDoc,
     XML.xmldom,

     FMX.Objects,
     FMX.Graphics,

     Soap.EncdDecd,

     Infra.Types;

type
   TSystemActionsHelper = record helper for TSystemActions
      function ToString:String;
      procedure FromString( aValue:String);
   end;

   TFieldTypeHelper = record helper for TFieldType
      function ToString:String;
      function FromString( Value:String):TFieldType;
      function ftToString:String;
      procedure ftFromString( aValue:string);
   end;

   TEnvironmentTypeHelper = record helper for TEnvironmentType
      function ToString:String;
      procedure FromString( aValue:String);
   end;


   TIntegerHelper = record helper for integer
   const
      MaxValue = 2147483647;
      MinValue = -2147483648;

      function ToBoolean: Boolean; inline;
      function ToHexString: string; overload; inline;
      function ToHexString(const MinDigits: Integer): string; overload;
      function ToSingle: Single; inline;
      function ToDouble: Double; inline;
      function ToExtended: Extended; inline;

      function Size: Integer;

      procedure Inc( N:integer = 1);
      procedure Dec( N:integer = 1);
      procedure Pred;
      procedure Succ;
      function MinorThan( aValue:Integer):Boolean;

      function ToJSONNumber:TJSONNumber;
      function ToString:String;
      procedure FromJSONNumber( Value:TJSONNumber);
      procedure FromJSONString( Value:TJSONString);
   end;

   TDoubleHelper = record helper for double
   private
      function InternalGetBytes(Index: Cardinal): UInt8; inline;
      function InternalGetWords(Index: Cardinal): UInt16; inline;
      procedure InternalSetBytes(Index: Cardinal; const Value: UInt8); inline;
      procedure InternalSetWords(Index: Cardinal; const Value: UInt16); inline;
      function GetBytes(Index: Cardinal): UInt8;
      function GetWords(Index: Cardinal): UInt16;
      function GetExp: UInt64; inline;
      function GetFrac: UInt64; inline;
      function GetSign: Boolean; inline;
      procedure SetBytes(Index: Cardinal; const Value: UInt8);
      procedure SetWords(Index: Cardinal; const Value: UInt16);
      procedure SetExp(NewExp: UInt64);
      procedure SetFrac(NewFrac: UInt64);
      procedure SetSign(NewSign: Boolean);

   public
      const
         Epsilon:Double = 4.9406564584124654418e-324;
         MaxValue:Double =  1.7976931348623157081e+308;
         MinValue:Double = -1.7976931348623157081e+308;
         PositiveInfinity:Double =  1.0 / 0.0;
         NegativeInfinity:Double = -1.0 / 0.0;
         NaN:Double = 0.0 / 0.0;

      function Exponent: Integer;
      function Fraction: Extended;
      function Mantissa: UInt64;

      property Sign: Boolean read GetSign write SetSign;
      property Exp: UInt64 read GetExp write SetExp;
      property Frac: UInt64 read GetFrac write SetFrac;

      function SpecialType: TFloatSpecial;
      procedure BuildUp(const SignFlag: Boolean; const Mantissa: UInt64; const Exponent: Integer);
      function ToString: string; overload; inline;
      function ToString(const AFormatSettings: TFormatSettings): string; overload; inline;
      function ToString(const Format: TFloatFormat; const Precision, Digits: Integer): string; overload; inline;
      function ToString(const Format: TFloatFormat; const Precision, Digits: Integer;
                           const AFormatSettings: TFormatSettings): string; overload; inline;
      function ToJSONNumber:TJSONNumber;
      function IsNan: Boolean; overload; inline;
      function IsInfinity: Boolean; overload; inline;
      function IsNegativeInfinity: Boolean; overload; inline;
      function IsPositiveInfinity: Boolean; overload; inline;

      property Bytes[Index: Cardinal]: UInt8 read GetBytes write SetBytes;  // 0..7
      property Words[Index: Cardinal]: UInt16 read GetWords write SetWords; // 0..3

      class function ToString(const Value: Double): string; overload; inline; static;
      class function ToString(const Value: Double; const AFormatSettings: TFormatSettings): string; overload; inline; static;
      class function ToString(const Value: Double; const Format: TFloatFormat; const Precision, Digits: Integer): string; overload; inline; static;
      class function ToString(const Value: Double; const Format: TFloatFormat; const Precision, Digits: Integer;
                                 const AFormatSettings: TFormatSettings): string; overload; inline; static;
      class function Parse(const S: string): Double; overload; static;
      class function Parse(const S: string; const AFormatSettings: TFormatSettings): Double; overload; static;
      class function TryParse(const S: string; out Value: Double): Boolean; overload;
        {$IFNDEF EXTENDEDHAS10BYTES}inline;{$ENDIF}static;
      class function TryParse(const S: string; out Value: Double; const AFormatSettings: TFormatSettings): Boolean; overload;
        {$IFNDEF EXTENDEDHAS10BYTES}inline;{$ENDIF}static;
      class function IsNan(const Value: Double): Boolean; overload; inline; static;
      class function IsInfinity(const Value: Double): Boolean; overload; inline; static;
      class function IsNegativeInfinity(const Value: Double): Boolean; overload; inline; static;
      class function IsPositiveInfinity(const Value: Double): Boolean; overload; inline; static;
      class function Size: Integer; inline; static;

   end;

   TDateTimeHelper = record helper for TDateTime
      function ToJSONDateTime:String;
      function ToJSONDate:String;
      function ToJSONTime:String;
      function ToString:String;
      function ToStrFmt( aValue:String = 'DD/MM/YYYY'):String;
      function isNull:Boolean;
      procedure FromJSONDateTime( Value:String);
      procedure FromString( aValue:String);

      function ToISO8601(const ADateTime: TDateTime; AUseUTC: Boolean = True): string;
      function FromISO8601(const AValue: string): TDateTime;
      function ToUnixTimestamp(const ADateTime: TDateTime): Int64;
      function FromUnixTimestamp(ATimestamp: Int64): TDateTime;
      function AddMinutes(const ADateTime: TDateTime; AMinutes: Integer): TDateTime;
      function AddDays(const ADateTime: TDateTime; ADays: Integer): TDateTime;
   end;

   TDateHelper = record helper for TDate
      function ToJSONDate:String;
      function ToString:String;
      function ToStrFmt( aValue:String = 'DD/MM/YYYY'):String;
      function isNull:Boolean;
      procedure FromJSONDate( Value:String);
      procedure FromString( aValue:String);
   end;

   TTimeHelper = record helper for TTime
      function ToJSONTime:String;
      function ToString:String;
      function isNull:Boolean;
      procedure FromJSONTime( Value:String);
      procedure FromString( aValue:String);
   end;

   TStringHelper = record helper for string
   strict private
      function  GetChar(AIndex: Integer): Char;
      procedure SetChar(AIndex: Integer; const Value: Char);

   public
      procedure Clear;
      procedure CreateGUID;
      function Concat(const AElements: TArray<string>): string;
      function Replace(const APatern, ANewValue: string; AFlags: TReplaceFlags): string;
      function RemoveChar(const AChar: Char): string;
      function RemoveChars(const AChars: array of Char): string;
      function CountOccurrences(const AChar: Char): Integer;
      function IncludeTrailingPathDelimiter: string;
      function IsEmpty: Boolean;
      function IsFloat: Boolean;
      function IsNumbersOnly: Boolean;
      function IsLettersOnly: Boolean;
      function IsMD5Hash: Boolean;
      function IsGUID: Boolean;
      function IsBoolean: Boolean;
      function InArray(const AArray: TArray<string>): Boolean;
      function Equals(const AStr: string): Boolean;
      function Compare(const AStr: string): Integer;
      function NumbersOnly: string;
      function LettersOnly: string;
      function Contains(const AStr: string): Boolean; overload;
      function Contains(const AStrs: array of string; const AAny: Boolean = True): Boolean; overload;
      function Quoted(const AQuoteChar: Char = #39): string;
      function DoubleQuote: string;
      function Unquote: string;
      function Format(const ATerms: array of const): string;
      function ToLower: string;
      function ToUpper: string;
      function ToUTF8: string;

      class function IsNullOrEmpty(const Value: string): Boolean; static;
      class function IsNullOrWhiteSpace(const Value: string): Boolean; static;
      class function Join(const Separator: string; const Values: array of string): string; overload; static;
      class function Join(const Separator: string; const Values: IEnumerator<string>): string; overload; static;
      class function Join(const Separator: string; const Values: IEnumerable<string>): string; overload; static; inline;
      class function Join(const Separator: string; const Values: array of string; StartIndex: Integer; Count: Integer): string; overload; static;

      {$IFDEF ANDROID}
      {$ELSE}
      function ToAnsi: AnsiString;
      {$ENDIF}
      function Trim: string;
      function TrimLeft: string;
      function TrimRight: string;
      function FirstUpper: string;
      function LPAD(const ALength: Integer; const AChar: Char): string;
      function RPAD(const ALength: Integer; const AChar: Char): string;
      function LeftSpaces(const ANumSpaces: Integer): string;
      function RightSpaces(const ANumSpaces: Integer): string;
      function ToInteger(const ADefValue: Integer = 0; const IsHex: Boolean = False): Integer;
      function ToFloat(const ADefValue: Extended = 0): Extended;
      function Copy(const AStart, ALength: Integer): string;
      function Delete(const AStart, ALength: Integer): string;
      function Length: Integer;
      function LengthBetween(const ALowerLimit, AHigherLimit: Integer): Boolean;
      function EscapeQuotes(const AQuote: Char = '"'): string;
      function ToJSONObject: TJSONObject;
      function ToJSONArray:TJSONArray;
      function Split(const ASeparator: Char): TArray<string>; overload;
      function Split(const ASeparator: string): TArray<string>; overload;
      function Pos(const ASubStr: string): Integer;
      function PosEx(const ASubStr: string; const AOffset: Integer): Integer;
      function Unaccent: string;
      function ToBase64: string;
      function DecodeBase64: string;
      function RemoveEscapes: string;
      property Char[AIndex: Integer]: Char read GetChar write SetChar;
      procedure ToJSON( aJSON:TJSONObject; aName:string; aNull:Boolean = false);
   end;

   TJSONValueHelper = class helper for TJSONValue
      procedure Clear;
      function Length: Integer;
      function InRange(const AMin, AMax: Integer): Boolean;
      function InRangeF(const AMin, AMax: Double): Boolean;

      function IsJSONObject: Boolean;
      function IsJSONArray: Boolean;
      function IsChar: Boolean;
      function IsString: Boolean;
      function IsInteger: Boolean;
      function IsFloat: Boolean;
      function IsBoolean: Boolean;
      function IsDateTime:Boolean;
      function IsNull:Boolean;

      function AsJSONArray: TJSONArray;
      function AsJSONObject: TJSONObject;
      function AsInteger: Integer;
      function AsFloat: Double;
      function AsString: String;
      function AsBoolean: Boolean;
      function AsDateTime: TDateTime;
      function AsUnsignedInt: UInt64;

      function JSONValueToFieldType:TFieldType;
      function JSONValueToTValue:TValue;
      function JSONValueToVariant:Variant;
   end;

   TBooleanHelper = record helper for Boolean
      function ToJSONBool:TJSONBool;
   end;

   TValueHelper = record helper for TValue
      function ValueToFieldType:TFieldType;
      function IsNull:Boolean;
   end;

   TVariantHelper = record helper for Variant
   public
      function ToJSONValue:TJSONValue;
      function ToStr:AnsiString;
   end;

   TImageHelper = class helper for TImage
   public
      function AsBase64:String;
      procedure FromBase64( aValue:String);
   end;

   TDataTypeHelper = record helper for TDataType
      procedure FromStr( aValue:String);
      function ToStr:String;
   end;

   TDataManagerHelper = record helper for TDataManager
      procedure FromStr( aValue:String);
      function ToStr:String;
   end;

   TDataEngineHelper = record helper for TDataEngine
      procedure FromStr( aValue:String);
      function ToStr:String;
   end;

   TUserAuthTypeHelper = record helper for TUserAuthType
      procedure FromStr( aValue:String);
      function ToStr:String;
   end;

   TIntervalTypeHelper = record helper for TIntervalType
      procedure FromStr( aValue:String);
      function ToStr:String;
   end;

   TValidationHelper = class
   public
      class function IsValidEmail(const AEmail: string): Boolean;
      class function IsValidGUID(const AValue: string): Boolean;
      class function IsStrongPassword(const APassword: string; AMinLength: Integer = 8): Boolean;
      class function IsValidCPF(const ACPF: string): Boolean;
      class function IsValidCNPJ(const ACNPJ: string): Boolean;
   end;

implementation

// Plataforma
uses Infra.Data.Core.Attributes;

procedure ConvertErrorFmt(ResString: PResStringRec; const Args: array of const); {$IFDEF ELF} local; {$ENDIF}
begin
  raise EConvertError.CreateResFmt(ResString, Args);
end;

{ TFieldTypeHelper }

function TFieldTypeHelper.FromString(Value: String): TFieldType;
begin
   Result := ftUnknown;

   case IndexStr( Value, [ 'String',
                           'Int64',
                           'Integer',
                           'Boolean',
                           'Float',
                           'Date',
                           'Time',
                           'DateTime',
                           'Graphic',
                           'Blob']) of
      0:Result := ftString;
      1:Result := ftLargeInt;
      2:Result := ftInteger;
      3:Result := ftBoolean;
      4:Result := ftFloat;
      5:Result := ftDate;
      6:Result := ftTime;
      7:Result := ftDateTime;
      8:Result := ftGraphic;
      9:Result := ftBlob;
   end;
end;

procedure TFieldTypeHelper.ftFromString( aValue:string);
begin
   Self := TFieldType( GetEnumValue( TypeInfo( TFieldType), aValue));
end;

function TFieldTypeHelper.ftToString: String;
begin
   Result := GetEnumName( TypeInfo( TFieldType), Ord( Self));
end;

function TFieldTypeHelper.ToString: String;
begin
   case Self of
      ftByte,
      ftFixedWideChar,
      ftFixedChar,
      ftWideString,
      ftBytes,
      ftVarBytes,
      ftString:Result   := 'String';

      ftLargeint:Result := 'Int64';

      //ftSingle,
      ftLongWord,
      ftShortint,
      ftSmallint,
      ftInteger,
      ftWord:Result := 'Integer';

      ftBoolean:Result := 'Boolean';

      ftFMTBcd,
      //ftExtended,
      ftFloat,
      ftCurrency,
      ftBCD:Result := 'Float';

      ftDate:Result := 'Date';
      ftTime:Result := 'Time';
      ftOraTimeStamp,
      ftTimeStamp,
      ftDateTime:Result := 'DateTime';

      ftBlob,
      ftMemo,
      ftFmtMemo,
      ftParadoxOle,
      ftDBaseOle,
      ftWideMemo,
      ftTypedBinary:Result := 'Blob';
      ftGraphic: Result    := 'Graphic';
   end;
end;

{ TIntegerHelper }

procedure TIntegerHelper.Dec(N: integer);
begin
   System.Dec( Self, N);
end;

procedure TIntegerHelper.FromJSONNumber(Value: TJSONNumber);
begin
   Self := Value.AsInt;
end;

procedure TIntegerHelper.FromJSONString(Value: TJSONString);
begin
   Self := Value.AsType<Integer>;
end;

procedure TIntegerHelper.Inc(N: integer);
begin
   System.Inc( Self, N);
end;

function TIntegerHelper.MinorThan(aValue: Integer): Boolean;
begin
   Result := Self < aValue;
end;

function TIntegerHelper.ToJSONNumber: TJSONNumber;
begin
   Result := TJSONNumber.Create( Self);
end;

function TIntegerHelper.ToString: String;
begin
   Result := IntToStr( Self);
end;

function TIntegerHelper.Size: Integer;
begin
  Result := SizeOf(Integer);
end;

procedure TIntegerHelper.Succ;
begin
   Self := System.Succ( Self);
end;

procedure TIntegerHelper.Pred;
begin
   Self := System.Pred( Self);
end;

function TIntegerHelper.ToBoolean: Boolean;
begin
  Result := Self <> 0;
end;

function TIntegerHelper.ToHexString: string;
begin
  Result := IntToHex(Self);
end;

function TIntegerHelper.ToHexString(const MinDigits: Integer): string;
begin
  Result := System.SysUtils.IntToHex(Self, MinDigits);
end;

function TIntegerHelper.ToSingle: Single;
begin
  Result := Self;
end;

function TIntegerHelper.ToDouble: Double;
begin
  Result := Self;
end;

function TIntegerHelper.ToExtended: Extended;
begin
  Result := Self;
end;

{ TDateTimeHelper }

function TDateTimeHelper.AddDays(const ADateTime: TDateTime; ADays: Integer): TDateTime;
begin
   Result := IncDay(ADateTime, ADays);
end;

function TDateTimeHelper.AddMinutes(const ADateTime: TDateTime; AMinutes: Integer): TDateTime;
begin
   Result := IncMinute(ADateTime, AMinutes);
end;

function TDateTimeHelper.FromISO8601(const AValue: string): TDateTime;
begin
   Result := ISO8601ToDate(AValue, True);
end;

procedure TDateTimeHelper.FromJSONDateTime(Value: String);
begin
   if not Value.IsEmpty then
   begin
      Value := Value.Replace( '\', '', [rfReplaceAll]);
      Self := ISO8601ToDate( Value)
   end;
end;

procedure TDateTimeHelper.FromString(aValue: String);
begin
   if not aValue.IsEmpty then
   begin
      aValue := aValue.Replace( '\', '', [rfReplaceAll]);
      Self := StrToDate( aValue);
   end;
end;

function TDateTimeHelper.FromUnixTimestamp(ATimestamp: Int64): TDateTime;
begin
   Result := UnixToDateTime(ATimestamp, True);
end;

function TDateTimeHelper.isNull: Boolean;
begin
   Result := Self <= 0;
end;

function TDateTimeHelper.ToISO8601(const ADateTime: TDateTime; AUseUTC: Boolean): string;
begin
   if AUseUTC then
      Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz"Z"', ADateTime)
   else Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz', ADateTime);
end;

function TDateTimeHelper.ToJSONDate: String;
begin
   Result := DateToISO8601( Self)
end;

function TDateTimeHelper.ToJSONDateTime: String;
begin
   Result := DateToISO8601( Self)
end;

function TDateTimeHelper.ToJSONTime: String;
begin
   Result := DateToISO8601( Self)
end;

function TDateTimeHelper.ToStrFmt(aValue: String): String;
begin
   Result := FormatDateTime( aValue, Self);
end;

function TDateTimeHelper.ToString: String;
begin
   Result := DateToStr( Self);
end;

function TDateTimeHelper.ToUnixTimestamp(const ADateTime: TDateTime): Int64;
begin
   Result := DateTimeToUnix(ADateTime, True);
end;

{ TDateHelper }

procedure TDateHelper.FromJSONDate(Value: String);
begin
   if not Value.IsEmpty then
   begin
      Value := Value.Replace( '\', '', [rfReplaceAll]);
      Self := ISO8601ToDate( Value);
   end;
end;

procedure TDateHelper.FromString(aValue: String);
begin
   if not aValue.IsEmpty then
   begin
      aValue := aValue.Replace( '\', '', [rfReplaceAll]);
      Self := StrToDate( aValue);
   end;
end;

function TDateHelper.isNull: Boolean;
begin
   Result := Self <= 0;
end;

function TDateHelper.ToJSONDate: String;
begin
   Result := DateToISO8601( Self)
end;

function TDateHelper.ToStrFmt(aValue: String): String;
begin
   Result := FormatDateTime( aValue, Self);
end;

function TDateHelper.ToString: String;
begin
   Result := DateToStr( Self);
end;

{ TTimeHelper }

procedure TTimeHelper.FromJSONTime(Value: String);
Var hora, minuto, segundo:integer;
begin
   Value := Value.Replace( '\', '', [rfReplaceAll]);
   hora := StrToInt( Copy( Value, 1, Pos(':', Value)-1));
   Delete( Value, 1, Pos(':', Value));
   minuto := StrToInt( Copy( Value, 1, Pos(':', Value)-1));
   Delete( Value, 1, Pos(':', Value));
   segundo := StrToIntDef( Value, 0);

   Self := EncodeTime( Hora, Minuto, Segundo, 0);;
end;

procedure TTimeHelper.FromString(aValue: String);
Var hora, minuto, segundo:integer;
begin
   aValue := aValue.Replace( '\', '', [rfReplaceAll]);
   hora := StrToInt( Copy( aValue, 1, Pos(':', aValue)-1));
   Delete( aValue, 1, Pos(':', aValue));
   minuto := StrToInt( Copy( aValue, 1, Pos(':', aValue)-1));
   Delete( aValue, 1, Pos(':', aValue));
   segundo := StrToIntDef( aValue, 0);

   Self := EncodeTime( Hora, Minuto, Segundo, 0);
end;

function TTimeHelper.isNull: Boolean;
begin
   Result := Self <= 0;
end;

function TTimeHelper.ToJSONTime: String;
begin
   Result := FormatDateTime( 'hh:mm:ss', Self);
end;

function TTimeHelper.ToString: String;
begin
   Result := TimeToStr( Self);
end;

{ TJSONValueHelper }

function TJSONValueHelper.AsBoolean: Boolean;
begin
  case Self is TJSONNull of
    True : Result := false;
    False:
    begin
      try
        Result := Self.GetValue<Boolean>;
      except
        Result := False;
      end;
    end;
  end;
end;

function TJSONValueHelper.AsDateTime: TDateTime;
begin
  try
    Result := ISO8601ToDate(Self.AsString.Trim);
  except
    Result := 0;
  end;
end;

function TJSONValueHelper.AsFloat: Double;
begin
  case Self is TJSONNull of
    True : Result := 0;
    False:
    begin
      try
        Result := Self.GetValue<Double>;
      except
        Result := 0;
      end;
    end;
  end;
end;

function TJSONValueHelper.AsInteger: Integer;
begin
  case Self is TJSONNull of
    True : Result := 0;
    False:
    begin
      try
        Result := Self.GetValue<Integer>;
      except
        Result := 0;
      end;
    end;
  end;
end;

function TJSONValueHelper.AsJSONArray: TJSONArray;
begin
  try
    Result := Self as TJSONArray;
  except
    Result := nil;
  end;
end;

function TJSONValueHelper.AsJSONObject: TJSONObject;
begin
  try
    Result := Self as TJSONObject;
  except
    Result := nil;
  end;
end;

function TJSONValueHelper.AsString: String;
begin
  try
    case Self.ToString.Trim = 'null' of
      True : Result := EmptyStr;
      False: Result := Self.ToString.Trim.Unquote;
    end;
  except
    Result := EmptyStr;
    Self.Clear;
  end;
end;

function TJSONValueHelper.AsUnsignedInt: UInt64;
begin
  case Self is TJSONNull of
    True : Result := 0;
    False:
    begin
      try
        Result := Self.GetValue<UInt64>;
      except
        Result := 0;
      end;
    end;
  end;
end;

procedure TJSONValueHelper.Clear;
begin
  if Assigned(Self) then
  begin
    {$IFNDEF VCL}
    Self.Free;
    {$ELSE}
    FreeAndNil(Self);
    {$ENDIF}
  end;
end;

function TJSONValueHelper.InRange(const AMin, AMax: Integer): Boolean;
begin
  Result := IsInteger and
            (Self.AsInteger >= AMin) and
            (Self.AsInteger <= AMax);
end;

function TJSONValueHelper.InRangeF(const AMin, AMax: Double): Boolean;
begin
  Result := IsFloat and
            (Self.AsFloat >= AMin) and
            (Self.AsFloat <= AMax);
end;

function TJSONValueHelper.IsBoolean: Boolean;
var
  strValue: string;
begin
  strValue := Self.AsString.ToLower;
  Result   := (strValue = 'true') or (strValue = 'false');
end;

function TJSONValueHelper.IsChar: Boolean;
begin
  Result := Self.AsString.Length = 1;
end;

function TJSONValueHelper.IsDateTime: Boolean;
begin
   try
      ISO8601ToDate(Self.AsString.Trim);
      Result := True;
   except
      Result := False;
   end;
end;

function TJSONValueHelper.IsFloat: Boolean;
var
  strValue: string;
begin
  strValue := Self.AsString;
  Result   := strValue.Contains('.') and (strValue.Length - strValue.NumbersOnly.Length = 1);
end;

function TJSONValueHelper.IsInteger: Boolean;
begin
  Result := Self.AsString.IsNumbersOnly;
end;

function TJSONValueHelper.IsJSONArray: Boolean;
begin
  try
    Result := Self is TJSONArray;
  except
    Result := False;
  end;
end;

function TJSONValueHelper.IsJSONObject: Boolean;
begin
  try
    Result := Self is TJSONObject;
  except
    Result := False;
  end;
end;

function TJSONValueHelper.IsNull: Boolean;
begin
   Result := Self is TJSONNull;
end;

function TJSONValueHelper.IsString: Boolean;
begin
  Result := (( Self.AsString.LettersOnly.Length > 0) or
             ( Self.ToString.Trim.Copy( 1, 1) = '"'));
end;

function TJSONValueHelper.JSONValueToFieldType: TFieldType;
begin
   Result := ftUnknown;

   if IsJSONObject then
      Result := ftObject
   else if IsString then
           Result := ftString
   else if IsInteger then
           Result := ftInteger
   else if IsFloat then
           Result := ftFloat
   else if IsBoolean then
           Result := ftBoolean
   else if IsDateTime then
           Result := ftDateTime;
end;

function TJSONValueHelper.JSONValueToTValue: TValue;
begin
   if IsJSONObject then
      Result := TValue.From( Self.AsJSONObject)
   else if IsInteger then
           Result := TValue.From( Self.AsInteger)
   else if IsFloat then
           Result := TValue.From( Self.AsFloat)
   else if IsBoolean then
           Result := TValue.From( Self.AsBoolean)
   else if IsDateTime then
           Result := TValue.From( Self.AsDateTime)
   else Result := TValue.From( Self.AsType<String>);
end;

function TJSONValueHelper.JSONValueToVariant: Variant;
begin
   Result := Unassigned;

   if IsString then
      Result := Self.AsString.Unquote
   else if IsInteger then
           Result := Self.AsInteger
   else if IsFloat then
           Result := Self.AsFloat
   else if IsBoolean then
           Result := Self.AsBoolean
   else if IsDateTime then
           Result := Self.AsDateTime;
end;

function TJSONValueHelper.Length: Integer;
begin
  Result := Self.AsString.Length;
end;

{ TBooleanHelper }

function TBooleanHelper.ToJSONBool: TJSONBool;
begin
   Result := TJSONBool.Create( Self);
end;

{ TStringHelper }

function TStringHelper.Contains(const AStr: string): Boolean;
begin
  Result := System.Pos(AStr, Self) > 0;
end;

procedure TStringHelper.Clear;
begin
  Self := EmptyStr;
end;

function TStringHelper.Compare(const AStr: string): Integer;
begin
  Result := CompareStr(Self, AStr);
end;

function TStringHelper.Concat(const AElements: TArray<string>): string;
var
  i: Integer;
begin
  Result := Self;

  for i := 0 to Pred(System.Length(AElements)) do
  begin
    Result := Result + AElements[i];
  end;
end;

function TStringHelper.Contains(const AStrs: array of string; const AAny: Boolean): Boolean;
var
  i: Integer;
begin
  Result := False;

  for i := 0 to System.Length(AStrs) do
  begin
    if Self.Contains(AStrs[i]) then
    begin
      Continue;
    end;

    Result := Contains(AStrs[i]);

    case AAny of
      True :
      begin
        if Result then
        begin
          Exit;
        end;
      end;
      False:
      begin
        if not Result then
        begin
          Exit;
        end;
      end;
    end;
  end;
end;

function TStringHelper.Copy(const AStart, ALength: Integer): string;
begin
  Result := System.Copy(Self, AStart, ALength);
end;

function TStringHelper.CountOccurrences(const AChar: Char): Integer;
var
  i: Integer;
begin
  Result := 0;

  {$IFDEF ANDROID}
  for i := 0 to Pred(Length) do
  {$ELSE}
  for i := 1 to Length do
  {$ENDIF}
  begin
    if Self[i] = AChar then
    begin
      Inc(Result);
    end;
  end;
end;

procedure TStringHelper.CreateGUID;
var
  guidGUID: TGUID;
begin
  System.SysUtils.CreateGUID(guidGUID);
  Self := guidGUID.ToString.ToLower.Replace('{', EmptyStr, [rfReplaceAll]).Replace('}', EmptyStr, [rfReplaceAll]);
end;

function TStringHelper.DecodeBase64: string;
var
  stmInput : TStringStream;
  stmOutput: TStringStream;
  LStr:String;
begin
   Result := EmptyStr;

   if Self.IsEmpty then
     Exit;

   stmOutput := TStringStream.Create;
   stmInput  := TStringStream.Create( Self);
   try
   try
      stmOutput.SetSize( stmInput.Size);
      stmOutput.Position := 0;
      stmInput.Position  := 0;
      TNetEncoding.Base64.Decode( stmInput, stmOutput);
      stmOutput.Position := 0;
      Result := stmOutput.DataString;

   finally
      stmInput.Free;
      stmOutput.Free;
   end;
   except
      on e:exception do
         LStr := e.Message;
   end;
end;

function TStringHelper.Delete(const AStart, ALength: Integer): string;
begin
  System.Delete(Self, AStart, ALength);
end;

function TStringHelper.DoubleQuote: string;
begin
  Result := Self.Replace(#39, #39#39, [rfReplaceAll]);
end;

function TStringHelper.Equals(const AStr: string): Boolean;
begin
  Result := Self = AStr;
end;

function TStringHelper.EscapeQuotes(const AQuote: Char): string;
begin
  Result := StringReplace(Self, AQuote, '\' + AQuote, [rfReplaceAll]);
end;

function TStringHelper.FirstUpper: string;
var
  strFirst: string;
begin
  Result    := Self.ToLower;
  strFirst  := Result[1];
  Result[1] := System.SysUtils.UpperCase(strFirst)[1];
end;

function TStringHelper.Format(const ATerms: array of const): string;
begin
  Result := System.SysUtils.Format(Self, ATerms);
end;

function TStringHelper.GetChar(AIndex: Integer): Char;
begin
  Result := Self[AIndex];
end;

function TStringHelper.InArray(const AArray: TArray<string>): Boolean;
var
  strElement: string;
begin
  Result := False;

  for strElement in AArray do
  begin
    Result := Self.Equals(strElement);

    if Result then
    begin
      Break;
    end;
  end;
end;

function TStringHelper.IncludeTrailingPathDelimiter: string;
begin
  Result := System.SysUtils.IncludeTrailingPathDelimiter(Self);
end;

function TStringHelper.IsBoolean: Boolean;
begin
  Result := Self.ToLower.Equals('true') or Self.ToLower.Equals('false');
end;

function TStringHelper.IsEmpty: Boolean;
begin
  Result := Self = EmptyStr;
end;

function TStringHelper.IsFloat: Boolean;
begin
  Result := (Self.CountOccurrences(FormatSettings.DecimalSeparator) = 1) and
            Self.Replace(FormatSettings.DecimalSeparator, EmptyStr, [rfReplaceAll]).IsNumbersOnly;
end;

function TStringHelper.IsGUID: Boolean;
begin
  Result := TRegEx.IsMatch(Self, '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}');
end;

function TStringHelper.IsLettersOnly: Boolean;
begin
  Result := TRegEx.IsMatch(Self, '[a-zA-Z]+');
end;

function TStringHelper.IsMD5Hash: Boolean;
begin
  Result := TRegEx.IsMatch(Self, '[a-f0-9]{32}');
end;

class function TStringHelper.IsNullOrEmpty(const Value: string): Boolean;
begin
   Result := Value = EmptyStr;
end;

class function TStringHelper.IsNullOrWhiteSpace(const Value: string): Boolean;
begin
  Result := Value.Trim.Length = 0;
end;

function TStringHelper.IsNumbersOnly: Boolean;
begin
  Result := TRegEx.IsMatch(Self, '[0-9]+');
end;

class function TStringHelper.Join(const Separator: string;
  const Values: array of string): string;
begin
  Result := Join(Separator, Values, 0, System.Length(Values));
end;

class function TStringHelper.Join(const Separator: string;
  const Values: array of string; StartIndex, Count: Integer): string;
var
  I: Integer;
  Max: Integer;
begin
  if (Count = 0) or ((System.Length(Values) = 0) and (StartIndex = 0)) then
    Result := ''
  else
  begin
    if (Count < 0) or (StartIndex >= System.Length(Values)) then
      raise ERangeError.CreateRes(@SRangeError);

    if (StartIndex + Count) > System.Length(Values) then
      Max := System.Length(Values)
    else
      Max := StartIndex + Count;

    Result := Values[StartIndex];
    for I:= StartIndex + 1 to Max - 1 do
      Result := Result + Separator + Values[I];
  end;
end;

class function TStringHelper.Join(const Separator: string;
  const Values: IEnumerable<string>): string;
begin
  if Values <> nil then
    Result := Join(Separator, Values.GetEnumerator)
  else
    Result := '';
end;

class function TStringHelper.Join(const Separator: string;
  const Values: IEnumerator<string>): string;
begin
  if (Values <> nil) and Values.MoveNext then
  begin
    Result := Values.Current;
    while Values.MoveNext do
      Result := Result + Separator + Values.Current;
  end
  else
    Result := '';
end;

function TStringHelper.LeftSpaces(const ANumSpaces: Integer): string;
var
  i: Integer;
begin
  Result := Self;
  i := 0;

  if ANumSpaces < 1 then
  begin
    Exit;
  end;

  repeat
    Result := ' ' + Result;
    i.Inc;
  until i > ANumSpaces;
end;

function TStringHelper.Length: Integer;
begin
  Result := System.Length(Self);
end;

function TStringHelper.LengthBetween(const ALowerLimit, AHigherLimit: Integer): Boolean;
begin
  Result := (Self.Length >= ALowerLimit) and (Self.Length <= AHigherLimit);
end;

function TStringHelper.LettersOnly: string;
var
  i: Integer;
begin
  Result := EmptyStr;

  {$IFDEF ANDROID}
  for i := 0 to Pred(Length) do
  {$ELSE}
  for i := 1 to Length do
  {$ENDIF}
  begin
    if Self[i].IsLetter or Self[i].IsSymbol then
    begin
      Result := Result + Self[i];
    end;
  end;
end;

function TStringHelper.LPAD(const ALength: Integer; const AChar: Char): string;
begin
  Result := Self;

  while Result.Length.MinorThan(ALength) do
  begin
    Result := AChar + Result;
  end;
end;

function TStringHelper.NumbersOnly: string;
var
  i: Integer;
begin
  Result := EmptyStr;

  {$IFDEF ANDROID}
  for i := 0 to Pred(Length) do
  {$ELSE}
  for i := 1 to Length do
  {$ENDIF}
  begin
    if Self[i].IsNumber then
    begin
      Result := Result + Self[i];
    end;
  end;
end;

function TStringHelper.Pos(const ASubStr: string): Integer;
begin
  Result := System.Pos(ASubStr, Self);
end;

function TStringHelper.PosEx(const ASubStr: string; const AOffset: Integer): Integer;
begin
  Result := System.StrUtils.PosEx(ASubStr, Self, AOffset);
end;

function TStringHelper.Quoted(const AQuoteChar: Char): string;
begin
  Result := AQuoteChar + Self + AQuoteChar;
end;

function TStringHelper.RemoveChar(const AChar: Char): string;
begin
  Result := Self.Replace(AChar, EmptyStr, [rfReplaceAll]);
end;

function TStringHelper.RemoveChars(const AChars: array of Char): string;
var
  i: Integer;
begin
  Result := Self;

  for i := 0 to System.Pred(System.Length(AChars)) do
  begin
    Result := Result.RemoveChar(AChars[i]);
  end;
end;

function TStringHelper.RemoveEscapes: string;
begin
  Result := Self.Replace('\/', '/', [rfReplaceAll]).Replace('\"', '"', [rfReplaceAll]).Replace('\r', #13, [rfReplaceAll]).Replace('\n', #10, [rfReplaceAll]);
end;

function TStringHelper.Replace(const APatern, ANewValue: string; AFlags: TReplaceFlags): string;
begin
  Result := StringReplace(Self, APatern, ANewValue, AFlags);
end;

function TStringHelper.RightSpaces(const ANumSpaces: Integer): string;
var
  i: Integer;
begin
  Result := Self;
  i := 0;

  if ANumSpaces < 1 then
  begin
    Exit;
  end;

  repeat
    Result := Result + ' ';
    i.Inc;
  until i > ANumSpaces;
end;

function TStringHelper.RPAD(const ALength: Integer; const AChar: Char): string;
begin
  Result := Self;

  while Result.Length.MinorThan(ALength) do
  begin
    Result := Result + AChar;
  end;
end;

procedure TStringHelper.SetChar(AIndex: Integer; const Value: Char);
begin
  Self[AIndex] := Value;
end;

function TStringHelper.Split(const ASeparator: string): TArray<string>;
var
  strTemp : string;
  intPos  : Integer;
  intIndex: Integer;
begin
  SetLength(Result, 0);
  strTemp := Self;

  if ASeparator.IsEmpty then
  begin
    Exit;
  end;

  intPos   := System.Pos(ASeparator, strTemp);
  intIndex := 0;

  while intPos > 0 do
  begin
    SetLength(Result, System.Succ( intIndex));
    Result[intIndex] := strTemp.Copy(1, System.Pred( intPos)).Trim;
    System.Delete(strTemp, 1, intPos + System.Pred( ASeparator.Length));
    intPos := System.Pos(ASeparator, strTemp);
    intIndex.Inc;
  end;

  SetLength(Result, System.Succ( intIndex));
  Result[intIndex] := strTemp;
end;

function TStringHelper.Split(const ASeparator: Char): TArray<string>;
var
  strSep: string;
begin
  strSep := ' ';
{$IFDEF ANDROID}
  strSep[1] := ASeparator;
{$ELSE}
  strSep[1] := ASeparator;
{$ENDIF}
  Result := Split(strSep);
end;

{$IFDEF ANDROID}
{$ELSE}
function TStringHelper.ToAnsi: AnsiString;
begin
  Result := RawByteString(Self);
end;
{$ENDIF}

function TStringHelper.ToBase64: string;
var
  stmInput : TStringStream;
  stmResult: TStringStream;
begin
  Result := EmptyStr;

  if Self.IsEmpty then
  begin
    Exit;
  end;

  stmInput  := TStringStream.Create(Self);
  stmResult := TStringStream.Create;
  stmResult.SetSize(stmInput.Size);
  TNetEncoding.Base64.Encode(stmInput, stmResult);
  Result := stmResult.DataString;
  stmInput.Free;
  stmResult.Free;
end;

function TStringHelper.ToFloat(const ADefValue: Extended): Extended;
begin
  Result := StrToFloatDef(Self, 0);
end;

function TStringHelper.ToInteger(const ADefValue: Integer; const IsHex: Boolean): Integer;
begin
{$IF CompilerVersion = 31.0}
  Result := ADefValue;
{$ENDIF}
  case IsHex of
    True : Result := StrToIntDef('$' + Self, ADefValue);
    False: Result := StrToIntDef(Self, ADefValue);
  end;
end;

function TStringHelper.ToJSONObject: TJSONObject;
begin
   if Self.Trim.IsEmpty then
      Result   := TJSONObject.Create
   else Result := TJSONObject.ParseJSONValue( Self) as TJSONObject
   //Result := TJSONObject.ParseJSONValue( TEncoding.UTF8.GetBytes( Self), 0) as TJSONObject;
end;

procedure TStringHelper.ToJSON(aJSON: TJSONObject; aName: string;
  aNull: Boolean);
begin
   if Assigned( aJSON) and ( not aName.IsEmpty) then
      if Self.IsEmpty and aNull then
         aJSON.AddPair( aName, TJSONNull.Create)
      else if not Self.IsEmpty then
              aJSON.AddPair( aName, Self);
end;

function TStringHelper.ToJSONArray: TJSONArray;
begin
   if Self.Trim.IsEmpty then
      Result   := TJSONArray.Create
   else Result := TJSONObject.ParseJSONValue(Self) as TJSONArray;
end;

function TStringHelper.ToLower: string;
begin
  Result := LowerCase(Self);
end;

function TStringHelper.ToUpper: string;
begin
  Result := UpperCase(Self);
end;

function TStringHelper.ToUTF8: string;
begin
  Result := string(UTF8Encode(Self));
end;

function TStringHelper.Trim: string;
begin
  Result := System.SysUtils.Trim(Self);
end;

function TStringHelper.TrimLeft: string;
begin
  Result := System.SysUtils.TrimLeft(Self);
end;

function TStringHelper.TrimRight: string;
begin
  Result := System.SysUtils.TrimRight(Self);
end;

function TStringHelper.Unaccent: string;
const
  STR_ACCENTS    = 'ÁÀÂÃÄÉÈÊÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑÝáàâãäéèêêëíìîïóòôõöúùûüçñý';
  STR_NO_ACCENTS = 'AAAAAEEEEEIIIIOOOOOUUUUCNYaaaaaeeeeeiiiiooooouuuucny';
{$IFDEF ANDROID}
  INT_START = 0;
  INT_END   = 1;
{$ELSE}
  INT_START = 1;
  INT_END   = 0;
{$ENDIF}

var
  i     : Integer;
  intPos: Integer;
begin
  Result := Self;

  for i := INT_START to Result.Length - INT_END do
  begin
    intPos := System.Pos(Result[i], STR_ACCENTS);

    if intPos > 0 then
    begin
      Result[i] := STR_NO_ACCENTS[intPos - INT_END];
    end;
  end;
end;

function TStringHelper.Unquote: string;
var
  intIndex: Integer;
begin
  Result := Self;
  {$IFDEF ANDROID}
  intIndex := 0;
  {$ELSE}
  intIndex := 1;
  {$ENDIF}

  case Result[intIndex].IsInArray(['"', #39]) of
    False: Exit;
    True : Result.Delete(1, 1);
  end;

  if Result[Result.Length{$IFDEF ANDROID} - 1 {$ENDIF}].IsInArray(['"', #39]) then
  begin
    Result.Delete(Result.Length, 1);
  end;
end;

{ TValueHelper }

function TValueHelper.IsNull: Boolean;
begin
   Result := True;

   case Self.Kind of
      tkInteger    :Result := Self.AsInteger = 0;
      tkChar       :Result := Self.AsString = EmptyStr;
      tkEnumeration:Result := Self.IsEmpty;
      tkFloat      :Result := Self.AsCurrency = 0;
      tkUString,
      tkString     :Result := Self.AsString = EmptyStr;
      tkClass      :Result := False;
      tkInt64      :Result := Self.AsInt64 = 0;
   end;
end;

function TValueHelper.ValueToFieldType: TFieldType;
begin
   Result := ftUnknown;

   case Self.Kind of
      tkInteger    :Result := ftInteger;
      tkChar       :Result := ftByte;
      tkEnumeration:Result := ftString;
      tkFloat      :Result := ftFloat;
      tkUString,
      tkString     :Result := ftString;
      tkClass      :Result := ftObject;
      tkInt64      :Result := ftLargeint;
   end;
end;

{ TVariantHelper }

function TVariantHelper.ToJSONValue: TJSONValue;
begin
  Result := nil;

  case VarType( Self) of
    varEmpty     :Result := TJSONNull.Create;
    varNull      :Result := TJSONNull.Create;
    varSmallInt  :Result := TJSONNumber.Create( VarToStr( Self));
    varInteger   :Result := TJSONNumber.Create( VarToStr( Self));
    varSingle    :Result := TJSONNumber.Create( VarToStr( Self));
    varDouble    :Result := TJSONNumber.Create( VarToStr( Self));
    varCurrency  :Result := TJSONNumber.Create( VarToStr( Self));
    varDate      :Result := TJSONString.Create( DateToISO8601( Self));
    varOleStr    :Result := TJSONString.Create( Self);
    varBoolean   :if Boolean( Self) then
                     Result   := TJSONTrue.Create
                  else Result := TJSONFalse.Create;
    varUnknown   :Result := TJSONNull.Create;
    varByte      :Result := TJSONString.Create( Self);
    varWord      :Result := TJSONNumber.Create( VarToStr( Self));
    varLongWord  :Result := TJSONNumber.Create( VarToStr( Self));
    varInt64     :Result := TJSONNumber.Create( VarToStr( Self));
    varStrArg    :Result := TJSONString.Create( Self);
    varString    :Result := TJSONString.Create( Self);
    varTypeMask  :Result := TJSONString.Create( Self);
    varUString   :Result := TJSONString.Create( Self);
  end;
end;

function TVariantHelper.ToStr: AnsiString;
begin
   Result := AnsiString( VarToStr( Self));
end;

{ TImageHelper }

function TImageHelper.AsBase64: String;
Var LOrigem:TBytesStream;
    LDestino:TStringStream;
begin
   try
      LOrigem  := TBytesStream.Create;
      LDestino := TStringStream.Create;
      Self.Bitmap.SaveToStream( LOrigem);
      LOrigem.Position := 0;

      TNetEncoding.Base64.Encode( LOrigem, LDestino);
      LDestino.Position := 0;
      LDestino.SaveToFile( 'C:\Users\rarro\Pictures\imgteste.txt');

      Result := LDestino.DataString;
   finally
      FreeAndNil( LOrigem);
      FreeAndNil( LDestino);
   end;
end;

procedure TImageHelper.FromBase64(aValue: String);
Var LOrigem:TStringStream;
    LDestino:TBytesStream;
    LTest:TStringList;
begin
   try
      //aValue := aValue.Trim.Replace( '\', '', []);

      try
         LTest := TStringList.Create;
         LTest.Text := aValue;
         LTest.SaveToFile( 'C:\Users\rarro\Pictures\decode.txt');
      finally
         FreeAndNil( LTest);
      end;

      LOrigem  := TStringStream.Create( aValue);
      LOrigem.Position := 0;
      LDestino := TBytesStream.Create;
      TNetEncoding.Base64.Decode( LOrigem, LDestino);
      LDestino.Position := 0;

      Self.Bitmap.LoadFromStream( LDestino);
   finally
      FreeAndNil( LOrigem);
      FreeAndNil( LDestino);
   end;
end;

{ TDoubleHelper }

function TDoubleHelper.InternalGetBytes(Index: Cardinal): UInt8;
type
  PByteArray = ^TByteArray;
  TByteArray = array[0..32767] of Byte;
begin
  Result := PByteArray(@Self)[Index];
end;

function TDoubleHelper.InternalGetWords(Index: Cardinal): UInt16;
type
  PWordArray = ^TWordArray;
  TWordArray = array[0..16383] of Word;
begin
  Result := PWordArray(@Self)[Index];
end;

procedure TDoubleHelper.InternalSetBytes(Index: Cardinal; const Value: UInt8);
type
  PByteArray = ^TByteArray;
  TByteArray = array[0..32767] of Byte;
begin
  PByteArray(@Self)[Index] := Value;
end;

procedure TDoubleHelper.InternalSetWords(Index: Cardinal; const Value: UInt16);
type
  PWordArray = ^TWordArray;
  TWordArray = array[0..16383] of Word;
begin
  PWordArray(@Self)[Index] := Value;
end;

function TDoubleHelper.GetBytes(Index: Cardinal): UInt8;
begin
  if Index >= 8 then System.Error(reRangeError);
  Result := InternalGetBytes(Index);
end;

function TDoubleHelper.GetWords(Index: Cardinal): UInt16;
begin
  if Index >= 4 then System.Error(reRangeError);
  Result := InternalGetWords(Index);
end;

procedure TDoubleHelper.SetBytes(Index: Cardinal; const Value: UInt8);
begin
  if Index >= 8 then System.Error(reRangeError);
  InternalSetBytes(Index, Value);
end;

procedure TDoubleHelper.SetWords(Index: Cardinal; const Value: UInt16);
begin
  if Index >= 4 then System.Error(reRangeError);
  InternalSetWords(Index, Value);
end;

function TDoubleHelper.GetExp: UInt64;
begin
  Result := (InternalGetWords(3) shr 4) and $7FF;
end;

function TDoubleHelper.GetFrac: UInt64;
begin
  Result := PUInt64(@Self)^ and $000FFFFFFFFFFFFF;
end;

function TDoubleHelper.GetSign: Boolean;
begin
  Result := InternalGetBytes(7) >= $80;
end;

class function TDoubleHelper.ToString(const Value: Double): string;
begin
  Result := FloatToStr(Value);
end;

class function TDoubleHelper.ToString(const Value: Double; const AFormatSettings: TFormatSettings): string;
begin
  Result := FloatToStr(Value, AFormatSettings);
end;

class function TDoubleHelper.ToString(const Value: Double; const Format: TFloatFormat; const Precision, Digits: Integer): string;
begin
  Result := FloatToStrF(Value, Format, Precision, Digits);
end;

class function TDoubleHelper.ToString(const Value: Double; const Format: TFloatFormat; const Precision, Digits: Integer;
  const AFormatSettings: TFormatSettings): string;
begin
  Result := FloatToStrF(Value, Format, Precision, Digits, AFormatSettings);
end;

class function TDoubleHelper.TryParse(const S: string; out Value: Double): Boolean;
{$IFDEF EXTENDEDHAS10BYTES}
var
  E: Extended;
begin
  Result := TryStrToFloat(S, E);
  Result := Result and (Double.MinValue <= E) and (E <= Double.MaxValue);
  if Result then
    Value := E;
end;
{$ELSE !EXTENDEDHAS10BYTES}
begin
  Result := TryStrToFloat(S, Value);
end;
{$ENDIF EXTENDEDHAS10BYTES}

class function TDoubleHelper.TryParse(const S: string; out Value: Double; const AFormatSettings: TFormatSettings): Boolean;
{$IFDEF EXTENDEDHAS10BYTES}
var
  E: Extended;
begin
  Result := TryStrToFloat(S, E, AFormatSettings);
  Result := Result and (Double.MinValue <= E) and (E <= Double.MaxValue);
  if Result then
    Value := E;
end;
{$ELSE !EXTENDEDHAS10BYTES}
begin
  Result := TryStrToFloat(S, Value, AFormatSettings);
end;
{$ENDIF EXTENDEDHAS10BYTES}

class function TDoubleHelper.Parse(const S: string): Double;
begin
  if not TryParse(S, Result) then
    ConvertErrorFmt(@SInvalidFloat2, [s, 'Double']);
end;

class function TDoubleHelper.Parse(const S: string; const AFormatSettings: TFormatSettings): Double;
begin
  if not TryParse(S, Result, AFormatSettings) then
    ConvertErrorFmt(@SInvalidFloat2, [s, 'Double']);
end;

class function TDoubleHelper.IsNan(const Value: Double): Boolean;
begin
  Result := (Value.SpecialType = TFloatSpecial.fsNan);
end;

class function TDoubleHelper.IsInfinity(const Value: Double): Boolean;
var
  FloatType: TFloatSpecial;
begin
  FloatType := Value.SpecialType;
  Result := (FloatType = fsInf) or (FloatType = fsNInf);
end;

class function TDoubleHelper.IsNegativeInfinity(const Value: Double): Boolean;
begin
  Result := (Value.SpecialType = TFloatSpecial.fsNInf);
end;

class function TDoubleHelper.IsPositiveInfinity(const Value: Double): Boolean;
begin
  Result := (Value.SpecialType = TFloatSpecial.fsInf);
end;

class function TDoubleHelper.Size: Integer;
begin
  Result := SizeOf(Double);
end;

function TDoubleHelper.ToString: string;
begin
  Result := FloatToStr(Self);
end;

function TDoubleHelper.ToString(const AFormatSettings: TFormatSettings): string;
begin
  Result := FloatToStr(Self, AFormatSettings);
end;

function TDoubleHelper.ToString(const Format: TFloatFormat; const Precision, Digits: Integer): string;
begin
  Result := FloatToStrF(Self, Format, Precision, Digits);
end;

function TDoubleHelper.ToString(const Format: TFloatFormat; const Precision, Digits: Integer;
                         const AFormatSettings: TFormatSettings): string;
begin
  Result := FloatToStrF(Self, Format, Precision, Digits, AFormatSettings);
end;

function TDoubleHelper.IsNan: Boolean;
begin
  Result := (Self.SpecialType = TFloatSpecial.fsNan);
end;

function TDoubleHelper.IsInfinity: Boolean;
var
  FloatType: TFloatSpecial;
begin
  FloatType := Self.SpecialType;
  Result := (FloatType = fsInf) or (FloatType = fsNInf);
end;

function TDoubleHelper.IsNegativeInfinity: Boolean;
begin
  Result := (Self.SpecialType = TFloatSpecial.fsNInf);
end;

function TDoubleHelper.IsPositiveInfinity: Boolean;
begin
  Result := (Self.SpecialType = TFloatSpecial.fsInf);
end;

procedure TDoubleHelper.BuildUp(const SignFlag: Boolean; const Mantissa: UInt64;
  const Exponent: Integer);
begin
  Self := 0.0;
  SetSign(SignFlag);
  SetExp(Exponent + $3FF);
  SetFrac(Mantissa and $000FFFFFFFFFFFFF);
end;

function TDoubleHelper.Exponent: Integer;
var
  E, F: UInt64;
begin
  E := GetExp;
  F := GetFrac;
  if (0 < E) and (E < $7FF) then
    Result := E - $3FF
  else if (E = 0) and (F <> 0) then
    Result := -1022 // Denormal
  else if (E = 0) and (F = 0) then
    Result := 0 // +/-Zero
  else
    Result := 0; // +/-INF, NaN
end;

function TDoubleHelper.Fraction: Extended;
var
  E, F: UInt64;
begin
  E := GetExp;
  F := GetFrac;
  if E = $7FF then
  begin
    if F = 0 then // +/- INF.
      Result := Extended.PositiveInfinity
    else // NaN
      Result := Extended.Nan;
  end
  else if E = 0 then
    Result := (F / $0010000000000000)
  else
    Result := 1.0 + (F / $0010000000000000);
end;

function TDoubleHelper.Mantissa: UInt64;
var
  E, F: UInt64;
begin
  E := GetExp;
  F := GetFrac;
  Result := F;
  if (0 < E) and (E < $7FF) then
    Result := Result or (UInt64(1) shl 52);
end;

procedure TDoubleHelper.SetExp(NewExp: UInt64);
var
  W: Word;
begin
  W := InternalGetWords(3);
  W := (W and $800F) or ((NewExp and $7FF) shl 4);
  InternalSetWords(3, W);
end;

procedure TDoubleHelper.SetFrac(NewFrac: UInt64);
var
  U64: UInt64;
begin
  U64 := PUInt64(@Self)^;
  U64 := (U64 and $FFF0000000000000) or (NewFrac and $000FFFFFFFFFFFFF);
  PUInt64(@Self)^ := U64;
end;

procedure TDoubleHelper.SetSign(NewSign: Boolean);
var
  B: Byte;
begin
  B := InternalGetBytes(7);
  if NewSign then B := B or $80
  else            B := B and $7F;
  InternalSetBytes(7, B);
end;

function TDoubleHelper.SpecialType: TFloatSpecial;
var
  U64: UInt64;
  W: Word;
begin
  W := InternalGetWords(3);
  if ($0010 <= W) and (W <= $7FEF) then
    Result := TFloatSpecial.fsPositive
  else if ($8010 <= W) and (W <= $FFEF) then
    Result := TFloatSpecial.fsNegative
  else
  begin
    U64 := PUInt64(@self)^;
    if U64 = 0 then
      Result := TFloatSpecial.fsZero
    else if U64 = $8000000000000000 then
      Result := TFloatSpecial.fsNZero
    else if w <= $000F then
      Result := TFloatSpecial.fsDenormal
    else if ($8000 <= w) and (w <= $800F) then
      Result := TFloatSpecial.fsNDenormal
    else if U64 = $7FF0000000000000 then
      Result := TFloatSpecial.fsInf
    else if U64 = $FFF0000000000000 then
      Result := TFloatSpecial.fsNInf
    else
      Result := TFloatSpecial.fsNan;
  end;
end;

function TDoubleHelper.ToJSONNumber: TJSONNumber;
begin
   Result := TJSONNumber.Create( Self);
end;

{ TSystemActionsHelper }

procedure TSystemActionsHelper.FromString(aValue: String);
begin
   Self := saView;

   case IndexStr( aValue, [ 'View',
                            'Browser',
                            'Find',
                            'Search',
                            'Insert',
                            'Update',
                            'Delete',
                            'Option']) of
      0:Self := saView;
      1:Self := saBrowser;
      2:Self := saFind;
      3:Self := saSearch;
      4:Self := saInsert;
      5:Self := saUpdate;
      6:Self := saDelete;
      7:Self := saOption;
   end;
end;

function TSystemActionsHelper.ToString: String;
begin
   case Self of
      saView   :Result := 'View';
      saBrowser:Result := 'Browser';
      saFind   :Result := 'Find';
      saSearch :Result := 'Search';
      saInsert :Result := 'Insert';
      saUpdate :Result := 'Update';
      saDelete :Result := 'Delete';
      saOption :Result := 'Option';
   end;
end;

{ TIntervalTypeHelper }

procedure TIntervalTypeHelper.FromStr(aValue: String);
begin
   case AnsiIndexStr( AnsiLowerCase( aValue), [ AnsiLowerCase( 'Dayly'),
                                                AnsiLowerCase( 'Weekly'),
                                                AnsiLowerCase( 'Monthly'),
                                                AnsiLowerCase( 'HalfYearly'),
                                                AnsiLowerCase( 'Yearly')]) of
      0:Self := itDayly;
      1:Self := itWeekly;
      2:Self := itMonthly;
      3:Self := itHalfYearly;
      4:Self := itYearly;
   end;

end;

function TIntervalTypeHelper.ToStr: String;
begin
   case Self of
      itDayly     :Result := 'Dayly';
      itWeekly    :Result := 'Weekly';
      itMonthly   :Result := 'Monthly';
      itHalfYearly:Result := 'HalfYearly';
      itYearly    :Result := 'Yearly';
   end;
end;

{ TDataTypeHelper }

procedure TDataTypeHelper.FromStr(aValue: String);
begin
   case AnsiIndexStr( AnsiLowerCase( aValue), [ AnsiLowerCase( 'DB'),
                                                AnsiLowerCase( 'Rest')]) of
      0:Self := dtDB;
      1:Self := dtRest;
   end;
end;

function TDataTypeHelper.ToStr: String;
begin
   case Self of
      dtDB  :Result := 'DB';
      dtRest:Result := 'Rest';
   end;
end;

{ TDataEngineHelper }

procedure TDataEngineHelper.FromStr(aValue: String);
begin
   case AnsiIndexStr( AnsiLowerCase( aValue), [ AnsiLowerCase( 'Firedac'),
                                                AnsiLowerCase( 'Zeus')]) of
      0:Self := deFiredac;
      1:Self := deZeus;
   end;
end;

function TDataEngineHelper.ToStr: String;
begin
   case Self of
      deFiredac:Result := 'Firedac';
      deZeus   :Result := 'Zeus';
   end;
end;

{ TDataManagerHelper }

procedure TDataManagerHelper.FromStr(aValue: String);
begin
   case AnsiIndexStr( AnsiLowerCase( aValue), [ AnsiLowerCase( 'Firebird'),
                                                AnsiLowerCase( 'Interbase'),
                                                AnsiLowerCase( 'MySQL'),
                                                AnsiLowerCase( 'SQLite')]) of
      0:Self := dmFirebird;
      1:Self := dmInterbase;
      2:Self := dmMySQL;
      3:Self := dmSQLite;
   end;
end;

function TDataManagerHelper.ToStr: String;
begin
   case Self of
      dmFirebird :Result := 'Firebird';
      dmInterbase:Result := 'Interbase';
      dmMySQL    :Result := 'MySQL';
      dmSQLite   :Result := 'SQLite';
   end;
end;

{ TUserAuthTypeHelper }

procedure TUserAuthTypeHelper.FromStr(aValue: String);
begin
   case AnsiIndexStr( AnsiLowerCase( aValue), [ AnsiLowerCase( 'None'),
                                                AnsiLowerCase( 'Basic'),
                                                AnsiLowerCase( 'Bearer'),
                                                AnsiLowerCase( 'OAuth'),
                                                AnsiLowerCase( 'OAuth2'),
                                                AnsiLowerCase( 'AWS')]) of
      0:Self := uatNone;
      1:Self := uatBasic;
      2:Self := uatBearer;
      3:Self := uatOAuth;
      4:Self := uatOAuth2;
      5:Self := uatAWS;
   end;
end;

function TUserAuthTypeHelper.ToStr: String;
begin
   case Self of
      uatNone  :Result := 'None';
      uatBasic :Result := 'Basic';
      uatBearer:Result := 'Bearer';
      uatOAuth :Result := 'OAuth';
      uatOAuth2:Result := 'OAuth2';
      uatAWS   :Result := 'AWS';
   end;
end;

{ TValidationHelper }

class function TValidationHelper.IsStrongPassword(const APassword: string; AMinLength: Integer): Boolean;
var HasUpper, HasLower, HasDigit, HasSpecial: Boolean;
    C: Char;
begin
  Result := False;

  if Length(APassword) < AMinLength then
    Exit;

  HasUpper := False;
  HasLower := False;
  HasDigit := False;
  HasSpecial := False;

  for C in APassword do
  begin
    if CharInSet(C, ['A'..'Z']) then HasUpper := True
    else if CharInSet(C, ['a'..'z']) then HasLower := True
    else if CharInSet(C, ['0'..'9']) then HasDigit := True
    else HasSpecial := True;
  end;

  Result := HasUpper and HasLower and HasDigit and HasSpecial;
end;

class function TValidationHelper.IsValidCNPJ(const ACNPJ: string): Boolean;
var CNPJ: string;
    I, D1, D2: Integer;
    Weights1: array[0..11] of Integer;
    Weights2: array[0..12] of Integer;
begin
  CNPJ := ACNPJ.Replace('.', '', []).Replace('/', '', []).Replace('-', '', []).Trim;
  Result := False;

  if Length(CNPJ) <> 14 then Exit;
  if TRegEx.IsMatch(CNPJ, '^(\d)\1{13}$') then Exit;

  Weights1[0] := 5; Weights1[1] := 4; Weights1[2] := 3; Weights1[3] := 2;
  Weights1[4] := 9; Weights1[5] := 8; Weights1[6] := 7; Weights1[7] := 6;
  Weights1[8] := 5; Weights1[9] := 4; Weights1[10] := 3; Weights1[11] := 2;

  Weights2[0] := 6; Weights2[1] := 5; Weights2[2] := 4; Weights2[3] := 3;
  Weights2[4] := 2; Weights2[5] := 9; Weights2[6] := 8; Weights2[7] := 7;
  Weights2[8] := 6; Weights2[9] := 5; Weights2[10] := 4; Weights2[11] := 3;
  Weights2[12] := 2;

  D1 := 0;
  for I := 0 to 11 do
    D1 := D1 + StrToInt(CNPJ[I + 1]) * Weights1[I];
  D1 := 11 - (D1 mod 11);
  if D1 >= 10 then D1 := 0;

  D2 := 0;
  for I := 0 to 12 do
    D2 := D2 + StrToInt(CNPJ[I + 1]) * Weights2[I];
  D2 := 11 - (D2 mod 11);
  if D2 >= 10 then D2 := 0;

  Result := (D1 = StrToInt(CNPJ[13])) and (D2 = StrToInt(CNPJ[14]));
end;

class function TValidationHelper.IsValidCPF(const ACPF: string): Boolean;
var CPF: string;
    I, D1, D2: Integer;
begin
  CPF := ACPF.Replace('.', '', []).Replace('-', '', []).Trim;
  Result := False;

  if Length(CPF) <> 11 then Exit;
  if TRegEx.IsMatch(CPF, '^(\d)\1{10}$') then Exit; // Todos dígitos iguais

  // Calcula primeiro dígito verificador
  D1 := 0;
  for I := 1 to 9 do
    D1 := D1 + StrToInt(CPF[I]) * (11 - I);
  D1 := 11 - (D1 mod 11);
  if D1 >= 10 then D1 := 0;

  // Calcula segundo dígito verificador
  D2 := 0;
  for I := 1 to 10 do
    D2 := D2 + StrToInt(CPF[I]) * (12 - I);
  D2 := 11 - (D2 mod 11);
  if D2 >= 10 then D2 := 0;

  Result := (D1 = StrToInt(CPF[10])) and (D2 = StrToInt(CPF[11]));
end;

class function TValidationHelper.IsValidEmail(const AEmail: string): Boolean;
const EMAIL_PATTERN = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
begin
   Result := TRegEx.IsMatch(AEmail, EMAIL_PATTERN);
end;

class function TValidationHelper.IsValidGUID(const AValue: string): Boolean;
var LGuid: TGUID;
begin
   try
      LGuid := StringToGUID('{' + AValue + '}');
   except
      try
         LGuid := StringToGUID( AValue);
      except
      end;
   end;

   Result := not LGuid.IsEmpty;
end;

{ TEnvironmentTypeHelper }

procedure TEnvironmentTypeHelper.FromString(aValue: String);
begin
   case AnsiIndexStr( AnsiLowerCase( aValue), [AnsiLowerCase( 'Development'),
                                               AnsiLowerCase( 'Statging'),
                                               AnsiLowerCase( 'Production')]) of
      0:Self := envDevelopment;
      1:Self := envStaging;
      2:Self := envProduction;
   end;
end;

function TEnvironmentTypeHelper.ToString: String;
begin
   case Self of
     envDevelopment:Result := 'Development';
     envStaging    :Result := 'Statging';
     envProduction :Result := 'Production';
   end;
end;

end.
