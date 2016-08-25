function shotStructure = shotProcessor(filename,fitType,writeCalcVarsToFile,writeExperimentalVarsToFile)
    
    %Parse and write experimental control variables to file (if necessary) and output
    %control variable structure
    informString = char(h5read(filename,'/Inform/Inform String'));
    splitInformString = strsplit(informString,'\n');
    dummyIndex = strfind(splitInformString,'# Current Variables');
    index = find(not(cellfun('isempty', dummyIndex)));
    currIndex = index+2;
    while ~strcmp(char(splitInformString(currIndex)),'#')
        currLine = char(splitInformString(currIndex));
        splitLine = strtrim(strsplit(currLine,'='));
        if writeExperimentalVarsToFile
            expVarName = sprintf('/Experimental Variables/%s',char(splitLine(1)));
            h5create(filename,expVarName,1);
            h5write(filename,expVarName,str2double(splitLine(2)));
        end
        shotStructure.(char(splitLine(1))) = str2double(splitLine(2));
        currIndex = currIndex + 1;
     end
     %Get index number
     dummyFileNumIndex = strfind(splitInformString,'FileNumber');
     fileIndex = find(not(cellfun('isempty', dummyFileNumIndex)));
     fileNumSplit = strsplit(char(splitInformString(fileIndex)),'=');
     shotStructure.Index = str2double(fileNumSplit(2));
     %Get magnification
     try
         dummyMagIndex = strfind(splitInformString,'Magnification');
         magIndex = find(not(cellfun('isempty', dummyMagIndex)));
         magSplit = strsplit(char(splitInformString(magIndex(1))),'=');
         shotStructure.Magnification = str2double(magSplit(2));
     end
     %Get timestamp
     dummyTimeIndex = strfind(splitInformString,'Timestamp');
     timeIndex = find(not(cellfun('isempty', dummyTimeIndex)));
     %Check if there is a timestamp. Added to grandfather in old shot files
     %which don't have timestamps
     if isempty(timeIndex) ~= 1
         timeSplit = strsplit(char(splitInformString(timeIndex(1))),'=');
         shotStructure.Timestamp = datetime(timeSplit(2),'InputFormat','dd-MM-yyyy HH:mm:ss');
     end
     if writeExperimentalVarsToFile
         h5create(filename,'/Experimental Variables/Index',1);
         h5write(filename,'/Experimental Variables/Index',str2double(fileNumSplit(2)));
         try
             h5create(filename,'/Experimental Variables/Magnification',1);
             h5write(filename,'/Experimental Variables/Magnification',shotStructure.Magnification);
         end
     end
     shotStructure.filePath = filename;
     
    fitDone = false;    
    %Run the required fit and send values 
    if strcmp(fitType,'absGaussFit')
        %first let's make a fit object and load the current file to it
        fit = absGaussFit;
        fit.loadFromFile(filename);
        %automagically find the centre coordinates
        fit.findCentreCoordinates();
        %Do the fits
        fit.runFits();
        try
            %Set the imaging system magnification
            fit.setMagnification(shotStructure.Magnification);
        catch
            disp('magnification not set in Setlist')
        end
        try
            %Calculate atom number
            fit.calculateAtomNumber(shotStructure.ImagingDetuning,shotStructure.ImagingIntensity);
        catch
            disp('imagingDetuning or imagingIntensity not set in Setlist')
        end
        %Grab the fit variables (specifically the x & y sigmas) and centre
        %coordinates and start populating the shotStructure
        fitStruct = fit.getFitVars();
        fitFields = fieldnames(fitStruct);
        for i = 1:length(fitFields)
            shotStructure.(char(fitFields(i))) = fitStruct.(char(fitFields(i)));
        end
        centreCoords = fit.getCentreCoordinates();
        centreNames = fieldnames(centreCoords);
        for i=1:2
            shotStructure.(char(centreNames(i))) = centreCoords.(char(centreNames(i)));
        end
        fitDone = true;
        shotStructure.fitType = 'absGaussFit';
    elseif strcmp(fitType,'absDipole')
        %first let's make a fit object and load the current file to it
        fit = absDipole;
        fit.loadFromFile(filename);
        %automagically find the centre coordinates
        fit.findCentreCoordinates();
        try
            %Set the imaging system magnification
            fit.setMagnification(shotStructure.Magnification);
        catch
            disp('magnification not set in Setlist')
        end
        try
            %Calculate atom number
            fit.calculateAtomNumber(shotStructure.ImagingDetuning,shotStructure.ImagingIntensity);
        catch
            disp('imagingDetuning or imagingIntensity not set in Setlist')
        end
        %Grab the fit variables (specifically the x & y sigmas) and centre
        %coordinates and start populating the shotStructure
        fitStruct = fit.getFitVars();
        fitFields = fieldnames(fitStruct);
        for i = 1:length(fitFields)
            shotStructure.(char(fitFields(i))) = fitStruct.(char(fitFields(i)));
        end
        fitDone = true;
        shotStructure.fitType = 'absDipole';
    elseif strcmp(fitType,'timeTaggerODMeasurement')
        fit = timeTaggerODMeasurement;
        fit.loadFromFile(filename);
        fit.runFit();
        %Grab the fit variables and start populating the shotStructure
        fitStruct = fit.getFitVars();
        fitFields = fieldnames(fitStruct);
        for i = 1:length(fitFields)
            shotStructure.(char(fitFields(i))) = fitStruct.(char(fitFields(i)));
        end
        fitDone = true;
        shotStructure.fitType = 'timeTaggerODMeasurement';
    end
    
    %Write variables gathered from fit to file if necessary
    if writeCalcVarsToFile && fitDone
        outVarNames = fieldnames(shotStructure);
        numVars = length(outVarNames);
        for i = 1:numVars;
            calcVarName = sprintf('/Calculated Values/%s',char(outVarNames(i)));
            h5create(filename,calcVarName,1);
            h5write(filename,calcVarName,shotStructure.(char(outVarNames(i))));
        end
    end
end