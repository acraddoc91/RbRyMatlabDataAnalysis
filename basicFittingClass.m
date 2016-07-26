classdef basicFittingClass < handle
    %Superclass for all fitting subclasses, should not be used directly but
    %serves as a framework for someone wanting to make their own fitting
    %class
    
    %Define some general properties here that are general to all fitting
    %classes
    properties
        processedImage = 0;
        roiPoints;
        rotationAngle=0;
        magnification=1.0;
        pixSize=3.69;
    end
    
    %And some methods which should be general to all fitting classes
    methods
        %Set the processed image of our object to that passed in the method
        function setProcessedImage(self,procImageIn)
            %remove infinities and NaNs which screw things up
            procImageIn(isinf(procImageIn))=0;
            procImageIn(isnan(procImageIn))=0;
            self.processedImage = procImageIn;
            %Check if a ROI has been set yet and if not just make a
            %standard ROI
            if isempty(self.roiPoints)
                %fliplr function needed as imcrop function operates weirdly and
                %requires the indicies in the order [x,y,width,height] which is
                %the opposite order to the way the size function operates
                self.roiPoints = [1,1,fliplr(size(imrotate(self.processedImage,self.rotationAngle)))];
                %If the above is too computationally expensive then you can
                %set ROI using
                %imSize = size(self.processedImage);
                %testRoi =
                %[1,1,ceil(abs(cos(self.rotationAngle*pi/180))*imSize(2)+abs(sin(self.rotationAngle*pi/180))*imSize(1)),ceil(abs(cos(self.rotationAngle*pi/180))*imSize(1)+abs(sin(self.rotationAngle*pi/180))*imSize(2))];
            end
        end
        %Do a contour plot of the processed image
        function plotProcessedImage(self)
            contour(self.processedImage);
        end
        %Get the processed image
        function procImageOut = getCutImage(self)
            %rotate the image by the rotation angle and apply the ROI to
            %give the output
            rotImage = imrotate(self.processedImage,self.rotationAngle);
            procImageOut = imcrop(rotImage,self.roiPoints);
        end
        %return the region of interest
        function roiOut = getROI(self)
            roiOut = self.roiPoints;
        end
        %set the region of interest
        function setRoi(self,roiIn)
            self.roiPoints = roiIn;
        end
        %set rotation angle
        function setRotationAngle(self,rotationAngle)
            self.rotationAngle = rotationAngle; 
        end
        %get rotation angle
        function rotAngleOut = getRotationAngle(self)
            rotAngleOut = self.rotationAngle;
        end
        %Function to set the magnification of the lens system used to
        %produce the shot
        function setMagnification(self,mag)
            self.magnification = mag;
        end
    end
end

