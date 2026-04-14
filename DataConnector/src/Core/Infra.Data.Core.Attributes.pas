unit Infra.Data.Core.Attributes;

interface

uses System.SysUtils, System.TypInfo,
     System.RTTI,
     System.Variants,
     System.Classes,
     System.Generics.Collections,

     Infra.Types,
     Infra.Utils;

type
   // Indica o nome da tabela no banco de dados
   Table = class( TCustomAttribute)
   private
      FName: String;
   public
      constructor Create( aName:String);
      property Name: String read FName write FName;

   end;

   // Indica o nome do contexto ao qual a tabela se refere (contexto é equivalente a módulo do sistema)
   TableModule = class( TCustomAttribute)
   private
      FName: String;
   public
      constructor Create( aName:String);
      property Name: String read FName write FName;

   end;

   // Indica se a entidade é uma view não permitindo operações de inclusão, alteração ou exclusão de dados
   View = class( TCustomAttribute)
   private
      FName: String;
   public
      constructor Create( aName:String);
      property Name: String read FName write FName;

   end;

   SysModule = class( TCustomAttribute)
   private
      FName: String;
   public
      constructor Create( aName:String);
      property Name: String read FName write FName;

   end;

   // Indica o tamanho da pagina de dados utilziada para a tabela na busca de dados
   Paginate = class( TCustomAttribute)
   private
      FPageSize: Integer;

   public
      constructor Create( aPageSize:Integer);
      property PageSize:Integer read FPageSize write FPageSize;

   end;

   // Indica se a entidade utilizara chache informando o lifetime da cache
   UseCache = class( TCustomAttribute)
   private
      FLifeTime: Integer;

   public
      constructor Create( aLifeTime:Integer = 1);
      property LifeTime:Integer read FLifeTime write FLifeTime;

   end;

   ClientCache = class( TCustomAttribute)
   private
      FLifeTime: Integer;

   public
      constructor Create( aLifeTime:Integer = 1);
      property LifeTime:Integer read FLifeTime write FLifeTime;

   end;

   Endpoint = class( TCustomAttribute)
   private
      FName:String;

   public
      constructor Create( aName:String);
      property Name:String read FName write FName;

   end;

   Host = class( TCustomAttribute)
   private
      FName:String;

   public
      constructor Create( aName:String);
      property Name:String read FName write FName;

   end;

   Port = class( TCustomAttribute)
   private
      FNumber:integer;

   public
      constructor Create( aNumber:Integer);
      property Number:integer read FNumber write FNumber;

   end;

   AuthorizationType = class( TCustomAttribute)
   private
      FName:String;

   public
      constructor Create( aName:String);
      property Name:String read FName write FName;

   end;

   SecurityResource = class( TCustomAttribute)
   private
      FSecurityResource:TSecurityResourceSet;

   public
      constructor Create( aSecuritySet:TSecurityResourceSet);
      property Resource:TSecurityResourceSet read FSecurityResource write FSecurityResource;

   end;

   RESTLookUp = class( TCustomAttribute)
   private
      FDisplay: string;
      FReferences: TArray<string>;
      FURIEndpoint: String;
      FKeys: TArray<string>;

   public
      constructor Create( aURIEndpoint:String; aDisplay:String; aKeys:String; aReferences:String);

      property URIEndpoint:String         read FURIEndpoint write FURIEndpoint;
      property Display:string             read FDisplay     write FDisplay;
      property Keys:TArray<string>        read FKeys        write FKeys;
      property References:TArray<string>  read FReferences  write FReferences;
   end;

   ShowGrid = class( TCustomAttribute);
   GridSize = class( TCustomAttribute)
   private
      FSize:Integer;

   public
      constructor Create( aSize:Integer);
      property Size:Integer read FSize write FSize;

   end;

   GridTitle = class( TCustomAttribute)
   private
      FTitle:String;

   public
      constructor Create( aTitle:String);
      property Title:String read FTitle write FTitle;

   end;

   // Indica um nome amigável para o campo ou tabela utilizado em mensagem automáticas de validação de dados
   Title = class( TCustomAttribute)
   private
      FName: String;
   public
      constructor Create( aName:String);
      property Name: String read FName write FName;

   end;

   // Indica o nome do campo da tabela do banco de dados
   FieldName = class( TCustomAttribute)
   private
      FName: String;
      FChanged: Boolean;
   public
      constructor Create( aName:String);
      property Name:String     read FName    write FName;
      property Changed:Boolean read FChanged write FChanged;

   end;

   // Indica qual o nome do parametro utilizado nos comandos SQL quando ouver repetição de campo ou quando for diferente do nome do campo na tabela
   ParamName = class( TCustomAttribute)
   private
      FName: String;
   public
      constructor Create( aName:String);
      property Name: String read FName write FName;

   end;

   // Indica que o campo não aceita valor nulo definindo uma mensagem para a validação
   NotNull = class( TCustomAttribute)
   private
      FMessage: String;

   public
      constructor Create( aMessage:String = '');overload;

      property &Message:String read FMessage write FMessage;
   end;

   // Idica o tamanho do campo
   Size = class( TCustomAttribute)
   private
      FSize:Integer;

   public
      constructor Create( aSize:Integer);
      property Size:Integer read FSize write FSize;

   end;

   // Indica a quantidade de casas decimais de um campo do tipo ponto flutuante
   Precision = class( TCustomAttribute)
   private
      FDecimal:Integer;

   public
      constructor Create( aDecimal:Integer);
      property Decimal:Integer read FDecimal write FDecimal;

   end;

   // Indica que o campo deve ser ignorado na geração do JSON
   Ignore = class(TCustomAttribute);

   // Indica que o campo deve ser ignorado na geração do JSON se não tiver valor (NULL)
   IgnoreNull = class( TCustomAttribute);

   // Indica o valor padrão de um campo para diversos tipos diferentes
   DefaultValue = class(TCustomAttribute)
   private
      FValue:Variant;

   public
      constructor Create( aValue:String);overload;
      constructor Create( aValue:Integer);overload;
      constructor Create( aValue:Double);overload;
      constructor Create( aValue:Boolean);overload;
      constructor Create( aValue:TDateTime);overload;
      constructor Create( aValue:TValue);overload;

      property Value:Variant read FValue write FValue;

   end;

   // Indica os valores válidos para um campo
   ValidValues = class( TCustomAttribute)
   private
      FValues:Variant;

   public
      constructor Create( aValues:String);
      property Values:Variant read FValues;

   end;

   FindValues = class( TCustomAttribute)
   private
      FValues:Variant;
      FSize:Integer;
      FCompareOperator:TCompareOperator;
      FLogicalOperator:TLogicalOperator;

   public
      constructor Create( aValues:String; aCompare:TCompareOperator = coEqual; aLogical:TLogicalOperator = loAnd);

      property Values:Variant                   read FValues           write FValues;
      property Size:Integer                     read FSize             write FSize;
      property CompareOperator:TCompareOperator read FCompareOperator  write FCompareOperator;
      property LogicalOperator:TLogicalOperator read FLogicalOperator  write FLogicalOperator;

   end;

   ExpressionOfValidation = class( TCustomAttribute)
   private
    FExpression: String;

   public
      constructor Create( aValue:String);
      property Expression:String read FExpression write FExpression;

   end;

   // Indica que o campo aceita zero como valor válido
   AllowZeroValue = class( TCustomAttribute);

   // Indica que o campo receberá a data corrente
   CurrentDate = class( TCustomAttribute);

   // Indica que o campo receberá a hora corrente
   CurrentTime = class( TCustomAttribute);

   // Indica que o campo receberá a data e hora corrente
   CurrentDateTime = class( TCustomAttribute);

   // Indica que o campo receberá o usuário que esta realizando a chamada
   CurrentUser = class( TCustomAttribute);

   // Indica que o campo é um campo criptografado
   PasswordField = class( TCustomAttribute);

   // Indica que o campo é de auto incremento
   AutoInc = class( TCustomAttribute);

   // Indica que o campo compõe a chave primária de campos multiplos
   KEY = class( TCustomAttribute);

   // Indica que o campo é a a chave primária
   PK = class( TCustomAttribute);

   // Indcia que o campo é uma chave única e não aceita valores repetidos na entidade
   UK = class( TCustomAttribute);

   // Indica que o campo não é utilzado na inclusão
   NoInsert = class( TCustomAttribute);

   // Indica que o campo não é utilizado na inclusão se estiver sem valor (NULL)
   NoInsertIfNull = class( TCustomAttribute);

   // Indica que o campo não é utilizado na alteração
   NoUpdate = class( TCustomAttribute);

   // Indica que o campo não é utilizado na alteração se estiver sem valor (NULL)
   NoUpdateIfNull = class( TCustomAttribute);

   // Indica que o campo é um campo customizado
   CustomField = class( TCustomAttribute);

   SearchField = class( TCustomAttribute);
   SearchNoPartial = class( TCustomAttribute);

   // Indica que o campo é um campo disponível para realizar filtro
   FindField = class( TCustomAttribute);

   // Indica que o campo é um campo de busca customizado
   CustomSearchField = class( TCustomAttribute);

   // Indica que o campo é do tipo BlocStream entretando armazena uma imagem
   ImageField = class( TCustomAttribute);

   // Indica que o campo é do tipo BlobText
   TextField = class( TCustomAttribute);

   // Indica que o campo é do tipo BlobStream
   FileField = class(  TCustomAttribute);

   // Indica que o campo irá conter o caminho de um arquivo
   PathField = class( TCustomAttribute);

   // Indica que o campo é um campo não habilitado
   DisableField = class( TCustomAttribute);

   // Indica que o campo é protegido
   ProtectedField = class( TCustomAttribute);

   // Indica que o campo aceita somente caracteres numéricos
   OnlyNumbers = class( TCustomAttribute);

   // Indica que o campo aceita somente caracteres alfa
   OnlyAlpha = class( TCustomAttribute);

   // Indica que o campo aceita caracteres alfanumericos
   AlphaNumeric = class( TCustomAttribute);

   // Indica que o campo não aceita caracteres especiais
   NoSpecialChars = class( TCustomAttribute);


   DetailField = class( TCustomAttribute)
   private
      FMasterField:String;

   public
      constructor Create( aMasterField:String);
      property MasterField:String read FMasterField write FMasterField;

   end;

   // Ordem padrão para o resultado de uma busca de dados
   DefaultOrder = class( TCustomAttribute)
   private
      FFields: String;

   public
      constructor Create( aFields:String);
      property Fields:String read FFields write FFields;

   end;

   // Indica que um campo é uma chave estrangeira para uma outra entidade
   FK = class( TCustomAttribute)
   private
      FClass:TPersistentClass;
      FMasterFields: String;
      FForeignFields: String;

   public
      constructor Create( aClass:TPersistentClass; aMasterFields:String; aForeignFields:String);

      property MasterFields:String       read FMasterFields   write FMasterFields;
      property ForeignFields:String      read FForeignFields  write FForeignFields;
      property ObjClass:TPersistentClass read FClass          write FClass;
   end;

   Parent = class( TCustomAttribute);

   DetailTable = class( TCustomAttribute)
   private
      FMasterFields:String;
      FKeyFields:String;

   public
      constructor Create( aMasterFields:String; aKeyFields:String);

      property MasterFields:String read FMasterFields write FMasterFields;
      property KeyFields:String    read FKeyFields    write FKeyFields;
   end;

   // valor minimo e máximo que um campo pode assumir
   Limits = class( TCustomAttribute)
   private
      FMinValue:Variant;
      FMaxValue:Variant;

   public
      constructor Create( aMinValue:Variant; aMaxValue:Variant);

      property MinValue:Variant read FMinValue write FMinValue;
      property MaxValue:Variant read FMaxValue write FMaxValue;
   end;

   // Valores válidos para campo do tipo string
   EnumStrings = class( TCustomAttribute)
   private
      FValues:TStringList;

   public
      constructor Create( StrValues:String);
      destructor Destroy;override;

      property Values:TStringList read FValues write FValues;
   end;

   // Indica que o campo possui mascara
   FieldMask = class( TCustomAttribute)
   private
      FMaskType:TMaskKind;
      FSaveMask:Boolean;
      FMask: String;

   public
      constructor Create( aMaskType:TMaskKind; aSaveMask:Boolean = False; aMask:String = '');
      property Mask:String read FMask write FMask;
      property MaskType:TMaskKind read FMaskType write FMaskType;
      property SaveMask:Boolean   read FSaveMask write FSaveMask;
   end;

