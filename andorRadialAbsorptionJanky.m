classdef andorRadialAbsorptionJanky < andorJanky
    %ANDORRADIALABSORPTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        procRadProfile = [];
        absInt = 0;
        probeInt = 0;
        rho = [];
        cutoff = 1;
        transmission = 1;
    end
    
    methods
        function obj = andorRadialAbsorptionJanky()
            obj.magnification = 1;
            obj.pixSize = 1;
            %obj.roi = [614-100,304-100,200,200];
            obj.cutoff = 50;
        end
        function removeBackground(self)
            background = mean(mean(self.processedImage(1:25,1:25)));
            self.processedImage = self.processedImage - background;
        end
        function getRadialProfile(self)
            [xLen,yLen] = size(self.processedImage);
            %Vectors centred on beam maxima
            xpix = [1:xLen]-xLen/2.0;
            ypix = [1:yLen]-yLen/2.0;
            %Create meshgrid
            [Xpix,Ypix] = meshgrid(xpix,ypix);
            %Theta that we care about
            theta = [0:0.005:2*pi];
            %And r
            rmax = sqrt(max(xpix)^2+max(ypix)^2);
            r = [0:0.1:rmax];
            self.rho = r*self.pixSize/self.magnification;
            %Meshgrid for r and theta
            [rmesh,thetaMesh] = meshgrid(r,theta);
            %Convert r & theta meshgrid to X and Y coordinates
            xmesh = rmesh.*cos(thetaMesh);
            ymesh = rmesh.*sin(thetaMesh);
            %Interpolate
            procPol = interp2(Xpix,Ypix,double(self.processedImage),xmesh,ymesh);
            %Integrate out azimuthal coordinate
            self.procRadProfile = trapz(theta,procPol,1);
            self.procRadProfile(isnan(self.procRadProfile))=0;
        end
        function radialIntegral(self)
            cutRho = self.rho;
            cutProcProfile = self.procRadProfile;
            cutRho(self.rho > self.cutoff) = [];
            cutProcProfile(self.rho > self.cutoff) = [];
            self.procInt = trapz(cutRho,cutProcProfile.*cutRho);
        end
        function plotProc(self,norm)
            cutRho = self.rho;
            cutProcProfile = self.procRadProfile;
            cutRho(self.rho > self.cutoff) = [];
            cutProcProfile(self.rho > self.cutoff) = [];
            if(norm)
                plot(cutRho,cutProcProfile/max(cutProcProfile));
            else
                plot(cutRho,cutProcProfile);
            end
        end
        function plotProcPowDist(self,norm)
            cutRho = self.rho;
            cutProcProfile = self.procRadProfile;
            cutRho(self.rho > self.cutoff) = [];
            cutProcProfile(self.rho > self.cutoff) = [];
            if(norm)
                plot(cutRho,cutProcProfile.*cutRho/max(cutProcProfile.*cutRho));
            else
                plot(cutRho,cutProcProfile.*cutRho);
            end
        end
        function runFit(self)
            self.getRadialProfile();
            self.radialIntegral();
            self.transmission = self.absInt/self.probeInt;
        end
        %Output fit values (specifically the x & y sigma atm) to a
        %structure
        function fitVars = getFitVars(self)
            fitVars.('transmission') = self.transmission;
            fitVars.('probeInt') = self.probeInt;
            fitVars.('absInt') = self.absInt;
        end
    end
    
end

