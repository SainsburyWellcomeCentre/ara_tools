function varargout = makeRegDir(simulate)
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


if nargin < 1
    simulate = false;
end


S=settings_handler('settingsFiles_ARAtools.yml');

regDir = fullfile(pwd,S.regDir);

if simulate
    fprintf('Running aratools.makeRegDir in simulate mode\n')
end


if ~exist(regDir,'dir')
    if simulate
        fprintf('Making directory %s\n', regDir)
    else
        mkdir(regDir)
    end
end

subDirNames = aratools.findRegDirs;

% Make the registration sub-directory
todayDate = datestr(now,'yyyy_mm_dd');
if isempty(subDirNames)
    % If there are no registration sub-directories then we make one.
    regDirToMake = ['reg_01__',todayDate,'_a'];
else
    % Otherwise registrations already exist. We make a new directory that
    % increments the previous one:
    [~,lastDirName] = fileparts(subDirNames{end});
    regIndex=regexp(lastDirName,'^reg_(\d{2})__','tokens');

    % The number of directories that contain today's date
    nDirs = sum(contains(subDirNames,todayDate));

    regDirToMake = sprintf('reg_%02d__%s_%s', ...
        str2num(regIndex{1}{1})+1, ...
        datestr(now,'yyyy_mm_dd'), ...
        incrementChar('a', nDirs));
end


if simulate
    fprintf('Making directory %s\n', regDirToMake)
else
    mkdir(fullfile(regDir,regDirToMake));
end


if nargout>0
    varargout{1} = fullfile(regDir,regDirToMake);
end

if nargout>1
    for ii=1:length(subDirNames)
        subDirNames{ii} = fullfile(regDir,subDirNames{ii});
    end
    varargout{2} = subDirNames;
end



% Internal functions follow
function incremented_char = incrementChar(tChar,incrementBy)
    % Increment character tChar to next highest for making file names
    %
    % tChar - character to increment
    % incrementBy - how much to increment tChar by

    if nargin < 2
        incrementBy = 1;
    end

    oChar = int16(tChar);

    oChar = oChar + incrementBy;

    % 122 is "z" so next go to "A" if we are here
    if oChar > 122
        oChar = oChar - 58;
    end

    incremented_char = char(oChar);
