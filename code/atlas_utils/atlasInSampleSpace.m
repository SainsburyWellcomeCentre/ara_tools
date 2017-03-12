function [atlasInSample,transformixLog]=atlasInSampleSpace
% use the parameters is downsample/ARA2sample to return the atlas registered to the sample
%
% function [atlas,log]=atlasInSampleSpace
%
% Purpose
% Use the downsample directory to return the atlas volume in same space as the 
% sample.
%
%
% Outputs
% atlas - a 3D matrix defining the atlas volume in the same space as your sample.
% log - the log text from tranformix 
%
% Rob Campbell - Basel, 2015



%Set default arguments
S=settings_handler('settingsFiles_ARAtools.yml');

downsampleDir = fullfile(pwd,S.downSampledDir);

if ~exist(downsampleDir,'dir')
    fprintf('Failed to find downsampled directory %s\n', downsampleDir), return
end

ara2sampleDir = fullfile(downsampleDir,S.ara2sampleDir);
if ~exist(ara2sampleDir,'dir')
    fprintf('Failed to find directory containing registration parameters: %s\n', ara2sampleDir), return
end


[~,atlasFname]=getARAfnames;


%fprintf('Loading atlas volume from %s...\n',atlasFname)
%atlasVol = mhd_read(atlasFname);



%Set up transformation directory: copy transform parameter files and modify those files as needed
%MATLAB should figure out the correct temporary directory on Windows
outputDir=fullfile(tempdir, sprintf('transformix_%s_%d', datestr(now,'yymmddHHMMSS'), round(rand*1E8)) ); 
if ~exist(outputDir)
    if ~mkdir(outputDir)
        error('Can''t make data directory %s',outputDir)
    end
else
    error('directory %s already exists. odd. Please check what is going on',outputDir)
end

%find the parameter files and copy to the temporary data directory
params = dir(fullfile(ara2sampleDir,'TransformParameters.*.txt'));
params = flipud(params);

for ii=1:length(params)
    fprintf('Copying %s to %s\n',params(ii).name,outputDir)
    copyfile(fullfile(ara2sampleDir,params(ii).name), outputDir)
end

%Modify the parameter files so that they chain together correctly: the files should point to the new copied locations. 
for ii=1:length(params)-1
    changeParameterInElastixFile(fullfile(outputDir,params(ii).name), ...
                                'InitialTransformParametersFileName', ...
                                fullfile(outputDir,params(ii+1).name))
end

%stop the interpolation and make the result image pixel type an int
for ii=1:length(params)-1
    changeParameterInElastixFile(fullfile(outputDir,params(ii).name), ...
                                'FinalBSplineInterpolationOrder', '0');

    changeParameterInElastixFile(fullfile(outputDir,params(ii).name), ...
                                'ResultImagePixelType', 'int');
end

%build the command. 
CMD = sprintf('transformix -out %s -tp %s -in %s', outputDir, fullfile(outputDir,params(1).name), atlasFname);

fprintf('Begining transformation using transformix:\n%s\n',CMD)
[status,result]=system(CMD);

if status %Things failed. Oh dear. 
    fprintf('\n\t*** Transform Failed! ***\n%s\n',result)
else
    d=dir(fullfile(outputDir,'result.mhd')); 
    if isempty(d)
        error('Failed to find transformed result. Retaining output directory %s for debugging purposes.',outputDir)
    end

    atlasInSample=mhd_read(fullfile(outputDir,d.name));
    transformixLog=readWholeTextFile([outputDir,filesep,'transformix.log']);
end



rmdir(outputDir,'s')
fprintf('\nFinished\n')