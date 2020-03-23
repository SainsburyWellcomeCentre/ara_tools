function tidyRegistrations
% List to CLI all existing registrations and allow the user to keep just one
%
% function pathToRegDir = aratools.tidyRegistrations
%
% PURPOSE
% Tidy existing registrations, keeping just one.
%
%
% INPUTS
% None
%
% OUTPUTS
% None
%
%
% EXAMPLE:
% >> aratools.tidyRegistrations
%
% Which registration do you want to keep?
%
% * 1. /Volumes/data/XYZ_123/registration/reg_01__2020_03_23_a
% Date conducted: 2020-03-23_13-57-13
% Channel #3 (green)
% Voxel size: 50 microns
% Filtering of sample volume: medfilt3 with filter size 7
% Registrations conducted:
%   ARA to sample
%   sample to ARA
%   Inversion of sample to ARA
%
% * 2. /Volumes/data/XYZ_123/registration/reg_02__2020_03_23_b
% Date conducted: 2020-03-23_14-28-31
% Channel #3 (green)
% Voxel size: 50 microns
% Filtering of sample volume: none
% Registrations conducted:
%   ARA to sample
%
%[1 .. 2]? 
%
%
% Rob Campbell - SWC 2020
%
% See also: aratools.findRegDirs, ARAregister



regDirs = aratools.findRegDirs;

if isempty(regDirs)
    fprintf('No existing registrations found.\n')
    return
elseif length(regDirs)==1
    fprintf('Only one registration directory found. Nothing to do.\n')
    return
end



fprintf('\nWhich registration do you want to keep?\n\n')

for ii=1:length(regDirs)
    tRegDir = regDirs{ii};
    fprintf(' * %d. %s\n', ii, tRegDir)

    regLogFile=fullfile(tRegDir,'registration_log.txt');
    if exist(regLogFile,'file')
        aratools.readLogFile(regLogFile,true);
        fprintf('\n')
    end

end




qs=sprintf('[1 .. %d]? ', length(regDirs));
userAnswer = [];
while isempty(userAnswer)
    userAnswer = input(qs,'s');
    userAnswer = str2num(userAnswer);
    if ~isempty(userAnswer) && userAnswer>=1 && userAnswer<=length(regDirs)
        break
    else
        userAnswer=[];
    end
end

[~,regDirNameToKeep] = fileparts(regDirs{userAnswer});
fprintf('\nKeeping registration "%s" and deleting the rest.\n', regDirNameToKeep)



% Delete
regDirs(userAnswer)=[];
for ii=1:length(regDirs)
    rmdir(regDirs{ii},'s')
end
