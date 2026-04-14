unit Infra.Utils;

interface

{Ver depois

Sincronizar DATAHora do computador
procedure SynchronizeDh;
var
  SystemTime: TSystemTime;
begin
  FDhSynchronized := False;
  DateTimeToSystemTime(GetCurrentDateTime, SystemTime);
  FDhSynchronized := SetLocalTime(SystemTime);
end;

https://showdelphi.com.br/como-fazer-uma-aplicacao-do-delphi-executar-como-administrador/

}

uses System.SysUtils,
     System.StrUtils,
     System.DateUtils,
     System.Classes,
     System.TypInfo,
     System.Math,
     System.Generics.Collections,
     System.RTTI,
     System.MaskUtils,
     System.RegularExpressions,
     System.JSON,
     System.Variants,
     System.Hash,
     System.NetEncoding,
     System.Types,
     System.UITypes,

     Data.DB,
     FMX.Edit,
     FMX.Graphics,
     FMX.Objects,
     FMX.TextLayout,
     FMX.ListView.Types,
     FMX.DialogService,

     Infra.Types,
     Infra.Helpers,

     XML.XMLIntf,

     IdHashMessageDigest,
     IdCoderMIME;

     // IP RegEx
     // '\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b'
const
   SpecialChars = [ '!', '@', '#', '$', '%', '&', '*', '(', ')',
                    '-', '_', '+', '=', '§', '{', '}', 'ª', 'º',
                    '[', ']', '°', '?', '/', '\', '|', ',', '.',
                    ':', ';', '<', '>', '¹', '²', '³', '£', '¢',
                    '¬'];
   AccentsChars = [ 'á', 'à', 'ã', 'â', 'ä',
                    'Á', 'À', 'Ã', 'Â', 'Ä',
                    'é', 'è', 'ê', 'ë',
                    'É', 'È', 'Ê', 'Ë',
                    'í', 'ì', 'î', 'ï',
                    'Í', 'Ì', 'Î', 'Ï',
                    'ó', 'ò', 'ô', 'õ', 'ö',
                    'Ó', 'Ò', 'Ô', 'Õ', 'Ö',
                    'ú', 'ù', 'û', 'ü',
                    'Ú', 'Ù', 'Û', 'Ü'];

   CriptKey : String = ('YUQL23KL23DF90WI5E1JAS467NMCXXL6JAOAUWWMCL0AOMM4A4VZYW9KHJUI2347EJHJKDF3424SKL K3LAKDJSL9RTIKJ');

type
   TUtils = class
   private
      class procedure ValidEnum<T>;overload;
      class procedure ValidEnum( aValue:TValue);overload;

      class function FormatStateInscription( aState:String):String;

   public
      class function Mask( aMask, aValue:string):string;

      class function IsSetValueValid<T>( aSet:TVariantArray<T>; aValue:T):Boolean;overload;
      class function StrIsSetValueValid<T>( aValue:String):Boolean;overload;

      class function EnumToStr<T>( aValue:T):String;overload;
      class function StrToEnum<T>( aValue:String):T;overload;

      class function StrEnumToValue<T>( aValue:String):TValue;overload;
      class function EnumToValue<T>( aValue:T):TValue;overload;

      class function ValueToStrEnum<T>( aValue:TValue):String;overload;
      class function ValueToStrEnum( aValue:TValue):String;overload;
      class function ValueToEnum<T>( aValue:TValue):T;overload;

      class function ValueToVar( aValue:TValue):Variant;
      class function VarToValue( aTypeKind:TTypeKind; aValue:Variant):TValue;overload;
      class function VarToValue( aValue:Variant):TValue;overload;
      class function VarToJSONValue( aValue:Variant):TJSONValue;
      class function GetJSONValueToVar<T>( aJSON:TJSONObject; aField:String):T;

      class function Rounding( aValue:Double; aPrecision:Integer = 2):Double;

      class function OnlyNumber( aValue:String):String;
      class function NoEspecialChar( aValue:String):String;

      class function FloatFormat( aValue:String):Currency;

      class function OnlyNumericChars( aValue:String):String;
      class function RemoveMaskChars( aValue:String):String;
      class function RemoveAccents( aValue:String):String;
      class function RemoveSpecialChars( aValue:String):String;
      class function FirstUpper( aValue:String):String;

      class function ByteArrayToStream( aData:TBytes):TMemoryStream;
      class function StreamToByteArray( aStream:TMemoryStream):TBytes;

      class function DefaultFormat( aObject:TEdit; aFormat:TMaskKind; aExtra:string = ''):String;overload;
      class function DefaultFormat( aValue:String; aFormat:TMaskKind; aExtra:string = ''):String;overload;
      class function eMailFormat( aValue:String):Boolean;
      class function ReturnMask( aFormat:TMaskKind):String;

      class function JSONDateToDateTime( aValue:String):TDateTime;overload;
      class function JSONDateToDateTime( aValue:TJSONValue):TDateTime;overload;
      class function DateTimeToJSONDate( aValue:TDateTime):String;

      class function JSONValueToInt( aValue:TJSONValue):Integer;
      class function JSONValueToVar( aValue:TJSONValue):Variant;
      class function JSONValueToValue( aValue:TJSONValue):TValue;

      class function ClassPropertyType( aValue:TRTTIProperty):TFieldType;
      class function JSONFieldType( aValue:TJSONValue):TFieldType;
      class function NewInstance( aValue:String):TObject;reintroduce;overload;
      class function NewInstance( aValue:TPersistentClass):TObject;reintroduce;overload;
      class function NewInstance<T:constructor>( aValue:T):T;reintroduce;overload;
      class function GetRttiFromInterface(AIntf: IInterface; out RttiType: TRttiType): Boolean;

      class function Crypt(const Src: String; const Secretkey:String = ''): String;
      class function DeCrypt(Src: String; const Secretkey:String = ''): String;
      class function StringMD5(const aValue:String):String;
      class function FileMD5(const aValue:String):String;
      class function SHA256(const AValue: string): string;
      class function SHA512(const AValue: string): string;
      class function GenerateRandomToken(ALength: Integer = 32): string;
      class function GenerateRandomCode(ALength: Integer = 6): string;

      class function ImageToBase64( aImage:TBitmap):String;
      class procedure Base64ToImage( aValue:String; aImage:TBitmap);
      class procedure ResourceImage( aResource:String; aImage:TImage);
      class function Encode64( aValue:String):String;
      class function Decode64( aValue:String):String;

      class function IntToBin(Value: LongWord): string;
      class function BinToInt( Value:String):Integer;
      class function CharToBin( Value:Char):String;

      class function GetTextHeight(const D: TListItemText; const Width: single; const Text: string): Integer;
      class function FileCount( aPath:String; aExtension:String = '*.*'):Integer;
      class function ConfirmationMessage( aText:String):Boolean;
      class function FixedSize( aValue:String; aSize:Integer; aChar:Char; aCharPosition:TCharPosition = cpLeft):String;
      class function LeftHoursDayEnd( aValue:TTime):Double;
      class function LeftSecondsDayEnd( aValue:TDateTime):Int64;

      class function FindNode( aNode:IXMLNode; aName:String):IXMLNode;
      class function FindNodeValue( aNode:IXMLNode; aName:String):Variant;
      class function FindNodeAttributeValue( aNode:IXMLNode; aName:String; aAttribute:String):Variant;
      class function FindNodeByAddress( aNode:IXMLNode; aName:String):IXMLNode;
      class function FindNodeValueByAddress( aNode:IXMLNode; aName:String):Variant;

      class function NewUUID: TUUIDStr;
      class function UTCNow: TUTCDateTime;
      class function LocalToUTC(const ADateTime: TDateTime): TUTCDateTime;
      class function UTCToLocal(const AUtcDateTime: TUTCDateTime): TDateTime;

   end;

