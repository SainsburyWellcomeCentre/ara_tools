function makeRegDir
% ARA helper function. Makes directories for registration within the current directory
%
% function aratools.makeRegDir
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



S=settings_handler('settingsFiles_ARAtools.yml');

regDir = fullfile(pwd,S.regDir);

if ~exist(regDir,'dir')
    mkdir(regDir)
end

dirsToMake = {S.ara2sampleDir, S.sample2araDir};

for ii=1:length(dirsToMake)
    tmp = fullfile(regDir,dirsToMake{ii});
    if ~exist(tmp)
        mkdir(tmp)
    end
end
