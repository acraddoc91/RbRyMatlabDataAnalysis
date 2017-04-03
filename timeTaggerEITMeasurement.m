classdef timeTaggerEITMeasurement < timeTaggerODMeasurement
    
    properties
        %eit = @(coffs,x) exp(-(coffs(1)*coffs(2)*(coffs(3)^2*coffs(2)+4*coffs(2)*(coffs(4)-(x-coffs(5))).^2+coffs(3)*coffs(2)^2)./((coffs(3)^2+4*(coffs(4)-(x-coffs(5))).^2).*(coffs(2)^2+4*(x-coffs(5)).^2)+2*(coffs(3)*coffs(2)+4*(coffs(4)-(x-coffs(5))).*(x-coffs(5)))*coffs(6)^2+coffs(6)^4)));
        eit = @(coffs,x) exp(-(coffs(1)*coffs(2)*(coffs(3)^2*coffs(2)+4*coffs(2)*(coffs(4)-(x-coffs(5))).^2+coffs(3)*coffs(6)^2)./((coffs(3)^2+4*(coffs(4)-(x-coffs(5))).^2).*(coffs(2)^2+4*(x-coffs(5)).^2)+2*(coffs(3)*coffs(2)+4*(coffs(4)-(x-coffs(5))).*(x-coffs(5)))*coffs(6)^2+coffs(6)^4)));
        %coffs(1) - OD
        %coffs(2) - Gamma
        %coffs(3) - gamma
        %coffs(4) - Delta Control
        %coffs(5) - probe offset
        %coffs(6) - Omega control
        coffs = [2,6,1,0,-20,1];
        startFreq = 0;
        endFreq = -42;
        opts = optimset('Display','off');
        lowerBounds = [0,0,0,-Inf,-Inf,0];
    end
    
    methods
        %Fit EIT function to the histogram data
        function runFit(self)
            %Grab OD histogram data
            [transmission,freq] = self.getTransmissionPlotData(1000);
            self.coffs(5) = (freq(end)-freq(1))/2;
            self.coffs = lsqcurvefit(self.eit,self.coffs,freq,transmission,self.lowerBounds,[],self.opts);
        end
        %Allows user to set start and end frequency of the spectrum
        function setFreqRange(self,startF,endF)
            self.startFreq=startF;
            self.endFreq=endF;
        end
        %Export fit variables structure
        function fitVars = getFitVars(self)
            fitVars.('opticalDepth') = self.coffs(1);
            fitVars.('Gamma') = self.coffs(2);
            fitVars.('gamma') = self.coffs(3);
            fitVars.('DeltaControl') = self.coffs(4);
            fitVars.('probeOffset') = self.coffs(5);
            fitVars.('OmegaControl') = self.coffs(6);
        end
        %This function takes the time tags and bins them into various time
        %bins it then works out the OD for each time bin and spits that out
        %as a column vector (ODTime) along with the mid-time of each bin
        function [ODTime,freq] = getODPlotData(self,numBins)
            %numBins = 1000;
            edges = [0:round(double(self.probeTags(end))*82.3e-12,3)/numBins:round(double(self.probeTags(end))*82.3e-12,3)];
            probeTimeCounts = histcounts(double(self.probeTags)*82.3e-12,edges);
            absTimeCounts = histcounts(double(self.absorptionTags)*82.3e-12,edges);
            avgBackCounts = double(length(self.backgroundTags))/double(length(edges));
            ODTime = -real(log((absTimeCounts-avgBackCounts)./(probeTimeCounts-avgBackCounts))*(1+(self.probeDetuning/self.linewidth)^2));
            time = mean([edges(1:end-1);edges(2:end)]);
            %Convert time to frequency
            freq = time/time(end)*(self.endFreq-self.startFreq)+self.startFreq;
        end
        function [transmission,freq] = getTransmissionPlotData(self,numBins)
            edges = [0:round(double(self.probeTags(end))*82.3e-12,3)/numBins:round(double(self.probeTags(end))*82.3e-12,3)];
            probeTimeCounts = histcounts(double(self.probeTags)*82.3e-12,edges);
            absTimeCounts = histcounts(double(self.absorptionTags)*82.3e-12,edges);
            avgBackCounts = double(length(self.backgroundTags))/double(length(edges));
            transmission = (absTimeCounts-avgBackCounts)./(probeTimeCounts-avgBackCounts))*(1+(self.probeDetuning/self.linewidth)^2);
            time = mean([edges(1:end-1);edges(2:end)]);
            freq = time/time(end)*(self.endFreq-self.startFreq)+self.startFreq;
        end
    end
    
end

