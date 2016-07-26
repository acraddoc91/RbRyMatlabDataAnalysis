function varargout = fitter(varargin)

    % Last Modified by GUIDE v2.5 11-Jul-2016 12:56:12

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
    handles.rotDegreeVal = 0;
    handles.angleUpdate = false;
    %check to see if fitter was called with an index passed to it
    if length(varargin) == 1
        handles.indexNum = varargin{1};
        %load file and do initial fit
        handles = loadFile(hObject,handles);
        handles = runFit_Callback(hObject, eventdata, handles);
        guidata(hObject,handles);
    end
    handles.timer = timer('ExecutionMode','fixedRate','Period', 0.3,'TimerFcn', {@GUIUpdate,hObject});
    start(handles.timer);
    guidata(hObject, handles);

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
function handles = runFit_Callback(hObject, eventdata, handles)
    %determine what fit type we are doing
    fitType = get(handles.fitType,'Value');
    switch fitType
        %gaussian fit case
        case 1
            %create fit function and load the image to it
            fit = absGaussFit;
            fit.setProcessedImage(handles.processedImage);
            try
                fit.setMagnification(handles.currShotData.Magnification);
            catch
            end
            fit.setRotationAngle(handles.rotDegreeVal);
            %determine if we want to manually specify centre coordinates
            manCords = get(handles.centreSelection,'Value');
            %Set ROI
            fit.setRoi(handles.roiRect_pix);
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
            try
                fit.calculateAtomNumber(handles.currShotData.ImagingDetuning,handles.currShotData.ImagingIntensity);
            catch
            end
            handles.fitVars = fit.getFitVars();
            %Set Atom number
            set(handles.atomNum,'String',handles.fitVars.N_atoms);
            %Set fit type
            handles.fitTypeString = 'absGaussFit';
            %save handles information
            guidata(hObject,handles);
            %rescale the centre for the rescaled image
            markerCentreX = handles.centreX_pix;
            markerCentreY = handles.centreY_pix;
            %redraw the marker with new centre point
            handles = repaintMarker(hObject,handles,markerCentreX,markerCentreY);
            
            %dipole fit case
        case 2
            %create fit function and load the image to it
            fit = absDipole;
            fit.setProcessedImage(handles.processedImage);
            try
                fit.setMagnification(handles.currShotData.Magnification);
            catch
            end
            fit.setRotationAngle(handles.rotDegreeVal);
            %determine if we want to manually specify centre coordinates
            manCords = get(handles.centreSelection,'Value');
            %Set ROI
            fit.setRoi(handles.roiRect_pix);
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
            %Plot the data
            axes(handles.xFitPlot)
            fit.plotX
            axes(handles.yFitPlot)
            fit.plotY
            try
                fit.calculateAtomNumber(handles.currShotData.ImagingDetuning,handles.currShotData.ImagingIntensity);
            catch
            end
            handles.fitVars = fit.getFitVars();
            %Set Atom number
            set(handles.atomNum,'String',handles.fitVars.N_atoms);
            %Set fit type
            handles.fitTypeString = 'absDipole';
            %save handles information
            guidata(hObject,handles);
            %rescale the centre for the rescaled image
            markerCentreX = handles.centreX_pix;
            markerCentreY = handles.centreY_pix;
            %redraw the marker with new centre point
            handles = repaintMarker(hObject,handles,markerCentreX,markerCentreY);
    end
    guidata(hObject,handles);

% --- Executes on mouse motion over figure - except title and menu.
function figure1_WindowButtonMotionFcn(hObject, eventdata, handles)

% --- Executes on button press in setMiddle.
function setMiddle_Callback(hObject, eventdata, handles)
    %set the axes to the cloud image
    axes(handles.procImage);
    %get the location of the centre point mouse click
    [markerCentreX,markerCentreY] = ginput(1);
    handles.centreX_pix = markerCentreX;
    handles.centreY_pix = markerCentreY;
    %repaint the marker to represent the new set point
    repaintMarker(hObject,handles,markerCentreX,markerCentreY);

%Function to redraw the cloud centre marker
function handles = repaintMarker(hObject,handles,markerCentreX,markerCentreY)
    %make sure we are drawing on the image axes
    axes(handles.procImage);
    %delete any previous markers
    if isfield(handles,'marker') ~= 0
        delete(handles.marker);
    end
    hold on;
    %write the new marker
    handles.marker = plot(markerCentreX,markerCentreY,'r+','MarkerSize',30);
    hold off;
    guidata(hObject,handles);


