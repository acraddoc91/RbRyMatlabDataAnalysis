classdef timeTaggerIntensityProfile < timeTaggerG2
    
    properties
        posPulseDisplacement = 9.5e-6;
        negPulseDisplacment = -0.5e-6;
        apdCounts = [];
    end
    
    methods
        %Constructor
        function obj = timeTaggerIntensityProfile()
            %See if there is an existing runningG2 class on the base
            %workspace else do nothing
            try
                obj = evalin('base','runningIntensityObj');
            end
        end
        function updateIntensityProfile(self)
            binWidth = 10e-9;
            endTime = 0.01;
            posBins = floor(self.posPulseDisplacement/binWidth);
            negBins = ceil(self.negPulseDisplacment/binWidth);
            if isempty(self.apdCounts)
                self.apdCounts = zeros(length(self.channelList),posBins-negBins+1);
            end
            for j=1:self.numShots
                for i=1:length(self.channelList)
                    channelHist = histcounts(double(self.tags{j}{i}*82.3e-12),[0:binWidth:self.startTags{j}(end)*82.3e-12+11e-6]);
                    for k = 1:length(self.startTags{j})
                        clockBin = round(self.startTags{j}(k)*82.3e-12/binWidth);
                        self.apdCounts(i,:) = self.apdCounts(i,:) + channelHist(clockBin+negBins:clockBin+posBins);
                    end
                end
            end
        end
        function [time,counts] = getApdCounts(self)
            binWidth = 10e-9;
            posBins = floor(self.posPulseDisplacement/binWidth);
            negBins = ceil(self.negPulseDisplacment/binWidth);
            time = [negBins:posBins]*binWidth;
            counts = self.apdCounts;
        end
    end
    
end

