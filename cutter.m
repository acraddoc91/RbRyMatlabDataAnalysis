function varargout = cutter(varargin)
% CUTTER MATLAB code for cutter.fig
%      CUTTER, by itself, creates a new CUTTER or raises the existing
%      singleton*.
%
%      H = CUTTER returns the handle to a new CUTTER or the handle to
%      the existing singleton*.
%
%      CUTTER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CUTTER.M with the given input arguments.
%
%      CUTTER('Property','Value',...) creates a new CUTTER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before cutter_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to cutter_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help cutter

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
    set(handles.cutTable,'ColumnFormat',{transpose(handles.fieldList),'char','logical'});
    %check to see if a cutTable exists on the base workspace
    try
        currCutTable = evalin('base','cutTable');
    catch
        currCutTable = {};
    end
    %load current cuts to the table
    [numCuts,~] = size(currCutTable);
    if numCuts == 0
        set(handles.cutTable,'Data',{'','',false})
    else
        for i=1:numCuts
            currCutTable{i,3} = true;
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
    set(handles.cutTable,'Data',[currTableData;{'','',false}])

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
        dummyDoCut = cutTableData(i,3);
        if dummyDoCut{1}
            cutTableOut = [cutTableOut;cutTableData(i,1:2)];
        end
    end
    %replace base workspace cutTable
    assignin('base','cutTable',cutTableOut);


% --- Executes on button press in clearCuts.
function clearCuts_Callback(hObject, eventdata, handles)
    %clear cutting table and clear the base workspace cutTable
    set(handles.cutTable,'Data',{'','',false})
    assignin('base','cutTable',{});
