classdef timeTaggerPulseMeasurement < handle
    %TIMETAGGERPULSEMEASUREMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        numShots = 1;
        min_time = 0e-6;
        max_time = 1.25e-6;
        bin_width = 10e-9;
        %experimental_losses = 0.71*0.802*.29;
        experimental_losses = 0.67*0.802*0.12;
        background_rate = 0;
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
            %Try and get channel list to auto update the experimental
            %losses
            try
                channel_list = h5read(filename,'/Inform/ChannelList');
                %Take the first channel and see what it is
                switch channel_list(1)
                    case 3
                        self.experimental_losses = 0.67*0.98*0.16;
                        self.background_rate = 82.5;
                    case 5
                        self.experimental_losses = 0.67*0.98*0.12;
                        self.background_rate = 82.5;
                    case 8
                        self.experimental_losses = 0.71*0.98*0.73;
                        self.background_rate = 9680;
                    otherwise
                end
            end
            for i = 1:length(clock_tags)
                high_words = high_words + bitand(clock_tags(i), 1);
            end
            self.cycles_per_shot = (double(length(clock_tags)) - double(high_words))/2.0;
            self.filename = filename;
            [self.tau,self.coinc] = pulseCalculator(self.filename, self.max_time, self.bin_width, self.min_time);
        end
        
        %Get the coincidences
        function runFit(self)
            self.tot_coinc = sum(self.coinc);
            self.photons_per_cycle = double(self.tot_coinc) / double(self.cycles_per_shot) / double(self.numShots) / double(self.experimental_losses);
        end
        
        %Export fit variables structure
        function fitVars = getFitVars(self)
            fitVars.('counts') = double(self.tot_coinc);
            fitVars.('photons_per_cycle') = self.photons_per_cycle;
            fitVars.('photons_per_cycle_minus_background') = self.photons_per_cycle - (self.max_time-self.min_time)*self.background_rate/self.experimental_losses;
            fitVars.('max_count') = double(max(self.coinc));
            fitVars.('TotalCycles') = double(self.cycles_per_shot);
        end
        
        %Get data for printing to live analysis
        function [counts, tau] = getPulsePlotData(self)
            tau = self.tau;
            counts = self.coinc;
        end
    end
    
end

