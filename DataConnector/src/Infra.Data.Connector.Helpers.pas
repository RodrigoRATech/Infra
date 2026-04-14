unit Infra.Data.Connector.Helpers;

interface

uses System.SysUtils,
     System.StrUtils,

     Infra.Data.Core.Types,
     Infra.Data.Connector.Types;

type
   TGenereteKindHelper = record helper for TGenereteKind
      function ToString:String;
      procedure FromString( aValue:String);
   end;

implementation

{ TGenereteKindHelper }

procedure TGenereteKindHelper.FromString(aValue: String);
begin
   case AnsiIndexStr( AnsiLowerCase( aValue), [ AnsiLowerCase( 'All'),
                                                AnsiLowerCase( 'Maked'),
                                                AnsiLowerCase( 'UnMarked')]) of
      0:Self := gkAll;
      1:Self := gkMarked;
      2:Self := gkUnMarked;
   end;
end;

function TGenereteKindHelper.ToString: String;
begin
   case Self of
      gkAll     :Result := 'All';
      gkMarked  :Result := 'Marked';
      gkUnMarked:Result := 'UnMarked';
   end;
end;

end.
