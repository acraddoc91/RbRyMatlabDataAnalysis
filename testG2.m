classdef testG2 < handle
    %TESTG2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tags = {};
        startTags = {};
        endTags = {};
        channelList = [];
        numShots = 0;
        binWidth = 25e-9;
        maxEdge = 1.5e-6;
        minEdge = -1.5e-6;
        g2denominator = [];
        g2numerator = [];
    end
    
    methods
        function loadFromFile(self,filename)
            %Try and grab the number of shots (try included for backward
            %compatibility)
            try
                self.numShots = h5read(filename,'/Inform/Shots');
            end
            dummy = cell(self.numShots);
            dummyClock = cell(self.numShots);
            %Read each tag window vector to the dummy cells
            for i=1:self.numShots
                dummy{i} = uint64(h5read(filename,sprintf('/Tags/TagWindow%i',i-1)));
                dummyClock{i} = uint64(h5read(filename,sprintf('/Tags/ClockTags%i',i-1)));
            end
            %Also grab the starttime and endtime vector
            dummyStart = uint64(h5read(filename,'/Tags/StartTag'));
            %And the channel list
            self.channelList = h5read(filename,'/Inform/ChannelList');
            %Expand tag array size
            self.tags = cell([self.numShots],1);
            self.startTags = cell(self.numShots,1);
            self.endTags = cell(self.numShots,1);
            %Loop over the number of shots
            for i=1:self.numShots
                %Need to recast i as a 16 bit number because Matlab will
                %cast i as an 8 bit one which causes problems for anything
                %with more than 21 shots
                ip = uint16(i);
                %Reset highcount to 0
                highCount = 0;
                %Grab the vector from the dummy cell structure
                dummy3 = cell2mat(dummy(ip));
                dummyClock3 = cell2mat(dummyClock(ip));
                %Pre-allocate size here to make things quicker later
                dummy2 = cell(length(self.channelList),1);
                dummyStartTags = NaN([length(dummyClock3),1]);
                dummyEndTags = NaN([length(dummyClock3),1]);
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
                %Reset highcount to 0
                highCount = 0;
                %Same for clock tags
                for j=1:length(dummyClock3)
                    %If the tag is a highword up the high count
                    if bitget(dummyClock3(j),1)==1
                        highCount = bitshift(dummyClock3(j),-1)-bitshift(dummyStart(2*ip-1),-1);
                    %Otherwise figure the absolute time since the window
                    %opened and append it to the dummy vector
                    else
                        slope = bitand(bitshift(dummyClock3(j),-28),1);
                        if slope == 1
                            dummyStartTags(j) = bitand(bitshift(dummyClock3(j),-1),2^27-1)+bitshift(highCount,27)-bitand(bitshift(dummyStart(2*ip),-1),2^27-1);
                        else
                            dummyEndTags(j) = bitand(bitshift(dummyClock3(j),-1),2^27-1)+bitshift(highCount,27)-bitand(bitshift(dummyStart(2*ip),-1),2^27-1);
                        end
                    end
                end
                %Strip out NaN values from each tag vector
                for k=1:length(self.channelList)
                    dummy2{k}(isnan(dummy2{k}(:,1)),:)=[];
                end
                dummyStartTags(isnan(dummyStartTags(:,1)),:)=[];
                dummyEndTags(isnan(dummyEndTags(:,1)),:)=[];
                %Append tag vectors to tag cell array
                self.tags{i} = dummy2;
                self.endTags{i} = dummyEndTags;
                self.startTags{i} = dummyStartTags;
            end
        end
        function updateG2(self,channel1,channel2)
            %Find the tag index for channel 1 & 2
            channel1Index = find(self.channelList == channel1,1);
            channel2Index = find(self.channelList == channel2,1);
            posSteps = floor(self.maxEdge/self.binWidth);
            negSteps = ceil(self.minEdge/self.binWidth);
            pulseSpacing = 10e-6/self.binWidth;
            %Make some vectors for the g2 numerator and denominator
            if isempty(self.g2numerator)
                self.g2numerator = zeros(1,posSteps-negSteps+1);
                self.g2denominator = zeros(1,posSteps-negSteps+1);
            end
            for i = 1:self.numShots
                %Apply the mask
                mask1 = zeros(length(self.tags{i}{channel1Index}),1);
                mask2 = zeros(length(self.tags{i}{channel2Index}),1);
                for j = 1:length(self.startTags{i})
                    mask1 = mask1 | (self.tags{i}{channel1Index} > self.startTags{i}(j)) & (self.tags{i}{channel1Index} < self.endTags{i}(j));
                    mask2 = mask2 | (self.tags{i}{channel2Index} > self.startTags{i}(j)) & (self.tags{i}{channel2Index} < self.endTags{i}(j));
                end
                maskedChannel1tags = self.tags{i}{channel1Index}(mask1);
                maskedChannel2tags = self.tags{i}{channel2Index}(mask2);
                %"Bin" tags
                binnedChannel1tags = int32(round(maskedChannel1tags*82.3e-12/self.binWidth));
                binnedChannel2tags = int32(round(maskedChannel2tags*82.3e-12/self.binWidth));
                for j = negSteps:posSteps
                    self.g2numerator(j-negSteps+1) = self.g2numerator(j-negSteps+1) + length(intersect(binnedChannel1tags,binnedChannel2tags+j));
                    for k = -2:2
                        if k ~= 0
                            self.g2denominator(j-negSteps+1) = self.g2numerator(j-negSteps+1) + length(intersect(binnedChannel1tags,binnedChannel2tags+j+k*pulseSpacing));
                        end
                    end
                end
            end
        end
    end 
end

