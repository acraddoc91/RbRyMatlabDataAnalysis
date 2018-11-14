classdef pulseFinder < timeTaggerG2
    %PULSEFINDER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        pulseCounts = cell(3,1);
    end
    
    methods
        function updatePulseCounts(self)
            pulseRepTime = 5e-6;
            binningWidth = 5e-9;
            binEdges = [0:binningWidth:pulseRepTime];
            numBins = int32(pulseRepTime/binningWidth);
            if isempty(self.pulseCounts{1})
                self.pulseCounts = cell(length(self.channelList),1);
                for j = 1:length(self.channelList)
                    self.pulseCounts{j} = zeros(1,numBins);
                end
            end
            for i = 1:length(self.channelList)
                tags = self.tags{1}{i} * 82.3e-12;
                for j = 1:length(self.startTags{1})
                    self.pulseCounts{i} = self.pulseCounts{i} + histcounts(tags-self.startTags{1}(j)*82.3e-12,binEdges);
                end
            end
        end
    end
    
end

