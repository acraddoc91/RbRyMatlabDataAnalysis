function [ tau,coinc ] = pulseCalculator( filename, max_time, bin_width, min_time )
%PULSECALCULATOR Summary of this function goes here
%   Detailed explanation goes here
    int_bin_width = round(bin_width/(82.3e-12*2)) * (82.3e-12*2);
    int_max_time = round(max_time/int_bin_width)*int_bin_width;
    int_min_time = round(min_time/int_bin_width)*int_bin_width;
    
    [coinc,tau] = mexPulseCalculator(filename,int_max_time,int_bin_width,int_min_time);

end

