function outputIm = h5readImage( filename,imPath )
%H5READIMAGE wrapper for the h5read function when dealing with images that
%automatically transposes the imported image to account for the fact that
%the h5read function transposes matricies by default
    outputIm = transpose(h5read(filename,imPath));

end

