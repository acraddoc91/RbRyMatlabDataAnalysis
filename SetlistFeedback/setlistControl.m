function varargout = setlistControl(varargin)
% SETLISTCONTROL MATLAB code for setlistControl.fig
%      SETLISTCONTROL, by itself, creates a new SETLISTCONTROL or raises the existing
%      singleton*.
%
%      H = SETLISTCONTROL returns the handle to a new SETLISTCONTROL or the handle to
%      the existing singleton*.
%
%      SETLISTCONTROL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SETLISTCONTROL.M with the given input arguments.
%
%      SETLISTCONTROL('Property','Value',...) creates a new SETLISTCONTROL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before setlistControl_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to setlistControl_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help setlistControl

% Last Modified by GUIDE v2.5 13-Jul-2016 12:15:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @setlistControl_OpeningFcn, ...
                   'gui_OutputFcn',  @setlistControl_OutputFcn, ...
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


% --- Executes just before setlistControl is made visible.
function setlistControl_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to setlistControl (see VARARGIN)

    % Choose default command line output for setlistControl
    handles.output = hObject;
    set(handles.varTable,'Data',{'','','',false,false})
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes setlistControl wait for user response (see UIRESUME)
    % uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = setlistControl_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in addVar.
function addVar_Callback(hObject, eventdata, handles)
    currVarTable=get(handles.varTable,'Data');
    set(handles.varTable,'Data',[currVarTable;{'','','',false,false}])


% --- Executes on button press in instantVars.
function instantVars_Callback(hObject, eventdata, handles)
    currVarTable = get(handles.varTable,'Data');
    [numVars,~] = size(currVarTable);
    for i = 1:numVars
        setlistVarArray(i) = setlistVariable(currVarTable(i,1),str2double(currVarTable(i,2)),currVarTable(i,3),currVarTable(i,4),currVarTable(i,5));
    end
    writeToSetlist(setlistInstantVariables(setlistVarArray))


% --- Executes on button press in mulliganButton.
function mulliganButton_Callback(hObject, eventdata, handles)
    mulliganIndex = str2num(get(handles.mulliganIndex,'String'));
    if length(mulliganIndex) == 0
        set(handles.mulliganIndex,'String','Enter index');
    else
        mulliganArray = setlistMulligan(round(mulliganIndex));
    end
    writeToSetlist(mulliganArray)
    updateLiveAnalysis;


function mulliganIndex_Callback(hObject, eventdata, handles)
% hObject    handle to mulliganIndex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of mulliganIndex as text
%        str2double(get(hObject,'String')) returns contents of mulliganIndex as a double


% --- Executes during object creation, after setting all properties.
function mulliganIndex_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mulliganIndex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
