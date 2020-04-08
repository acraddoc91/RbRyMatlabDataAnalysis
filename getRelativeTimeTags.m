function [ tags ] = getRelativeTimeTags( filename, mergeWindowsAcrossShots )
    %Function that takes a time tagger HDF5 file and pulls out the time
    %tags relative to the start time of each window.
    
    % filename is the filename of the HDF5 file you want
    
    % mergeWindowsAcrossShots is a boolean which sets whether you want to
    % collate all the data for each window across all the shots in the file
    
    % Function spits out a cell array that should have a number of columns
    % equal to the number of windows per shot and a number of rows equal
    % either to the number of shots, if mergeWindowsAcrossShots = false,
    % or equal to 1, if mergeWindowsAcrossShots = true

    %Try and read the number of windows in each shot, try included for
    %backwards compatibility
    try
        numWindows = h5read(filename,'/Inform/Windows');
    catch
        disp('Number of windows not set, assuming 3')
        numWindows = 3;
    end
    %Try and read the number of shots in file, try included for backwards
    %compatibility
    try
        numShots = h5read(filename,'/Inform/Shots');
    catch
        disp('Number of shots not set, assuming 1')
        numShots = 1;
    end
    dummy = cell(numShots,numWindows);
    tags = cell(numShots,numWindows);
    %Read each tag window vector to the dummy cells
    for i=1:numShots
        for j=1:numWindows
            dummy{i,j} = h5read(filename,sprintf('/Tags/TagWindow%i',(i-1)*numWindows+(j-1)));
        end
    end
    %Also grab the starttime vector
    dummyStart = h5read(filename,'/Tags/StartTag');
    %Loop over the number of shots and windows
    for i=1:numShots
        %Need to recast i as a 16 bit number because Matlab will
        %cast i as an 8 bit one which causes problems for anything
        %with more than 21 shots
        ip = uint16(i);
        for j=1:numWindows
            %Need to recast i as a 16 bit number because Matlab will
            %cast i as an 8 bit one which causes problems for anything
            %with more than 21 shots
            jp = uint16(j);
            %Reset highcount to 0
            highCount = 0;
            %Grab the vector from the dummy cell structure
            dummy3 = cell2mat(dummy(ip,jp));
            %Initialise for speed
            dummy2 = NaN(length(dummy3),1);
            %Loop over the number of tags
            for k=1:length(dummy3)
                %If the tag is a highword up the high count
                if bitget(dummy3(k),1)==1
                    highCount = bitshift(dummy3(k),-1)-bitshift(dummyStart(2*(numWindows*(ip-1)+(jp-1))+1),-1);
                %Otherwise figure the absolute time since the window
                %opened and append it to the dummy vector
                else
                    dummy2(k) = bitand(bitshift(dummy3(k),-1),2^27-1)+bitshift(highCount,27)-bitand(bitshift(dummyStart(2*(numWindows*(ip-1)+(jp-1))+2),-1),2^27-1);
                end
            end
            %Clear out NaN values and append to tags cell
            dummy2(isnan(dummy2(:,1)),:)=[];
            tags{ip,jp} = dummy2;
        end
    end
    %If we want to merge all the data from like windows across shots
    if mergeWindowsAcrossShots
        tagsOut = cell(numWindows,1);
        %Loop over each window
        for j=1:numWindows
            tagsOut{j} = cat(1,tags{:,j});
        end
        tags = tagsOut;
    end
end