implementation

{ Table }

constructor Table.Create(aName: String);
begin
   FName := aName;
end;

{ FieldName }

constructor FieldName.Create(aName: String);
begin
   FName    := aName;
   FChanged := False;
end;

{ NotNull }

constructor NotNull.Create(aMessage: String);
begin
   FMessage := aMessage;
end;

{ Size }

constructor Size.Create(aSize: Integer);
begin
   FSize := aSize;
end;

{ Precision }

constructor Precision.Create(aDecimal: Integer);
begin
   FDecimal := aDecimal;
end;

{ DefaultValue }

constructor DefaultValue.Create(aValue: String);
begin
   FValue := aValue;
end;

constructor DefaultValue.Create(aValue: Integer);
begin
   FValue := aValue;
end;

constructor DefaultValue.Create(aValue: Double);
begin
   FValue := aValue;
end;

constructor DefaultValue.Create(aValue: TDateTime);
begin
   FValue := aValue;
end;

constructor DefaultValue.Create(aValue: TValue);
begin
   FValue := aValue.AsVariant;
end;

constructor DefaultValue.Create(aValue: Boolean);
begin
   FValue := aValue;
end;

{ FK }

constructor FK.Create( aClass:TPersistentClass; aMasterFields:String; aForeignFields:String);
begin
   FClass         := aClass;
   FMasterFields  := aMasterFields;
   FForeignFields := aForeignFields;