%Save fitted data to shotData in the base workspace
function saveVals_Callback(hObject, eventdata, handles)
    %Pull in the shotData from the base workspace
    shotData = evalin('base','shotData');
    outGoingIndexNum = find([shotData.Index]==handles.indexNumAct);
    %Update shotData with new values
    shotData(outGoingIndexNum).centreX_pix = handles.centreX_pix;
    shotData(outGoingIndexNum).centreY_pix = handles.centreY_pix;
    fitFieldNames = fieldnames(handles.fitVars);
    for i=1:length(fitFieldNames)
        shotData(outGoingIndexNum).(char(fitFieldNames(i))) = handles.fitVars.(char(fitFieldNames(i)));
    end
    shotData(outGoingIndexNum).fitType = handles.fitTypeString;
    %Write new shotData to workspace
    assignin('base','shotData',shotData);
    
%function to load shot for refitting    
function handles = loadFile(hObject,handles)
    %import shotData to grab filename
    shotData = grabCutData;
    handles.indexNumAct = shotData(handles.indexNum).Index;
    set(handles.indexDisp,'String',int2str(shotData(handles.indexNum).Index));    
    fullFilename = char(shotData(handles.indexNum).filePath);
    set(handles.filepathDisp,'String',fullFilename);
    %grab pictures from file and get processed image
    %(log(absorption-background)/(probe-background))
    dummyFit = absGaussFit;
    dummyFit.loadFromFile(fullFilename);
    handles.processedImage = dummyFit.getCutImage;
    %Set initial rotation
    handles.rotDegreeVal = shotData(handles.indexNum).rotAngle;
    set(handles.rotDegree,'String',strcat(num2str(handles.rotDegreeVal),'°'));
    set(handles.rotSlider,'Value',handles.rotDegreeVal/180);
    %plot the processed image to the procImage axes
    handles = updateProcessedImage(handles);
    %Set initial ROI, note fliplr is required as the imcrop function is weird;
    handles.currShotData = shotData(handles.indexNum);
    %determine initial fit type
    if strcmp(handles.currShotData.fitType,'absGaussFit')
        set(handles.fitType,'Value',1);
    elseif strcmp(handles.currShotData.fitType,'absDipole')
        set(handles.fitType,'Value',2);
    end
    %save all handles information
    guidata(hObject,handles)


% --- Executes on button press in roiSetter.
function roiSetter_Callback(hObject, eventdata, handles)
    %Prevent re-clicking of the button
    set(handles.roiSetter,'Enable','off')
    %get cropped image
    [~,roiRect] = imcrop();
    %Figure out scaling rounding to nearest integer
    handles.roiRect_pix = [ceil(roiRect(1)),ceil(roiRect(2)),floor(roiRect(3)),floor(roiRect(4))];
    guidata(hObject,handles);
    %Repaint the ROI rectangle
    repaintROIRectangle(hObject,handles,roiRect);
    %Allow button to be clicked
    set(handles.roiSetter,'Enable','on')

%function to repaint the ROI rectangle on the image
function repaintROIRectangle(hObject,handles,roiRectangle)
    %make sure we are drawing to the processed image
    axes(handles.procImage);
    %Delete any old ROI rectangles if necessary
    if isfield(handles,'roiImageRectangle') ~= 0
        delete(handles.roiImageRectangle);
    end
    %Paint the new rectangle and save the rectangle to handles
    hold on
    handles.roiImageRectangle = rectangle('Position',roiRectangle);
    guidata(hObject,handles);
    hold off


% --- Executes on slider movement.
function rotSlider_Callback(hObject, eventdata, handles)
    %Set the rotation degree value in handles and update the rotation angle
    %indicator
    handles.rotDegreeVal = get(handles.rotSlider,'Value')*180;
    set(handles.rotDegree,'String',strcat(num2str(handles.rotDegreeVal),'°'));
    %Tell the updater that the image needs to be rotated
    handles.angleUpdate = true;
    guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function rotSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rotSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end

%Runs periodically to update stuff from the GUI    
function GUIUpdate(timerObj,eventdata,hObject)
    handles = guidata(hObject);
    %Check if the rotation angle has been changed and if so update image
    if handles.angleUpdate
        handles = updateProcessedImage(handles);
    end
    guidata(hObject,handles);

function handles = updateProcessedImage(handles)
    rotatedImage = imrotate(handles.processedImage,+handles.rotDegreeVal);
    axes(handles.procImage);
    handles.procImageResize = imshow(-rotatedImage,'InitialMagnification','fit','DisplayRange',[min(min(-rotatedImage)),max(max(-rotatedImage))],'Parent',handles.procImage);
    handles.roiRect_pix = [1,1,fliplr(size(rotatedImage))];
    handles.angleUpdate = false;

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
    if strcmp(get(handles.timer, 'Running'), 'on')
        stop(handles.timer);
    end
    % Destroy timer
    delete(handles.timer)
    delete(hObject);
