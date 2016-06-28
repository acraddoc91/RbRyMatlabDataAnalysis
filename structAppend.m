function totStruct = structAppend( struct1,struct2 )
%function to append two structures. If fieldnames are different between the
%two structures the function will fill out each structure with blank fields
%to prevent errors

fields1 = fieldnames(struct1);
fields2 = fieldnames(struct2);

missingFields1 = {};
missingFields2 = {};

%check for any fields missing from struct2 that are present in struct1
for i = 1:length(fields1)
    [~,exists]=find(strcmp(fields2,fields1{i}));
    if isempty(exists)
        missingFields2 = [missingFields2,fields1{i}];
    end
end
%check for any fields missing from struct1 that are present in struct2
for i = 1:length(fields2)
    [~,exists]=find(strcmp(fields1,fields2{i}));
    if isempty(exists)
        missingFields1 = [missingFields1,fields2{i}];
    end
end

%if struct1 has missing fields go ahead and populate the missing field for
%each element with NaN
if length(missingFields1) ~= 0
    for i = 1:length(missingFields1)
        [struct1.(char(missingFields1(i)))] = deal(NaN);
    end
end
%if struct2 has missing fields go ahead and populate the missing field for
%each element with NaN
if length(missingFields2) ~= 0
    for i = 1:length(missingFields2)
        [struct2.(char(missingFields2(i)))] = deal(NaN);
    end
end

%append the two structures (which should have exactly the same fieldnames)
%togther
totStruct = [struct1,struct2];

end