implementation

{ TUtils }

class procedure TUtils.Base64ToImage(aValue: String; aImage: TBitmap);
Var LOrigem:TStringStream;
    LDestino:TStringStream;
begin
   try
      LOrigem  := TStringStream.Create( aValue);
      LOrigem.Position := 0;
      LDestino := TStringStream.Create;
      TNetEncoding.Base64.Decode( LOrigem, LDestino);
      LDestino.Position := 0;

      aImage.LoadFromStream( LDestino);
   finally
      FreeAndNil( LOrigem);
      FreeAndNil( LDestino);
   end;
end;

class function TUtils.BinToInt(Value: String): Integer;
   function Pow(i, k: Integer): Integer;
   var
     j, Count: Integer;
   begin
      if k>0 then
         j:=2
      else j:=1;

      for Count:=1 to k-1 do
         j:=j*2;

      Result:=j;
   end;

var
   Len, Res, i: Integer;
   Error: Boolean;

begin
   Error := False;
   Len   := Length(Value);
   Res   := 0;

   for i:=1 to Len do
      if (Value[i]='0') or (Value[i]='1') then
         Res:=Res+Pow(2, Len-i) * StrToInt(Value[i])
      else begin
         raise Exception.Create('O valor informado não é um valor binário válido');
         Error:=True;
         Break;
      end;

   if Error=True then Result:=0
      else Result:=Res;
end;

class function TUtils.ByteArrayToStream(aData: TBytes): TMemoryStream;
begin
   Result := TMemoryStream.Create;
   Result.Write( aData, length(aData)*SizeOf(aData[0]));
   Result.Position := 0;
end;

class function TUtils.CharToBin(Value: Char): String;
begin
   Result := IntToBin( Ord( Value));
end;

class function TUtils.ClassPropertyType(aValue: TRTTIProperty): TFieldType;
begin
   Result := ftUnknown;

   case aValue.PropertyType.TypeKind of
      tkInt64  :Result := ftLargeint;
      tkInteger:Result := ftInteger;
      tkFloat:begin
         if CompareText( 'TDateTime', aValue.PropertyType.Name) = 0 then
            Result := ftDateTime
         else if CompareText( 'TDate', aValue.PropertyType.Name) = 0 then
                 Result := ftDate
         else if CompareText( 'TTime', aValue.PropertyType.Name) = 0 then
                 Result := ftTime
         else Result := ftFloat;
      end;
      tkWChar,
      tkLString,
      tkWString,
      tkUString,
      tkString:Result := ftString;
      tkVariant:Result := ftString;
      tkEnumeration:begin
         if aValue.PropertyType.Name = 'Boolean' then
            Result   := ftBoolean
         else Result := ftReference;
      end;
      tkClass:Result := ftObject;
   end;
end;

class function TUtils.ConfirmationMessage(aText: String): Boolean;
var LResult:Boolean;
begin
  lResult := False;

  TDialogService.PreferredMode := TDialogService.TPreferredMode.Platform;

  TDialogService.MessageDialog( AText, TMsgDlgType.mtConfirmation,
    [ TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo ], TMsgDlgBtn.mbNo, 0,
    procedure(const AResult: TModalResult)
    begin
      LResult := AResult = 6;
    end);

  Result := lResult;
end;

class function TUtils.Crypt(const Src: String; const Secretkey:String = ''): String;
var KeyLen : Integer;
    KeyPos : Integer;
    OffSet : Integer;
    Dest   : String;
    SrcPos : Integer;
    SrcAsc : Integer;
    Range : Integer;
    LSecretKey:String;
