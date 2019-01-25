classdef timeTaggerPulseMeasurement < handle
    %TIMETAGGERPULSEMEASUREMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        numShots = 1;
        min_time = 1e-6;
        max_time = 2.5e-6;
        bin_width = 10e-9;
        experimental_losses = 0.2;
        filename = '';
        tot_coinc = 0;
        cycles_per_shot = 1;
        photons_per_cycle = 0;
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
            clock_tags = h5read(filename,'/Tags/ClockTags0');
            high_words = 0;
            for i = 1:length(clock_tags)
                high_words = high_words + bitand(clock_tags(i), 1);
            end
            self.cycles_per_shot = double(length(clock_tags)) - double(high_words);
            self.filename = filename;
            [self.tau,self.coinc] = pulseCalculator(self.filename, self.max_time, self.bin_width, self.min_time);
        end
        
        %Get the coincidences
        function runFit(self)
            self.tot_coinc = sum(self.coinc);
            self.photons_per_cycle = double(self.tot_coinc) / self.cycles_per_shot / double(self.numShots) / self.experimental_losses;
        end
        
        %Export fit variables structure
        function fitVars = getFitVars(self)
            fitVars.('counts') = self.tot_coinc;
            fitVars.('photons_per_cycle') = self.photons_per_cycle;
        end
        
        %Get data for printing to live analysis
        function [counts, tau] = getPulsePlotData(self)
            tau = self.tau;
            counts = self.coinc;
        end
    end
    
end

