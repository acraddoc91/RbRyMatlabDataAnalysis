function cutShotData = cutDataFunc()
    %Will perform cuts on shotData given a cutTable on the base workspace
    try
        %grab the base workspace cutTable and shotData
        cutTable = evalin('base','cutTable');
        [numCuts,~]=size(cutTable);
        cutShotData = evalin('base','shotData');
        %For each cut in the cutTable create the evaluation string to
        %cut the data and run it.
        
        %%I may want to find a cleaner way to do
        %%this but for the moment this seems to be the easiest
        for i=1:numCuts
            evalString = sprintf('cutShotData(find([cutShotData.%s] %s))',char(cutTable(i,1)),char(cutTable(i,2)));
            cutShotData = eval(evalString);
        end
    catch ME
        %display any errors that may occur and in a worse case just return
        %the shotData from the base workspace
        %disp(ME)
        cutShotData = evalin('base','shotData');
    end
end