end;

{ Title }

constructor Title.Create(aName: String);
begin
   FName := aName;
end;

{ TableModule }

constructor TableModule.Create(aName: String);
begin
   FName := aName;
end;

{ ParamName }

constructor ParamName.Create(aName: String);
begin
   FName := aName;
end;

{ Endpoint }

constructor Endpoint.Create(aName: String);
begin
   FName := aName;
end;

{ Host }

constructor Host.Create(aName: String);
begin
   FName := aName;
end;

{ Port }

constructor Port.Create( aNumber:Integer);
begin
   FNumber := aNumber;
end;

{ AuthorizationType }

constructor AuthorizationType.Create(aName: String);
begin
   FName := aName;
end;

{ SysModule }

constructor SysModule.Create(aName: String);
begin
   FName := aName;
end;

{ GridSize }

constructor GridSize.Create(aSize: Integer);
begin
   FSize := aSize;
end;

{ Limits }

constructor Limits.Create(aMinValue, aMaxValue: Variant);
begin
   FMinValue := aMinValue;
   FMaxValue := aMaxValue;
end;

{ FieldMask }

constructor FieldMask.Create(aMaskType: TMaskKind; aSaveMask:Boolean; aMask: String);
begin
   FMaskType := aMaskType;
   FMask     := aMask;
