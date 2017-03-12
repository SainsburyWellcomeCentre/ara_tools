function mhdFile = getDownSampledMHDFile(expDir)
% ARA helper function. Returns downsampled MHD file name when called from experiment root dir
%
% function mhdFile = getDownSampledMHDFile(expDir)
%
% Purpose
% return the downsampled MHD file name in the current sample's downsampled directory.
% If an input argument is provided, look in this relative or absolute path for the
% sample directory.
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
% Rob Campbell


if nargin==0 | isempty(expDir)
    expDir=['.',filesep];
end


mhdFile=[];
S=settings_handler('settingsFiles_ARAtools.yml');

if strcmp(expDir,S.downSampledDir)
    %This catches a silly corner case
    expDir=['.',filesep];
end


downsampleDir=fullfile(expDir,S.downSampledDir);

if ~exist(downsampleDir,'dir')
    fprintf('%s - Can not find directory "%s"\n', mfilename, downsampleDir), return
end
D=dir(fullfile(downsampleDir,'ds*_*_*.mhd'));
if length(D)==0
    fprintf('%s - No appropriate .mhd files in %s\n', mfilename, downsampleDir), return
end
if length(D)>1
    fprintf('Found %d .mhd files in %s. Expected 1.\n', length(D), downsampleDir), return
end

mhdFile = D.name;