unit REST.Request.Adapter.Registration;

interface

uses
  System.Classes,
  DesignIntf,
  REST.Request.Adapter,
  REST.Request.Adapter.Editor;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Andrea Magni', [TDataSetRESTRequestAdapter]);
  RegisterComponentEditor(TDataSetRESTRequestAdapter, TDataSetRESTRequestAdapterEditor);
end;

end.
