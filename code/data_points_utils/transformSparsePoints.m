function transformSparsePoints(csvName,params,fname)
% Runs transformix on sparse points csv files exported from MaSIV using elastix params
%
% function transformSparsePoints(csvName,params,fname)
%
% Purpose
% Run an Elastix transform on sparse points or a tree exported from MaSIV.
% Useful for registering points to ARA following an inverse transform. The
% main purpose of this wralper function is to reshuffle the columns of data
% going into transformix then being returned from transformix.
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

% We will assume the last three columns contain z, x, and y positions of 
% each data point. For instance, there will be 5 columns for neurite trees
% exported from MaSIV, with column one being the node ID and two being the
% parent node ID. Data with only 3 columns are sparse points, such as cell 
% locations or electrode tracks.
indexOffset = size(data,2)-3; %The column at which to start reading point data
if indexOffset<0
    fprintf('%s finds that file %s has only %d columns. Expected at least three\n',...
        mfilename, size(data,2))
    return
end

% Changes column order for transformix, runs the transform, then changes it back
tmpData = data(:,[2,3,1]+indexOffset);
transformed = transformix(tmpData,params);
data(:,(1:3)+indexOffset) = transformed.OutputPoint(:,[3,1,2]);

fprintf('\n%s is writing transformed points to %s\n', mfilename, fname)
csvwrite(fname,data)
