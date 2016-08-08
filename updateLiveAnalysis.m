function updateLiveAnalysis()
    %update liveAnalysis
    try
        liveAnalysisObject=evalin('base','liveAnalysisObject');
    end
    if exist('liveAnalysisObject','var')
        liveAnalysisHandles = guidata(liveAnalysisObject);
        liveAnalysisHandles.requireUpdate = true;
        guidata(liveAnalysisObject,liveAnalysisHandles);
    end
end

