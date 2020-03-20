function varargout = makeRegDir
% ARA helper function. Makes directories for registration within the current directory
%
% function pathToRegDir = aratools.makeRegDir
%
% Purpose
% Make a directory into which we will register data. Return the path as a string.
% Makes directories in the form:
%
% registration/reg_01__2020_03_19_a
% registration/reg_02__2020_03_19_b
% registration/reg_03__2020_03_20_a
% etc..
%
% Within each the following will be created by ARAregister:
% registration/reg_01__2020_03_19_a/ARA_to_sample
% registration/reg_01__2020_03_19_a/sample_to_ARA
%
%
% Outputs [optional]
% pathToRegDir - absolute path to the just-made registration directory
% existingRegDirs - cell array of absolute paths to all existing registration directories
%
%
% Rob Campbell - SWC 2020
%
% See also: aratools.findRegDirs


S=settings_handler('settingsFiles_ARAtools.yml');

regDir = fullfile(pwd,S.regDir);

if ~exist(regDir,'dir')
    mkdir(regDir)
end

subDirNames = aratools.findRegDirs;

% Make the registration sub-directory
if isempty(subDirNames)
    % If there are no registration sub-directories then we make one.
    regDirToMake = ['reg_01__',datestr(now,'yyyy_mm_dd'),'_a'];
else
    % Otherwise registrations already exist. We make a new directory that
    % increments the previous one:
    finalIndex = ['a':'z','A':'Z'];
    [~,lastDirName] = fileparts(subDirNames{end});
    regIndex=regexp(lastDirName,'^reg_(\d{2})__','tokens');
    dayIndex=regexp(lastDirName,'.*_(\w)$','tokens');
    f=find(finalIndex==dayIndex{1}{1});

    regDirToMake = sprintf('reg_%02d__%s_%s', ...
        str2num(regIndex{1}{1})+1, ...
        datestr(now,'yyyy_mm_dd'), ...
        finalIndex(f+1));
end


mkdir(fullfile(regDir,regDirToMake));


if nargout>0
    varargout{1}=fullfile(regDir,regDirToMake);
end

if nargout>1
    for ii=1:length(subDirNames)
        subDirNames{ii} = fullfile(regDir,subDirNames{ii});
    end
    varargout{2}=subDirNames;
end
