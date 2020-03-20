function tidyRegistrations
% List to CLI all existing registrations and allow the user to keep just one
%
% function pathToRegDir = aratools.tidyRegistrations
%
% Purpose
% Tidy existing registrations, keeping just one.
%
%
% Inputs
% None
%
% Outputs
% None
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



fprintf('Which registration do you want to keep?\n')

for ii=1:length(regDirs)
    fprintf(' * %d. %s\n', ii, regDirs{ii})
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
