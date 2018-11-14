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
            %obj.setRotationAngle(8);
            %obj.roiPoints = [300,870,400,80];
            %For z-axis imaging
            %obj.rotationAngle = 0;
            %Old ROI for z-axis imaging
            %obj.roiPoints = [983,424,359,176];
            %New ROI for z-axis imaging
            %obj.roiPoints = [400,600,600,300];
           % obj.roiPoints=[635, 670, 80, 50]         
           
          
         %obj.roiPoints = [623-50,364-25,100,50];
         %obj.roiPoints = [635-47,385-30,76,25]; %before Jan26 17
         %obj.roiPoints = [650-47,385-30,76,25]; %after Jan26 17 to March
         %8th17
           %obj.roiPoints = [650-65,385-22,76,25]; %currently using
           
          % obj.roiPoints = [650-72,385-27,95,30]; %currently using changed 3 pixels made bigger ROI to see the dipole at resonance 
            %obj.roiPoints = [626-300,373-150,600,300]; %sandy 04/12                            
            
            %obj.roiPoints = [626-600,373-220,800,300]; %dipole focus? 04/12
            %obj.roiPoints = [980,350,75,300]%vertical direction dipole
            %bj.roiPoints = [320,850,600,480]%vertical direction molasses
            %obj.roiPoints = [706-30,326-15,60,30]
           % obj.roiPoints = [2.595100000000000e+02,0.510000000000000,8.849800000000000e+02,6.699800000000000e+02]
           %obj.roiPoints = [719-300,404-100,600,200];
           %obj.roiPoints = [855-35,404-15,70,30];
           %obj.roiPoints = [825-40,430-20,80,40];%Using May 16017
          % obj.roiPoints = [812-30,436-10,60,20];%Using June 8 2017
           % obj.roiPoints = [812-30,436-10,60,20];%Using June 8 2017
           %obj.roiPoints = [808-50,440-25,100,50];%Using June 27 2017
           %obj.roiPoints = [800-35,442-15,70,30];%Using Sept 4
           
           %obj.roiPoints = [815-75,428-25,150,50];%Using Sept 14
           %obj.roiPoints = [810-40,432-15,80,30]; %Using Oct 5, founs the best focus at 810 it was at 822 after realignment
         %obj.roiPoints = [820-80,444-20,160,40];%Using  Sept 19 vertical
         % obj.roiPoints = [1064-150,478-40,300,80];%Using  Sept 19 horizontal
            % obj.roiPoints = [770-50,442-20,100,40];%Dipole 1064 31 August
            % 2017 high OD Not good for 1012
           %obj.roiPoints = [810-100,425-50,200,100];
          %  obj.roiPoints = [719-10,404-10,55,25];
         %obj.roiPoints = [740-40,434-15,80,30];
          %obj.roiPoints = [753-15,434-215,30,430]; %dimple imaging
          obj.roiPoints = [611-40,552-40,80,80]; %Sandy 4/26/2018 
          % obj.roiPoints = [611-25,552-15,50,30];
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
            %Determine the maximum of this collapsed vector for both columns and
            %rows to find the approximate middle of the cloud.
            [~,maxCol] = max(summedRows);
            [~,maxRow] = max(summedCols);
            self.centreX = maxCol;
            self.centreY = maxRow;
        end
        %Plot the x directional slice of the cloud with its fit
        function plotX(self)
            cutImage = self.getCutImage;
            [ysiz,~]=size(cutImage);
            if(self.centreY-10 < 1)
                xVec = sum(cutImage(1:self.centreY+2,:),1)/(self.centreY+2);
            elseif(self.centreY+10 > ysiz)
                xVec = sum(cutImage(self.centreY-2:ysiz,:),1)/(ysiz-self.centreY+2);
            else
                xVec = sum(cutImage(self.centreY-2:self.centreY+2,:),1)/5;
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
                yVec = sum(cutImage(:,1:self.centreX+2),2)/(self.centreX+2);
            elseif(self.centreX+10 > xsiz)
                yVec = sum(cutImage(:,self.centreX-2:xsiz),2)/(xsiz-self.centreX+2);
            else
                yVec = sum(cutImage(:,self.centreX-2:self.centreX+2),2)/5;
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

