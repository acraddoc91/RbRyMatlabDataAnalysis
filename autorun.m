function analysisdone = autorun(filename,fitType,writeCalcVarsToFile,writeExperimentalVarsToFile)
    %autorun function which should be called each time imaging data is
    %collected
    analysisdone=0;
    shotStructure = shotProcessor(filename,fitType,writeCalcVarsToFile,writeExperimentalVarsToFile);
    %Try and import shotData from the base workspace and update it
    try
        shotIn = evalin('base','shotData');
    catch ME
        %disp(ME.identifier)
        assignin('base','shotData',shotStructure);
    end
    if exist('shotIn','var')
        %see if index already exists
        repIndex = find([shotIn.Index]==shotStructure.Index);
        if isempty(repIndex)
            shotOut = structAppend(shotIn,shotStructure);
        else
            %remove repeated index
            shotIn(repIndex) = [];
            shotOut = structAppend(shotIn,shotStructure);
        end
        assignin('base','shotData',shotOut);
    end
    analysisdone=1;
end

