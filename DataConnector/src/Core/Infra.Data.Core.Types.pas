unit Infra.Data.Core.Types;

interface

const
   MINUTE_SECS    = 60;
   HOUR_SECS      = MINUTE_SECS * 60;
   STANDARD_CACHE = MINUTE_SECS * 5;

   STANDARD_PAGE  = 40;

type
   TDataType        = ( dtRest, dtDataBase);
   TFieldKind       = ( fkImage, fkFile, fkBasic);
   TClientCache     = ( ccNone, ccDataBase, ccMemory, ccHybrid);
   TDataComponent   = ( dcFiredac, dcZeus);
   TDatabaseManager = ( dmFirebird, dmInterbase, dmMySQL, dmSQLite);

   TFilterAction = ( faEqual, faDifferent, faBigger, faBiggerThen, faLess, faLessThen,
                     faBetween, faIn, faIsNull, faNotIsNull, faLike);
   TOnDataValidation = procedure of object;

   TDataObjectKind = ( okTable, okView, okCustomView);

implementation

end.
