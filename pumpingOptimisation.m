classdef pumpingOptimisation < timeTaggerSpectra
    properties
        %Define the gaussian fitting function
        lorentz = @(coffs,x) coffs(1)./(coffs(2).^2+(x-coffs(3)).^2);
        mf2PeakFreq = -38;
        mf1PeakFreq = -55;
        reducedRange = 50;
        opts = optimset('Display','off');
        arbmf1Pop = 0;
        arbmf2Pop = 0;
        relativePop = 0;        
    end
    
    methods
        %Calculate the detuning adjusted OD
        function runFit(self)
            self.absorptionCount = double(length(self.absorptionTags));
            self.probeCount = double(length(self.probeTags));
            self.backgroundCount = double(length(self.backgroundTags));
            self.opticalDepth = -log((self.absorptionCount-self.backgroundCount)/(self.probeCount-self.backgroundCount))*(1+(self.probeDetuning/self.linewidth)^2);
            %Grab seperate peaks and fit lorentzians
            initcoffs = [2,6,0];
            [redODmf2,redFreqmf2] = self.getmf2PeakData();
            initcoffs(3) = self.mf2PeakFreq;
            mf2Coffs = lsqcurvefit(@self.lorentz,initcoffs,redFreqmf2,redODmf2,[],[],self.opts);
            initcoffs(3) = self.mf1PeakFreq;
            [redODmf1,redFreqmf1] = self.getmf1PeakData();
            mf1Coffs = lsqcurvefit(@self.lorentz,initcoffs,redFreqmf1,redODmf1,[],[],self.opts);
            %Do some jiggery pokery with clebsch gordan coefficients to
            %work out relative populations
            self.arbmf1Pop = mf1Coffs(1)/mf1Coffs(2)^2 * 15/8;
            self.arbmf2Pop = mf2Coffs(1)/mf2Coffs(2)^2 * 3;
            self.relativePop = self.arbmf2Pop/self.arbmf1Pop;
        end
        function [redOD,redFreq] = getmf2PeakData(self)
            [OD,Freq] = self.getODPlotData(500);
            peakBin = round((self.mf2PeakFreq-Freq(1))/(Freq(end)-Freq(1))*500);
            redFreq = Freq(peakBin-self.reducedRange:peakBin+self.reducedRange);
            redOD = OD(peakBin-self.reducedRange:peakBin+self.reducedRange);
        end
        function [redOD,redFreq] = getmf1PeakData(self)
            [OD,Freq] = self.getODPlotData(500);
            peakBin = round((self.mf1PeakFreq-Freq(1))/(Freq(end)-Freq(1))*500);
            redFreq = Freq(peakBin-self.reducedRange:peakBin+self.reducedRange);
            redOD = OD(peakBin-self.reducedRange:peakBin+self.reducedRange);
        end
        %Export fit variables structure
        function fitVars = getFitVars(self)
            fitVars.('opticalDepth') = self.opticalDepth;
            fitVars.('absorptionCount') = self.absorptionCount;
            fitVars.('probeCount') = self.probeCount;
            fitVars.('backgroundCount') = self.backgroundCount;
            fitVars.('arbitrary_m_f=1_Population') = self.arbmf1Pop;
            fitVars.('arbitrary_m_f=2_Population') = self.arbmf2Pop;
            fitVars.('relativePopulation') = self.relativePop;
        end
    end
end