begin
   if SecretKey = EmptyStr then
      LSecretKey := CriptKey
   else LSecretKey := Secretkey;

   if ( Src = '') Then
      Result:= ''
   else begin
      Dest   := '';
      KeyLen := Length( LSecretKey);
      KeyPos := 0;
      Range  := 256;

      Randomize;
      OffSet := Random(Range);
      Dest   := Format('%1.2x',[OffSet]);

      for SrcPos := 1 to Length(Src) do
      begin
         SrcAsc := (Ord(Src[SrcPos]) + OffSet) Mod 255;

         if KeyPos < KeyLen then
            KeyPos := KeyPos + 1
         else KeyPos := 1;

         SrcAsc := SrcAsc Xor Ord( LSecretKey[ KeyPos]);
         Dest   := Dest + Format('%1.2x',[SrcAsc]);
         OffSet := SrcAsc;
      end;

      Result:= Dest;
   end;
end;

class function TUtils.DateTimeToJSONDate(aValue: TDateTime): String;
begin
   Result := DateToISO8601( aValue);
end;

class function TUtils.Decode64(aValue: String): String;
begin
   Result := TIdDecoderMIME.DecodeString( aValue);
end;

class function TUtils.DeCrypt(Src: String; const Secretkey:String = ''): String;
var KeyLen : Integer;
    KeyPos : Integer;
    OffSet : Integer;
    Dest   : String;
    SrcPos : Integer;
    SrcAsc : Integer;
    TmpSrcAsc : Integer;
    LSecretkey:String;
begin
   Src := Src.Trim;
   if SecretKey = EmptyStr then
      LSecretkey   := CriptKey
   else LSecretkey := Secretkey;

   if (Src = '') Then
      Result := ''
   else begin
      Dest   := '';
      KeyLen := Length( LSecretkey);
      KeyPos := 0;
      OffSet := StrToInt('$' + copy(Src,1,2));//<--------------- adiciona o $ entra as aspas simples
      SrcPos := 3;

      repeat
         SrcAsc := StrToInt('$' + copy(Src,SrcPos,2));//<--------------- adiciona o $ entra as aspas simples

         if (KeyPos < KeyLen) Then
            KeyPos := KeyPos + 1
         else KeyPos := 1;

         TmpSrcAsc := SrcAsc Xor Ord( LSecretkey[KeyPos]);

         if TmpSrcAsc <= OffSet then
            TmpSrcAsc := 255 + TmpSrcAsc - OffSet
         else TmpSrcAsc := TmpSrcAsc - OffSet;

         Dest   := Dest + Chr(TmpSrcAsc);
         OffSet := SrcAsc;
         SrcPos := SrcPos + 2;
      until (SrcPos >= Length(Src));

      Result := Dest;
   end;
end;

class function TUtils.DefaultFormat(aValue: String; aFormat: TMaskKind; aExtra: string): String;
Var LValue:String;
    LDecimal:Integer;
    LDecimalMask:String;
begin
   Result := EmptyStr;
   LValue := aValue;

   case aFormat of
      mkCNPJ:LValue := Mask('##.###.###/####-##', OnlyNumber(LValue));
      mkCPF:LValue := Mask('###.###.###-##', OnlyNumber(LValue));
      mkInscricaoEstadual:LValue := Mask( FormatStateInscription( aExtra), OnlyNumber( LValue));
      mkCNPJorCPF:begin
         LValue := OnlyNumber( LValue);

         if Length( LValue) <= 11 then
            LValue   := Mask('###.###.###-##', LValue)
         else LValue := Mask('##.###.###/####-##', LValue);
      end;
      mkTelefoneFixo:LValue := Mask('(##) ####-####', OnlyNumber( LValue));
      mkCelular:LValue:= Mask('(##) #####-####', OnlyNumber(LValue));
      mkPersonalizado:LValue := Mask( aExtra, OnlyNumber(LValue));
      mkValor:begin
         LDecimal     := StrToIntDef( aExtra, 2);
         LDecimalMask := EmptyStr;

         if LValue = '' then
            LValue := '0';

         LValue := StringReplace( LValue, '.', '', [rfReplaceAll]);
         LValue := StringReplace( LValue, ',', '', [rfReplaceAll]);

         for var I:word := 1 to LDecimal do
            LDecimalMask := LDecimalMask + '0';

         try
            LValue := FormatFloat('#,##0.'+LDecimalMask , strtofloat( OnlyNumber( LValue)) / Power( 10, LDecimal));
         except
            LValue := FormatFloat('#,##0.'+LDecimalMask, 0);
         end;
      end;
      mkMoeda:begin
         if LValue = '' then
            LValue := '0';

         try
            LValue := FormatFloat('#,##0.00', strtofloat( OnlyNumber( LValue)) / 100);
         except
            LValue := FormatFloat('#,##0.00', 0);
         end;

         if aExtra = '' then
            aExtra := 'R$';

         LValue := aExtra + LValue;
      end;
      mkCEP:LValue := Mask('##.###-###', OnlyNumber(LValue));
      mkData:begin
        LValue := OnlyNumber( LValue);

        if Length(LValue) < 8 then
            LValue := Mask('##/##/####', LValue)
        else begin
            try
                LValue := Mask('##/##/####', LValue);
                strtodate(LValue);
                LValue := LValue;
            except
                LValue := '';
            end;
        end;
      end;
      mkHora:begin
        LValue := OnlyNumber(LValue);

        if Length(LValue) < 6 then
            LValue := Mask('##:##:##', LValue)
        else begin
            try
                LValue := Mask('##:##:##', LValue);
                strtodate(LValue);
                LValue := LValue;
            except
                LValue := '';
            end;
        end;
      end;
      mkHoraMin:begin
        LValue := OnlyNumber(LValue);

        if Length(LValue) < 4 then
            LValue := Mask('##:##', LValue)
        else begin
            try
                LValue := Mask('##:##', LValue);
                strtodate(LValue);
                LValue := LValue;
            except
                LValue := '';
            end;
        end;
      end;
      mkDataHora:begin
        LValue := OnlyNumber(LValue);

        if Length(LValue) < 15 then
            LValue := Mask('##/##/#### ##:##:##', LValue)
        else begin
            try
                LValue := Mask('##/##/#### ##:##:##', LValue);
                strtodate(LValue);
                LValue := LValue;
            except
                LValue := '';
            end;
        end;
      end;
      mkPeso:begin
         if LValue.IsEmpty then
            LValue := '0';

         try
            LValue := FormatFloat( '#,##0.000', strtofloat( LValue) / 1000);
         except
            LValue := FormatFloat('#,##0.000', 0);
         end;

      end;
      mkTelefone:if Length( OnlyNumber(LValue)) <= 11 then
                    LValue   := Mask('(##) #####-####', OnlyNumber(LValue))
                 else LValue := Mask('(##) ####-####', OnlyNumber(LValue));
   end;

   Result := LValue;
