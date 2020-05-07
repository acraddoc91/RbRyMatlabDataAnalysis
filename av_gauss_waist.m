function[wx, wy, x,  xVec] = av_gauss_waist(dipole)
im=cell(4,1);
%xf=hola;
[m,n]=size(dipole);

 M=1.035;
pixs=3.69;
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
improbe=dipole/5;
summedRows = sum(improbe,1);
summedCols = sum(improbe,2);
[~,centreX] = max(summedRows);
[~,centreY] = max(summedCols);
sp = improbe(centreY,centreX);
 
 xVec = sum(improbe(centreY-2:centreY+2,:),1)/5;
% vec=[1:1024];
    x=linspace(1,n,n)*pixs/M;
 yVec = sum(improbe(:, centreX-2:centreX+2),2)/5;
 yVec=yVec';
 
 y=linspace(1,m,m)*pixs/M;
% 
 ftx=fittype('a*exp(-(x-b)^2/c^2/2)+d');
 options = fitoptions(ftx);
 options.StartPoint = [sp centreX*pixs/M 2 100];
 options.Lower = [0 0 0 -Inf];
 options.Upper = [100*sp 1024 100 Inf];
% 
 fx=fit(x', xVec', ftx, options)
% 
 fty=fittype('a*exp(-(x-b)^2/c^2/2)+d');
 options = fitoptions(fty);
 options.StartPoint = [sp centreY*pixs/M 2 100];
 options.Lower = [0 0 0 -Inf];
 options.Upper = [100*sp 1024 100 Inf];
% 
 fy=fit(y', yVec', fty, options)
% 
% NAi=1.29/(350);
% NAl=1.936/(39);
% M=NAl/NAi;
% %pixs=13;

% pixs=3.69;
% 
 ax=coeffvalues(fx);
 ay=coeffvalues(fy);
% 

 wx=ax(3);
 wy=ay(3);
% %sx=c*13/M
% 
figure
imagesc(dipole)

 figure
 plot(fx,x,xVec)
% % hold;
% % plot(fy,vec,yVec)
%  
% figure
% imagesc(improbe)
% colormap(jet)
end