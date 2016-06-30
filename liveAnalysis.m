function varargout = liveAnalysis(varargin)
    % LIVEANALYSIS MATLAB code for liveAnalysis.fig
    %      LIVEANALYSIS, by itself, creates a new LIVEANALYSIS or raises the existing
    %      singleton*.
    %
    %      H = LIVEANALYSIS returns the handle to a new LIVEANALYSIS or the handle to
    %      the existing singleton*.
    %
    %      LIVEANALYSIS('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in LIVEANALYSIS.M with the given input arguments.
    %
    %      LIVEANALYSIS('Property','Value',...) creates a new LIVEANALYSIS or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before liveAnalysis_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to liveAnalysis_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help liveAnalysis

    % Last Modified by GUIDE v2.5 30-Jun-2016 13:44:36

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @liveAnalysis_OpeningFcn, ...
                       'gui_OutputFcn',  @liveAnalysis_OutputFcn, ...
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


% --- Executes just before liveAnalysis is made visible.
function liveAnalysis_OpeningFcn(hObject, eventdata, handles, varargin)
    % Choose default command line output for liveAnalysis
    handles.shotData = struct;
    handles.variables = {};
    handles.xField = '';
    handles.yField = '';
    guidata(hObject, handles);
    handles.timer = timer('ExecutionMode','fixedRate','Period', 0.1,'TimerFcn', {@GUIUpdate,hObject});
    start(handles.timer);
    handles.output = hObject;

    % Update handles structure
    guidata(hObject, handles);

% UIWAIT makes liveAnalysis wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = liveAnalysis_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


% --- Executes on selection change in xVar.
function xVar_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function xVar_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


% --- Executes on selection change in yVar.
function yVar_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function yVar_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

%Executes when needed to update GUI    
function GUIUpdate(timerObj,eventdata,hObject)
    handles = guidata(hObject);
    try
        %Grab the data from the base workspace and update the live plot
        %based on the fields selected
        shotIn = grabCutData;
        if isequal(shotIn,handles.shotData) ~= 1
            if isequal(fieldnames(shotIn),fieldnames(handles.shotData)) ~= 1
                handles.variables = fieldnames(shotIn);
                set(handles.yVar,'String',handles.variables);
                set(handles.xVar,'String',handles.variables);
            end
            handles.shotData = shotIn;  
        end
        handles.xField = char(handles.variables(get(handles.xVar,'Value')));
        handles.yField = char(handles.variables(get(handles.yVar,'Value')));
        handles.currentPlot = plot(handles.livePlot,[handles.shotData.(handles.xField)],[handles.shotData.(handles.yField)],'.');
        xlabel(handles.livePlot,handles.xField,'Interpreter','none');
        ylabel(handles.livePlot,handles.yField,'Interpreter','none');
        guidata(hObject,handles)
    end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
    % hObject    handle to figure1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    if strcmp(get(handles.timer, 'Running'), 'on')
        stop(handles.timer);
    end
    % Destroy timer
    delete(handles.timer)
    % Hint: delete(hObject) closes the figure
    delete(hObject);


%Allows user to refit point selected by cursor click
function refitButton_Callback(hObject, eventdata, handles)
    %Get number of point to refit and open up the refit gui to do fit
    axes(handles.livePlot);
    refitIndexNum = selectdata('SelectionMode','Closest');
    fitter(refitIndexNum);


%Makes a popout figure from the plot currently being viewed for
%manipulation
function popoutButton_Callback(hObject, eventdata, handles)
    popfig = figure;
    plot([handles.shotData.(handles.xField)],[handles.shotData.(handles.yField)],'.');
    xlabel(handles.xField,'Interpreter','none');
    ylabel(handles.yField,'Interpreter','none');


%Allows user to load data from file
function loadFromFile_Callback(hObject, eventdata, handles)
    %Popout listbox to choose fit types
    fitList = {'absGaussFit'};
    [fitIndex,fitChosen] = listdlg('PromptString','Select fit type','SelectionMode','single','ListString',fitList);
    %If fit has been chosen reload data file using selected fit type
    if(fitChosen)
        fitType = char(fitList(fitIndex));
        reloadDataFile(fitType);
    end



%Opens up data cutter GUI
function openCutter_Callback(hObject, eventdata, handles)
    cutter(fieldnames(handles.shotData))


%Start curve fitting session with current data
function fitButton_Callback(hObject, eventdata, handles)
    cftool([handles.shotData.(handles.xField)],[handles.shotData.(handles.yField)]);


% --- Executes on button press in saveSessButton.
function saveSessButton_Callback(hObject, eventdata, handles)
    [filename,pathname] = uiputfile;
    totfilename = strcat(pathname,filename);
    cutTable = evalin('base','cutTable');
    shotData = evalin('base','shotData');
    save(totfilename,'cutTable','shotData');
