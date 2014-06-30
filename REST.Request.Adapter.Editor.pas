unit REST.Request.Adapter.Editor;

interface

uses
  System.Classes
  , System.SysUtils

  , DesignEditors

  , REST.Request.Adapter;

type
  TDataSetRESTRequestAdapterEditor = class(TComponentEditor)
  private
    function CurrentObj: TDataSetRESTRequestAdapter;
  protected
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

implementation

uses
  VCL.Dialogs;

{ TDataSetRESTRequestAdapterEditor }

function TDataSetRESTRequestAdapterEditor.CurrentObj: TDataSetRESTRequestAdapter;
begin
  Result := Component as TDataSetRESTRequestAdapter;
end;

procedure TDataSetRESTRequestAdapterEditor.ExecuteVerb(Index: Integer);
begin
  inherited;
  case Index of
    0: begin
         CurrentObj.UpdateRequest;
         ShowMessage(Format('Request %s updated! Target param name: %s', [CurrentObj.Request.Name, CurrentObj.TargetParamName]));
       end;
  end;
  Designer.Modified;
end;

function TDataSetRESTRequestAdapterEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := 'Update Request';
  end;
end;

function TDataSetRESTRequestAdapterEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

end.
