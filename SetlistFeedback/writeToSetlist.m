function writeToSetlist(command,setListIP,setListPort)
    %set default arguments if some are missing
    switch nargin
        case 1
            setListIP = 'localhost';
            setListPort = getSetListPort(setListIP);
        case 2
            setListPort = getSetListPort(setListIP);
    end

    %first let's put the string command in the correct format
    byteCommand = unicode2native(command);
    %Need to do some janky decimal to binary and back to decimal conversion
    %to make the 4 byte string which tells Setlist how long the incoming
    %commad is
    binaryCommLength = decimalToBinaryVector(length(byteCommand));
    totBinaryCommLength = [zeros(1,32-length(binaryCommLength)),binaryCommLength];
    byteCommLength = [binaryVectorToDecimal(totBinaryCommLength(1:8)),binaryVectorToDecimal(totBinaryCommLength(9:16)),binaryVectorToDecimal(totBinaryCommLength(17:24)),binaryVectorToDecimal(totBinaryCommLength(25:32))];
    %ths is our total byte string to send to Setlist
    totCommandToSetlist = [byteCommLength,byteCommand];
    
    %let's open up the TCP connection and write in the data
    setlist = tcpclient(setListIP,setListPort);
    write(setlist,totCommandToSetlist);
    pause(0.2);
    setlistResponse = read(setlist);
    disp(native2unicode(setlistResponse));
end

%function to grab setlist port from labview
function port = getSetListPort(setListIP)
    labviewURL = strcat('http://',setListIP,':3580/SetList/JSON');
    portString = webread('http://localhost:3580/SetList/JSON');
    portSplit = strsplit(portString,'=');
    port = str2double(portSplit(2));
end