classdef timeTaggerODMeasurement < handle
    %Time tagger OD measurment class
    
    properties
        absorptionCount = 0;
        probeCount = 0;
        backgroundCount = 0;
        opticalDepth = 0;
        probeDetuning = 0; %Probe detuning in MHz
        linewidth = 6.0659 %Rb D2 linewidth in MHz
        absorptionTags = [];
        probeTags = [];
        backgroundTags = [];
        numShots = 1;
    end
    
    methods
        %Grab counts from file
        function loadFromFile(self,filename)
            try
                self.numShots = h5read(filename,'/Inform/Shots');
            end
            for i=1:self.numShots
                dummy(i*3-2) = h5read(filename,sprintf('/Tags/TagWindow%i',i*3-3));
                dummy(i*3-1) = h5read(filename,sprintf('/Tags/TagWindow%i',i*3-2));
                dummy(i*3) = h5read(filename,sprintf('/Tags/TagWindow%i',i*3-1));
            end
            dummyStart = h5read(filename,'/Tags/StartTag');
            for i=1:self.numShots*3
                highCount = 0;
                for j=1:legnth(dummy(i))
                    if bitget(dummy(i,j),1)==1
                        highCount = bitshift(dummy(i*2-1,j),-1)-bitshift(dummyStart(i*3-2),-1);
                    else
                        dummy2 = [dummy2,bitand(bitshift(dummy(i,j),-1),2^28-1)+bitshift(highCount,27)-bitand(bitshift(dummyStart(2*i),-1),2^28-1)];
                    end
                end
                switch rem(i,3)
                    case 1
                        self.absorbtionTags = [self.absorptionTags,dummy2];
                    case 2
                        self.probeTags = [self.probeTags,dummy2];
                    case 0
                        self.backgroundTags = [self.backgroundTags,dummy2];
                end
            end
        end
        %Calculate the detuning adjusted OD
        function runFit(self)
            self.absorptionCount = double(length(self.absorptionTags));
            self.probeCount = double(length(self.probeTags));
            self.backgroundCount = double(length(self.backgroundTags));
            self.opticalDepth = -log((self.absorptionCount-self.backgroundCount)/(self.probeCount-self.backgroundCount))*(1+(self.probeDetuning/self.linewidth)^2);
        end
        %Export fit variables structure
        function fitVars = getFitVars(self)
            fitVars.('opticalDepth') = self.opticalDepth;
            fitVars.('absorptionCount') = self.absorptionCount;
            fitVars.('probeCount') = self.probeCount;
            fitVars.('backgroundCount') = self.backgroundCount;
        end
        function [ODTime,midTime] = getODPlotData(self)
            edges = [0:round(double(self.probeTags(end))*82.3e-12,3)/20:round(double(self.probeTags(end))*82.3e-12,3)];
            probeTimeCounts = histcounts(double(self.probeTags)*82.3e-12,edges);
            absTimeCounts = histcounts(double(self.absorptionTags)*82.3e-12,edges);
            avgBackCounts = double(length(self.backgroundTags))/double(length(edges));
            ODTime = -real(log((absTimeCounts-avgBackCounts)./(probeTimeCounts-avgBackCounts))*(1+(self.probeDetuning/self.linewidth)^2));
            midTime = mean([edges(1:end-1);edges(2:end)]);
        end
    end
    
end

