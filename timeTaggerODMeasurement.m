classdef timeTaggerODMeasurement < handle
    %Time tagger OD measurment class
    
    properties
        absorptionCount = 0;
        probeCount = 0;
        backgroundCount = 0;
        opticalDepth = 0;
        probeDetuning = 0; %Probe detuning in MHz
        linewidth = 6.0659 %Rb D2 linewidth in MHz
    end
    
    methods
        %Grab counts from file
        function loadFromFile(self,filename)
            self.absorptionCount = double(h5read(filename,'/Clicks/Absorption'));
            self.probeCount = double(h5read(filename,'/Clicks/Probe'));
            self.backgroundCount = double(h5read(filename,'/Clicks/Background'));
        end
        %Calculate the detuning adjusted OD
        function runFit(self)
            self.opticalDepth = ((self.absorptionCount-self.backgroundCount)/(self.probeCount-self.backgroundCount))*(1+(self.probeDetuning/self.linewidth)^2);
        end
        %Export fit variables structure
        function fitVars = getFitVars(self)
            fitVars.('opticalDepth') = self.opticalDepth;
            fitVars.('absorptionCount') = self.absorptionCount;
            fitVars.('probeCount') = self.probeCount;
            fitVars.('backgroundCount') = self.backgroundCount;
        end
    end
    
end

