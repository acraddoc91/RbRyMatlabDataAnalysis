function [ varStruct ] = loadVars(filename)
    %function to load calculated and controlled variables from an HDF5 file
    
    %create a structure to hold variables
    varStruct = struct;
    
    %grab calulated values from file
%     dumCalc = h5info(filename,'/Calculated Values');
%     numCalcVars = length(dumCalc.Datasets);
%     for i = 1:numCalcVars
%         calcVarName = char(dumCalc.Datasets(i).Name);
%         calcVarValue = h5read(filename,sprintf('/Calculated Values/%s',calcVarName));
%         varStruct.(calcVarName) = calcVarValue;
%     end
    
    %grab control variables from file
    dumExp = h5info(filename,'/Control Variables');
    numExpVars = length(dumExp.Datasets);
    for i = 1:numExpVars
        expVarName = char(dumExp.Datasets(i).Name);
        expVarValue = h5read(filename,sprintf('/Control Variables/%s',expVarName));
        varStruct.(expVarName) = expVarValue;
    end
    
end