end;

class function TUtils.DefaultFormat(aObject: TEdit; aFormat: TMaskKind; aExtra: string): String;
begin
    TThread.Queue(Nil, procedure
    var LValue:string;
    begin
        LValue := Self.DefaultFormat( aObject.Text, aFormat, aExtra);
        aObject.Text := LValue;
        aObject.CaretPosition := aObject.Text.Length;
    end);
end;

class function TUtils.eMailFormat(aValue: String): Boolean;
begin
   Result := TRegEx.IsMatch( aValue, '^([0-9a-zA-Z]([-\.\w]*[0-9a-zA-Z])*@([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,9})$');
end;

class function TUtils.Encode64(aValue: String): String;
begin
   Result := TIdEncoderMIME.EncodeString( aValue);
end;

class function TUtils.EnumToStr<T>(aValue: T): String;
begin
   ValidEnum<T>;
   Result := TRTTIEnumerationType.GetName<T>( aValue);
end;

class function TUtils.EnumToValue<T>(aValue: T): TValue;
begin
   ValidEnum<T>;

   Result := StrEnumToValue<T>( EnumToStr<T>( aValue));
end;

class function TUtils.FileCount(aPath, aExtension: String): Integer;
var cont : integer;
    {$IFDEF WIN32 or WIN64}
    sr: TSearchRec;
    {$endif}
begin
   cont := 0;

   {$WARN SYMBOL_PLATFORM OFF}
   {$IFDEF WIN32 or WIN64}
   if FindFirst( aPath + PathDelim + aExtension, faArchive, sr) = 0 then
   begin
      repeat
        if (sr.Attr and faArchive) = sr.Attr then
           inc(cont);
      until FindNext(sr) <> 0;

      FindClose(sr);
   end;
   {$ENDIF}
   {$WARN SYMBOL_PLATFORM  ON}

   Result := Cont;
end;

class function TUtils.FileMD5(const aValue: String): String;
var LMD5: TIdHashMessageDigest5;
    LArquivo: TFileStream;
begin
   LMD5 := TIdHashMessageDigest5.Create;
   LArquivo := TFileStream.Create( aValue, fmOpenRead OR fmShareDenyWrite);

   try
      Result := LMD5.HashStreamAsHex(LArquivo);
   finally
      LArquivo.Free;
      LMD5.Free;
   end;
end;

class function TUtils.FindNode(aNode: IXMLNode; aName: String): IXMLNode;
begin
   Result := Nil;

   if Assigned( aNode) then
      if AnsiLowerCase( aNode.NodeName) = AnsiLowerCase( aName) then
         Result := aNode
      else if aNode.HasChildNodes then
              for var I:integer := 0 to Pred( aNode.ChildNodes.Count) do
              begin
                 Result := FindNode( aNode.ChildNodes[I], aName);

                 if Assigned( Result) then
                    Exit;
              end;
end;

class function TUtils.FindNodeAttributeValue(aNode: IXMLNode; aName,
  aAttribute: String): Variant;
Var LNode:IXMLNode;
begin
   Result := Unassigned;
   LNode  := FindNode( aNode, aName);

   if Assigned( LNode) and LNode.HasAttribute( aAttribute) then
      Result := LNode.Attributes[ aAttribute]
end;

class function TUtils.FindNodeByAddress(aNode: IXMLNode;
  aName: String): IXMLNode;
Var LStruct:TStringList;
    LKey:String;
    LNode:IXMLNode;
begin
   try
      LStruct := TStringList.Create;
      LStruct.Delimiter     := '\';
      LStruct.DelimitedText := aName;
      LNode := aNode;

      for var I:integer := 0 to Pred( LStruct.Count) do
      begin
         if not Assigned( LNode) then
            exit;

         LKey  := LStruct.Strings[ i];
         LNode := FindNode( LNode, LKey);
      end;

      Result := LNode;
   finally
      FreeAndNil( LStruct);
   end;
end;

class function TUtils.FindNodeValue(aNode: IXMLNode;
  aName: String): Variant;
Var LNode:IXMLNode;
begin
   Result := Unassigned;
   LNode  := FindNode( aNode, aName);

   if Assigned( LNode) then
      if LNode.IsTextElement then
         Result := LNode.NodeValue;
end;

class function TUtils.FindNodeValueByAddress(aNode: IXMLNode;
  aName: String): Variant;
Var LNode:IXMLNode;
begin
   Result := Unassigned;
   LNode := FindNodeByAddress( aNode, aName);

   if Assigned( LNode) then
      Result := LNode.NodeValue;
end;

class function TUtils.FirstUpper(aValue: String): String;
const
  excecao: array[0..5] of string = ( 'da', 'de', 'do', 'das', 'dos', 'e');

var tamanho, j: integer;
    i: byte;

begin
  Result  := AnsiLowerCase( aValue);
  tamanho := Length( Result);

  for j := 1 to tamanho do
    // Se é a primeira letra ou se o caracter anterior é um espaço
    if (j = 1) or ((j>1) and (Result[j-1]=Chr(32))) then
      Result[j] := AnsiUpperCase(Result[j])[1];

  for i := 0 to Length(excecao)-1 do
    result:= StringReplace(result,excecao[i],excecao[i],[rfReplaceAll, rfIgnoreCase]);
end;

class function TUtils.FixedSize(aValue: String; aSize: Integer;
  aChar: Char; aCharPosition: TCharPosition): String;
