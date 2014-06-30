unit MainFormUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  IPPeerClient, System.Rtti, Data.Bind.EngExt, Fmx.Bind.DBEngExt, Fmx.Bind.Grid,
  System.Bindings.Outputs, Fmx.Bind.Editors, Data.Bind.Components,
  Data.Bind.Grid, Data.Bind.DBScope, FMX.Layouts, FMX.Grid, REST.Client,
  Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client, REST.Response.Adapter,
  Data.Bind.ObjectScope, FMX.Memo, REST.Request.Adapter;

type
  TMainForm = class(TForm)
    RESTResponse1: TRESTResponse;
    RESTResponseDataSetAdapter1: TRESTResponseDataSetAdapter;
    FDMemTable1: TFDMemTable;
    RESTRequest1: TRESTRequest;
    RESTClient1: TRESTClient;
    Grid1: TGrid;
    BindSourceDB1: TBindSourceDB;
    BindingsList1: TBindingsList;
    LinkGridToDataSourceBindSourceDB1: TLinkGridToDataSource;
    Memo1: TMemo;
    RESTRequest2: TRESTRequest;
    btnUpdateRequest: TButton;
    DataSetRESTRequestAdapter1: TDataSetRESTRequestAdapter;
    procedure FormCreate(Sender: TObject);
    procedure btnUpdateRequestClick(Sender: TObject);
  private
    { Private declarations }
    function FilterHandler(const ADataSet: TDataSet): Boolean;
  public
    { Public declarations }

  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
  System.JSON, StrUtils;


procedure TMainForm.btnUpdateRequestClick(Sender: TObject);
begin
  DataSetRESTRequestAdapter1.UpdateRequest;
  Memo1.Text := RESTRequest2.Params.ParameterByName(DataSetRESTRequestAdapter1.TargetParamName).Value;
end;

function TMainForm.FilterHandler(const ADataSet: TDataSet): Boolean;
begin
  Result := ADataSet.FieldByName('name').AsString.StartsWith('A', True);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RESTRequest1.Execute;
end;

end.
