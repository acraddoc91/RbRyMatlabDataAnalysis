function varStruct = setlistVariable( name,defaultValue,sequenceFunction,informIgor,sequence )
%returns a setlist variable structure
    switch nargin
        case 1
            defaultValue = [];
            sequenceFunction = [];
            informIgor = [];
            sequence = [];
        case 2
            sequenceFunction = [];
            informIgor = [];
            sequence = [];
        case 3
            informIgor = [];
            sequence = [];
        case 4
            sequence = [];
    end
    varStruct = struct('name',name,'defaultValue',defaultValue,'sequenceFunction',sequenceFunction,'informIgor',informIgor,'sequence',sequence);

end

