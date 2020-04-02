function voxelSize = getSampleVoxelSize(expDir)
% Called from sample directory. Determines voxel size of the downsampled data
%
% function voxelSize = getSampleVoxelSize(expDir)
%
% Purpose 
% returns voxel size of downsampled data as a string.
%
% Inputs
% expDir - [optional] relative or absolute path to sample directory
%          if expDir is missing, look in the current directory. 
%           (see also aratools.getDownSampledFile)
%
% Outputs
% voxelSize - a string defining the downsampled voxel size. e.g. 25 or 10
%
%
% Rob Campbell - Basel 2015

if nargin==0 | isempty(expDir)
    expDir=['.',filesep];
end

dsFile = aratools.getDownSampledFile(expDir);
if isempty(dsFile)
    fprintf('%s finds no suitable downsampled file\n',mfilename)
    return
end

%Get the voxel size from the file name
if iscell(dsFile)
    dsFile=dsFile{1};
end

tok=regexp(dsFile,'.*_([012345]\d)_([012345]\d)_ch0\d\.','tokens');
if isempty(tok)
    fprintf('%s - Can not find voxel size from file name %s\n', mfilename, dsFile), return
end

tok=tok{1};

if length(tok)~=2
    fprintf('%s - Did not find two voxel size numbers in file name %s\n', mfilename, dsFile), return
end


%voxels should be square
if ~strcmp(tok{1},tok{2})
    fprintf('Voxel sizes %s and %s are not equal so voxels not square. No such ARA. Quitting\n', tok{1}, tok{2}),    return
end
voxelSize = tok{1};
