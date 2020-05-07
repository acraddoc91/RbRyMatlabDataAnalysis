classdef timeTaggerDoubleODMeasurement < handle
    %TIMETAGGERDOUBLEOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
%         absorptionCount = [0,0];
%         probeCount = [0,0];
%         backgroundCount = [0,0];
%         opticalDepth = 0;
%         transmission = [0,0];
        %%%
        absorptionCount = [0,0,0];
        probeCount = [0,0, 0];
        backgroundCount = [0,0, 0];
        opticalDepth = 0;
        transmission = [0,0, 0];
        %%%
        maxOD = 0;
        probeDetuning = 0; %Probe detuning in MHz
        linewidth = 6.0659 %Rb D2 linewidth in MHz
        absorptionTags = {};
        probeTags = {};
        backgroundTags = {};
        channelList = [];
        numShots = 1;
        %Set this to true and the below edges to those desired if you want
        %to look at a specific time window rather than across all the
        %measurement time taken
        userEdge = false;
        lowEdge = 0e-6;
        highEdge = 20e-6;
    end
    
    methods
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
            %And the channel list
            self.channelList = h5read(filename,'/Inform/ChannelList');
            %Expand tag array size
            self.absorptionTags = cell([self.numShots],1);
            self.probeTags = cell([self.numShots],1);
            self.backgroundTags = cell([self.numShots],1);
            %Also grab the starttime vector
            dummyStart = uint64(h5read(filename,'/Tags/StartTag'));            
            %Loop over the number of shots
            for i=1:self.numShots*3
                %Need to recast i as a 16 bit number because Matlab will
                %cast i as an 8 bit one which causes problems for anything
                %with more than 21 shots
                ip = uint16(i);
                %Reset highcount to 0
                highCount = uint64(0);
                %Grab the vector from the dummy cell structure
                dummy3 = uint64(cell2mat(dummy(ip)));
                %Pre-allocate size here to make things quicker later
                dummy2 = cell(length(self.channelList),1);
                for k=1:length(self.channelList)
                    %Initialise each channels tag vector to be a NaN vector
                    %the same length as the total number of tags
                    dummy2{k} = NaN([length(dummy3),1]);
                end
                %Loop over the number of tags
                for j=1:length(dummy3)
                    %If the tag is a highword up the high count
                    if bitget(dummy3(j),1)==1
                        highCount = bitshift(dummy3(j),-1)-bitshift(dummyStart(2*ip-1),-1);
                    %Otherwise figure the absolute time since the window
                    %opened and append it to the dummy vector
                    else
                        channel = bitand(bitshift(dummy3(j),-29),7)+1;
                        channelIndex = find(self.channelList == channel,1);
                        dummy2{channelIndex}(j) = bitand(bitshift(dummy3(j),-1),2^27-1)+bitshift(highCount,27)-bitand(bitshift(dummyStart(2*ip),-1),2^27-1);
                    end
                end
                %Strip out NaN values from each tag vector
                for k=1:length(self.channelList)
                    dummy2{k}(isnan(dummy2{k}(:,1)),:)=[];
                end
                %Append tag vectors to tag cell array
                switch rem(i,3)
                    case 1
                        self.absorptionTags = dummy2;
                    case 2
                        self.probeTags = dummy2;
                    case 0
                        self.backgroundTags = dummy2;
                end
            end
        end
        %Calculate the detuning adjusted OD
        function runFit(self)
            %If user has set own edges
