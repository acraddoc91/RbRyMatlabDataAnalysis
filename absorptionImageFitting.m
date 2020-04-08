classdef absorptionImageFitting < basicImageFittingClass
    %Class for absorption image fitting
    
    properties
        atomNumber = 0;
    end
    
    methods
        %Function to load a .h5 file up and extract the processed image
        function loadFromFile(self,filename)
            %Grab the images from file
            absorption = double(h5readImage(filename,'/Images/Absorption'));
            probe = double(h5readImage(filename,'/Images/Probe'));
            background = double(h5readImage(filename,'/Images/Background'));
            %From the absorption, probe and background images get the processed OD
            %image
            self.setProcessedImage(-real(log((absorption-background)./(probe-background))));
        end
        %Function to determine atom number
        function calculateAtomNumber(self,imagingDetuning,imagingIntensity)
            %values for 87Rb D2 line
            gam = 38.116 * 10^6;
            %isat = 1.6692*10^(-3); %W/cm^2 for sigma_\pm polarised light
            isat = 2.5033*10^(-3); %W/cm^2 for pi polarised light
            hbar = 1.0545718*10^(-34);
            omega = 2*pi*384.2281152028*10^12;
            sig0 = hbar*omega*gam/(2*isat);
            sig = sig0/(1+4*(2*pi*imagingDetuning*10^6/gam)^2+(imagingIntensity/(isat))) * 10^-4; %in m^2
            procImage = self.getCutImage();
            procImage(procImage<0) = 0; %set any values of procImage which have a negative OD, which comes about because of interference in the image
            self.atomNumber = sum(sum(procImage))*(self.pixSize*10^(-6)/self.magnification)^2/sig;
        end
        function atomNum = getAtomNumber(self)
            atomNum = self.atomNumber;
        end
    end
    
end

