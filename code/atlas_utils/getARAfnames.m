function [templateFile,atlasFile,araDir] = getARAfnames(expDir)
% ARA helper function. Returns full paths to ARA files to be used for this experiment
%
% function [templateFile,atlasFile,araDir] = getARAfnames
%
% Gets the full path to the ARA files used for this voxel size. 
%
% 
% Inputs
% expDir - [optional] relative or absolute path to sample directory
%          if expDir is missing, look in the current directory. 
%		   (see also getDownSampledMHDFile)
%
%
% Outputs
% templateFile - full path to ARA template file
% atlasFile - full path to ARA atlas file
% araDir - full path to directory containing the above
%
%
% Rob Campbell - Basel 2015


if nargin==0 | isempty(expDir)
	expDir=['.',filesep];
end

%pre-define as empty so we always get an output of some sort
templateFile=[];
atlasFile=[];
araDir=[];


S=settings_handler('settingsFiles_ARAtools.yml');

downsampleDir=S.downSampledDir;

voxelSize = getSampleVoxelSize;

%So the ARA sub directory is;
araSubDir = sprintf(S.araSubDirFormat,voxelSize);


%check it's there
araDir = fullfile(S.araDir,araSubDir);
if ~exist(araDir,'dir')
	fprintf('Can not find ARA directory %s\n', araDir)
	return
end



%So we should be able to find the template and the ARA
templateFile = fullfile(araDir,'template.mhd');
if ~exist(templateFile,'file')
	fprintf('Can not find ARA template file at %s\n', templateFile)
	templateFile=[];
end

atlasFile = fullfile(araDir,'atlas.mhd');
if ~exist(atlasFile,'file')
	fprintf('Can not find ARA atlas file at %s\n', atlasFile)
	atlasFile=[];
end
