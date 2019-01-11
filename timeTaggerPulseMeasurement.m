classdef timeTaggerPulseMeasurement < handle
    %TIMETAGGERPULSEMEASUREMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        numShots = 1;
        min_time = 1e-6;
        max_time = 2.5e-6;
        bin_width = 10e-9;
        filename = '';
        tot_coinc = 0;
        coinc = [];
        tau = [];
    end
    
    methods
        %Grab tags from file
        function loadFromFile(self,filename)
            %Try and grab the number of shots (try included for backward
            %compatibility)
            try
                self.numShots = h5read(filename,'/Inform/Shots');
            end
            self.filename = filename;
            [self.tau,self.coinc] = pulseCalculator(self.filename, self.max_time, self.bin_width, self.min_time);
        end
        
        %Get the coincidences
        function runFit(self)
            self.tot_coinc = sum(self.coinc);
        end
        
        %Export fit variables structure
        function fitVars = getFitVars(self)
            fitVars.('counts') = self.tot_coinc;
        end
        
        %Get data for printing to live analysis
        function [counts, tau] = getPulsePlotData(self)
            tau = self.tau;
            counts = self.coinc;
        end
    end
    
end