begin
   Result := EmptyStr;

   if Length( aValue) > aSize then
      Result := Copy( aValue, 1, aSize)
   else begin
      Result := StringOfChar( aChar, aSize - Length( aValue));

      if aCharPosition = cpLeft then
         Result   := Result + aValue
      else Result := aValue + Result;
   end;
end;

class function TUtils.FloatFormat(aValue: String): Currency;
begin
  while Pos( '.', aValue) > 0 do
    delete( aValue, Pos( '.', aValue),1);

  Result := StrToCurr( aValue);
end;

class function TUtils.FormatStateInscription( aState:String): String;
begin
   case AnsiIndexStr( AnsiLowerCase( aState), [ AnsiLowerCase( 'AC'), AnsiLowerCase( 'AL'), AnsiLowerCase( 'AP'),
                                                AnsiLowerCase( 'AM'), AnsiLowerCase( 'BA'), AnsiLowerCase( 'CE'),
                                                AnsiLowerCase( 'DF'), AnsiLowerCase( 'ES'), AnsiLowerCase( 'GO'),
                                                AnsiLowerCase( 'MA'), AnsiLowerCase( 'MT'), AnsiLowerCase( 'MS'),
                                                AnsiLowerCase( 'MG'), AnsiLowerCase( 'PA'), AnsiLowerCase( 'PB'),
                                                AnsiLowerCase( 'PR'), AnsiLowerCase( 'PE'), AnsiLowerCase( 'PI'),
                                                AnsiLowerCase( 'RJ'), AnsiLowerCase( 'RN'), AnsiLowerCase( 'RS'),
                                                AnsiLowerCase( 'RO'), AnsiLowerCase( 'RR'), AnsiLowerCase( 'SC'),
                                                AnsiLowerCase( 'SP'), AnsiLowerCase( 'SE'), AnsiLowerCase( 'TO')]) of
      00:Result := '##.###.###/###-##';
      01:Result := '#########';
      02:Result := '#########';
      03:Result := '##.###.###-#';
      04:Result := '######-##';
      05:Result := '########-#';
      06:Result := '###########-##';
      07:Result := '#########';
      08:Result := '##.###.###-#';
      09:Result := '#########';
      10:Result := '##########-#';
      11:Result := '#########';
      12:Result := '###.###.###/####';
      13:Result := '##-######-#';
      14:Result := '########-#';
      15:Result := '########-##';
      16:Result := '##.#.###.#######-#';
      17:Result := '#########';
      18:Result := '##.###.##-#';
      19:Result := '##.###.###-#';
      20:Result := '###/#######';
      21:Result := '###.#####-#';
      22:Result := '########-#';
      23:Result := '###.###.###';
      24:Result := '###.###.###.###';
      25:Result := '#########-#';
      26:Result := '###########';
   end;
end;

class function TUtils.GenerateRandomCode(ALength: Integer): string;
const DIGITS = '0123456789';
var I: Integer;
begin
   Randomize;
   SetLength(Result, ALength);

   for I := 1 to ALength do
      Result[I] := DIGITS[Random(10) + 1];
end;

class function TUtils.GenerateRandomToken(ALength: Integer): string;
const CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
var
  I: Integer;
begin
   Randomize;
   SetLength(Result, ALength);

   for I := 1 to ALength do
      Result[I] := CHARS[Random(Length(CHARS)) + 1];
end;

class function TUtils.GetJSONValueToVar<T>(aJSON: TJSONObject; aField: String): T;
Var LValue:TJSONValue;
begin
   LValue := aJSON.FindValue( aField);

   if Assigned( LValue) then
      Result := LValue.AsType<T>;
end;

class function TUtils.GetRttiFromInterface(AIntf: IInterface; out RttiType: TRttiType): Boolean;
var obj: TObject;
    IntfType: TRttiInterfaceType;
    ctx: TRttiContext;
    tmpIntf: IInterface;
begin
  Result := False;

  // get the implementing object...
  obj := AIntf as TObject;

  // enumerate the object's interfaces, looking for the
  // one that matches the input parameter...
  for IntfType in (ctx.GetType(obj.ClassType) as TRttiInstanceType).GetImplementedInterfaces do
  begin
    if obj.GetInterface(IntfType.GUID, tmpIntf) then
    begin
      if AIntf = tmpIntf then
      begin
        RttiType := IntfType;
        Result := True;
        Exit;
      end;
      tmpIntf := nil;
    end;
  end;
end;

class function TUtils.GetTextHeight(const D: TListItemText;
  const Width: single; const Text: string): Integer;
var Layout: TTextLayout;
begin
   // Create a TTextLayout to measure text dimensions
   Layout := TTextLayoutManager.DefaultTextLayout.Create;

   try
      Layout.BeginUpdate;
      try
         // Initialize layout parameters with those of the drawable
         Layout.Font.Assign(D.Font);
         Layout.VerticalAlign   := D.TextVertAlign;
         Layout.HorizontalAlign := D.TextAlign;
         Layout.WordWrap        := D.WordWrap;
         Layout.Trimming        := D.Trimming;
         Layout.MaxSize         := TPointF.Create(Width, TTextLayout.MaxLayoutSize.Y);
         Layout.Text            := Text;
      finally
         Layout.EndUpdate;
      end;

      // Get layout height
      Result := Round(Layout.Height);
      // Add one em to the height
      Layout.Text := 'm';
      Result := Result + Round(Layout.Height);
   finally
      Layout.Free;
   end;
end;

class function TUtils.ImageToBase64(aImage: TBitmap): String;
Var LOrigem:TBytesStream;
    LDestino:TStringStream;
begin
   try
      LOrigem  := TBytesStream.Create;
      LDestino := TStringStream.Create;
      aImage.SaveToStream( LOrigem);
      LOrigem.Position := 0;

      TNetEncoding.Base64.Encode( LOrigem, LDestino);
      LDestino.Position := 0;

      Result := LDestino.DataString;
   finally
      FreeAndNil( LOrigem);
      FreeAndNil( LDestino);
   end;
