function varargout = fitter(varargin)
% FITTER MATLAB code for fitter.fig
%      FITTER, by itself, creates a new FITTER or raises the existing
%      singleton*.
%
%      H = FITTER returns the handle to a new FITTER or the handle to
%      the existing singleton*.
%
%      FITTER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FITTER.M with the given input arguments.
%
%      FITTER('Property','Value',...) creates a new FITTER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before fitter_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to fitter_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help fitter

% Last Modified by GUIDE v2.5 13-May-2016 18:14:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @fitter_OpeningFcn, ...
                   'gui_OutputFcn',  @fitter_OutputFcn, ...
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


% --- Executes just before fitter is made visible.
function fitter_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to fitter (see VARARGIN)

% Choose default command line output for fitter
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes fitter wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = fitter_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in loadFile.
function loadFile_Callback(hObject, eventdata, handles)
[filename,path,~] = uigetfile('.h5');
fullFilename = sprintf('%s%s',char(path),char(filename));
absorption = double(h5read(fullFilename,'/Images/Absorption'));
probe = double(h5read(fullFilename,'/Images/Probe'));
background = double(h5read(fullFilename,'/Images/Background'));
handles.processedImage = real(log((absorption-background)./(probe-background)));
axes(handles.axes1);
handles.procImageResize = imshow(imresize(handles.processedImage,[1080 1080]),'InitialMagnification','fit','DisplayRange',[min(min(handles.processedImage)),1]);
guidata(hObject,handles)
% hObject    handle to loadFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in centreSelection.
function centreSelection_Callback(hObject, eventdata, handles)
% hObject    handle to centreSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns centreSelection contents as cell array
%        contents{get(hObject,'Value')} returns selected item from centreSelection


% --- Executes during object creation, after setting all properties.
function centreSelection_CreateFcn(hObject, eventdata, handles)
% hObject    handle to centreSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on mouse press over axes background.q
function axes1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over loadFile.
function loadFile_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to loadFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on selection change in fitType.
function fitType_Callback(hObject, eventdata, handles)
% hObject    handle to fitType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns fitType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from fitType


% --- Executes during object creation, after setting all properties.
function fitType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fitType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in runFit.
function runFit_Callback(hObject, eventdata, handles)
fitType = get(handles.fitType,'Value');
switch fitType
    case 1
        fit = absGaussFit;
        fit.setProcessedImage(handles.processedImage);
        manCords = get(handles.centreSelection,'Value');
        procImageSize = size(handles.processedImage);
        scaleY = procImageSize(2)/1080;
        scaleX = procImageSize(1)/1080;
        switch manCords
            case 1
                fit.findCentreCoordinates
                dummyCentre = fit.getCentreCoordinates;
                handles.centreX = dummyCentre.centreX_pix/scaleX;
                handles.centreY = dummyCentre.centreY_pix/scaleY;
                repaintMarker(hObject,handles);
            case 2
                fit.setCentreCoordinates(round(handles.centreX*scaleX),round(handles.centreY*scaleY));
        end
        fit.runXFit;
        fit.runYFit;
        axes(handles.xFitPlot)
        fit.plotX
        axes(handles.yFitPlot)
        fit.plotY
end
% hObject    handle to runFit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on mouse motion over figure - except title and menu.
function figure1_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in setMiddle.
function setMiddle_Callback(hObject, eventdata, handles)
axes(handles.axes1);
[handles.centreY,handles.centreX] = ginput(1);
repaintMarker(hObject,handles)
% hObject    handle to setMiddle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function repaintMarker(hObject,handles)
axes(handles.axes1);
if isfield(handles,'marker') ~= 0
    delete(handles.marker);
end
hold on;
handles.marker = plot(handles.centreY,handles.centreX,'r+','MarkerSize',30);
guidata(hObject,handles);
hold off;