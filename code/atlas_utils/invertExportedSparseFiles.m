function invertExportedSparseFiles(inverted,logging)
% Load CSV files with sparse point data and invert them
%
% function invertExportedSparseFiles(inverted,logging)
%
% Purpose
% This function is called by ARAregister to register all sparse
% CSV files to the ARA and place the registered versions of the CSV
% files in the sample2ara directory.
% This function can also be called standalone (even with) no
% input args. Just call from experiment root directory. 
%
%
% Inputs
% inverted - the inverted transformed data stored in a MAT file
% logging - the structure containing the names of the exported neurite trees
%
%
% Rob Campbell

S=settings_handler('settingsFiles_ARAtools.yml');
elastixDir = fullfile(S.downSampledDir,S.sample2araDir);

if nargin<1 | isempty(inverted)
    load(fullfile(elastixDir,S.invertedMatName)) %loads "inverted"
end

if nargin<2 | isempty(logging)
    logFileName=fullfile(S.downSampledDir,S.sparseDataMatLogFname);
    if ~exist(logFileName,'file')
        fprintf('Can not find log file %s. SKIPPING SPARSE POINT TRANSFORMATION!\n',logFileName)
        return
    end
    load(logFileName) %loads "logging"

    %example loggin:
    %>> logging
    %
    % logging = 
    %
    %  struct with fields:
    %
    %    fname: 'YH298_traced_cells_tree_01.csv'
    %    downsample: [26.7950 2.7780]
    %    type: 'tree'


end


for ii=1:length(logging)
    fname = fullfile(S.downSampledDir,logging(ii).fname);
    if ~exist(fname,'file')
        fprintf('skipping missing file %s\n',fname)
        continue
    end
    fprintf('Beginning transform of %s file %s\n',logging(ii).type,fname)
    transformSparsePoints(fname,inverted,fullfile(elastixDir,logging(ii).fname))
end
