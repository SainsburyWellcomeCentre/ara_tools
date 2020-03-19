function fname = getDownSampledFile(expDir)
% ARA helper function. Returns downsampled stack file name when called from experiment root dir
%
% function fname = aratools.getDownSampledFile(expDir)
%
% Purpose
% Return the downsampled stack file name in the current sample's downsampled data directory.
% If an input argument is provided, look in this relative or absolute path for the
% sample directory. This could be either an MHD file or a TIFF.
%
% 
% Inputs
% expDir - [optional] relative or absolute path to sample directory
%          if expDir is missing, look in the current directory. 
%
% Outputs
% fname - a cell array of all available downsampled files
%
%
% Examples
% 1. 
% >> cd XY123_121212
% >> getDownSampledMHDFile
% ans =
%  1x2 cell array
%    {'dsxyz_25_25_02.tif'}    {'dsxyz_25_25_03.tif'
%
% 2. 
% >> getDownSampledMHDFile('XY123_121212')l
%
% Rob Campbell - SWC 2019


if nargin==0 | isempty(expDir)
    expDir=['.',filesep];
end

S=settings_handler('settingsFiles_ARAtools.yml');

if strcmp(expDir,S.downSampledDir)
    %This catches a silly corner case
    expDir=['.',filesep];
end


fname=[];
downsampleDir= aratools.getDownSampledDir(expDir);
if isempty(downsampleDir)
    return
end


% Find all downsampled MHD to TIFF files

Dmhd=dir(fullfile(downsampleDir,'ds*_*_*.mhd'));
Dtiff=dir(fullfile(downsampleDir,'ds*_*_*.tif*'));

if length(Dmhd)==0 && length(Dtiff)==0
    fprintf('%s - No appropriate MHD or TIFF files in %s\n', mfilename, downsampleDir)
    return
end

D = [Dmhd,Dtiff];
fname={};
for ii=1:length(D)
    fname{ii} = D(ii).name;
end
