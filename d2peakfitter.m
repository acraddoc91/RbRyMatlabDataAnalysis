dummyFit = timeTaggerSpectra;
dummyFit.loadFromFile(shotData(end).filePath);
maxOD = [0,0,0,0];
%lorentzian function
lorentzFunc = @(coffs,x) (coffs(1)./(coffs(2).^2+(x-coffs(3)).^2));
initcoffs = [0.6,6,0];
opts = optimset('Display','off');
%seperate out peaks
[ODDat,freq] = dummyFit.getODPlotData(1000);
%mf = 2
roughPeakCent = 750;
range = 75;
initcoffs(3) = -40;
tempFreq = freq(roughPeakCent-range:roughPeakCent+range);
tempODDat = ODDat(roughPeakCent-range:roughPeakCent+range);
coffs = lsqcurvefit(lorentzFunc,initcoffs,tempFreq,tempODDat,[],[],opts);
plot(tempFreq,tempODDat,'.')
hold all
plot(tempFreq,lorentzFunc(coffs,tempFreq));
maxOD(4) = 3*coffs(1)/coffs(2)^2;
%mf = 1
roughPeakCent = 600;
range = 50;
initcoffs(3) = -50;
tempFreq = freq(roughPeakCent-range:roughPeakCent+range);
tempODDat = ODDat(roughPeakCent-range:roughPeakCent+range);
coffs = lsqcurvefit(lorentzFunc,initcoffs,tempFreq,tempODDat,[],[],opts);
plot(freq(roughPeakCent-range:roughPeakCent+range),ODDat(roughPeakCent-range:roughPeakCent+range),'.')
plot(tempFreq,lorentzFunc(coffs,tempFreq));
maxOD(3) = 15/8*coffs(1)/coffs(2)^2;
%mf = 0
roughPeakCent = 450;
range = 50;
initcoffs(3) = -60;
tempFreq = freq(roughPeakCent-range:roughPeakCent+range);
tempODDat = ODDat(roughPeakCent-range:roughPeakCent+range);
coffs = lsqcurvefit(lorentzFunc,initcoffs,tempFreq,tempODDat,[],[],opts);
plot(freq(roughPeakCent-range:roughPeakCent+range),ODDat(roughPeakCent-range:roughPeakCent+range),'.')
plot(tempFreq,lorentzFunc(coffs,tempFreq));
maxOD(2) = 5/3*coffs(1)/coffs(2)^2;
%mf = -1
roughPeakCent = 350;
range = 50;
initcoffs(3) = -65;
tempFreq = freq(roughPeakCent-range:roughPeakCent+range);
tempODDat = ODDat(roughPeakCent-range:roughPeakCent+range);
coffs = lsqcurvefit(lorentzFunc,initcoffs,tempFreq,tempODDat,[],[],opts);
plot(freq(roughPeakCent-range:roughPeakCent+range),ODDat(roughPeakCent-range:roughPeakCent+range),'.')
plot(tempFreq,lorentzFunc(coffs,tempFreq));
maxOD(1) = 15/8*coffs(1)/coffs(2)^2;