end;

{ RESTLookUp }

constructor RESTLookUp.Create( aURIEndpoint:String; aDisplay:String; aKeys:String; aReferences:String);
begin
   FURIEndpoint := aURIEndpoint;
   FDisplay     := aDisplay;
   FKeys        := aKeys.Split( [';']);
   FReferences  := aReferences.Split( [';']);
end;

{ GridTitle }

constructor GridTitle.Create(aTitle: String);
begin
   FTitle := aTitle;
end;

{ EnumStrings }

constructor EnumStrings.Create(StrValues: String);
begin
   FValues := TStringList.Create;
   FValues.Delimiter     := ';';
   FValues.DelimitedText := StrValues;
end;

destructor EnumStrings.Destroy;
begin
   FreeAndNil( FValues);
   inherited;
end;

{ DetailTable }

constructor DetailTable.Create(aMasterFields, aKeyFields: String);
begin
   FMasterFields := aMasterFields;
   FKeyFields    := aKeyFields;
end;

{ DetailField }

constructor DetailField.Create(aMasterField: String);
begin
   FMasterField := aMasterField;
end;

{ Paginate }

constructor Paginate.Create(aPageSize: Integer);
begin
   FPageSize := aPageSize;
end;

{ UseCache }

constructor UseCache.Create(aLifeTime: Integer);
begin
   FLifeTime := aLifeTime;
end;

{ ClientCache }

constructor ClientCache.Create(aLifeTime: Integer);
begin
   FLifeTime := aLifeTime;
end;

{ SecurityResource }

constructor SecurityResource.Create(aSecuritySet: TSecurityResourceSet);
begin
   FSecurityResource := aSecuritySet;
end;

{ FindValues }

constructor FindValues.Create(aValues:String; aCompare: TCompareOperator; aLogical: TLogicalOperator);
Var lstArray: TStringList;
    LArray:array of variant;
begin
   try
      FSize    := 1;
      lstArray := TStringList.Create;
      lstArray.Clear;
      lstArray.Delimiter := '|';
      lstArray.DelimitedText := Trim( aValues);

      if lstArray.Count > 1 then
      begin
         SetLength( LArray, lstArray.Count);

         for var I:integer := 0 To lstArray.Count -1 Do
            LArray[i] := lstArray.Strings[i];

         FValues := LArray;
         FSize   := lstArray.Count;
      end
      else FValues := aValues;
   finally
      FreeAndNil( lstArray);
   end;

   FCompareOperator := aCompare;
   FLogicalOperator := aLogical;

end;

{ ValidValues }

constructor ValidValues.Create(aValues: String);
Var lstArray: TStringList;
    LArray:array of variant;
begin
   try
      lstArray := TStringList.Create;
      lstArray.Clear;
      lstArray.Delimiter := '|';
      lstArray.DelimitedText := Trim( aValues);

      if lstArray.Count > 1 then
      begin
         SetLength( LArray, lstArray.Count);

         for var I:integer := 0 To lstArray.Count -1 Do
            LArray[i] := lstArray.Strings[i];

         FValues := LArray;
      end
      else FValues := aValues;
   finally
      FreeAndNil( lstArray);
   end;
end;

{ ExpressionOfValidation }

constructor ExpressionOfValidation.Create(aValue: String);
begin
   FExpression := aValue;
end;

{ DefaultOrder }

constructor DefaultOrder.Create(aFields: String);
begin
   FFields := aFields;
end;

{ View }

constructor View.Create(aName: String);
begin
   FName := aName;
end;

end.
