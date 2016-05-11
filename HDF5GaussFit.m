function [outVarNames,outVarVals,outVarUnits] = HDF5GaussFit( filename, pixSize,pixSizeUnits)

    %Grab the images from file
    absorption = double(h5read(filename,'/Images/Absorption'));
    probe = double(h5read(filename,'/Images/Probe'));
    background = double(h5read(filename,'/Images/Background'));
    %From the absorption, probe and background images get the processed OD
    %image
    processed = real(log((absorption-background)./(probe-background)));
    %Sum over the columns and rows respectively to collapse the processed
    %image down into a a vector
    summedCols = sum(processed,1);
    summedRows = sum(processed,2);
    %Determine the minimum of this collapsed vector for both columns and
    %rows to find the approximate middle of the cloud.
    [~,minCol] = min(summedRows);
    [~,minRow] = min(summedCols);
    %Take a slice in y (columns) and x (rows) for plus/minus 10
    %columns/rows about the middle of the cloud. This averages out some of
    %the noise of a single pixel wide column or row
    yVec = sum(processed(minCol-10:minCol+10,:),1)/21;
    xVec = sum(processed(:,minRow-10:minRow+10),2)/21;
    %Set some initial parameters for the gaussian fit
    initXCoffs = [1,1,900,300];
    initYCoffs = [1,1,500,300];
    %Define effective x vector for the f(x) fits in the x and y direction
    xPix = [1:length(xVec)];
    yPix = transpose([1:length(yVec)]);
    %Define the gaussian fitting function and set the fitting function to not output
    %a mess of crap about it finishing the fit
    f =@(coffs,x) transpose(coffs(1)-coffs(2).*exp(-(x-coffs(3)).^2/(2*coffs(4).^2)));
    opts = optimset('Display','off');
    %Fit the gaussian in x and y
    xCoffs = lsqcurvefit(f,initXCoffs,xPix,xVec,[],[],opts);
    yCoffs = lsqcurvefit(f,initYCoffs,yPix,yVec,[],[],opts);
    %Scale the determined width by the pixel size to get the real width
    xSig = xCoffs(4)*pixSize;
    ySig = yCoffs(4)*pixSize;
    %plot(yPix,yVec,'.')
    %hold all
    %plot(yPix,f(yCoffs,yPix))
    %Clean up output variables
    outVarNames = {'xSig','ySig','minCol','minRow'};
    outVarVals = [xSig,ySig,minCol,minRow];
    outVarUnits = {pixSizeUnits,pixSizeUnits,'pixels','pixels'};
    
end

