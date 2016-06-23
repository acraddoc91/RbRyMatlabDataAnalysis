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
        atomNumber = 0;
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
            summedCols = sum(self.getProcessedImage,1);
            summedRows = sum(self.getProcessedImage,2);
            %Determine the minimum of this collapsed vector for both columns and
            %rows to find the approximate middle of the cloud.
            [~,minCol] = min(summedRows);
            [~,minRow] = min(summedCols);
            self.centreX = minCol;
            self.centreY = minRow;
            self.xCoffs(3) = self.centreX;
            self.yCoffs(3) = self.centreY;
        end
        %Fit the cloud in the X direction
        function runXFit(self)
            processedImage = self.getProcessedImage();
            xVec = sum(processedImage(:,self.centreY-10:self.centreY+10),2)/21;
            self.xCoffs(2) = -min(xVec);
            xPix = [1:length(xVec)];
            self.xCoffs = lsqcurvefit(self.gauss,self.xCoffs,xPix,xVec,[],[],self.opts);
        end
        %Fit the cloud in the Y direction
        function runYFit(self)
            processedImage = self.getProcessedImage();
            yVec = sum(processedImage(self.centreX-10:self.centreX+10,:),1)/21;
            self.yCoffs(2) = -min(yVec);
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
            roi = self.getROI;
            centreCoords.('centreX_pix') = self.centreX + roi(1);
            centreCoords.('centreY_pix') = self.centreY + roi(2);
        end
        %Output fit values (specifically the x & y sigma atm) to a
        %structure
        function fitVars = getFitVars(self)
            %note sigmaX & sigmaY are in micrometres
            fitVars.('sigmaX_um') = self.xCoffs(4)*self.pixSize*self.magnification;
            fitVars.('sigmaY_um') = self.yCoffs(4)*self.pixSize*self.magnification;
            fitVars.('N_atoms') = self.getAtomNumber;
        end
        %Function to set the magnification of the lens system used to
        %produce the shot
        function setMagnification(self,mag)
            self.magnification = mag;
        end
        function calculateAtomNumber(self,imagingDetuning,imagingIntensity)
            %values for 87Rb D2 line
            gam = 38.116 * 10^6;
            isat = 1.6692*10^(-3); %W/cm^2 for sigma_\pm polarised light
            %isat = 2.5033; %W/cm^2 for pi polarised light
            hbar = 1.0545718*10^(-34);
            omega = 2*pi*384.2281152028*10^12;
            sig0 = hbar*omega*gam/(2*isat);
            sig = sig0/(1+4*(2*pi*imagingDetuning/gam)^2+(imagingIntensity/(isat))) * 10^-4; %in m^2
            procImage = self.getProcessedImage();
            self.atomNumber = -sum(sum(procImage))*(self.magnification*self.pixSize*10^(-6))^2/sig;
        end
        function atomNum = getAtomNumber(self)
            atomNum = self.atomNumber;
        end
    end
    
end