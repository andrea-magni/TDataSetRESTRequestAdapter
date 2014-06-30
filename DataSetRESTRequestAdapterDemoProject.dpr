program DataSetRESTRequestAdapterDemoProject;

uses
  FMX.Forms,
  MainFormUnit in 'MainFormUnit.pas' {MainForm},
  REST.Request.Adapter in 'REST.Request.Adapter.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
