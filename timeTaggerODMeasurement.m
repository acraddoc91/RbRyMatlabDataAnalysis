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
    end
    
    methods
        %Grab counts from file
        function loadFromFile(self,filename)
            dummyAbs = h5read(filename,'/Tags/TagWindow0');
            dummyProbe = h5read(filename,'/Tags/TagWindow1');
            dummyBack = h5read(filename,'/Tags/TagWindow2');
            dummyStart = h5read(filename,'/Tags/StartTag');
            highCount = 0;
            %Pull out absorption tags
            for i=[1:length(dummyAbs)]
                if bitget(dummyAbs(i),1)==1
                    highCount = bitshift(dummyAbs(i),-1)-bitshift(dummyStart(1),-1);
                else
                    self.absorptionTags = [self.absorptionTags,bitand(bitshift(dummyAbs(i),-1),2^28-1)+bitshift(highCount,27)-bitand(bitshift(dummyStart(2),-1),2^28-1)];
                end
            end
            highCount = 0;
            %And probe
            for i=[1:length(dummyProbe)]
                if bitget(dummyProbe(i),1)==1
                    highCount = bitshift(dummyProbe(i),-1)-bitshift(dummyStart(3),-1);
                else
                    self.probeTags = [self.probeTags,bitand(bitshift(dummyProbe(i),-1),2^28-1)+bitshift(highCount,27)-bitand(bitshift(dummyStart(4),-1),2^28-1)];
                end
            end
            highCount = 0;
            %And background
            for i=[1:length(dummyBack)]
                if bitget(dummyBack(i),1)==1
                    highCount = bitshift(dummyBack(i),-1)-bitshift(dummyStart(5),-1);
                else
                    self.backgroundTags = [self.backgroundTags,bitand(bitshift(dummyBack(i),-1),2^28-1)+bitshift(highCount,27)-bitand(bitshift(dummyStart(6),-1),2^28-1)];
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
            ODTime = -log((absTimeCounts-avgBackCounts)./(probeTimeCounts-avgBackCounts))*(1+(self.probeDetuning/self.linewidth)^2);
            midTime = mean([edges(1:end-1);edges(2:end)]);
        end
    end
    
end

