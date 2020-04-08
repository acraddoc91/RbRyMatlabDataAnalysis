classdef andorRadialAbsorption < andorAbsorptionImage
    %ANDORRADIALABSORPTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        probeRadProfile = [];
        absRadProfile = [];
        absInt = 0;
        probeInt = 0;
        rho = [];
        cutoff = 1;
        transmission = 1;
    end
    
    methods
        function obj = andorRadialAbsorption()
            obj.magnification = 19.5;
            obj.pixSize = 13.0e-6;
            obj.roi = [614-100,304-100,200,200];
            obj.cutoff = 50e-6;
        end
        function getRadialProfile(self)
            [xLen,yLen] = size(self.absorption);
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
            absPol = interp2(Xpix,Ypix,double(self.absorption-self.background),xmesh,ymesh);
            probePol = interp2(Xpix,Ypix,double(self.probe-self.background),xmesh,ymesh);
            %Integrate out azimuthal coordinate
            self.absRadProfile = trapz(theta,absPol,1);
            self.probeRadProfile = trapz(theta,probePol,1);
            self.absRadProfile(isnan(self.absRadProfile))=0;
            self.probeRadProfile(isnan(self.probeRadProfile))=0;
        end
        function radialIntegral(self)
            cutRho = self.rho;
            cutAbsProfile = self.absRadProfile;
            cutProbeProfile = self.probeRadProfile;
            cutRho(self.rho > self.cutoff) = [];
            cutAbsProfile(self.rho > self.cutoff) = [];
            cutProbeProfile(self.rho > self.cutoff) = [];
            self.absInt = trapz(cutRho,cutAbsProfile.*cutRho);
            self.probeInt = trapz(cutRho,cutProbeProfile.*cutRho);
        end
        function plotProbe(self,norm)
            cutRho = self.rho;
            cutProbeProfile = self.probeRadProfile;
            cutRho(self.rho > self.cutoff) = [];
            cutProbeProfile(self.rho > self.cutoff) = [];
            if(norm)
                plot(cutRho,cutProbeProfile/max(cutProbeProfile));
            else
                plot(cutRho,cutProbeProfile);
            end
        end
        function plotAbs(self,norm)
            cutRho = self.rho;
            cutAbsProfile = self.absRadProfile;
            cutRho(self.rho > self.cutoff) = [];
            cutAbsProfile(self.rho > self.cutoff) = [];
            if(norm)
                plot(cutRho,cutAbsProfile/max(cutAbsProfile));
            else
                plot(cutRho,cutAbsProfile);
            end
        end
        function plotAbsPowDist(self,norm)
            cutRho = self.rho;
            cutAbsProfile = self.absRadProfile;
            cutRho(self.rho > self.cutoff) = [];
            cutAbsProfile(self.rho > self.cutoff) = [];
            if(norm)
                plot(cutRho,cutAbsProfile.*cutRho/max(cutAbsProfile.*cutRho));
            else
                plot(cutRho,cutAbsProfile.*cutRho);
            end
        end
        function plotProbePowDist(self,norm)
            cutRho = self.rho;
            cutProbeProfile = self.probeRadProfile;
            cutRho(self.rho > self.cutoff) = [];
            cutProbeProfile(self.rho > self.cutoff) = [];
            if(norm)
                plot(cutRho,cutProbeProfile.*cutRho/max(cutProbeProfile.*cutRho));
            else
                plot(cutRho,cutProbeProfile.*cutRho);
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

