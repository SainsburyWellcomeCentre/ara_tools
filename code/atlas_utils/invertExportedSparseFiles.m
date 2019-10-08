function invertExportedSparseFiles(inverted)
% Load CSV files with sparse point data and invert them
%
% function invertExportedSparseFiles(inverted)
%
% Purpose
% This function is called by ARAregister to register all sparse
% CSV files to the ARA and place the registered versions of the CSV
% files in the sample2ara directory.
% This function can also be called standalone (even with) no
% input args. Just call from experiment root directory. 
%
%
% Inputs [optional]
% inverted - The inverted transform data structure stored in a MAT file. 
%            This is the  output of invertElastixTransform from MelastiX. 
%            If you ran ARAregister, this will be found in sample2ARA/inverted.mat
%            Calling this funtion without input arguments will cause it to 
%            search for this file and attempt to load it. 
%
%
% Rob Campbell - Basel
% Modified July 2019 to not rely on logging structure, which we no longer make



% Set up directory names
S=settings_handler('settingsFiles_ARAtools.yml');
downsampledDir = aratools.getDownSampledDir;
elastixDir = fullfile(downsampledDir,S.sample2araDir);


% If running without input arguments, find the inverted .mat file
if nargin<1 | isempty(inverted)
    invFname = fullfile(elastixDir,S.invertedMatName);
    if ~exist(invFname, 'file')
        fprintf('%s can not find elastix.m output file at %s\n',...
            mfilename, invFname)
        return
    end
    load(invFname) %loads a variable called "inverted"
end



% Search for all CSV files, which we will assume are sparse data 
sparseFiles = dir(fullfile(downsampledDir,'*.csv'));
for ii=1:length(sparseFiles)
    fname = fullfile(downsampledDir,sparseFiles(ii).name);
    fprintf('Beginning transform of sparse data file %s\n', fname)
    transformSparsePoints(fname,inverted,fullfile(elastixDir,sparseFiles(ii).name))
end
