classdef timeTaggerG3 < timeTaggerG2
    %TIMETAGGERG3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        g3numerator = [];
        g3denominator = [];
    end
    
    methods
        function updateG3(self,channel1,channel2,channel3)
            posSteps = uint16(floor(self.maxEdge/self.binWidth));
            negSteps = uint16(-ceil(self.minEdge/self.binWidth));
            binPulseSpacing = int32(self.pulseSpacing/self.binWidth);
            %This is just the mean time of each bin
            midTime = [negSteps:posSteps]*self.binWidth;
            %Find the tag index for channel 1 & 2
            channel1Index = find(self.channelList == channel1,1);
            channel2Index = find(self.channelList == channel2,1);
            channel3Index = find(self.channelList == channel3,1);
            %Make some vectors for the g3 numerator and denominator
            if isempty(self.g3numerator)
                self.g3numerator = zeros(length(midTime),length(midTime));
                self.g3denominator = zeros(length(midTime),length(midTime));
            end
            for j=1:length(self.numShots)
                %Apply mask
                maskedChannel1 = transpose(testMask(uint32(self.tags{j}{channel1Index}),uint32(self.startTags{j}),uint32(self.endTags{j})));
                maskedChannel2 = transpose(testMask(uint32(self.tags{j}{channel2Index}),uint32(self.startTags{j}),uint32(self.endTags{j})));
                maskedChannel3 = transpose(testMask(uint32(self.tags{j}{channel3Index}),uint32(self.startTags{j}),uint32(self.endTags{j})));
                maskedChannel1(maskedChannel1==0)=[];
                maskedChannel2(maskedChannel2==0)=[];
                maskedChannel3(maskedChannel3==0)=[];
                channel1bins = uint32(ceil(double(maskedChannel1)*82.3e-12/self.binWidth));
                channel2bins = uint32(ceil(double(maskedChannel2)*82.3e-12/self.binWidth));
                channel3bins = uint32(ceil(double(maskedChannel3)*82.3e-12/self.binWidth));
                %Update numerator and denominator
                self.g3numerator = self.g3numerator + getNumerg3(channel1bins,channel2bins,channel3bins,posSteps,negSteps);
                self.g3denominator = self.g3denominator + getDenomg3(channel1bins,channel2bins,channel3bins,posSteps,negSteps,binPulseSpacing);
            end
        end
        function [midTime,g3] = getG3(self)
            posSteps = floor(self.maxEdge/self.binWidth);
            negSteps = ceil(self.minEdge/self.binWidth);
            %This is just the mean time of each bin
            midTime = [negSteps:posSteps]*self.binWidth;
            g3 = double(self.g3numerator)./double(self.g3denominator)*12;
        end
        function [tau,g3,g3err] = getFoldedG3(self)
            posSteps = floor(self.maxEdge/self.binWidth);
            negSteps = ceil(self.minEdge/self.binWidth);
            %This is just the mean time of each bin
            tau = [0:posSteps]*self.binWidth;
            %Fold the numerator and denominator
            foldedNumerator = zeros(posSteps+1,posSteps+1);
            foldedDenominator = zeros(posSteps+1,posSteps+1);
            %For tau1,tau2 = 0
            foldedNumerator(1,1) = self.g3numerator(-negSteps+1,-negSteps+1);
            foldedDenominator(1,1) = self.g3denominator(-negSteps+1,-negSteps+1);
            %For tau1 = 0 , tau2=/=0
            for j=1:posSteps
                foldedNumerator(1,1+j) = self.g3numerator(-negSteps+1,-negSteps+1+j)+self.g3numerator(-negSteps+1,-negSteps+1-j);
                foldedDenominator(1,1+j) = self.g3denominator(-negSteps+1,-negSteps+1+j) + self.g3denominator(-negSteps+1,-negSteps+1-j);
            end
            %For tau1=/= 0 , tau2=0
            for i=1:posSteps
                foldedNumerator(1+i,1) = self.g3numerator(-negSteps+1+i,-negSteps+1)+self.g3numerator(-negSteps+1-i,-negSteps+1);
                foldedDenominator(1+i,1) = self.g3denominator(-negSteps+1+i,-negSteps+1) + self.g3denominator(-negSteps+1-i,-negSteps+1);
            end
            %For all other tau1 & tau2
            for i=1:posSteps
                for j=1:posSteps
                    foldedNumerator(1+i,1+j) = self.g3numerator(-negSteps+1+i,-negSteps+1+j) + self.g3numerator(-negSteps+1+i,-negSteps+1-j) + self.g3numerator(-negSteps+1-i,-negSteps+1+j) + self.g3numerator(-negSteps+1-i,-negSteps+1-j);
                    foldedDenominator(1+i,1+j) = self.g3denominator(-negSteps+1+i,-negSteps+1+j) + self.g3denominator(-negSteps+1+i,-negSteps+1-j) + self.g3denominator(-negSteps+1-i,-negSteps+1+j) + self.g3denominator(-negSteps+1-i,-negSteps+1-j);
                end
            end
            g3 = double(foldedNumerator)*12./double(foldedDenominator);
            g3err = 12*(foldedNumerator.*(foldedDenominator+foldedNumerator)./(foldedDenominator.^3)).^(1/2);
        end
    end
    
end