%             self.absorptionCount(1) = double(length(self.absorptionTags{1}));
%             self.absorptionCount(2) = double(length(self.absorptionTags{2}));
%             self.probeCount(1) = double(length(self.probeTags{1}));
%             self.probeCount(2) = double(length(self.probeTags{2}));
%             self.backgroundCount(1) = double(length(self.backgroundTags{1}));
%             self.backgroundCount(2) = double(length(self.backgroundTags{2}));
%             self.transmission = (self.absorptionCount-self.backgroundCount)./(self.probeCount-self.backgroundCount);
            self.absorptionCount(1) = double(length(self.absorptionTags{1}));
            self.absorptionCount(2) = double(length(self.absorptionTags{2}));
             self.absorptionCount(3) = double(length(self.absorptionTags{3}));
            self.probeCount(1) = double(length(self.probeTags{1}));
            self.probeCount(2) = double(length(self.probeTags{2}));
            self.probeCount(3) = double(length(self.probeTags{3}));
            self.backgroundCount(1) = double(length(self.backgroundTags{1}));
            self.backgroundCount(2) = double(length(self.backgroundTags{2}));
            self.backgroundCount(3) = double(length(self.backgroundTags{3}));
            self.transmission = (self.absorptionCount-self.backgroundCount)./(self.probeCount-self.backgroundCount);
        end
        %Export fit variables structure
        function fitVars = getFitVars(self)
%             fitVars.('absorptionCount1') = self.absorptionCount(1);
%             fitVars.('probeCount1') = self.probeCount(1);
%             fitVars.('backgroundCount1') = self.backgroundCount(1);
%             fitVars.('transmission1') = self.transmission(1);
%             fitVars.('absorptionCount2') = self.absorptionCount(2);
%             fitVars.('probeCount2') = self.probeCount(2);
%             fitVars.('backgroundCount2') = self.backgroundCount(2);
%             fitVars.('transmission2') = self.transmission(2);
%             fitVars.('reltrans') = self.transmission(1)-self.transmission(2);
%             fitVars.('relCount') = self.probeCount(1)-self.probeCount(2);
%             fitVars.('absorptionCountTot') = sum(self.absorptionCount);
%             fitVars.('probeCountTot') = sum(self.probeCount);
%             fitVars.('backgroundCountTot') = sum(self.backgroundCount);
%             fitVars.('transmissionTot') = (sum(self.absorptionCount)-sum(self.backgroundCount))./(sum(self.probeCount)-sum(self.backgroundCount));
            fitVars.('absorptionCount1') = self.absorptionCount(1);
            fitVars.('probeCount1') = self.probeCount(1);
            fitVars.('backgroundCount1') = self.backgroundCount(1);
            fitVars.('transmission1') = self.transmission(1);
            fitVars.('absorptionCount2') = self.absorptionCount(2);
            fitVars.('probeCount2') = self.probeCount(2);
            fitVars.('backgroundCount2') = self.backgroundCount(2);
            fitVars.('transmission2') = self.transmission(2);
            fitVars.('absorptionCount3') = self.absorptionCount(3);
            fitVars.('probeCount3') = self.probeCount(3);
            fitVars.('backgroundCount3') = self.backgroundCount(3);
            fitVars.('transmission3') = self.transmission(3);
            fitVars.('reltrans') = self.transmission(1)-self.transmission(2);
            fitVars.('relCount') = self.probeCount(1)-self.probeCount(2);
            fitVars.('absorptionCountTot') = sum(self.absorptionCount);
            fitVars.('probeCountTot') = sum(self.probeCount);
            fitVars.('backgroundCountTot') = sum(self.backgroundCount);
            fitVars.('transmissionTot') = (sum(self.absorptionCount)-sum(self.backgroundCount))./(sum(self.probeCount)-sum(self.backgroundCount));
        end
        function [ODTime,midTime] = getTransmissionPlotData(self)
            numBins = 40;
            if  self.userEdge
                edges = [self.lowEdge:(self.highEdge-self.lowEdge)/numBins:self.highEdge];
            else
                edges = [0:round(double(self.probeTags(1,end))*82.3e-12,5)/numBins:round(double(self.probeTags(1,end))*82.3e-12,5)];
            end
            probeTimeCounts = histcounts(double(self.probeTags(1))*82.3e-12,edges);
            absTimeCounts = histcounts(double(self.absorptionTags(1))*82.3e-12,edges);
            avgBackCounts = double(length(self.backgroundTags(1)))/double(length(edges));
            ODTime = max((absTimeCounts-avgBackCounts)./(probeTimeCounts-avgBackCounts),0);
            midTime = mean([edges(1:end-1);edges(2:end)]);
        end
    end
    
end

