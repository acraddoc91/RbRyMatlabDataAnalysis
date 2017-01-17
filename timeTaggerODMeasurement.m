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
        %Grab tags from file
        function loadFromFile(self,filename)
            %Try and grab the number of shots (try included for backward
            %compatibility)
            try
                self.numShots = h5read(filename,'/Inform/Shots');
                isModulation = h5read(filename,'/Inform/TrapModulation');
                if isModulation
                    self.numModulationWindows = h5read(filename,'/Inform/ModulationWindows');
                end
            end
            dummy = {};
            %Read each tag window vector to the dummy cells
            if isModulaton
                for i=1:self.numShots*self.numModulationWindows*2+1
                    dummy{end+1} = h5read(filename,sprintf('/Tags/TagWindow%i',i-1));
                end
            else
                for i=1:self.numShots*3
                    dummy{end+1} = h5read(filename,sprintf('/Tags/TagWindow%i',i-1));
                end
            end
            %Also grab the starttime vector
            dummyStart = h5read(filename,'/Tags/StartTag');
            %Loop over the number of shots (multiplied by three for
            %absorption)
            for i=1:length(dummy)
                %Reset highcount to 0
                highCount = 0;
                %Grab the vector from the dummy cell structure
                dummy3 = cell2mat(dummy(i));
                dummy2 = [];
                %Loop over the number of tags
                for j=1:length(dummy3)
                    %If the tag is a highword up the high count
                    if bitget(dummy3(j),1)==1
                        highCount = bitshift(dummy3(j),-1)-bitshift(dummyStart(2*i-1),-1);
                        %Otherwise figure the absolute time since the window
                        %opened and append it to the dummy vector
                    else
                        dummy2 = [dummy2,bitand(bitshift(dummy3(j),-1),2^28-1)+bitshift(highCount,27)-bitand(bitshift(dummyStart(2*i),-1),2^28-1)];
                    end
                 end
                 %Figure out which tag set the dummy tags belong to and send
                 %them to the correct vector
                 if isModulation
                     if rem(i,2*self.numModulationWindows+1) <= self.numModulationWindows
                         self.absorptionTags = [self.absorptionTags,dummy2];
                     elseif rem(i,2*self.numModulationWindows+1) <= 2*self.numModulationWindows
                         self.probeTags = [self.absorptionTags,dummy2];
                     else
                         self.backgroundTags = [self.backgroundTags,dummy2];
                     end
                 else
                     switch rem(i,3)
                        case 1
                            self.absorptionTags = [self.absorptionTags,dummy2];
                        case 2
                            self.probeTags = [self.probeTags,dummy2];
                        case 0
                            self.backgroundTags = [self.backgroundTags,dummy2];
                     end
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
        %This function takes the time tags and bins them into various time
        %bins it then works out the OD for each time bin and spits that out
        %as a column vector (ODTime) along with the mid-time of each bin
        function [ODTime,midTime] = getODPlotData(self)
            numBins = 20;
            edges = [0:round(double(self.probeTags(end))*82.3e-12,3)/numBins:round(double(self.probeTags(end))*82.3e-12,3)];
            probeTimeCounts = histcounts(double(self.probeTags)*82.3e-12,edges);
            absTimeCounts = histcounts(double(self.absorptionTags)*82.3e-12,edges);
            avgBackCounts = double(length(self.backgroundTags))/double(length(edges));
            ODTime = -real(log((absTimeCounts-avgBackCounts)./(probeTimeCounts-avgBackCounts))*(1+(self.probeDetuning/self.linewidth)^2));
            midTime = mean([edges(1:end-1);edges(2:end)]);
        end
        function [absTimeCounts,midTime] = getAbsPlotData(self)
             numBins = 20;
            edges = [0:round(double(self.probeTags(end))*82.3e-12,3)/numBins:round(double(self.probeTags(end))*82.3e-12,3)];
            absTimeCounts = histcounts(double(self.absorptionTags)*82.3e-12,edges);
            midTime = mean([edges(1:end-1);edges(2:end)]);
        end
    end
    
end

