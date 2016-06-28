function cutShotData = cutDataFunc()
    %Will perform cuts on shotData given a cutTable on the base workspace
    try
        cutTable = evalin('base','cutTable');
        [numCuts,~]=size(cutTable);
        cutShotData = evalin('base','shotData');
        for i=1:numCuts
            evalString = sprintf('cutShotData(find([cutShotData.%s] %s))',char(cutTable(i,1)),char(cutTable(i,2)));
            cutShotData = eval(evalString);
        end
    catch ME
        disp(ME)
        cutShotData = evalin('base','shotData');
    end
end

