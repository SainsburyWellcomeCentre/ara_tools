function fname = getDownSampledFile(expDir)
% ARA helper function. Returns downsampled stack file name when called from experiment root dir
%
% function fname = getDownSampledFile(expDir)
%
% Purpose
% return the downsampled stack file name in the current sample's downsampled directory.
% If an input argument is provided, look in this relative or absolute path for the
% sample directory. This could be either an MHD file or a TIFF.
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
% >> getDownSampledMHDFile
% ans =
%   dsXY123_25_25_02.mhd
%
% 2. 
% >> getDownSampledMHDFile('XY123_121212')
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


downsampleDir=fullfile(expDir,S.downSampledDir);

if ~exist(downsampleDir,'dir')
    fprintf('%s - Can not find directory "%s" in sample directory %s\n', mfilename, downsampleDir,pwd)
    return
end

Dmhd=dir(fullfile(downsampleDir,'ds*_*_*.mhd'));
Dtiff=dir(fullfile(downsampleDir,'ds*_*_*.tif*'));

if length(Dmhd)==0 && length(Dtiff)==0
    fprintf('%s - No appropriate mhd or tiff files in %s\n', mfilename, downsampleDir)
    return
end

if length(Dmhd)>1
    fprintf('Found %d mhd files in %s. Expected 1.\n', length(D), downsampleDir)
    return
end

if length(Dtiff)>1
    fprintf('Found %d tiff files in %s. Expected 1.\n', length(D), downsampleDir)
    return
end

if ~isempty(Dtiff)
    fname = Dtiff.name;
elseif ~isempty(Dmhd)
    fname = Dmhd.name;
end
