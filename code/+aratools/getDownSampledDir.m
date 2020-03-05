function dsDir = getDownSampledDir(expDir)
% ARA helper function. Returns downsampled stack file name when called from experiment root dir
%
% function dsDir = getDownSampledDir(expDir)
%
% Purpose
% Return all downsampled directory names in the current sample's 
% downsampled directory. If an input argument is provided, look in this 
% relative or absolute path for the sample directory. This could be either 
% an MHD file or a TIFF. The purpose of this function is that it can be
% extended in the future to cope with multiple downsampled directories
% in the same sample directory. 
%
% 
% Inputs
% expDir - [optional] relative or absolute path to sample directory
%          if expDir is missing, look in the current directory. 
%
%
% Examples
% 1. 
% >> cd XY123_121212
% >> getDownSampledDir
% ans =
%   dsXY123_25_25_02.mhd
%
% 2. 
% >> getDownSampledMHDFile('XY123_121212')
%
%
% Rob Campbell - SWC 2019


if nargin==0 | isempty(expDir)
    expDir=['.',filesep];
end


fname=[];
S=settings_handler('settingsFiles_ARAtools.yml');

if strcmp(expDir,S.downSampledDir)
    %This catches a silly corner case
    expDir=['.',filesep];
end


downsampleDir.name = fullfile(S.downSampledDir, sprintf('%03d_micron',S.ARAsize));
downsampleDir.folder = expDir;


if length(downsampleDir)==0
    fprintf('%s - Can not find directory "%s" in sample directory %s\n', mfilename, downsampleDir,pwd)
    return
end

if length(downsampleDir)>1
    fprintf('Found multiple downsampled directories\n')
    for ii=1:length(downsampleDir)
        fprintf('%s\n',downsampleDir(ii).name)
    end
    fprintf('NOT SET UP TO DEAL WITH THIS YET\n')
    dsDir=[];
end

dsDir = downsampleDir.name;
