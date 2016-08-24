function varargout = cutter(varargin)

% Last Modified by GUIDE v2.5 28-Jun-2016 18:51:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @cutter_OpeningFcn, ...
                   'gui_OutputFcn',  @cutter_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before cutter is made visible.
function cutter_OpeningFcn(hObject, eventdata, handles, varargin)
    %Cutter takes a fieldlist as the argument in, so when cutter is
    %openened go ahead and grab the fieldlist and stick it into handles and
    %set the selectable fields of the cutting table to be the field list
    dummyFieldList = varargin(1);
    handles.fieldList = dummyFieldList{1};
    set(handles.cutTable,'ColumnFormat',{transpose(handles.fieldList),{'>','>=','<','<=','==','~='},'char','logical'});
    %check to see if a cutTable exists on the base workspace
    try
        currCutTable = evalin('base','cutTable');
    catch
        currCutTable = {};
    end
    %load current cuts to the table
    [numCuts,~] = size(currCutTable);
    if numCuts == 0
        set(handles.cutTable,'Data',{'','','',false})
    else
        for i=1:numCuts
            currCutTable{i,4} = true;
        end
        set(handles.cutTable,'Data',currCutTable);
    end
    % Choose default command line output for cutter
    handles.output = hObject;
    % Update handles structure
    guidata(hObject, handles);

% UIWAIT makes cutter wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = cutter_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;


% --- Executes on button press in addCut.
function addCut_Callback(hObject, eventdata, handles)
    %when add cut is pressed add an extra line to the cutting table
    currTableData=get(handles.cutTable,'Data');
    set(handles.cutTable,'Data',[currTableData;{'','','',false}])

% --- Executes during object creation, after setting all properties.
function cutTable_CreateFcn(hObject, eventdata, handles)


% --- Executes during object deletion, before destroying properties.
function cutTable_DeleteFcn(hObject, eventdata, handles)

function cutTable_CellSelectionCallback(hObject,eventdata,handles)


% --- Executes on button press in doCuts.
function doCuts_Callback(hObject, eventdata, handles)
    %Grab the cuting table
    cutTableData = get(handles.cutTable,'Data');
    [numCuts,~]=size(cutTableData);
    cutTableOut = {};
    %strip out any cuts which aren't supposed to be made
    for i=1:numCuts
        dummyDoCut = cutTableData(i,4);
        if dummyDoCut{1}
            cutTableOut = [cutTableOut;cutTableData(i,1:3)];
        end
    end
    %replace base workspace cutTable
    assignin('base','cutTable',cutTableOut);
    updateLiveAnalysis();


% --- Executes on button press in clearCuts.
function clearCuts_Callback(hObject, eventdata, handles)
    %clear cutting table and clear the base workspace cutTable
    set(handles.cutTable,'Data',{'','','',false})
    assignin('base','cutTable',{});
