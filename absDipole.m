classdef absDipole < absorptionImageFitting
    %Class for doing stuff with dipole trap images
    
    properties
        centreX=0;
        centreY=0;
    end
    
    methods
        %Constructor just to set ROI and rotation
        function obj = absDipole()
            %For y-axis imaging
            obj.setRotationAngle(8);
            obj.roiPoints = [683,597,426,72];
            %For z-axis imaging
            %obj.rotationAngle = 0;
            %obj.roiPoints = [983,424,359,176];
        end
        %Manually set the coordinates to the cloud centre
        function goodPoint = setCentreCoordinates(self,centreXIn,centreYIn)
            %Check centre is within ROI
            ROI = self.getROI();
            if centreXIn > ROI(1) && centreXIn < ROI(1)+ROI(3) && centreYIn > ROI(2) && centreYIn < ROI(2)+ROI(4)
                %Set location of the centre of the cloud
                self.centreX = centreXIn - ROI(1);
                self.centreY = centreYIn - ROI(2);
                goodPoint = true;
            else
                goodPoint = false;
            end
        end
        %Automagically find the centre of the trap
        function findCentreCoordinates(self)
            %Sum over the columns and rows respectively to collapse the processed
            %image down into a a vector
            summedRows = sum(self.getCutImage,1);
            summedCols = sum(self.getCutImage,2);
            %Determine the minimum of this collapsed vector for both columns and
            %rows to find the approximate middle of the cloud.
            [~,minCol] = min(summedRows);
            [~,minRow] = min(summedCols);
            self.centreX = minCol;
            self.centreY = minRow;
        end
        %Plot the x directional slice of the cloud with its fit
        function plotX(self)
            cutImage = self.getCutImage;
            [ysiz,~]=size(cutImage);
            if(self.centreY-10 < 1)
                xVec = sum(cutImage(1:self.centreY+10,:),1)/(self.centreY+10);
            elseif(self.centreY+10 > ysiz)
                xVec = sum(cutImage(self.centreY-10:ysiz,:),1)/(ysiz-self.centreY+10);
            else
                xVec = sum(cutImage(self.centreY-10:self.centreY+10,:),1)/21;
            end
            spatialVec = self.pixSize/self.magnification * [1:length(xVec)]- self.pixSize/self.magnification * self.centreX;
            plot(spatialVec,xVec,'.')
            xlabel('Distance in X direction (\mum)')
            ylabel('OD')
        end
        %Plot the y directional slice of the cloud with its fit
        function plotY(self)
            cutImage = self.getCutImage;
            [~,xsiz]=size(cutImage);
            if(self.centreX-10 < 1)
                yVec = sum(cutImage(:,1:self.centreX+10),2)/(self.centreX+10);
            elseif(self.centreX+10 > xsiz)
                yVec = sum(cutImage(:,self.centreX-10:xsiz),2)/(xsiz-self.centreX+10);
            else
                yVec = sum(cutImage(:,self.centreX-10:self.centreX+10),2)/21;
            end
            spatialVec = self.pixSize/self.magnification * [1:length(yVec)]- self.pixSize/self.magnification * self.centreY;
            plot(spatialVec,yVec,'.')
            xlabel('Distance in Y direction (\mum)')
            ylabel('OD')
        end
        %Output fit values (specifically the x & y sigma atm) to a
        %structure
        function fitVars = getFitVars(self)
            fitVars.('N_atoms') = self.atomNumber;
            fitVars.('rotAngle') = self.rotationAngle;
        end
        %Return centre coordinates
        function centreCoords = getCentreCoordinates(self)
            centreCoords.('centreX_pix') = self.centreX + self.roiPoints(1);
            centreCoords.('centreY_pix') = self.centreY + self.roiPoints(2);
        end
    end
    
end

