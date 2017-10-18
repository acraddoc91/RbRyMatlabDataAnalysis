classdef andorAbsorptionImage < basicImageFittingClass
    %Class for absorption image fitting
    
    properties
        atomNumber = 0;
        absorption = [];
        probe = [];
        background = [];
        roi = [1,1,1024,1024];
    end
    
    methods
        %Function to load a .h5 file up and extract the processed image
        function loadFromFile(self,filename)
            if(isempty(self.absorption))
                %Grab the images from file
                self.absorption = imcrop(double(h5readImage(filename,'/Images/Absorption')),self.roi);
                self.probe = imcrop(double(h5readImage(filename,'/Images/Probe')),self.roi);
                self.background = imcrop(double(h5readImage(filename,'/Images/Background')),self.roi);
            else
                %Grab the images from file
                self.absorption = self.absorption + imcrop(double(h5readImage(filename,'/Images/Absorption')),self.roi);
                self.probe = self.probe + imcrop(double(h5readImage(filename,'/Images/Probe')),self.roi);
                self.background = self.background + imcrop(double(h5readImage(filename,'/Images/Background')),self.roi);
            end
        end
        function transmissionImage = getTransmissionImage(self)
            transmissionImage = (self.absorption-self.background)./(self.probe-self.background);
        end
    end
    
end

