function transformSparsePoints(csvName,params,fname)
% Runs transformix on sparse points csv files exported from MaSIV using elastix params
%
% function transformSparsePoints(csvName,params,fname)
%
% Purpose
% Run an Elastix transform on sparse points or a tree exported from MaSIV.
% Useful for registering points to ARA following an inverse transform.
% 
%
% Inputs
% csvName -  The path to the CSV file containing the exported sparse data
%            (neurite tree or cell locations).
% params  -  MelastiX structure. e.g. output of invertElastixTransform.
% fname   -  the file name to which we save the transformed points 
%
%
% Outputs
% Produces a new CSV file. 
%
%
% Rob Campbell - Basel 2015
%
%
% See also:
% invertElastixTransform.m


if isstr(csvName) & exist(csvName)
    data = csvread(csvName);
else
    fprintf('csvName should be a valid path to a csv file')
end

if size(data,2)==5
    indexOffset=2;
elseif size(data,2)==3
    indexOffset=0;
else
    fprintf('Number of columns is %d. Expected 5 or 3 columns. Aborting\n',size(data,2))
end

tmpData = data(:,[2,3,1]+indexOffset);

transformed = transformix(tmpData,params);

data(:,(1:3)+indexOffset) = transformed.OutputPoint(:,[3,1,2]);


csvwrite(fname,data)
