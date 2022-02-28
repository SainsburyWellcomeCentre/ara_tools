function existingRegDirs = findRegDirs
% ARA helper function. Looks for existing registration sub-directories
%
% function existingRegDirs = aratools.findRegDirs
%
% Purpose
% Return absolute paths to existing registration sub-directories made by 
% the function aratools.makeRegDir
%
%
% Outputs
% existingRegDirs - cell array of absolute paths to all existing registration directories
%
%
% Rob Campbell - SWC 2020
%
% See also: aratools.makeRegDir



S=settings_handler('settingsFiles_ARAtools.yml');

regDir = fullfile(pwd,S.regDir);

if ~exist(regDir,'dir')
    existingRegDirs={};
    return
end

% Get list of directories that exist in this path
contents = dir(regDir);
subDirNames = {contents.name};
existingRegDirs = subDirNames([contents.isdir]);


% Keep only registration directories
for ii=length(existingRegDirs):-1:1
    % Check whether this is a registration sub-directory
    if isempty(regexp(existingRegDirs{ii},'reg_\d{2}__\d{4}_\d{2}_\d{2}_\w'))
        existingRegDirs(ii)=[];
    else
        existingRegDirs{ii} = fullfile(regDir,existingRegDirs{ii});
    end
end
