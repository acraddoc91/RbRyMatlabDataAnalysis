classdef timeTaggerODMeasurement < handle
    %Time tagger OD measurment class
    
    properties
        absorptionCount = 0;
        probeCount = 0;
        backgroundCount = 0;
        opticalDepth = 0;
        transmission = 0;
        maxOD = 0;
        probeDetuning = 0; %Probe detuning in MHz
        linewidth = 6.0659 %Rb D2 linewidth in MHz
        absorptionTags = [];
        probeTags = [];
        backgroundTags = [];
        numShots = 1;
        %Set this to true and the below edges to those desired if you want
        %to look at a specific time window rather than across all the
        %measurement time taken
        userEdge = false;
        lowEdge = 0e-6;
        highEdge = 20e-6;
    end
    
    methods
        %Grab tags from file
        function loadFromFile(self,filename)
            %Try and grab the number of shots (try included for backward
            %compatibility)
            try
                self.numShots = h5read(filename,'/Inform/Shots');
            end
            dummy = {};
            %Read each tag window vector to the dummy cells
            for i=1:self.numShots
                dummy{end+1} = h5read(filename,sprintf('/Tags/TagWindow%i',i*3-3));
                dummy{end+1} = h5read(filename,sprintf('/Tags/TagWindow%i',i*3-2));
                dummy{end+1} = h5read(filename,sprintf('/Tags/TagWindow%i',i*3-1));
            end
            %Also grab the starttime vector
            dummyStart = uint64(h5read(filename,'/Tags/StartTag'));
            %Loop over the number of shots (multiplied by three for
            %absorption)
            for i=1:self.numShots*3
                %Need to recast i as a 16 bit number because Matlab will
                %cast i as an 8 bit one which causes problems for anything
                %with more than 21 shots
                ip = uint16(i);
                %Reset highcount to 0
                highCount = uint64(0);
                %Grab the vector from the dummy cell structure
                dummy3 = uint64(cell2mat(dummy(ip)));
                dummy2 = [];
                %Loop over the number of tags
                for j=1:length(dummy3)
                    %If the tag is a highword up the high count
                    if bitget(dummy3(j),1)==1
                        highCount = bitshift(dummy3(j),-1)-bitshift(dummyStart(2*ip-1),-1);
                    %Otherwise figure the absolute time since the window
                    %opened and append it to the dummy vector
                    else
                        dummy2 = [dummy2,bitand(bitshift(dummy3(j),-1),2^27-1)+bitshift(highCount,27)-bitand(bitshift(dummyStart(2*ip),-1),2^27-1)];
                        %dummy2 = [dummy2,bitshift(highCount,27)];
                    end
                end
                %Figure out which tag set the dummy tags belong to and send
                %them to the correct vector
                switch rem(ip,3)
                    case 1
                        self.absorptionTags = [self.absorptionTags,dummy2];
                    case 2
                        self.probeTags = [self.probeTags,dummy2];
                    case 0
                        self.backgroundTags = [self.backgroundTags,dummy2];
                end
            end
        end
        %Calculate the detuning adjusted OD
        function runFit(self)
            %If user has set own edges
            if self.userEdge
                self.absorptionCount = sum(self.getAbsPlotData());
                self.probeCount = sum(self.getProbePlotData());
                self.backgroundCount = sum(self.getBackPlotData());
            else
                self.absorptionCount = double(length(self.absorptionTags));
                self.probeCount = double(length(self.probeTags));
                self.backgroundCount = double(length(self.backgroundTags));
            end
            self.transmission = (self.absorptionCount-self.backgroundCount)/(self.probeCount-self.backgroundCount);
            self.opticalDepth = -log((self.absorptionCount-self.backgroundCount)/(self.probeCount-self.backgroundCount))*(1+(self.probeDetuning/self.linewidth)^2);
            [ODTime,~] = self.getODPlotData();
            self.maxOD = max(ODTime);
        end
        %Export fit variables structure
        function fitVars = getFitVars(self)
            fitVars.('opticalDepth') = self.opticalDepth;
            fitVars.('absorptionCount') = self.absorptionCount;
            fitVars.('probeCount') = self.probeCount;
            fitVars.('backgroundCount') = self.backgroundCount;
            fitVars.('maxOD') = self.maxOD;
            fitVars.('transmission') = self.transmission;
        end
        %This function takes the time tags and bins them into various time
        %bins it then works out the OD for each time bin and spits that out
        %as a column vector (ODTime) along with the mid-time of each bin
        function [ODTime,midTime] = getODPlotData(self)
            numBins = 100;
            if  self.userEdge
                edges = [self.lowEdge:(self.highEdge-self.lowEdge)/numBins:self.highEdge];
            else
                edges = [0:round(double(self.probeTags(end))*82.3e-12,5)/numBins:round(double(self.probeTags(end))*82.3e-12,5)];
            end
            probeTimeCounts = histcounts(double(self.probeTags)*82.3e-12,edges);
            absTimeCounts = histcounts(double(self.absorptionTags)*82.3e-12,edges);
            avgBackCounts = double(length(self.backgroundTags))/double(length(edges));
            ODTime = -log(max((absTimeCounts-avgBackCounts)./(probeTimeCounts-avgBackCounts),0))*(1+(self.probeDetuning/self.linewidth)^2);
            midTime = mean([edges(1:end-1);edges(2:end)]);
        end
        %Bins absorption tags
        function [absTimeCounts,midTime] = getAbsPlotData(self)
            numBins = 50;
            if  self.userEdge
                edges = [self.lowEdge:(self.highEdge-self.lowEdge)/numBins:self.highEdge];
            else
                edges = [0:round(double(self.absorptionTags(end))*82.3e-12,5)/numBins:round(double(self.absorptionTags(end))*82.3e-12,5)];
            end
            absTimeCounts = histcounts(double(self.absorptionTags)*82.3e-12,edges);
            midTime = mean([edges(1:end-1);edges(2:end)]);
        end
        %Bins probe tags
        function [probeTimeCounts,midTime] = getProbePlotData(self)
            numBins = 200;
            if  self.userEdge
                edges = [self.lowEdge:(self.highEdge-self.lowEdge)/numBins:self.highEdge];
            else
                edges = [0:round(double(self.probeTags(end))*82.3e-12,5)/numBins:round(double(self.probeTags(end))*82.3e-12,5)];
            end
            probeTimeCounts = histcounts(double(self.probeTags)*82.3e-12,edges);
            midTime = mean([edges(1:end-1);edges(2:end)]);
        end
        %Bins background tags
        function [backTimeCounts,midTime] = getBackPlotData(self)
            numBins = 200;
            if  self.userEdge
                edges = [self.lowEdge:(self.highEdge-self.lowEdge)/numBins:self.highEdge];
            else
                edges = [0:round(double(self.probeTags(end))*82.3e-12,5)/numBins:round(double(self.probeTags(end))*82.3e-12,5)];
            end
            backTimeCounts = histcounts(double(self.backgroundTags)*82.3e-12,edges);
            midTime = mean([edges(1:end-1);edges(2:end)]);
        end
        function [ODTime,midTime] = getTransmissionPlotData(self)
            numBins = 40;
            if  self.userEdge
                edges = [self.lowEdge:(self.highEdge-self.lowEdge)/numBins:self.highEdge];
            else
                edges = [0:round(double(self.probeTags(end))*82.3e-12,5)/numBins:round(double(self.probeTags(end))*82.3e-12,5)];
            end
            probeTimeCounts = histcounts(double(self.probeTags)*82.3e-12,edges);
            absTimeCounts = histcounts(double(self.absorptionTags)*82.3e-12,edges);
            avgBackCounts = double(length(self.backgroundTags))/double(length(edges));
            ODTime = max((absTimeCounts-avgBackCounts)./(probeTimeCounts-avgBackCounts),0);
            midTime = mean([edges(1:end-1);edges(2:end)]);
        end
    end
    
end