end;

class function TUtils.IntToBin(Value: LongWord): string;
var
   i: Integer;
   pStr: PChar;
begin
   SetLength( Result,8);
   pStr := PChar(Pointer(Result));  // Get a pointer to the string

   for i := 7 downto 0 do
      pStr[i] := Char(Ord('0') + ((Value shr (7 - i)) and 1));
end;

class function TUtils.IsSetValueValid<T>(aSet: TVariantArray<T>; aValue: T): Boolean;
Var LItem:Integer;
begin
   ValidEnum<T>;
   Result := TArray.BinarySearch<T>( aSet, aValue, LItem);
end;

class function TUtils.JSONDateToDateTime(aValue: TJSONValue): TDateTime;
begin
   Result := 0;

   if not ( aValue is TJSONNull) then
      Result := JSONDateToDateTime( aValue.AsType<String>);
end;

class function TUtils.JSONFieldType(aValue: TJSONValue): TFieldType;
begin
   Result := ftUnknown;

   if aValue is TJSONObject then
      Result := ftObject
   else if aValue is TJSONString then
        begin
           try
              ISO8601ToDate( aValue.AsType<String>, True);
              Result := ftDateTime;
           except
              Result := ftString;
           end;
        end
        else if aValue is TJSONNumber then
             begin
                if Frac( TJSONNumber( aValue).AsDouble) > 0.00 then
                   Result := ftFloat
                else Result := ftInteger;
             end
             else if aValue is TJSONBool then
                     Result := ftBoolean;
end;

class function TUtils.JSONValueToInt(aValue: TJSONValue): Integer;
begin
   if ( aValue is TJSONNull) or ( not ( aValue is TJSONNumber)) then
      Result := 0
   else Result := aValue.AsType<Integer>;
end;

class function TUtils.JSONValueToValue(aValue: TJSONValue): TValue;
begin
   Result := TValue.FromVariant( JSONValueToVar( aValue));
end;

class function TUtils.JSONValueToVar(aValue: TJSONValue): Variant;
begin
   case JSONFieldType( aValue) of
      ftDateTime:Result := ISO8601ToDate( aValue.AsType<String>);
      ftString  :Result := aValue.AsType<String>;
      ftFloat   :Result := aValue.AsType<Double>;
      ftInteger :Result := aValue.AsType<Integer>;
      ftBoolean :Result := aValue is TJSONTrue;
      else Result := Unassigned;
   end;
end;

class function TUtils.LeftHoursDayEnd(aValue: TTime): Double;
Var LDayEnd:TTime;
begin
   LDayEnd := StrToTime( '23:59:59');
   Result := SecondSpan( aValue, LDayEnd);
end;

class function TUtils.LeftSecondsDayEnd(aValue: TDateTime): Int64;
Var LDayEnd:TDateTime;
begin
   LDayEnd := StrToTime( '23:59:59');
   Result  := Trunc( SecondSpan( TimeOf( aValue), LDayEnd));
end;

class function TUtils.LocalToUTC(const ADateTime: TDateTime): TUTCDateTime;
begin
   Result := TTimeZone.Local.ToUniversalTime(ADateTime);
end;

class function TUtils.JSONDateToDateTime(aValue: String): TDateTime;
begin
   Result := 0;

   if not aValue.Trim.IsEmpty then
      TryISO8601ToDate( aValue, Result, False);
end;

class function TUtils.Mask(aMask, aValue: string): string;
var x, p : integer;
begin
   p := 1;
   Result := '';

   if aValue.IsEmpty then
       exit;

   for x := 1 to Length( aMask) do
   begin
      if aMask.Char[x] = '#' then
      begin
          Result := Result + aValue.Char[p];
          inc(p);
      end
      else Result := Result + aMask.Char[x];

      if p = Length(aValue) then
         break;
   end;
end;

class function TUtils.NewInstance(aValue: String): TObject;
var LContext: TRttiContext;
    LInstance: TRttiInstanceType;
begin
   Result := nil;

   try
      LContext  := TRttiContext.Create;
      LInstance := ( LContext.GetType( FindClass( aValue).ClassInfo) as TRttiInstanceType);
      Result    := (LInstance.MetaclassType.Create);
   except
   end;
end;

class function TUtils.NewInstance(aValue: TPersistentClass): TObject;
var LContext: TRttiContext;
    LInstance: TRttiInstanceType;
    LObject:TObject;
begin
   Result := nil;

   try
      LContext  := TRttiContext.Create;
      LInstance := ( LContext.GetType( aValue.ClassInfo) as TRttiInstanceType);
      LObject   := TObject( LInstance.MetaclassType.Create).Create;
      Result    := LObject;
   except
   end;
end;

class function TUtils.NewInstance<T>(aValue: T): T;
begin
   Result := T.Create;
end;

class function TUtils.NewUUID: TUUIDStr;
var LGuid: TGUID;
begin
  CreateGUID(LGuid);
  Result := GUIDToString(LGuid).Replace('{', '', []).Replace('}', '', []).ToLower;
end;

class function TUtils.NoEspecialChar(aValue: String): String;
Var LChar:Char;
begin
   Result := EmptyStr;

   for LChar in aValue do
      if Not CharInSet( LChar, [ '0'..'9', 'a'..'z','A'..'Z']) then
         Result := Result + LChar;
end;

class function TUtils.OnlyNumber(aValue: String): String;
Var LChar:Char;
begin
   Result := EmptyStr;

   for LChar in aValue do
      if CharInSet( LChar, [ '0'..'9']) then
         Result := Result + LChar;
end;

class function TUtils.OnlyNumericChars(aValue: String): String;
Var i:integer;
begin
   for I := 1 to Length( aValue) do
      if CharInSet( aValue[ I], [ '.', ',', '-', '0'..'9', '(', ')']) then
         Result := Result + aValue[ I];
