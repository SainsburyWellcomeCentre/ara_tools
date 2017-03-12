function lasagnaCommandsShow(relativePaths)
% print to screen the lasagna commands that can be run to show registration quality of downsampled data
%
% function lasagnaCommandsShow(relativePaths)
%
%
% Purpose
% Following running image registration "blind" using ARAregister, you will still want to check the 
% registration quality and overlay and sparse point data you may have. This function produces
% lasagna start commands that can be quickly copied and pasted into the bash command line.
%
% 
% Inputs
% relativePaths - [optional, 0 by default] if 1 produce relative paths (from exp. root dir) 
%                 not absolute paths. 
%
%
% Rob Campbell

if nargin<1
    relativePaths=0;
end

S=settings_handler('settingsFiles_ARAtools.yml');
load(fullfile(S.downSampledDir,S.sparseDataMatLogFname)) %loads "logging"


if strcmp(logging(1).type,'tree') %(all data in one struct will be of the same type)
    flag='T';
elseif strcmp(logging(1).type,'sparse points')
    flag='S';
end


% --------------------------------------------------------------------------
fprintf('\nConfirm that sparse data are correctly projected onto brain:\n')
mhdFile = getDownSampledMHDFile;
for ii=1:length(logging)
    if relativePaths
        path2MHD = fullfile(S.downSampledDir,mhdFile);
        path2Dat = fullfile(S.downSampledDir,logging(ii).fname);        
    else
        path2MHD = fullfile(pwd,S.downSampledDir,mhdFile);
        path2Dat = fullfile(pwd,S.downSampledDir,logging(ii).fname);        
    end
    fprintf('lasagna -im %s -%s %s\n', path2MHD, flag, path2Dat)
end



% --------------------------------------------------------------------------
fprintf('\nConfirm that sparse data are correctly projected onto ARA:\n')
templateFile = getARAfnames;
elastixDir = fullfile(S.downSampledDir,S.sample2araDir);
for ii=1:length(logging)
    if relativePaths
        path2Dat = fullfile(elastixDir,logging(ii).fname);        
    else
        path2Dat = fullfile(pwd,elastixDir,logging(ii).fname);        
    end
    fprintf('lasagna -im %s -%s %s\n', templateFile, flag, path2Dat)
end




% --------------------------------------------------------------------------
fprintf('\nAssess registration quality of sample to ARA:\n')
resultsFile = fullfile(elastixDir,'result.1.mhd');

if ~relativePaths
    resultsFile = fullfile(pwd,resultsFile);        
end

fprintf('lasagna -im %s %s\n', templateFile, resultsFile)

