classdef timeTaggerG2 < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tags = {};
        startTags = {};
        endTags = {};
        channelList = [];
        numShots = 0;
        %These are tau limits we are interested in for our correlation
        %function
        maxEdge = 1.5e-6;
        minEdge = -1.5e-6;
        binWidth = 25e-9;
        clockChannel = 2;
        pulseSpacing = 10e-6;
        pulseCorrDist = 2;
        g2numerator = [];
        g2denominator = [];
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
        function updateG2Outdated(self,channel1,channel2)
            posSteps = floor(self.maxEdge/self.binWidth);
            negSteps = ceil(self.minEdge/self.binWidth);
            binPulseSpacing = int32(self.pulseSpacing/self.binWidth);
            %This is just the mean time of each bin
            midTime = [negSteps:posSteps]*self.binWidth;
            %Find the tag index for channel 1 & 2
            channel1Index = find(self.channelList == channel1,1);
            channel2Index = find(self.channelList == channel2,1);
            %Make some vectors for the g2 numerator and denominator
            if isempty(self.g2numerator)
                self.g2numerator = zeros(1,length(midTime));
                self.g2denominator = zeros(1,length(midTime));
            end
            %Loop over each shot
            for j=1:length(self.numShots)
                endTimes = double(self.endTags{j})*82.3e-12;
                startTimes = double(self.startTags{j})*82.3e-12;
                histEdges = [0:self.binWidth:endTimes(end)];
                %Make the histograms for channel 1 and channel 2
                channel1hist = int32(histcounts(double(self.tags{j}{channel1Index})*82.3e-12,histEdges));
                channel2hist = int32(histcounts(double(self.tags{j}{channel2Index})*82.3e-12,histEdges));
                %histograms for the start and end times
                endhist = histcounts(endTimes,histEdges);
                starthist = histcounts(startTimes,histEdges);
                %Determine the mask for the data we care about
                mask = int32(zeros(1,length(starthist)));
                flipflop = 0;
                for i=1:length(mask)
                    if starthist(i) == 1
                        flipflop = 1;
                    end
                    mask(i) = flipflop;
                    if endhist(i) == 1
                        flipflop = 0;
                    end
                end
                %Apply the mask to both channel 1 and 2
                maskedChannel1hist = mask.*channel1hist;
                maskedChannel2hist = mask.*channel2hist;
                %Now let's calculate coincidence counts within a pulse
                for i = negSteps:posSteps
                    % tau < 0
                    if i < 0
                        self.g2numerator(i-negSteps+1) = self.g2numerator(i-negSteps+1) + sum(maskedChannel1hist(-i+1:end).*maskedChannel2hist(1:end+i))* (2*self.pulseCorrDist);
                        for k=-self.pulseCorrDist:self.pulseCorrDist
                            if k < 0
                                self.g2denominator(i-negSteps+1) = self.g2denominator(i-negSteps+1) + sum(maskedChannel1hist(-k*binPulseSpacing+1-i:end).*maskedChannel2hist(1:end+k*binPulseSpacing+i));
                            elseif k > 0
                                self.g2denominator(i-negSteps+1) = self.g2denominator(i-negSteps+1) + sum(maskedChannel1hist(1:end-k*binPulseSpacing-i).*maskedChannel2hist(k*binPulseSpacing+1+i:end));
                            end
                        end
                    % tau > 0
                    elseif i > 0
                        self.g2numerator(i-negSteps+1) = self.g2numerator(i-negSteps+1) + sum(maskedChannel1hist(1:end-i).*maskedChannel2hist(i+1:end))* (2*self.pulseCorrDist);
                        for k=-self.pulseCorrDist:self.pulseCorrDist
                            if k < 0
                                self.g2denominator(i-negSteps+1) = self.g2denominator(i-negSteps+1) + sum(maskedChannel1hist(-k*binPulseSpacing+1-i:end).*maskedChannel2hist(1:end+k*binPulseSpacing+i));
                            elseif k > 0
                                self.g2denominator(i-negSteps+1) = self.g2denominator(i-negSteps+1) + sum(maskedChannel1hist(1:end-k*binPulseSpacing-i).*maskedChannel2hist(k*binPulseSpacing+1+i:end));
                            end
                        end
                    % tau = 0
                    elseif i == 0
                        self.g2numerator(i-negSteps+1) = self.g2numerator(i-negSteps+1) + sum(maskedChannel1hist.*maskedChannel2hist) * (2*self.pulseCorrDist);
                        for k=-self.pulseCorrDist:self.pulseCorrDist
                            if k < 0
                                self.g2denominator(-negSteps+1) = self.g2denominator(-negSteps+1) + sum(maskedChannel1hist(-k*binPulseSpacing+1:end).*maskedChannel2hist(1:end+k*binPulseSpacing));
                            elseif k > 0
                                self.g2denominator(-negSteps+1) = self.g2denominator(-negSteps+1) + sum(maskedChannel1hist(1:end-k*binPulseSpacing).*maskedChannel2hist(k*binPulseSpacing+1:end));
                            end
                        end
                    end
                end
            end
        end
        function updateG2Test(self,channel1,channel2)
            posSteps = uint16(floor(self.maxEdge/self.binWidth));
            negSteps = uint16(-ceil(self.minEdge/self.binWidth));
            binPulseSpacing = int32(self.pulseSpacing/self.binWidth);
            %This is just the mean time of each bin
            midTime = [negSteps:posSteps]*self.binWidth;
            %Find the tag index for channel 1 & 2
            channel1Index = find(self.channelList == channel1,1);
            channel2Index = find(self.channelList == channel2,1);
            %Make some vectors for the g2 numerator and denominator
            if isempty(self.g2numerator)
                self.g2numerator = zeros(1,length(midTime));
                self.g2denominator = zeros(1,length(midTime));
            end
            %Loop over each shot
            for j=1:length(self.numShots)
                endTimes = double(self.endTags{j})*82.3e-12;
                startTimes = double(self.startTags{j})*82.3e-12;
                histEdges = [0:self.binWidth:endTimes(end)];
                %Make the histograms for channel 1 and channel 2
                channel1hist = uint16(histcounts(double(self.tags{j}{channel1Index})*82.3e-12,histEdges));
                channel2hist = uint16(histcounts(double(self.tags{j}{channel2Index})*82.3e-12,histEdges));
                %histograms for the start and end times
                endhist = histcounts(endTimes,histEdges);
                starthist = histcounts(startTimes,histEdges);
                %Determine the mask for the data we care about
                mask = uint16(zeros(1,length(starthist)));
                flipflop = 0;
                for i=1:length(mask)
                    if starthist(i) == 1
                        flipflop = 1;
                    end
                    mask(i) = flipflop;
                    if endhist(i) == 1
                        flipflop = 0;
                    end
                end
                %Apply the mask to both channel 1 and 2
                maskedChannel1hist = uint16(mask.*channel1hist);
                maskedChannel2hist = uint16(mask.*channel2hist);
                %Now let's calculate coincidence counts within a pulse
                self.g2numerator = self.g2numerator + getNumer(maskedChannel1hist,maskedChannel2hist,posSteps,negSteps);
                self.g2denominator = self.g2denominator + getDenom(maskedChannel1hist,maskedChannel2hist,posSteps,negSteps,binPulseSpacing);
            end
        end
        function updateG2Test2(self,channel1,channel2)
            posSteps = uint16(floor(self.maxEdge/self.binWidth));
            negSteps = uint16(-ceil(self.minEdge/self.binWidth));
            binPulseSpacing = int32(self.pulseSpacing/self.binWidth);
            %This is just the mean time of each bin
            midTime = [negSteps:posSteps]*self.binWidth;
            %Find the tag index for channel 1 & 2
            channel1Index = find(self.channelList == channel1,1);
            channel2Index = find(self.channelList == channel2,1);
            %Make some vectors for the g2 numerator and denominator
            if isempty(self.g2numerator)
                self.g2numerator = zeros(1,length(midTime));
                self.g2denominator = zeros(1,length(midTime));
            end
            for j=1:length(self.numShots)
                %Apply mask
                maskedChannel1 = transpose(testMask(uint32(self.tags{j}{channel1Index}),uint32(self.startTags{j}),uint32(self.endTags{j})));
                maskedChannel2 = transpose(testMask(uint32(self.tags{j}{channel2Index}),uint32(self.startTags{j}),uint32(self.endTags{j})));
                maskedChannel1(maskedChannel1==0)=[];
                maskedChannel2(maskedChannel2==0)=[];
                channel1bins = uint32(ceil(double(maskedChannel1)*82.3e-12/self.binWidth));
                channel2bins = uint32(ceil(double(maskedChannel2)*82.3e-12/self.binWidth));
                %Update numerator and denominator
                self.g2numerator = self.g2numerator + getNumer2(channel1bins,channel2bins,posSteps,negSteps);
                self.g2denominator = self.g2denominator + getDenom2(channel1bins,channel2bins,posSteps,negSteps,binPulseSpacing);
            end
        end
        function updateG2WithoutCross(self,channel1,channel2)
            posSteps = uint16(floor(self.maxEdge/self.binWidth));
            negSteps = uint16(-ceil(self.minEdge/self.binWidth));
            %binPulseSpacing = int32(self.pulseSpacing/self.binWidth);
            %This is just the mean time of each bin
            midTime = [negSteps:posSteps]*self.binWidth;
            %Find the tag index for channel 1 & 2
            channel1Index = find(self.channelList == channel1,1);
            channel2Index = find(self.channelList == channel2,1);
            %Make some vectors for the g2 numerator and denominator
            if isempty(self.g2numerator)
                self.g2numerator = zeros(1,length(midTime));
                %self.g2denominator = zeros(1,length(midTime));
            end
            for j=1:length(self.numShots)
                %Apply mask
                maskedChannel1 = transpose(testMask(uint32(self.tags{j}{channel1Index}),uint32(self.startTags{j}),uint32(self.endTags{j})));
                maskedChannel2 = transpose(testMask(uint32(self.tags{j}{channel2Index}),uint32(self.startTags{j}),uint32(self.endTags{j})));
                maskedChannel1(maskedChannel1==0)=[];
                maskedChannel2(maskedChannel2==0)=[];
                channel1bins = uint32(ceil(double(maskedChannel1)*82.3e-12/self.binWidth));
                channel2bins = uint32(ceil(double(maskedChannel2)*82.3e-12/self.binWidth));
                %Update numerator and denominator
                self.g2numerator = self.g2numerator + getNumer2(channel1bins,channel2bins,posSteps,negSteps);
                self.g2denominator(1) = self.g2denominator(1) + length(channel1bins);
                self.g2denominator(2) = self.g2denominator(2) + length(channel2bins);
            end
        end
        function [midTime,g2] = getG2(self)
            posSteps = floor(self.maxEdge/self.binWidth);
            negSteps = ceil(self.minEdge/self.binWidth);
            %This is just the mean time of each bin
            midTime = [negSteps:posSteps]*self.binWidth;
            g2 = double(self.g2numerator)./double(self.g2denominator)*4;
        end
        function [midTime,g2,g2err] = getFoldedG2(self)
            posSteps = floor(self.maxEdge/self.binWidth);
            negSteps = ceil(self.minEdge/self.binWidth);
            %Fold the numerator and denominator
            foldedNumerator = zeros(1,posSteps+1);
            foldedDenominator = zeros(1,posSteps+1);
            %For tau = 0
            foldedNumerator(1) = self.g2numerator(-negSteps+1);
            foldedDenominator(1) = self.g2denominator(-negSteps+1);
            for i=1:posSteps
                foldedNumerator(i+1) = self.g2numerator(-negSteps+1+i) + self.g2numerator(-negSteps+1-i);
                foldedDenominator(i+1) = self.g2denominator(-negSteps+1+i) + self.g2denominator(-negSteps+1-i);
            end
            %This is just the mean time of each bin
            midTime = [0:posSteps]*self.binWidth;
            g2 = foldedNumerator*4./foldedDenominator;
            g2err = 4*(foldedNumerator./(foldedDenominator.^2)+(foldedNumerator.^2)./(foldedDenominator.^3)).^(1/2);
        end
        function [channel1hist,channel2hist,posSteps,negSteps,binPulseSpacing] = getChannelHist(self,channel1,channel2)
            posSteps = uint16(floor(self.maxEdge/self.binWidth));
            negSteps = uint16(-ceil(self.minEdge/self.binWidth));
            binPulseSpacing = int32(self.pulseSpacing/self.binWidth);
            %Find the tag index for channel 1 & 2
            channel1Index = find(self.channelList == channel1,1);
            channel2Index = find(self.channelList == channel2,1);
            endTimes = double(self.endTags{1})*82.3e-12;
            startTimes = double(self.startTags{1})*82.3e-12;
            histEdges = [0:self.binWidth:endTimes(end)];
            %Make the histograms for channel 1 and channel 2
            channel1hist = uint16(histcounts(double(self.tags{1}{channel1Index})*82.3e-12,histEdges));
            channel2hist = uint16(histcounts(double(self.tags{1}{channel2Index})*82.3e-12,histEdges));
        end
        function [channel1bins,channel2bins,posSteps,negSteps,binPulseSpacing] = getChannelBins(self,channel1,channel2)
            posSteps = uint16(floor(self.maxEdge/self.binWidth));
            negSteps = uint16(-ceil(self.minEdge/self.binWidth));
            binPulseSpacing = int32(self.pulseSpacing/self.binWidth);
            %This is just the mean time of each bin
            midTime = [negSteps:posSteps]*self.binWidth;
            %Find the tag index for channel 1 & 2
            channel1Index = find(self.channelList == channel1,1);
            channel2Index = find(self.channelList == channel2,1);
            maskedChannel1 = self.tags{1}{channel1Index};
            maskedChannel2 = self.tags{1}{channel2Index};
            channel1bins = uint32(ceil(maskedChannel1*82.3e-12/self.binWidth));
            channel2bins = uint32(ceil(maskedChannel2*82.3e-12/self.binWidth));
        end
    end
end