classdef timeTaggerG2 < handle
    
    properties
        tags = {};
        endTags = [];
        channelList = [];
        numShots = 0;
        g2Matrix = [];
        %These are tau limits we are interested in for our correlation
        %function
        maxEdge = 1.5e-6;
        minEdge = -1.5e-6;
        binWidth = 25e-9;
    end
    
    methods
        function loadFromFile(self,filename)
            %Try and grab the number of shots (try included for backward
            %compatibility)
            try
                self.numShots = h5read(filename,'/Inform/Shots');
            end
            dummy = cell(self.numShots);
            %Read each tag window vector to the dummy cells
            for i=1:self.numShots
                dummy{i} = uint64(h5read(filename,sprintf('/Tags/TagWindow%i',i-1)));
            end
            %Also grab the starttime and endtime vector
            dummyStart = uint64(h5read(filename,'/Tags/StartTag'));
            dummyEnd = uint64(h5read(filename,'/Tags/EndTag'));
            %And the channel list
            self.channelList = h5read(filename,'/Inform/ChannelList');
            self.endTags = zeros([self.numShots,1]);
            %Expand tag array size
            self.tags = cell([self.numShots],1);
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
                self.tags{i} = dummy2;
                %And work out end time for window
                highCount = bitshift(dummyEnd(2*ip-1),-1)-bitshift(dummyStart(2*ip-1),-1);
                self.endTags(i) = bitand(bitshift(dummyEnd(2*ip),-1),2^27-1)+bitshift(highCount,27)-bitand(bitshift(dummyStart(2*ip),-1),2^27-1);
            end
        end
        function [midTime,g2] = calculateG2(self,channel1,channel2,binWidth)
            %These are tau limits we are interested in for our correlation
            %function
            maxEdge = 0.5e-6;
            minEdge = -0.5e-6;
            edges = [minEdge:binWidth:maxEdge];
            %This is just the mean time of each bin
            midTime = mean([edges(1:end-1);edges(2:end)]);
            %Variable to hold the total number of counts we recieve from
            %the second channel so we can normalise g2
            totChannel2Counts = 0;
            %Find the tag index for channel 1 & 2
            channel1Index = find(self.channelList == channel1,1);
            channel2Index = find(self.channelList == channel2,1);
            %Loop over each shot
            for j=1:length(self.numShots)
               %Grab tags for given shot and channel
                channel1Tags = self.tags{j}{channel1Index}*82e-12;
                channel2Tags = self.tags{j}{channel2Index}*82e-12;
                %Update the number of counts from channel 2
                totChannel2Counts = totChannel2Counts + length(channel2Tags);
                %Vector to help deal with the finite width of the
                %measurment window
                isNanVec = zeros([1,length(edges)-1]);
                %This is the coincidence vector which holds our binned coincidence
                %counts
                binnedCoincidenceCounts = zeros([1,length(edges)-1]);
                endTime = self.endTags(j)*82.3e-12;
                %Loop over each data point in channel 1's tag list
                for i=1:length(channel1Tags)
                    %Offset channel 2 tags so they are measured relative to
                    %the event we are looking at
                    %subVec = channel2Tags-channel1Tags(i);
                    %Make a histogram of the offset events and add it to
                    %our coincidence counts
                    binnedCoincidenceCounts = binnedCoincidenceCounts + histcounts(channel2Tags,edges+channel1Tags(i));
                    %If our channel 1 event happens within the histogram
                    %edge of the measurement window this prevents any bins
                    %that would lie outside the measurement window from
                    %counting towards g2
                    %If the channel 1 event is on the lower edge
                    if(channel1Tags(i) < -edges(1))
                        dummyNaN = ones([1,floor((maxEdge+channel1Tags(i))/binWidth)]);
                        isNanVec(length(isNanVec)-length(dummyNaN)+1:end) = isNanVec(length(isNanVec)-length(dummyNaN)+1:end) + dummyNaN;
                    %Or upper edge
                    elseif((endTime-channel1Tags(i)) < edges(end))
                        dummyNaN = ones([1,floor((-minEdge+channel1Tags(i))/binWidth)]);
                        isNanVec(1:length(dummyNaN)) = isNanVec(1:length(dummyNan)) + dummyNaN;
                    %If the event is safely within the histogram window
                    else
                        isNanVec = isNanVec+1;
                    end
                end
            end
            %Scale to account for the fact that there are edges to the
            %measurement window. This also effectively is a devision by the
            %number of counts in channel 1
            scaledCounts = binnedCoincidenceCounts./isNanVec;
            g2 = scaledCounts/totChannel2Counts * sum(self.endTags)*82.3e-12/binWidth;
        end
        function updateG2(self,channel1,channel2)
            posSteps = floor(self.maxEdge/self.binWidth);
            negSteps = ceil(self.minEdge/self.binWidth);
            %Find the tag index for channel 1 & 2
            channel1Index = find(self.channelList == channel1,1);
            channel2Index = find(self.channelList == channel2,1);
            tempG2Mat = zeros([self.numShots,posSteps-negSteps+1]);
            %Loop over each shot
            for j=1:self.numShots
               %Grab tags for given shot and channel
                channel1Tags = self.tags{j}{channel1Index}*82.3e-12;
                channel2Tags = self.tags{j}{channel2Index}*82.3e-12;
                %Check to see if either tags list is empty
                if (~isempty(channel1Tags))&&(~isempty(channel2Tags))
                    %Update the number of counts from channel 2
                    %Variable to hold the total number of counts we recieve from
                    %the second channel so we can normalise g2
                    totChannel2Counts = length(channel2Tags);
                    totChannel1Counts = length(channel1Tags);
                    %Vector to help deal with the finite width of the
                    %measurment window
                    contributingBins = zeros([1,posSteps-negSteps+1]);
                    %This is the coincidence vector which holds our binned coincidence
                    %counts
                    binnedCoincidenceCounts = zeros([1,posSteps-negSteps+1]);
                    channel2hist = histcounts(channel2Tags,[0:self.binWidth:self.endTags(j)*82.3e-12]);
                    channel1hist = histcounts(channel1Tags,[0:self.binWidth:self.endTags(j)*82.3e-12]);
                    % tau=0
                    binnedCoincidenceCounts(-negSteps+1) = sum(channel1hist.*channel2hist);
                    contributingBins(-negSteps+1) = length(channel1hist);
                    % tau<0
                    for i=negSteps:-1
                        binnedCoincidenceCounts(i-negSteps+1) = sum(channel1hist(-i+1:end).*channel2hist(1:end+i));
                        contributingBins(i-negSteps+1) = length(channel1hist)+i;
                    end
                    %tau > 0
                    for i=1:posSteps
                        binnedCoincidenceCounts(i-negSteps+1) = sum(channel1hist(1:end-i).*channel2hist(i+1:end));
                        contributingBins(i-negSteps+1) = length(channel1hist)-i;
                    end
                    tempG2Mat(j,:) = binnedCoincidenceCounts/(totChannel1Counts*totChannel2Counts)*length(channel1hist)^2./contributingBins;
                %Just ignore that line  
                else
                    tempG2Mat(j,:) = NaN([1,posSteps-negSteps+1]);
                end
            end
            if (isempty(self.g2Matrix))
                self.g2Matrix = tempG2Mat;
            else
                self.g2Matrix = [self.g2Matrix;tempG2Mat];
            end
        end
        function [midTime,g2] = getG2(self)
            posSteps = floor(self.maxEdge/self.binWidth);
            negSteps = ceil(self.minEdge/self.binWidth);
            %This is just the mean time of each bin
            midTime = [negSteps:posSteps]*self.binWidth;
            g2 = nanmean(self.g2Matrix);
        end
        function clearG2(self)
            self.g2Matrix = [];
        end
    end
    
end

