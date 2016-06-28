function reloadDataFile( fitType )
%RELOADDATA Dummy function to reload data to shotData using autorun

[filename,pathname,~] = uigetfile;
totFilename = strcat(pathname,filename);
autorun(totFilename,fitType,false,false);

end

