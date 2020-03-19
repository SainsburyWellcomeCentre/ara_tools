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
% pathToRegDir - absolute path to registration directory
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

% Now we automatically generate a directory name into which we will do the registration
contents = dir(regDir);
subDirNames = {contents.name};
subDirNames = subDirNames([contents.isdir]);


% Keep only registration directories
for ii=length(subDirNames):-1:1
    % Check whether this is a registration sub-directory
    if isempty(regexp(subDirNames{ii},'reg_\d{2}__\d{4}_\d{2}_\d{2}_\w'))
        subDirNames(ii)=[];
    end
end


% Make the registration sub-directory
if isempty(subDirNames)
    % If there are no registration sub-directories then we make one.
    regDirToMake = ['reg_01__',datestr(now,'yyyy_mm_dd'),'_a'];
else
    % Otherwise registrations already exist. We make a new directory that
    % increments the previous one:
    finalIndex = ['a':'z','A':'Z'];
    lastDirName = subDirNames{end};
    regIndex=regexp(lastDirName,'^reg_(\d{2})__','tokens');
    dayIndex=regexp(lastDirName,'.*_(\w)$','tokens');
    f=find(finalIndex==dayIndex{1}{1});

    regDirToMake = sprintf('reg_%02d__%s_%s', ...
        str2num(regIndex{1}{1})+1, ...
        datestr(now,'yyyy_mm_dd'), ...
        finalIndex(f+1));
end


regDir = fullfile(regDir,regDirToMake);
mkdir(regDir)


if nargout>0
    varargout{1}=regDir;
end
