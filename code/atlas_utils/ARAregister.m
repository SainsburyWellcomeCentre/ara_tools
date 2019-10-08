function ARAregister(varargin)
% Register sample brain to the ARA and create transform parameters for sparse points
%
% function ARAregister('param1',val1, 'param2',val2, ...)
%
% Purpose
% Register sample brain to the ARA (Allen Reference Atlas) in various ways. 
% This function assumes you have a directory containing your brain in the same
% voxel size as the ARA. You can generate this for instance, by running the
% downsampleAllChannels command from stitchit. This will produce a directory
% called downsampledStacks_25. 
%
% By default this function:
% 1. Registers the ARA template TO the sample.
% 2. Registers the sample to the ARA template.
% 3. If (2) was done, the inverse transform of it is also calculated and applied
%    to both volume images and sparse data.
%
%
% The results are saved to downsampleDir
%
% If no inputs are provided it looks for the default down-sample directory. 
% The ARA to use is infered from the file names in downsampleDir. 
% NOTE: once this function has been run you can transform the sparse points to ARA
%       again simply by running invertExportedSparseFiles from the experiment root dir.
%
%
% Inputs (optional parameter/value pairs)
% 'downsampleDir' - String defining the directory that contains the downsampled data. 
%                   By default uses value from toolbox YML file (see source code for now).
% 'ara2sample' - [bool, default true] whether to register the ARA to the sample
% 'sample2ara' - [bool, default true] whether to register the sample to the ARA
% 'suppressInvertSample2ara' - [bool. default false] if true, the inverse transform is not
%                            calculated if the sample2ara transform is performed.
%                            You need the inverse transform if you want to go on to 
%                            register sparse points to the ARA. 
% 'elastixParams' - paths to parameter files. By default we use those in ARA_tools/elastix_params/
%
%
% Outputs
% none
%
%
% For more details see the repository ReadMe file and als see the wiki
% (https://github.com/SainsburyWellcomeCentre/ara_tools/wiki/Example-1-basic-registering). 
%
%
% Examples
% - Run with defaults
% >> ARAregister
%
% - Run with another set of parameter files
% >> ARAregister('elastix_params','ParamBSpline.txt'})
%
%
% Rob Campbell - Basel, 2015
%
% Also see from this repository:
% invertExportedSparseFiles (and transformSparsePoints), aratools.rescaleAllSparsePoints



%Parse input arguments
S=settings_handler('settingsFiles_ARAtools.yml');

params = inputParser;
params.CaseSensitive=false;

params.addParamValue('mult',1, @isnumeric)
params.addParamValue('adjHistogram',false,@(x) islogical(x) || x==1 || x==0)

params.addParamValue('downsampleDir',fullfile(pwd,S.downSampledDir),@ischar)
params.addParamValue('ara2sample',true,@(x) islogical(x) || x==1 || x==0)
params.addParamValue('sample2ara',true,@(x) islogical(x) || x==1 || x==0)
params.addParamValue('suppressInvertSample2ara',false,@(x) islogical(x) || x==1 || x==0)

toolboxPath = fileparts(which(mfilename));
toolboxPath = fileparts(fileparts(toolboxPath));
elastix_params_default = {fullfile(toolboxPath,'elastix_params','01_ARA_affine.txt'),
                fullfile(toolboxPath,'elastix_params','02_ARA_bspline.txt')};
params.addParamValue('elastixParams',elastix_params_default,@iscell)


params.parse(varargin{:});
mult = params.Results.mult;
adjHistogram = params.Results.adjHistogram;
downsampleDir = aratools.getDownSampledDir;
ara2sample = params.Results.ara2sample;
sample2ara = params.Results.sample2ara;
suppressInvertSample2ara = params.Results.suppressInvertSample2ara;
elastixParams = params.Results.elastixParams;



if ~exist(downsampleDir,'dir')
    fprintf('Failed to find downsampled directory %s\n', downsampleDir), return
end

if sample2ara && suppressInvertSample2ara
    invertSample2ara = false;
else
    invertSample2ara = true ;
end

%Check that the elastixParams are there
for ii=1:length(elastixParams)
    if ~exist(elastixParams{ii},'file')
        error('Can not find elastix param file %s',elastixParams{ii})
    end
end





%Figure out which atlas to use
dsFile = aratools.getDownSampledFile;
if isempty(dsFile)
    return %warning message already issued
end


