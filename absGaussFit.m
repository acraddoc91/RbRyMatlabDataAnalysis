classdef absGaussFit < absorptionImageFitting
    %Class for an absorption imaging gaussian cloud fit
    
    properties
        %Perhaps should find some other way to set pixel size that is more
        %appropriate
        centreX=0;
        centreY=0;
        xCoffs=[0,1,900,300];
        yCoffs=[0,1,500,300];
        %Define the gaussian fitting function
        gauss = @(coffs,x) transpose(coffs(1)+coffs(2).*exp(-(x-coffs(3)).^2/(2*coffs(4).^2)));
        %Define lower bounds so we don't end up with negative sigmas and
        %whatnot
        lowerBounds = [-Inf,-Inf,0,0];
        opts = optimset('Display','off');
    end
    
    methods
        %Constructor just to set ROI and rotation
        function obj = absGaussFit()
            %obj.roiPoints = [800-45,435-20,90,40];
            %obj.roiPoints = [659-75,415-25,150,50]; %vertical 26/1/2018
            %obj.roiPoints = [652-30,437-15,60,30]; %vertical 26/1/2018
            %obj.roiPoints = [611-40,552-15,80,30]; %vertical 25/2/2018
            %obj.roiPoints = [618-35,551-15,70,30]; %vertical 6/3/2018
            %obj.roiPoints = [610-25,551-15,50,30]; %vertical 16/4/2018
            %obj.roiPoints = [611-30,552-15,60,30]; %26/4/2018
           %obj.roiPoints = [610-40,545-30,80,60]; %26/4/2018
           %obj.roiPoints = [595-50,548-40,100,80]; %4/10/2018
          obj.roiPoints = [605-50,552-40,100,80]; %25/10/2018
            %obj.roiPoints = [591-40,551-15,80,30];
            %obj.roiPoints = [614-75,565-25,150,50];
            %obj.roiPoints = [637-350,442-100,700,200];
            %obj.roiPoints = [0,432-20,850,40];
            %obj.roiPoints = [690-50,583-25,100,50]; %horizontal
       %   obj.roiPoints = [955-80,583-20,160,40]; %side 4/10/2018 last
            %obj.roiPoints = [833-45,527-11,90,22]; %side 5/3/2018 
            %obj.roiPoints = [585-75,565-75,150,150]; %side 26/1/2018
            %obj.roiPoints = [960-75,580-25,150,50]; %horizontal 23/1/2018
            %obj.roiPoints = [5.545100000000000e+02,10.055100000000000e+02,0.889800000000000e+02,0.289800000000000e+02];
        end
        %Manually set the coordinates to the cloud centre
        function goodPoint = setCentreCoordinates(self,centreXIn,centreYIn)
            %Check centre is within ROI
            ROI = self.getROI();
            if centreXIn > ROI(1) && centreXIn < ROI(1)+ROI(3) && centreYIn > ROI(2) && centreYIn < ROI(2)+ROI(4)
                %Set location of the centre of the cloud
                self.centreX = centreXIn - ROI(1);
                self.centreY = centreYIn - ROI(2);
                self.xCoffs(3) = self.centreX;
                self.yCoffs(3) = self.centreY;
                goodPoint = true;
            else
                goodPoint = false;
            end
        end
        %Automagically find the centre of the cloud
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
            self.xCoffs(3) = self.centreX;
            self.yCoffs(3) = self.centreY;
        end
        %Fit the cloud in the X direction
        function runXFit(self)
            cutImage = self.getCutImage;
            [ysiz,~]=size(cutImage);
            if(self.centreY-5 < 1)
                xVec = sum(cutImage(1:self.centreY+5,:),1)/(self.centreY+5);
            elseif(self.centreY+5 > ysiz)
                xVec = sum(cutImage(self.centreY-5:ysiz,:),1)/(ysiz-self.centreY+5);
            else
                xVec = sum(cutImage(self.centreY-5:self.centreY+5,:),1)/11;
            end
            self.xCoffs(2) = max(xVec);
            xPix = transpose([1:length(xVec)]);
            try
                self.xCoffs = lsqcurvefit(self.gauss,self.xCoffs,xPix,xVec,self.lowerBounds,[],self.opts);
            catch ME
                self.xCoffs = [NaN,NaN,NaN,NaN];
            end
        end
        %Fit the cloud in the Y direction
        function runYFit(self)
            cutImage = self.getCutImage;
            [~,xsiz]=size(cutImage);
            if(self.centreX-5 < 1)
                yVec = sum(cutImage(:,1:self.centreX+5),2)/(self.centreX+5);
            elseif(self.centreX+5 > xsiz)
                yVec = sum(cutImage(:,self.centreX-5:xsiz),2)/(xsiz-self.centreX+5);
            else
                yVec = sum(cutImage(:,self.centreX-5:self.centreX+5),2)/11;
            end
            self.yCoffs(2) = max(yVec);
            yPix = [1:length(yVec)];
            try
                self.yCoffs = lsqcurvefit(self.gauss,self.yCoffs,yPix,yVec,self.lowerBounds,[],self.opts);
            catch ME
                self.yCoffs = [NaN,NaN,NaN,NaN];
            end
        end
        %Run both fits, included for brevity in other locations
        function runFits(self)
            self.runXFit();
            self.runYFit();
        end
        %Plot the x directional slice of the cloud with its fit
        function plotX(self)
            cutImage = self.getCutImage;
            [ysiz,~]=size(cutImage);
            if(self.centreY-5 < 1)
                xVec = sum(cutImage(1:self.centreY+5,:),1)/(self.centreY+5);
            elseif(self.centreY+5 > ysiz)
                xVec = sum(cutImage(self.centreY-5:ysiz,:),1)/(ysiz-self.centreY+5);
            else
                xVec = sum(cutImage(self.centreY-5:self.centreY+5,:),1)/11;
            end
            spatialVec = self.pixSize/self.magnification * [1:length(xVec)]- self.pixSize/self.magnification * self.centreX;
            plot(spatialVec,xVec,'.')
            hold all
            plot(spatialVec,self.gauss(self.xCoffs,[1:length(xVec)]))
            hold off
            xlabel('Distance in X direction (\mum)')
            ylabel('OD')
            legend('x-data',sprintf('\\sigma_x = %.0f\\mum',self.xCoffs(4)*self.pixSize/self.magnification),'Location','northwest');
            legend('boxoff');
        end
        %Plot the y directional slice of the cloud with its fit
        function plotY(self)
            cutImage = self.getCutImage;
            [~,xsiz]=size(cutImage);
            if(self.centreX-5 < 1)
                yVec = sum(cutImage(:,1:self.centreX+5),2)/(self.centreX+5);
            elseif(self.centreX+5 > xsiz)
                yVec = sum(cutImage(:,self.centreX-5:xsiz),2)/(xsiz-self.centreX+5);
            else
                yVec = sum(cutImage(:,self.centreX-5:self.centreX+5),2)/11;
            end
            spatialVec = self.pixSize/self.magnification * [1:length(yVec)]- self.pixSize/self.magnification * self.centreY;
            plot(spatialVec,yVec,'.')
            hold all
            plot(spatialVec,self.gauss(self.yCoffs,[1:length(yVec)]))
            hold off
            xlabel('Distance in Y direction (\mum)')
            ylabel('OD')
            legend('y-data',sprintf('\\sigma_y = %.0f\\mum',self.yCoffs(4)*self.pixSize/self.magnification),'Location','northwest');
            legend('boxoff');
        end
        %Return centre coordinates
        function centreCoords = getCentreCoordinates(self)
            centreCoords.('centreX_pix') = self.centreX + self.roiPoints(1);
            centreCoords.('centreY_pix') = self.centreY + self.roiPoints(2);
        end
        %Output fit values (specifically the x & y sigma atm) to a
        %structure
        function fitVars = getFitVars(self)
            %note sigmaX & sigmaY are in micrometres
            fitVars.('sigmaX_um') = self.xCoffs(4)*self.pixSize/self.magnification;
            fitVars.('sigmaY_um') = self.yCoffs(4)*self.pixSize/self.magnification;
            fitVars.('calcCentreX_pix') = self.xCoffs(3)+self.roiPoints(1);
            fitVars.('calcCentreY_pix') = self.yCoffs(3)+self.roiPoints(2);
            fitVars.('N_atoms') = self.atomNumber;
            fitVars.('rotAngle') = self.rotationAngle;
            fitVars.('peakODx') = self.xCoffs(1)+self.xCoffs(2);
            fitVars.('peakODy') = self.yCoffs(1)+self.yCoffs(2);
        end
    end
    
end