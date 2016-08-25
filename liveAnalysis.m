function varargout = liveAnalysis(varargin)

    % Edit the above text to modify the response to help liveAnalysis

    % Last Modified by GUIDE v2.5 10-Aug-2016 11:53:47

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
    handles.imageIndexAct = 0;
    handles.requireUpdate = true;
    guidata(hObject, handles);
    handles.timer = timer('ExecutionMode','fixedRate','Period', 0.3,'TimerFcn', {@GUIUpdate,hObject});
    start(handles.timer);
    handles.output = hObject;
    % Update handles structure
    guidata(hObject, handles);
    addpath('SetlistFeedback');
    assignin('base','liveAnalysisObject',hObject);

% UIWAIT makes liveAnalysis wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = liveAnalysis_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


% --- Executes on selection change in xVar.
function xVar_Callback(hObject, eventdata, handles)
    handles = updatePlot(handles);
    guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function xVar_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


% --- Executes on selection change in yVar.
function yVar_Callback(hObject, eventdata, handles)
    handles = updatePlot(handles);
    guidata(hObject,handles);
    
% --- Executes during object creation, after setting all properties.
function yVar_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

%Executes when needed to update GUI    
function GUIUpdate(timerObj,eventdata,hObject)
    handles = guidata(hObject);
    %Make sure liveAnalysisObject hasn't been deleted
    try
        h=evalin('base','liveAnalysisObject');
    catch
        assignin('base','liveAnalysisObject',hObject);
    end
    %See if shotData or the cut table has changed
    if handles.requireUpdate
        try
            %Grab the data from the base workspace and update the live plot
            %based on the fields selected
            shotIn = grabCutData;
            %Update image index list. Check to make sure the current index is
            %not out of bounds for the new string
            if handles.imageIndexAct <= length(shotIn)
                set(handles.imageIndexList,'String',[shotIn.Index]);
            else
                handles.imageIndexAct = length(shotIn);
                set(handles.imageIndexList,'Value',handles.imageIndexAct);
                set(handles.imageIndexList,'String',[shotIn.Index]);
                updateImage(hObject,handles);
            end
            if isequal(shotIn,handles.shotData) ~= 1
                if isequal(fieldnames(shotIn),fieldnames(handles.shotData)) ~= 1
                    handles.variables = fieldnames(shotIn);
                    set(handles.yVar,'String',handles.variables);
                    set(handles.xVar,'String',handles.variables);
                end
                handles.shotData = shotIn;  
            end
            handles = updatePlot(handles);
        end
        try
            if get(handles.mostRecentImage,'Value')
                %check to see if there are any new shots in shotData and update
                %displayed image if necessary
                newMaxIndexAct = length([shotIn.Index]);
                if newMaxIndexAct > handles.imageIndexAct
                    handles.imageIndexAct = newMaxIndexAct;
                    handles=updateImage(hObject,handles);
                end
            end
        end
        handles.requireUpdate = false;
    end
    %check if figure closed and if so delete handles.popfig & popfigAxes and set popout
    %button text back
    if isfield(handles,'popfig')
        if ishandle(handles.popfig) == 0
            set(handles.popoutButton,'String','Popout figure');
            handles = rmfield(handles,'popfig');
            handles = rmfield(handles,'popfigAxes');
        end
    end
    guidata(hObject,handles)

%function to update the displayed shot image
function handles=updateImage(hObject,handles)
    %grab shot filename from index
    fullFilename = char(handles.shotData(handles.imageIndexAct).filePath);
    %check shot fit type and get appropriate processed image
    if strcmp(handles.shotData(handles.imageIndexAct).fitType,'absGaussFit')
        dummyFit = absGaussFit;
    elseif strcmp(handles.shotData(handles.imageIndexAct).fitType,'absDipole')
        dummyFit = absDipole;
    end
    dummyFit.loadFromFile(fullFilename);
    if strcmp(handles.shotData(handles.imageIndexAct).fitType,'absDipole') | strcmp(handles.shotData(handles.imageIndexAct).fitType,'absGaussFit')
        handles.processedImage = dummyFit.getCutImage;
        axes(handles.imageViewer);
        %See if we want to colourise our image
        if get(handles.colourise,'Value')==1
            %If so plot using default colour palette
            handles.procImageViewer = imagesc(handles.processedImage,'Parent',handles.imageViewer, [0,max(max(handles.processedImage))]);
            set(handles.imageViewer,'xtick',[]);
            set(handles.imageViewer,'ytick',[]);
            colorbar(handles.imageViewer);
            colormap(handles.imageViewer,'jet');
            axis(handles.imageViewer,'image');
        else
            %Otherwise plot using greyscale paletter
            handles.procImageViewer = imshow(-handles.processedImage,'InitialMagnification','fit','DisplayRange',[min(min(-handles.processedImage)),max(max(-handles.processedImage))],'Parent',handles.imageViewer);
            colormap(handles.imageViewer,'gray');
        end
    end
    set(handles.imageIndexList,'Value',handles.imageIndexAct);
    guidata(hObject,handles);

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
    if strcmp(handles.shotData(refitIndexNum).fitType,'absGaussFit')|strcmp(handles.shotData(refitIndexNum).fitType,'absDipole')
        fitter(refitIndexNum);
    end


