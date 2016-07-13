function instantSetJson = setlistInstantVariables( variableArray )
%returns a setlist instant variable string to be written to setlist
    %Make sure logicals are parsed as true/false not 1/0
    instantSetJson = savejson('',struct('instantVariables',variableArray),'ParseLogical',true);
end

