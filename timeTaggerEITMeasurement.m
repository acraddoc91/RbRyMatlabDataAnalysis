classdef timeTaggerEITMeasurement < timeTaggerODMeasurement
    
    properties
        %eit = @(coffs,x) exp(-(coffs(1)*coffs(2)*(coffs(3)^2*coffs(2)+4*coffs(2)*(coffs(4)-(x-coffs(5))).^2+coffs(3)*coffs(2)^2)./((coffs(3)^2+4*(coffs(4)-(x-coffs(5))).^2).*(coffs(2)^2+4*(x-coffs(5)).^2)+2*(coffs(3)*coffs(2)+4*(coffs(4)-(x-coffs(5))).*(x-coffs(5)))*coffs(6)^2+coffs(6)^4)));
        %eit = @(coffs,x) exp(-(coffs(1)*coffs(2)*(coffs(3)^2*coffs(2)+4*coffs(2)*(coffs(4)-(x-coffs(5))).^2+coffs(3)*coffs(6)^2)./((coffs(3)^2+4*(coffs(4)-(x-coffs(5))).^2).*(coffs(2)^2+4*(x-coffs(5)).^2)+2*(coffs(3)*coffs(2)+4*(coffs(4)-(x-coffs(5))).*(x-coffs(5)))*coffs(6)^2+coffs(6)^4)));
        eit = @(coffs,x) exp(-coffs(1)/(1+coffs(6)^2/(coffs(2)*coffs(3))))*exp(-(x-coffs(5)).^2/(2*(coffs(6)^2/(coffs(2)*sqrt(8*coffs(1))))^2));
        %coffs(1) - OD
        %coffs(2) - Gamma
        %coffs(3) - gamma
        %coffs(4) - Delta Control
        %coffs(5) - probe offset
        %coffs(6) - Omega control
        %Form of equation for use in curve fitter
        % exp(-(OD*6.06*(g^2*6.06+4*6.06*(dc-(x-off)).^2+g*omc^2)./((g^2+4*(dc-(x-off)).^2).*(g^2+4*(x-off).^2)+2*(g*6.06+4*(dc-(x-off)).*(x-off))*omc^2+omc^4)))
        %coffs = [5,6,1,30,0,10];
        coffs = [30,6.8,0.4,0,0,8];
%         startFreq = 29;
%         endFreq = 34;
         startFreq =-30;
        endFreq = 30;
        opts = optimset('Display','off');
%         lowerBounds = [0,5.9,0,26,-0.1,0];
%         upperBounds = [Inf,6.1,0.6,33,0.1,9];
          lowerBounds = [0,6.8,0,-50,-50,0];
        upperBounds = [Inf,6.8,1,50,50,25];
    end
    
    methods
        %Fit EIT function to the histogram data
        function runFit(self)
            %Grab OD histogram data
            [transmission,freq] = self.getTransmissionPlotData(50);
            self.coffs(5) = (max(freq)-min(freq))/2+min(freq);
            self.coffs = lsqcurvefit(self.eit,self.coffs,freq,transmission,self.lowerBounds,self.upperBounds,self.opts);
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
            fitVars.('TwoDetuning') = self.coffs(4)+self.coffs(5);
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
            transmission = (absTimeCounts-avgBackCounts)./(probeTimeCounts-avgBackCounts)*(1+(self.probeDetuning/self.linewidth)^2);
            time = mean([edges(1:end-1);edges(2:end)]);
            freq = time/time(end)*(self.endFreq-self.startFreq)+self.startFreq;
        end
    end
    
end

