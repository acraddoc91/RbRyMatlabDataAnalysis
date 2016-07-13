function mulliganJson = setlistMulligan( mulliganArray )
%returns setlist mulligan json
    %need to have a seperate method for a 1x1 array as matlab automatically
    %converts this to a scalar
    if length(mulliganArray)==1
        mulliganJson = strcat('{"mulligan":[',num2str(mulliganArray),']}');
    elseif length(mulliganArray)==0
        mulliganJson = '';
    else
        mulliganJson = savejson('',struct('mulligan',[mulliganArray]));
    end
    try
        cutTable = evalin('base','cutTable');
    catch
        cutTable = {};
    end
    for i = 1:length(mulliganArray)
        cutTable = [cutTable;{'Index','~=',num2str(mulliganArray(i))}];
    end
    assignin('base','cutTable',cutTable);
end