end;

class function TUtils.RemoveAccents(aValue: String): String;
Var i:integer;
begin
   for I := 1 to Length( aValue) do
      case aValue[ I] of
         'á', 'à', 'ã', 'â', 'ä':Result := Result + 'a';
         'Á', 'À', 'Ã', 'Â', 'Ä':Result := Result + 'A';
         'é', 'è', 'ê', 'ë'     :Result := Result + 'e';
         'É', 'È', 'Ê', 'Ë'     :Result := Result + 'e';
         'í', 'ì', 'î', 'ï'     :Result := Result + 'i';
         'Í', 'Ì', 'Î', 'Ï'     :Result := Result + 'I';
         'ó', 'ò', 'ô', 'õ', 'ö':Result := Result + 'o';
         'Ó', 'Ò', 'Ô', 'Õ', 'Ö':Result := Result + 'O';
         'ú', 'ù', 'û', 'ü'     :Result := Result + 'u';
         'Ú', 'Ù', 'Û', 'Ü'     :Result := Result + 'U';
         else Result := Result + aValue[ I];
      end;
end;

class function TUtils.RemoveMaskChars(aValue: String): String;
Var i:integer;
begin
   for I := 1 to Length( aValue) do
      if not ( CharInSet( aValue[ I], [ ' ', '.', '/', '-', '(',')'])) then
         Result := Result + aValue[ I];
end;

class function TUtils.RemoveSpecialChars(aValue: String): String;
Var i:integer;
begin
   Result := EmptyStr;

   for I := 1 to Length( aValue) do
      if not ( CharInSet( aValue[ I], [ '!', '@', '#', '$', '%', '&', '*', '(', ')',
                                        '-', '_', '+', '=', '§', '{', '}', 'ª', 'º',
                                        '[', ']', '°', '?', '/', '\', '|', ',', '.',
                                        ':', ';', '<', '>', '¹', '²', '³', '£', '¢',
                                        '¬'])) then
         Result := Result + aValue[ I];
end;

class procedure TUtils.ResourceImage(aResource: String; aImage: TImage);
var Resource : TResourceStream;
begin
  Resource := TResourceStream.Create(HInstance, aResource, RT_RCDATA);
  try
    aImage.Bitmap.LoadFromStream(Resource);
  finally
    Resource.Free;
  end;
end;

class function TUtils.ReturnMask(aFormat: TMaskKind): String;
begin
   case aFormat of
      mkCNPJ:             Result := '##.###.###/####-##';
      mkCPF:              Result := '###.###.###-##';
      mkInscricaoEstadual:Result := EmptyStr;
      mkCNPJorCPF:        Result := EmptyStr;
      mkTelefoneFixo:     Result := '(##) ####-####';
      mkCelular:          Result := '(##) #####-####';
      mkPersonalizado:    Result := EmptyStr;
      mkValor:            Result := '#,##0.00';
      mkMoeda:            Result := '#,##0.00';
      mkCEP:              Result := '##.###-###';
      mkData:             Result := '##/##/####';
      mkHora:             Result := '##:##:##';
      mkHoraMin:          Result := '##:##';
      mkDataHora:         Result := '##/##/#### ##:##:##';
      mkPeso:             Result := '#,##0.000';
      mkTelefone:         Result := EmptyStr;
      else                Result := EmptyStr;
   end;
end;

class function TUtils.Rounding(aValue: Double; aPrecision: Integer = 2): Double;
var Factor, Fraction: Extended;
begin
   if aPrecision > 0 then
   begin
      Factor   := IntPower( 10, aPrecision);
      aValue   := StrToFloat( FloatToStr( aValue * Factor));
      Result   := Int( aValue);
      Fraction := Frac( aValue);

      if Fraction = 0.00 then
         Result := Result
      else if Fraction >= 0.5 then
              Result := Result + 1
           else if Fraction <= -0.5 then
                   Result := Result - 1;

      Result := Result / Factor;
   end
   else Result := aValue;
end;

class function TUtils.SHA256(const AValue: string): string;
begin
   Result := THashSHA2.GetHashString(AValue, THashSHA2.TSHA2Version.SHA256).ToLower;
end;

class function TUtils.SHA512(const AValue: string): string;
begin
   Result := THashSHA2.GetHashString(AValue, THashSHA2.TSHA2Version.SHA512).ToLower;
end;

class function TUtils.StreamToByteArray(aStream: TMemoryStream): TBytes;
var LStreamPos: Int64;
begin
   if Assigned(aStream) then
   begin
      LStreamPos := aStream.Position;
      aStream.Position := 0;
      SetLength(Result, aStream.Size);
      aStream.Read(Result, aStream.Size);
      aStream.Position := LStreamPos;
   end
   else SetLength(Result, 0);
end;

class function TUtils.StrEnumToValue<T>(aValue: String): TValue;
begin
   ValidEnum<T>;

   if not StrIsSetValueValid<T>( aValue) then
      raise Exception.Create( '"'+ aValue +'" is a invalid value');


   Result := TValue.FromOrdinal( TypeInfo(T),
                                 GetEnumValue( TypeInfo(T), aValue));
end;

class function TUtils.StringMD5(const aValue: String): String;
var LMD5: TIdHashMessageDigest5;
begin
   Result := EmptyStr;

   if not aValue.Trim.IsEmpty then
   begin
      LMD5 := TIdHashMessageDigest5.Create;
      try
         Result := LMD5.HashStringAsHex( aValue.Trim);
      finally
         LMD5.Free;
      end;
   end;
end;

class function TUtils.StrIsSetValueValid<T>(aValue: String): Boolean;
begin
   ValidEnum<T>;
   Result := GetEnumValue( TypeInfo( T), aValue) >= 0;
end;

