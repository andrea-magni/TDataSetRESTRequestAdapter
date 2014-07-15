unit REST.Request.Adapter;

interface

uses
  System.JSON, System.Rtti, System.Classes,
  SysUtils,
  Data.DB,
  Data.Bind.Components,
  REST.Client,
  REST.Exception;

type
  TDataSetAdapterRecordsMode = (AllRecords, CurrentRecord, AcceptFilter);
  TDataSetAdapterFilterRecordEvent = function(const ADataSet: TDataSet): Boolean of object;

  TDataSetRESTRequestAdapter=class(TComponent)
  private
    FAutoCreateTargetParam: Boolean;
    FDataSet: TDataSet;
    FOnFilterRecord: TDataSetAdapterFilterRecordEvent;
    FRequest: TCustomRESTRequest;
    FRecordsMode: TDataSetAdapterRecordsMode;
    FSingleObjectAsArray: Boolean;
    FTargetParamName: string;
    function GetJSONData: TJSONValue;
    procedure SetDataSet(const Value: TDataSet);
    procedure SetRequest(const Value: TCustomRESTRequest);
  protected
    function GetJSONDataAcceptFilter: TJSONValue; virtual;
    function GetJSONDataAllRecords: TJSONValue; virtual;
    function GetJSONDataCurrentRecord: TJSONValue; virtual;
    function GetTargetParam: TRESTRequestParameter; virtual;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    // properties
    property JSONData: TJSONValue read GetJSONData;
  public
    constructor Create(AOwner: TComponent); override;
    procedure UpdateRequest; virtual;
    procedure UpdateRequestAndExecute;
  published
    property AutoCreateTargetParam: Boolean read FAutoCreateTargetParam write FAutoCreateTargetParam default true;
    property DataSet: TDataSet read FDataSet write SetDataSet;
    property RecordsMode: TDataSetAdapterRecordsMode read FRecordsMode write FRecordsMode;
    property Request: TCustomRESTRequest read FRequest write SetRequest;
    property SingleObjectAsArray: Boolean read FSingleObjectAsArray write FSingleObjectAsArray default false;
    property TargetParamName: string read FTargetParamName write FTargetParamName;

    // events
    property OnFilterRecord: TDataSetAdapterFilterRecordEvent read FOnFilterRecord write FOnFilterRecord;
  end;

  function RecordToJSONObject(const ADataSet: TDataSet; const ARootPath: string = ''): TJSONObject;
  function DataSetToJSONArray(const ADataSet: TDataSet; const AAcceptFunc: TFunc<Boolean> = nil): TJSONArray;

implementation

uses
  System.Generics.Collections,
  REST.Types;

type
  TJSONFieldType = (NestedObject, NestedArray, SimpleValue);

function GetJSONFieldType(const AField: TField): TJSONFieldType;
begin
  Result := SimpleValue;
  if AField.Value = '(object)' then
    Result := NestedObject
  else if AField.Value = '(array)' then
    Result := NestedArray;
end;

function RecordToJSONObject(const ADataSet: TDataSet; const ARootPath: string = ''): TJSONObject;
var
  LField: TField;
  LPairName: string;
begin
  if not Assigned(ADataSet) then
    raise Exception.Create('DataSet not assigned');
  if not ADataSet.Active then
    raise Exception.Create('DataSet is not active');
  if ADataSet.IsEmpty then
    raise Exception.Create('DataSet is empty');


  Result := TJSONObject.Create;

  for LField in ADataSet.Fields do
  begin
    if (ARootPath = '') or (LField.FieldName.StartsWith(ARootPath + '.')) then
    begin
      LPairName := LField.FieldName;
      if ARootPath <> '' then
        LPairName := LPairName.Substring(Length(ARootPath) + 1);

      if LPairName.Contains('.') then
        Continue;

      case GetJSONFieldType(LField) of
        NestedObject: Result.AddPair(LPairName, RecordToJSONObject(ADataSet, LField.FieldName));
         SimpleValue: Result.AddPair(LPairName, LField.Value); { TODO -oAndrea : Handle field types }
         NestedArray: raise ENotImplemented.Create('Nested array values not yet implemented');
      end;
    end;
  end;
end;


