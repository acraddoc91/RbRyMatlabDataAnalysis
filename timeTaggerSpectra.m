classdef timeTaggerSpectra < timeTaggerODMeasurement
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        startFreq = -40;
        endFreq = 40;
    end
    
    methods
        %This function takes the time tags and bins them into various time
        %bins it then works out the OD for each time bin and spits that out
        %as a column vector (ODTime) along with the mid-time of each bin
        function [ODTime,freq] = getODPlotData(self,numBins)
            edges = [0:round(double(self.probeTags(end))*82.3e-12,6)/numBins:round(double(self.probeTags(end))*82.3e-12,6)];
            probeTimeCounts = histcounts(double(self.probeTags)*82.3e-12,edges);
            absTimeCounts = histcounts(double(self.absorptionTags)*82.3e-12,edges);
            avgBackCounts = double(length(self.backgroundTags))/double(length(edges));
            ODTime = -real(log((absTimeCounts-avgBackCounts)./(probeTimeCounts-avgBackCounts))*(1+(self.probeDetuning/self.linewidth)^2));
            midTime = mean([edges(1:end-1);edges(2:end)]);
            freq = midTime/midTime(end)*(self.endFreq-self.startFreq)+self.startFreq;
        end
        %Calculate the detuning adjusted OD
        function runFit(self)
            self.absorptionCount = double(length(self.absorptionTags));
            self.probeCount = double(length(self.probeTags));
            self.backgroundCount = double(length(self.backgroundTags));
            self.opticalDepth = -log((self.absorptionCount-self.backgroundCount)/(self.probeCount-self.backgroundCount))*(1+(self.probeDetuning/self.linewidth)^2);
            [ODTime,~] = self.getODPlotData(200);
            self.maxOD = max(ODTime);
        end
        %Allows user to set start and end frequency of the spectrum
        function setFreqRange(self,startF,endF)
            self.startFreq=startF;
            self.endFreq=endF;
        end
    end
    
end

