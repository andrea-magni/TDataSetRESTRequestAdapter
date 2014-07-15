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
    1: begin
         CurrentObj.UpdateRequestAndExecute;
         ShowMessage(
           Format(
             'Request %s updated and executed! Target param name: %s, Execution Status Code: %d %s in %d ms',
             [CurrentObj.Request.Name, CurrentObj.TargetParamName, CurrentObj.Request.Response.StatusCode
              , CurrentObj.Request.Response.StatusText, CurrentObj.Request.ExecutionPerformance.TotalExecutionTime]));
       end;

  end;
  Designer.Modified;
end;

function TDataSetRESTRequestAdapterEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := 'Update Request';
    1: Result := 'Update and Execute Request';
  end;
end;

function TDataSetRESTRequestAdapterEditor.GetVerbCount: Integer;
begin
  Result := 2;
end;

end.
