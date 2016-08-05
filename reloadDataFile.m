function reloadDataFile( fitType )
%RELOADDATA Dummy function to reload data to shotData using autorun

[filename,pathname,fileSelected] = uigetfile('.h5','MultiSelect','on');
%ensure file has been selected
if(fileSelected>0)
    %check if only one file selected
    if isa(filename,'char')
        %if only one file selected load it with designated fit type
        totFilename = strcat(pathname,filename);
        autorun(totFilename,fitType,false,false);
    else
        %if multiple files selected loop over each file to import them
        parfor i = 1:length(filename)
            totFilename = strcat(pathname,char(filename(i)));
            reloadStruct(i) = shotProcessor(totFilename,fitType,false,false);
        end
        try
            shotIn = evalin('base','shotData');
        catch
        end
        if exist('shotIn','var')
            for i = 1:length(reloadStruct)
                %see if index already exists
                repIndex = find([shotIn.Index]==reloadStruct(i).Index);
                if isempty(repIndex)
                    shotIn = structAppend(shotIn,reloadStruct(i));
                else
                    %remove repeated index
                    shotIn(repIndex) = [];
                    shotIn = structAppend(shotIn,reloadStruct(i));
                end
            end
            assignin('base','shotData',shotIn);
        else
            assignin('base','shotData',reloadStruct);
        end
    end
end

end