if iscell(dsFile)
    if length(dsFile) == 1
        dsFile = dsFile{1};
    else
        %Display choices to screen and allow user to choose which volume to register
        fprintf('\n Which volume do you want to use for registration?\n')
        for ii=1:length(dsFile)
            fprintf('%d. %s\n',ii,dsFile{ii})
        end
        qs=sprintf('[1 .. %d]? ', length(dsFile));
        OUT = [];
        while isempty(OUT)
            OUT = input(qs,'s');
            OUT = str2num(OUT);
            if ~isempty(OUT) && OUT>=1 && OUT<=length(dsFile)
                break
            else
                OUT=[];
            end
        end

        dsFile = dsFile{OUT};
        fprintf('\nRunning registration on volume %s\n\n',dsFile)

    end

end

templateFile = getARAfnames;
if isempty(templateFile)
    return  %warning message already issued
end

%The path to the sample file
sampleFile = fullfile(downsampleDir,dsFile);
if ~exist(sampleFile,'file')
    fprintf('Can not find sample file at %s\n', sampleFile), return
end


%load the images
fprintf('Loading image volumes...')
templateVol = mhd_read(templateFile);

[~,~,ext] = fileparts(sampleFile);
switch ext
    case '.mhd'
        sampleVol = mhd_read(sampleFile);
    case '.tif'
        sampleVol = aratools.loadTiffStack(sampleFile);
end
fprintf('\n')

fprintf('multiplying sample volume\n')
sampleVol = sampleVol * mult; 
fprintf('\n')

if ara2sample
    fprintf('adjusting image\n')
    sampleVol = imadjustn(sampleVol);
end

%We should now be able to proceed with the registration. 
if ara2sample

    fprintf('Beginning registration of ARA to sample\n')
    %make the directory in which we will conduct the registration
    elastixDir = fullfile(downsampleDir,S.ara2sampleDir);
    if ~mkdir(elastixDir)
        fprintf('Failed to make directory %s\n',elastixDir)
    else
        fprintf('Conducting registration in %s\n',elastixDir)

        % Info on what was registered is logged here
        logFname = fullfile(elastixDir,'ARA_reg_log.txt');
        logRegInfoToFile(logFname,sprintf('Registered volume file: %s\n', sampleFile))
        [~,params]=elastix(templateVol,sampleVol,elastixDir,elastixParams);
        if ~iscell(params.TransformParameters)
            fprintf('\n\n\t** Transforming the ARA to the sample failed (see above).\n\t** Check Elastix parameters and your sample volumes\n\n')
        end
        %optionally remove files used to conduct registration 
        if S.removeMovingAndFixed
            delete(fullfile(elastixDir,[S.ara2sampleDir,'_moving*']))
            delete(fullfile(elastixDir,[S.ara2sampleDir,'_target*']))
        end
    end

end

if sample2ara
    fprintf('Beginning registration of sample to ARA\n')

    %make the directory in which we will conduct the registration
    elastixDir = fullfile(downsampleDir,S.sample2araDir);
    if ~mkdir(elastixDir)
        fprintf('Failed to make directory %s\n',elastixDir)
    else
        fprintf('Conducting registration in %s\n',elastixDir)
        [~,params]=elastix(sampleVol,templateVol,elastixDir,elastixParams);
        if ~iscell(params.TransformParameters)
            fprintf('\n\n\t** Transforming the sample to the ARA failed (see above).\n\t** Check Elastix parameters and your sample volumes\n')
            fprintf('\t** Not initiating inverse transform.\n\n')
            return
        end
    end

if ~suppressInvertSample2ara
        fprintf('Beginning inversion of sample to ARA\n')
        inverted=invertElastixTransform(elastixDir);
        save(fullfile(elastixDir,S.invertedMatName),'inverted')

        %Now we can transform the sparse points files 
        invertExportedSparseFiles(inverted)
    end
    if S.removeMovingAndFixed
        delete(fullfile(elastixDir,[S.sample2araDir,'_moving*']))
        delete(fullfile(elastixDir,[S.sample2araDir,'_target*']))
    end
end

fprintf('\nFinished\n')




function logRegInfoToFile(fname,dataToLog)
    %Write string dataToLog to fname. 
    %This little function is just to make it easier to log identity of the channel being registered 

    fid = fopen(fname,'w+');
    if fid<0
        fprintf('FAILED TO WRITE LOG DATA TO FILE %s\n',fname)
        return
    end
    fprintf(fid,dataToLog);
    fclose(fid);
