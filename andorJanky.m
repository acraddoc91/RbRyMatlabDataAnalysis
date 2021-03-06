classdef andorJanky < basicImageFittingClass
    %ANDORJANKY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %roi = [0,0,1024,1024];
        roi = [573-50,469-50,100,100];
    end
    
    methods
        function loadFromFile(self,filename)
            if(isempty(self.processedImage))
                %Grab the images from file
                self.processedImage = imcrop(double(h5readImage(filename,'/Images/Single Image')),self.roi);
            else
                %Grab the images from file
                self.processedImage = self.processedImage + imcrop(double(h5readImage(filename,'/Images/Single Image')),self.roi);
            end
        end
    end
    
end

