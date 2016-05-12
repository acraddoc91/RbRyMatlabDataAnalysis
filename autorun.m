function [] = autorun(filename,fitType,writeCalcVarsToFile,parseInform)
    %autorun function which should be called each time imaging data is
    %collected

    %Set camera pixel size, for the flea it's 3.69um per pixel
    cameraPixSize = 3.69;
    cameraPixSizeUnits = 'um';
    
    fitDone = false;    
    %Run the required fit
    if strcmp(fitType,'absGaussFit')
        [outVarNames,outVarVals,outVarUnits]=HDF5GaussFit(filename,cameraPixSize,cameraPixSizeUnits);
        fitDone = true;
    end
    
    %Write variables gathered from fit to file if necessary
    if writeCalcVarsToFile && fitDone
        numVars = length(outVarNames);
        for i = 1:numVars;
            calcVarName = sprintf('/Calculated Values/%s',char(outVarNames(i)));
            h5create(filename,calcVarName,1);
            h5write(filename,calcVarName,outVarVals(i));
            h5writeatt(filename,calcVarName,'units',char(outVarUnits(i)));
        end
    end
    
    %Parse and write experimental control variables to file
    if parseInform
        informString = char(h5read(filename,'/Inform/Inform String'));
        splitInformString = strsplit(informString,'\n');
        dummyIndex = strfind(splitInformString,'# Current Variables');
        index = find(not(cellfun('isempty', dummyIndex)));
        currIndex = index+2;
        while ~strcmp(char(splitInformString(currIndex)),'#')
             currLine = char(splitInformString(currIndex));
             splitLine = strtrim(strsplit(currLine,'='));
             expVarName = sprintf('/Control Variables/%s',char(splitLine(1)));
             h5create(filename,expVarName,1);
             h5write(filename,expVarName,str2double(splitLine(2)));
             currIndex = currIndex + 1;
         end
        dummyFileNumIndex = strfind(splitInformString,'FileNumber');
        fileIndex = find(not(cellfun('isempty', dummyFileNumIndex)));
        fileNumSplit = strsplit(char(splitInformString(fileIndex)),'=');
        h5create(filename,'/Control Variables/Index',1);
        h5write(filename,'/Control Variables/Index',str2double(fileNumSplit(2)));
    end

end

