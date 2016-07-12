function instantSetJson = setlistInstantVariables( variableArray )
%returns a setlist instant variable string to be written to setlist
    instantSetJson = savejson('',struct('instantVariables',variableArray));
end