%Makes a popout figure from the plot currently being viewed for
%manipulation
function popoutButton_Callback(hObject, eventdata, handles)
    %Check if there is already a popout figure
    if isfield(handles,'popfig')
        %If so add new data to current popout figure
        axes(handles.popfigAxes);
        hold all
        plot([handles.shotData.(handles.xField)],[handles.shotData.(handles.yField)],'.');
        hold off
    else
        %If not plot a new figure
        handles.popfig = figure;
        handles.popfigAxes = axes;
        plot([handles.shotData.(handles.xField)],[handles.shotData.(handles.yField)],'.');
        xlabel(handles.xField,'Interpreter','none');
        ylabel(handles.yField,'Interpreter','none');
        set(handles.popoutButton,'String','Add to pop fig');
    end
    guidata(hObject,handles);


%Allows user to load data from file
function loadFromFile_Callback(hObject, eventdata, handles)
    %Popout listbox to choose fit types
    fitList = {'absGaussFit','absDipole','timeTaggerODMeasurement'};
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


%Saves cutTable and shotData to file for later recollection
function saveSessButton_Callback(hObject, eventdata, handles)
    [filename,pathname] = uiputfile;
    totfilename = strcat(pathname,filename);
    cutTable = evalin('base','cutTable');
    shotData = evalin('base','shotData');
    save(totfilename,'cutTable','shotData');


% --- Executes on selection change in imageIndexList.
function imageIndexList_Callback(hObject, eventdata, handles)
    %turn off most recent image tracking
    set(handles.mostRecentImage,'Value',0);
    %get index of image from index list and display image
    handles.imageIndexAct = get(handles.imageIndexList,'Value');
    guidata(hObject,handles);
    updateImage(hObject,handles);
    


% --- Executes during object creation, after setting all properties.
function imageIndexList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to imageIndexList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in mostRecentImage.
function mostRecentImage_Callback(hObject, eventdata, handles)
% hObject    handle to mostRecentImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of mostRecentImage


%Allows you to select shot from the plot to display in the image viewer
function imagFromPlot_Callback(hObject, eventdata, handles)
    %turn off tracking most recent image
    set(handles.mostRecentImage,'Value',0);
    %grab data point to display image for and display image
    axes(handles.livePlot);
    handles.imageIndexAct = selectdata('SelectionMode','Closest');
    guidata(hObject,handles);
    updateImage(hObject,handles);


%Allows you to select a shot from the plot to mulligan
function mulliganButton_Callback(hObject, eventdata, handles)
    %grab data point to mulligan
    axes(handles.livePlot);
    mulliganIndex = selectdata('SelectionMode','Closest');
    mulliganIndexAct = handles.shotData(mulliganIndex).Index;
    %Send mulligan to setlist
    mulliganJSON = setlistMulligan(mulliganIndexAct);
    writeToSetlist(mulliganJSON)
    updateLiveAnalysis();


%Opens setlist control window
function setlistControl_Callback(hObject, eventdata, handles)
    setlistControl;


%Prints current image to the base workspace
function printImageToWorkspace_Callback(hObject, eventdata, handles)
    try
        assignin('base','imageFromLiveAnalysis',handles.processedImage);
    catch
        msgbox('No image to send to workspace');
    end
    
%Updates the plot in liveAnalysis    
function handles = updatePlot(handles)
    %Grab the x and y field names
    handles.xField = char(handles.variables(get(handles.xVar,'Value')));
    handles.yField = char(handles.variables(get(handles.yVar,'Value')));
    %Plot the data with the given x and y fields
    handles.currentPlot = plot(handles.livePlot,[handles.shotData.(handles.xField)],[handles.shotData.(handles.yField)],'.');
    %Label the graph using the x and y field names
    xlabel(handles.livePlot,handles.xField,'Interpreter','none');
    ylabel(handles.livePlot,handles.yField,'Interpreter','none');


%Runs when colourise image checkbox is changed
function colourise_Callback(hObject, eventdata, handles)
    %Update image to reflect new colour palette choice
    handles = updateImage(hObject,handles);
    guidata(hObject,handles);
