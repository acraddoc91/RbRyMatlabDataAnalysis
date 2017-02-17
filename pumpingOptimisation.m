classdef pumpingOptimisation < timeTaggerSpectra
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %Define the gaussian fitting function
        lorentz = @(coffs,x) transpose(coffs(1)/(coffs(2)^2+(x-coffs(3))^2));
        mf2PeakFreq = -40;
        mf1PeakFreq = -55;
    end
    
    methods
        %Calculate the detuning adjusted OD
        function runFit(self)
            self.absorptionCount = double(length(self.absorptionTags));
            self.probeCount = double(length(self.probeTags));
            self.backgroundCount = double(length(self.backgroundTags));
            self.opticalDepth = -log((self.absorptionCount-self.backgroundCount)/(self.probeCount-self.backgroundCount))*(1+(self.probeDetuning/self.linewidth)^2);
            [OD,Freq] = self.getODPlotData(500);
        end
        function [redOD,redFreq] = getmf2PeakData(self)
            [OD,Freq] = self.getODPlotData(500);
            peakBin = (Freq(end)-Freq(1))/500*self.mf2PeakFreq
            redFreq = Freq(peakBin-50:peakBin+50);
            redOD = OD(peakBin-50:peakBin+50);
            figure;
            plot(redFreq,redOD);
        end
    end
    
end

