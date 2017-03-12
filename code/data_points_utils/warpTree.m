function warpTree(csvName,params,fname)
% Warp tree in csvfile using elastix params (params)
%
% function warpTree(csvName,params,fname)
%
% Purpose
% Transform tree. Useful for registering points to ARA following an inverse transform.
%
% Inputs
% csvName - The path to the CSV file containing the exported neurite tree.
% params - MelastiX structure. e.g. output of invertElastixTransform.
% fname - the file name to which we save the transformed points 
%
% Outputs
% Produces a new CSV file. 
%
%
% Rob Campbell - Basel 2015
%
% DEPRECATED: see transformSparsePoints.m

fprintf('DEPRECATED: see transformSparsePoints.m\n')


if isstr(csvName) & exist(csvName)
    data = csvread(csvName);
else
    fprintf('csvName should be a valid path to a csv file')
end


treeData = data(:,[4,5,3]);

transformed = transformix(treeData,params);

data(:,3:5) = transformed.OutputPoint(:,[3,1,2]);


csvwrite(fname,data)
