function sequenceSetJson = setlistSequenceSet( arrayOfVariableArrays )
%returns setlist sequence set JSON
    sequenceSetJson = savejson('',struct('sequenceSets',arrayOfVariableArrays));
end

