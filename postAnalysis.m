function varargout = postAnalysis(varargin)
% POSTANALYSIS MATLAB code for postAnalysis.fig
%      POSTANALYSIS, by itself, creates a new POSTANALYSIS or raises the existing
%      singleton*.
%
%      H = POSTANALYSIS returns the handle to a new POSTANALYSIS or the handle to
%      the existing singleton*.
%
%      POSTANALYSIS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in POSTANALYSIS.M with the given input arguments.
%
%      POSTANALYSIS('Property','Value',...) creates a new POSTANALYSIS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before postAnalysis_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to postAnalysis_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help postAnalysis

% Last Modified by GUIDE v2.5 12-May-2016 18:25:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @postAnalysis_OpeningFcn, ...
                   'gui_OutputFcn',  @postAnalysis_OutputFcn, ...
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


% --- Executes just before postAnalysis is made visible.
function postAnalysis_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to postAnalysis (see VARARGIN)

% Choose default command line output for postAnalysis
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes postAnalysis wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = postAnalysis_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
[filenames,path,~] = uigetfile('.h5','Multiselect','on');
varStruct = struct;
for i=1:length(filenames)
    filename = sprintf('%s%s',char(path),char(filenames(i)));
    [outVarNames,outVarVals,~]=HDF5GaussFit(filename,3.69,'um');
    for j=1:length(outVarVals)
        varStruct(i).(char(outVarNames(j))) = outVarVals(j);
    end
    dumExp = h5info(filename,'/Experimental Variables');
    numExpVars = length(dumExp.Datasets);
    for j = 1:numExpVars
        expVarName = char(dumExp.Datasets(j).Name);
        expVarValue = h5read(filename,sprintf('/Experimental Variables/%s',expVarName));
        varStruct(i).(expVarName) = expVarValue;
    end
end
structFieldNames = fieldnames(varStruct);
assignin('base','varStruct',varStruct);
set(handles.popupmenu2,'String',structFieldNames);
set(handles.popupmenu3,'String',structFieldNames);
    
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in popupmenu2.
function popupmenu2_Callback(hObject, eventdata, handles)
refreshPlot(handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2


% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu3.
function popupmenu3_Callback(hObject, eventdata, handles)
refreshPlot(handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu3


% --- Executes during object creation, after setting all properties.
function popupmenu3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function refreshPlot(handles)
varStruct = evalin('base','varStruct');
axes(handles.axes1);
variables = get(handles.popupmenu2,'String');
xField = char(variables(get(handles.popupmenu2,'Value')));
yField = char(variables(get(handles.popupmenu3,'Value')));
plot([varStruct.(xField)],[varStruct.(yField)],'.');
