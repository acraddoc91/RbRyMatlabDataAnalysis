function analysisdone = autorun(filename,fitType,writeCalcVarsToFile,writeExperimentalVarsToFile,magnification)
    %autorun function which should be called each time imaging data is
    %collected
    analysisdone=0;
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
        %Set the imaging system magnification
        fit.setMagnification(magnification);
        %Grab the fit variables (specifically the x & y sigmas) and centre
        %coordinates and start populating the shotStructure
        shotStructure = fit.getFitVars();
        centreCoords = fit.getCentreCoordinates();
        centreNames = fieldnames(centreCoords);
        for i=1:2
            shotStructure.(char(centreNames(i))) = centreCoords.(char(centreNames(i)));
        end
        fitDone = true;
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
     dummyFileNumIndex = strfind(splitInformString,'FileNumber');
     fileIndex = find(not(cellfun('isempty', dummyFileNumIndex)));
     fileNumSplit = strsplit(char(splitInformString(fileIndex)),'=');
     if writeExperimentalVarsToFile
         h5create(filename,'/Experimental Variables/Index',1);
         h5write(filename,'/Experimental Variables/Index',str2double(fileNumSplit(2)));
     end
     shotStructure.Index = str2double(fileNumSplit(2));
     shotStructure.filePath = filename;
     
     %Try and import shotData from the base workspace and update it
     try
         shotIn = evalin('base','shotData');
         shotOut = [shotIn,shotStructure];
         assignin('base','shotData',shotOut);
     catch
         assignin('base','shotData',shotStructure);
     end
     analysisdone=1;
end

