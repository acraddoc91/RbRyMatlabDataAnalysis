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
        for i = 1:length(filename)
            totFilename = strcat(pathname,char(filename(i)));
            autorun(totFilename,fitType,false,false);
        end
    end
end

end

