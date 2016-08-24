function updateLiveAnalysis()
    %Function which will set the requireUpdate variable of liveAnalysis to
    %true causing liveAnalysis to update its internal shotData.
    try
        liveAnalysisObject=evalin('base','liveAnalysisObject');
    end
    if exist('liveAnalysisObject','var')
        liveAnalysisHandles = guidata(liveAnalysisObject);
        liveAnalysisHandles.requireUpdate = true;
        guidata(liveAnalysisObject,liveAnalysisHandles);
    end
end

