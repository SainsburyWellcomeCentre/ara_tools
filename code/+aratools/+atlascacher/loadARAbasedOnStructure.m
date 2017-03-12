function DATA = loadARAbasedOnStructure(DATA)
% Load an ARA based on the paths in a previously loaded structure
%
% Purpose
% Uses a previously loaded structure, which may have an empty 
% or missing atlasVolume field, to populate that field with an 
% atlas volume. This function isn't likely to be called directly
% by the user. 
%
%
% Example
% LOADED_ARA = loadARAbasedOnStructure(LOADED_ARA)
%
% Rob Campbell - Basel 2015.



    pathToARA=fullfile(DATA.pathToFile,DATA.fname);
    fprintf('Loading %s\n',pathToARA)
    DATA.atlasVolume = mhd_read( pathToARA);
