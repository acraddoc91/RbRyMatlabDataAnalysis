function [ varStruct ] = loadVars(filename)
    varStruct = struct;

    dumCalc = h5info(filename,'/Calculated Values');
    numCalcVars = length(dumCalc.Datasets);
    for i = 1:numCalcVars
        calcVarName = char(dumCalc.Datasets(i).Name);
        calcVarValue = h5read(filename,sprintf('/Calculated Values/%s',calcVarName));
        varStruct.(calcVarName) = calcVarValue;
    end
    
    dumExp = h5info(filename,'/Experimental Variables');
    numExpVars = length(dumExp.Datasets);
    for i = 1:numExpVars
        expVarName = char(dumExp.Datasets(i).Name);
        expVarValue = h5read(filename,sprintf('/Experimental Variables/%s',expVarName));
        varStruct.(expVarName) = expVarValue;
    end
    
end

