classdef absGaussFit < basicFittingClass
    %Class for an absorption imaging gaussian cloud fit
    
    properties
        %Perhaps should find some other way to set pixel size that is more
        %appropriate
        pixSize=3.69;
        magnification=1.0;
        centreX=0;
        centreY=0;
        xCoffs=[0,1,900,300];
        yCoffs=[0,1,500,300];
        %Define the gaussian fitting function
        gauss = @(coffs,x) transpose(coffs(1)-coffs(2).*exp(-(x-coffs(3)).^2/(2*coffs(4).^2)));
        opts = optimset('Display','off');
    end
    
    methods
        %Function to load a .h5 file up and extract the processed image
        function loadFromFile(self,filename)
            %Grab the images from file
            absorption = double(h5read(filename,'/Images/Absorption'));
            probe = double(h5read(filename,'/Images/Probe'));
            background = double(h5read(filename,'/Images/Background'));
            %From the absorption, probe and background images get the processed OD
            %image
            self.setProcessedImage(real(log((absorption-background)./(probe-background))));
        end
        %Manually set the coordinates to the cloud centre
        function goodPoint = setCentreCoordinates(self,centreXIn,centreYIn)
            %Check centre is within ROI
            ROI = self.getROI();
            if centreXIn > ROI(1) && centreXIn < ROI(3) && centreYIn > ROI(2) && centreYIn < ROI(4)
                %Set location of the centre of the cloud
                self.centreX = centreXIn;
                self.centreY = centreYIn;
                goodPoint = true;
            else
                goodPoint = false;
            end
        end
        %Automagically find the centre of the cloud
        function findCentreCoordinates(self)
            %Sum over the columns and rows respectively to collapse the processed
            %image down into a a vector
            summedCols = sum(self.getProcessedImageROI,1);
            summedRows = sum(self.getProcessedImageROI,2);
            %Determine the minimum of this collapsed vector for both columns and
            %rows to find the approximate middle of the cloud.
            [~,minCol] = min(summedRows);
            [~,minRow] = min(summedCols);
            self.centreX = minCol;
            self.centreY = minRow;
        end
        %Fit the cloud in the X direction
        function runXFit(self)
            processedImage = self.getProcessedImage();
            xVec = sum(processedImage(:,self.centreY-10:self.centreY+10),2)/21;
            xPix = [1:length(xVec)];
            self.xCoffs = lsqcurvefit(self.gauss,self.xCoffs,xPix,xVec,[],[],self.opts);
        end
        %Fit the cloud in the Y direction
        function runYFit(self)
            processedImage = self.getProcessedImage();
            yVec = sum(processedImage(self.centreX-10:self.centreX+10,:),1)/21;
            yPix = transpose([1:length(yVec)]);
            self.yCoffs = lsqcurvefit(self.gauss,self.yCoffs,yPix,yVec,[],[],self.opts);
        end
        %Run both fits, included for brevity in other locations
        function runFits(self)
            self.runXFit();
            self.runYFit();
        end
        %Plot the x directional slice of the cloud with its fit
        function plotX(self)
            processedImage = self.getProcessedImage();
            xVec = sum(processedImage(:,self.centreY-10:self.centreY+10),2)/21;
            spatialVec = self.pixSize * self.magnification * [1:length(xVec)]- self.pixSize * self.magnification * self.centreX;
            plot(spatialVec,xVec,'.')
            hold all
            plot(spatialVec,self.gauss(self.xCoffs,[1:length(xVec)]))
            hold off
            xlabel('Distance in X direction (\mum)')
            ylabel('OD')
            legend('x-data',sprintf('\\sigma_x = %.0f\\mum',self.xCoffs(4)*self.pixSize * self.magnification),'Location','southwest');
            legend('boxoff');
        end
        %Plot the y directional slice of the cloud with its fit
        function plotY(self)
            processedImage = self.getProcessedImage();
            yVec = sum(processedImage(self.centreX-10:self.centreX+10,:),1)/21;
            spatialVec = self.pixSize * self.magnification * [1:length(yVec)]- self.pixSize * self.magnification * self.centreY;
            plot(spatialVec,yVec,'.')
            hold all
            plot(spatialVec,self.gauss(self.yCoffs,[1:length(yVec)]))
            hold off
            xlabel('Distance in Y direction (\mum)')
            ylabel('OD')
            legend('y-data',sprintf('\\sigma_y = %.0f\\mum',self.yCoffs(4)*self.pixSize * self.magnification),'Location','southwest');
            legend('boxoff');
        end
        %Return centre coordinates
        function centreCoords = getCentreCoordinates(self)
            centreCoords.('centreX_pix') = self.centreX;
            centreCoords.('centreY_pix') = self.centreY;
        end
        %Output fit values (specifically the x & y sigma atm) to a
        %structure
        function fitVars = getFitVars(self)
            %note sigmaX & sigmaY are in micrometres
            fitVars.('sigmaX_um') = self.xCoffs(4)*self.pixSize*self.magnification;
            fitVars.('sigmaY_um') = self.yCoffs(4)*self.pixSize*self.magnification;
        end
        %Function to set the magnification of the lens system used to
        %produce the shot
        function setMagnification(self,mag)
            self.magnification = mag;
        end
    end
    
end