function DataSetToJSONArray(const ADataSet: TDataSet; const AAcceptFunc: TFunc<Boolean> = nil): TJSONArray;
var
  LBookmark: TBookmark;
begin
  Assert(Assigned(ADataSet));

  Result := TJSONArray.Create;

  ADataSet.DisableControls;
  try
    LBookmark := ADataSet.Bookmark;
    try
      ADataSet.First;
      while not ADataSet.Eof do
      try
        if (not Assigned(AAcceptFunc)) or (AAcceptFunc()) then
          Result.AddElement(RecordToJSONObject(ADataSet));
      finally
        ADataSet.Next;
      end;
    finally
      ADataSet.GotoBookmark(LBookmark);
    end;
  finally
    ADataSet.EnableControls;
  end;
end;


{ TRESTDataSetRequestAdapter }

function TDataSetRESTRequestAdapter.GetTargetParam: TRESTRequestParameter;
begin
  Assert(Assigned(Request));

  Result := Request.Params.ParameterByName(TargetParamName);
  if not Assigned(Result) then
  begin
    if not AutoCreateTargetParam then
      raise Exception.CreateFmt('Target parameter not found: %s', [TargetParamName]);

    // create param
    Result := Request.Params.AddItem;
    try
      Result.Kind := TRESTRequestParameterKind.pkREQUESTBODY;
      Result.name := TargetParamName;
      Result.ContentType := TRESTContentType.ctAPPLICATION_JSON;
    except
      Result.Free;
      raise;
    end;
  end;
end;

constructor TDataSetRESTRequestAdapter.Create(AOwner: TComponent);
begin
  inherited;
  FAutoCreateTargetParam := True;
  FRecordsMode := TDataSetAdapterRecordsMode.CurrentRecord;
  FSingleObjectAsArray := False;
  FTargetParamName := 'body';
end;

function TDataSetRESTRequestAdapter.GetJSONData: TJSONValue;
begin
  Result := nil;
  case RecordsMode of
       AllRecords: Result := GetJSONDataAllRecords;
    CurrentRecord: Result := GetJSONDataCurrentRecord;
     AcceptFilter: Result := GetJSONDataAcceptFilter;
  end;
end;

function TDataSetRESTRequestAdapter.GetJSONDataAcceptFilter: TJSONValue;
begin
  Result := DataSetToJSONArray(DataSet,
    function:Boolean
    begin
      Result := True;
      if Assigned(OnFilterRecord) then
        Result := OnFilterRecord(DataSet);
    end);
end;

function TDataSetRESTRequestAdapter.GetJSONDataAllRecords: TJSONValue;
begin
  Result := DataSetToJSONArray(DataSet);
end;

function TDataSetRESTRequestAdapter.GetJSONDataCurrentRecord: TJSONValue;
var
  LObj: TJSONObject;
begin
  LObj := RecordToJSONObject(DataSet);
  if SingleObjectAsArray then
  begin
    Result := TJSONArray.Create;
    TJSONArray(Result).AddElement(LObj);
  end
  else
    Result := LObj;
end;

procedure TDataSetRESTRequestAdapter.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;

  if (Operation = opRemove) then
  begin
    if (AComponent = FDataSet) then
      FDataSet := nil;
    if (AComponent = FRequest) then
      FRequest := nil;
  end;
end;

procedure TDataSetRESTRequestAdapter.SetDataSet(const Value: TDataSet);
begin
  FDataSet := Value;
end;

procedure TDataSetRESTRequestAdapter.SetRequest(
  const Value: TCustomRESTRequest);
begin
  FRequest := Value;
end;

procedure TDataSetRESTRequestAdapter.UpdateRequest;
var
  LParam: TRESTRequestParameter;
  LJSONValue: TJSONValue;
begin
  Assert(Assigned(Request));

  LParam := GetTargetParam;
  Assert(Assigned(LParam));

  LJSONValue := JSONData;
  if Assigned(LJSONValue) then
    LParam.Value := JSONData.ToString
  else
    LParam.Value := '';
end;


procedure TDataSetRESTRequestAdapter.UpdateRequestAndExecute;
begin
  UpdateRequest;
  Request.Execute;
end;

end.
