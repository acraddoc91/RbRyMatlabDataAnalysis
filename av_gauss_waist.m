function[wx, wy, M] = avergwaist(hola)
im=cell(4,1);
xf=hola;
% for i=1:4
%    file = strcat('probe', num2str(i));
%    im{i} = strcat('im', num2str(i));
%    fp=strcat('E:\Andor\p',xf, file, '.h5');
%    test = andorAbsorptionImage();
%    test.loadFromFile(fp);
%    im{i}=test.probe;
% end
% 
% improbe=(im{1}+im{2}+im{3}+im{4})/4;
% %improbe=sum(cellfun(@double,im(:,1)));
improbe=imageFromLiveAnalysis;
summedRows = sum(improbe,1);
summedCols = sum(improbe,2);
[~,centreX] = max(summedRows);
[~,centreY] = max(summedCols);
sp = improbe(centreY,centreX);
 
% xVec = sum(improbe(centreY:centreY+1,:),1)/2;
% vec=[1:1024];
% yVec = sum(improbe(:, centreX:centreX+1),2)/2;
% yVec=yVec';
% 
% ftx=fittype('a*exp(-(x-b)^2/c^2/2)+d');
% options = fitoptions(ftx);
% options.StartPoint = [sp centreX 2 100];
% options.Lower = [0 0 0 -Inf];
% options.Upper = [100*sp 1024 10 Inf];
% 
% fx=fit(vec', xVec', ftx, options)
% 
% fty=fittype('a*exp(-(x-b)^2/c^2/2)+d');
% options = fitoptions(fty);
% options.StartPoint = [sp centreY 2 100];
% options.Lower = [0 0 0 -Inf];
% options.Upper = [100*sp 1024 10 Inf];
% 
% fy=fit(vec', yVec', fty, options)
% 
% NAi=1.29/(350);
% NAl=1.936/(39);
% M=NAl/NAi;
% %pixs=13;
% M=1.1;
% pixs=3.69;
% 
% ax=coeffvalues(fx);
% ay=coeffvalues(fy);
% 
% wx=ax(3)*pixs/M;
% wy=ay(3)*pixs/M;
% %sx=c*13/M
% 
% % figure
% % plot(fx,vec,xVec)
% % hold;
% % plot(fy,vec,yVec)
%  
% figure
% imagesc(improbe)
% colormap(jet)
end