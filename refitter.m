function varargout = refitter(varargin)
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

    % Last Modified by GUIDE v2.5 17-May-2016 15:32:34

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
    handles.output = hObject;
    handles.roiPoints = [1,1,1080,1080];
    guidata(hObject, handles);
    if length(varargin) == 1
        handles.indexNum = varargin{1};
        loadFile(hObject,handles);
    end

% --- Outputs from this function are returned to the command line.
function varargout = fitter_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;


% --- Executes on button press in LoadIndex.
function LoadIndex_Callback(hObject, eventdata, handles)
    %load the base workspace variable structure
    shotData = evalin('base','shotData');
    %get index to load
    handles.indexNum = listdlg('PromptString','Choose index to re-fit','ListString',strsplit(int2str([shotData.Index])),'SelectionMode','single');
    loadFile(hObject,handles);
    
% --- Executes on selection change in centreSelection.
function centreSelection_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function centreSelection_CreateFcn(hObject, eventdata, handles)
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over LoadIndex.
function LoadIndex_ButtonDownFcn(hObject, eventdata, handles)


% --- Executes on selection change in fitType.
function fitType_Callback(hObject, eventdata, handles)

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
    %determine what fit type we are doing
    fitType = get(handles.fitType,'Value');
    switch fitType
        %gaussian fit case
        case 1
            %create fit function and load the image to it
            fit = absGaussFit;
            fit.setProcessedImage(handles.processedImage);
            %determine if we want to manually specify centre coordinates
            manCords = get(handles.centreSelection,'Value');
            %either manually set centre coordinates or find them automagically
            switch manCords
                case 1
                    fit.findCentreCoordinates
                case 2
                    fit.setCentreCoordinates(round(handles.centreX_pix),round(handles.centreY_pix));
            end
            %grab the centre coordinates and save them to handles
            dummyCentre = fit.getCentreCoordinates;
            handles.centreX_pix = dummyCentre.centreX_pix;
            handles.centreY_pix = dummyCentre.centreY_pix;
            %do the fits and plot the results to their respective axes
            fit.runFits();
            axes(handles.xFitPlot)
            fit.plotX
            axes(handles.yFitPlot)
            fit.plotY
            %save the fitting variables to handles
            handles.fitVars = fit.getFitVars();
            %save handles information
            guidata(hObject,handles);
            %rescale the centre for the rescaled image
            markerCentreX = handles.centreX_pix/handles.scaleX;
            markerCentreY = handles.centreY_pix/handles.scaleY;
            %redraw the marker with new centre point
            repaintMarker(hObject,handles,markerCentreX,markerCentreY);
end

% --- Executes on mouse motion over figure - except title and menu.
function figure1_WindowButtonMotionFcn(hObject, eventdata, handles)

% --- Executes on button press in setMiddle.
function setMiddle_Callback(hObject, eventdata, handles)
    %set the axes to the cloud image
    axes(handles.procImage);
    %get the location of the centre point mouse click
    [markerCentreY,markerCentreX] = ginput(1);
    handles.centreX_pix = markerCentreX*handles.scaleX;
    handles.centreY_pix = markerCentreY*handles.scaleY;
    %repaint the marker to represent the new set point
    repaintMarker(hObject,handles,markerCentreX,markerCentreY)

%Function to redraw the cloud centre marker
function repaintMarker(hObject,handles,markerCentreX,markerCentreY)
    %make sure we are drawing on the image axes
    axes(handles.procImage);
    %delete any previous markers
    if isfield(handles,'marker') ~= 0
        delete(handles.marker);
    end
    hold on;
    %write the new marker
    handles.marker = plot(markerCentreY,markerCentreX,'r+','MarkerSize',30);
    guidata(hObject,handles);
    hold off;


% --- Executes on button press in saveVals.
function saveVals_Callback(hObject, eventdata, handles)
    shotData = evalin('base','shotData');
    handles.centreX_pix;
    shotData(handles.indexNum).centreX_pix = handles.centreX_pix;
    shotData(handles.indexNum).centreY_pix = handles.centreY_pix;
    fitFieldNames = fieldnames(handles.fitVars);
    for i=1:length(fitFieldNames)
        shotData(handles.indexNum).(char(fitFieldNames(i))) = handles.fitVars.(char(fitFieldNames(i)));
    end
    assignin('base','shotData',shotData);
    
%function to load shot for refitting    
function loadFile(hObject,handles)
    %import shotData to grab filename
    shotData = evalin('base','shotData');
    set(handles.indexDisp,'String',int2str(shotData(handles.indexNum).Index));
    fullFilename = char(shotData(handles.indexNum).filePath);
    set(handles.filepathDisp,'String',fullFilename);
    %grab pictures from file and get processed image
    %(log(absorption-background)/(probe-background))
    absorption = double(h5read(fullFilename,'/Images/Absorption'));
    probe = double(h5read(fullFilename,'/Images/Probe'));
    background = double(h5read(fullFilename,'/Images/Background'));
    handles.processedImage = real(log((absorption-background)./(probe-background)));
    %plot the processed image to the procImage axes
    axes(handles.procImage);
    handles.procImageResize = imshow(imresize(handles.processedImage,[1080 1080]),'InitialMagnification','fit','DisplayRange',[min(min(handles.processedImage)),1]);
    %determine image scaling relative to axes1
    procImageSize = size(handles.processedImage);
    handles.scaleY = procImageSize(2)/1080;
    handles.scaleX = procImageSize(1)/1080;
    %save all handles information
    guidata(hObject,handles)


% --- Executes on button press in roiSetter.
function roiSetter_Callback(hObject, eventdata, handles)
    %get cropped image
    set(handles.roiSetter,'Enable','off')
    axes(handles.procImage);
    [~,handles.roiPoints] = imcrop();
    if isfield(handles,'roiRectangle') ~= 0
        delete(handles.roiRectangle);
    end
    handles.roiRectangle = rectangle('Position',handles.roiPoints);
    handles.roiPoints
    set(handles.roiSetter,'Enable','on')
    guidata(hObject,handles);
    