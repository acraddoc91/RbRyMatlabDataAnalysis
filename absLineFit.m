classdef absLineFit < absorptionImageFitting
    %ABSLINEFIT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        centreX=0;
    end
    
    methods
        function obj = absLineFit()
            obj.roiPoints = [609-10,541-540,20,1080];
        end
        function fitVars = getFitVars(self)
            fitVars.('N_atoms') = self.atomNumber;
        end
    end
    
end