class function TUtils.StrToEnum<T>(aValue: String): T;
begin
   ValidEnum<T>;

   if not StrIsSetValueValid<T>( aValue) then
      raise Exception.Create( '"'+ aValue +'" is a invalid value');

   Result := TRTTIEnumerationType.GetValue<T>( aValue);
end;

class function TUtils.UTCNow: TUTCDateTime;
begin
   Result := TTimeZone.Local.ToUniversalTime(Now)
end;

class function TUtils.UTCToLocal(const AUtcDateTime: TUTCDateTime): TDateTime;
begin
    Result := TTimeZone.Local.ToLocalTime(AUtcDateTime);
end;

class procedure TUtils.ValidEnum( aValue:TValue);
begin
   if aValue.TypeInfo.Kind <> tkEnumeration then
      raise Exception.Create( 'Type informed isen''t valid value on this operation');
end;

class procedure TUtils.ValidEnum<T>;
Var LContext:TRttiContext;
    LType:TRttiType;
begin
   LContext  := TRttiContext.Create;
   LType     := LContext.GetType( System.TypeInfo( T));

   if LType.TypeKind <> tkEnumeration then
      raise Exception.Create( 'Type informed isen''t valid value on this operation');
end;

class function TUtils.ValueToEnum<T>(aValue: TValue): T;
begin
   ValidEnum<T>;
   Result := TRTTIEnumerationType.GetValue<T>( aValue.AsVariant);
end;

class function TUtils.ValueToStrEnum(aValue: TValue): String;
begin
   ValidEnum( aValue);
   Result := GetEnumName( aValue.TypeInfo, aValue.AsVariant);
end;

class function TUtils.ValueToStrEnum<T>( aValue:TValue): String;
begin
   ValidEnum<T>;

   Result := TRTTIEnumerationType.GetName<T>(
                TRTTIEnumerationType.GetValue<T>( aValue.AsVariant)
             );
end;

class function TUtils.ValueToVar(aValue: TValue): Variant;
begin
   case aValue.TypeInfo.Kind of
      tkInteger:Result := aValue.AsInteger;
      tkInt64:Result   := aValue.AsInt64;
      tkSet: ;
      tkClass: ;
      tkMethod: ;
      tkChar,
      tkWChar,
      tkLString,
      tkWString,
      tkVariant,
      tkUString,
      tkString:Result := aValue.AsString;
      tkEnumeration:begin
         if aValue.TypeInfo.Name = 'Boolean' then
            Result   := StrToBool( aValue.ToString)
         else Result := TValue.FromOrdinal( aValue.TypeInfo,
                                            GetEnumValue( aValue.TypeInfo,
                                                          aValue.ToString)).AsVariant;
      end;
      tkFloat:begin
        case AnsiIndexStr( AnsiLowerCase( String( aValue.TypeInfo.Name)), [ AnsiLowerCase( 'TDateTime'),
                                                                                     AnsiLowerCase( 'TTime'),
                                                                                     AnsiLowerCase( 'TDate')]) of
           0:Result    := StrToDateTime( aValue.AsString);
           1:Result    := StrToTime( aValue.AsString);
           2:Result    := StrToDate( aValue.AsString);
           else Result := aValue.AsCurrency;
        end;
      end;

      // ver como tratar posteriormente
      {tkArray: ;
      tkRecord: ;

      tkUnknown: ;
      tkInterface: ;
      tkDynArray: ;
      tkClassRef: ;
      tkPointer: ;
      tkProcedure: ;
      tkMRecord: ;}
      else raise Exception.Create( 'Value type invalid.');
   end;
end;

class function TUtils.VarToJSONValue(aValue: Variant): TJSONValue;
begin
  case VarType( aValue) of
    varEmpty     :Result := TJSONNull.Create;
    varNull      :Result := TJSONNull.Create;
    varSmallInt  :Result := TJSONNumber.Create( VarToStr( aValue));
    varInteger   :Result := TJSONNumber.Create( VarToStr( aValue));
    varSingle    :Result := TJSONNumber.Create( VarToStr( aValue));
    varDouble    :Result := TJSONNumber.Create( VarToStr( aValue));
    varCurrency  :Result := TJSONNumber.Create( VarToStr( aValue));
    varDate      :Result := TJSONString.Create( DateToISO8601( aValue));
    varOleStr    :Result := TJSONString.Create( aValue);
    varBoolean   :if aValue then
                     Result   := TJSONTrue.Create
                  else Result := TJSONFalse.Create;
    varUnknown   :Result := TJSONNull.Create;
    varByte      :Result := TJSONString.Create( aValue);
    varWord      :Result := TJSONNumber.Create( VarToStr( aValue));
    varLongWord  :Result := TJSONNumber.Create( VarToStr( aValue));
    varInt64     :Result := TJSONNumber.Create( VarToStr( aValue));
    varStrArg    :Result := TJSONString.Create( aValue);
    varString    :Result := TJSONString.Create( aValue);
    varTypeMask  :Result := TJSONString.Create( aValue);
    varUString   :Result := TJSONString.Create( aValue);
    else Result := TJSONNull.Create;
  end;
end;

class function TUtils.VarToValue(aValue: Variant): TValue;
begin
   Result := TValue.FromVariant( aValue);
end;

class function TUtils.VarToValue(aTypeKind: TTypeKind; aValue: Variant): TValue;
begin
   case aTypeKind of
      tkInteger,
      tkInt64,
      tkFloat,
      tkChar,
      tkWChar,
      tkLString,
      tkWString,
      tkVariant,
      tkUString,
      tkString,
      tkEnumeration:Result := TValue.FromVariant( aValue);

      // ver como tratar posteriormente
      {tkArray: ;
      tkRecord: ;

      tkSet: ;
      tkClass: ;
      tkMethod: ;
      tkUnknown: ;
      tkInterface: ;
      tkDynArray: ;
      tkClassRef: ;
      tkPointer: ;
      tkProcedure: ;
      tkMRecord: ;}
      else raise Exception.Create( 'Value type invalid.');
   end;
end;

end.
