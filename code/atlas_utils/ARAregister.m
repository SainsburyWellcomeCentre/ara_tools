function ARAregister(varargin)
% Register sample brain to the ARA and create transform parameters for sparse points
%
% function ARAregister('param1',val1, 'param2',val2, ...)
%
% Purpose
% Register sample brain to the ARA (Allen Reference Atlas) in various ways. 
% This function assumes you have a directory containing your brain in the same
% voxel size as the ARA. You can generate this for instance, by running the
% downsampleAllChannels command from stitchit.
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
%                   By default uses value derived from the toolbox YML file using 
%                   the function aratools.getDownSampledDir.
% 'ara2sample' - [bool, default true] whether to register the ARA to the sample
% 'sample2ara' - [bool, default true] whether to register the sample to the ARA
% 'suppressInvertSample2ara' - [bool. default false] if true, the inverse transform is not
%                            calculated if the sample2ara transform is performed.
%                            You need the inverse transform if you want to go on to 
%                            register sparse points to the ARA. 
% 'elastixParams' - paths to parameter files. By default we use those in ARA_tools/elastix_params/
% 'channel' - If missing an interactive selector at the command line appears. If present,
%             channelToRegister should be an integer that corresponds channel IDs embdedded 
%             in downsampled file names. For example: dsXYZ001_25_25_ch02.tiff is channel 2.
%             NOTE: this input is ignored if only one downsampled file is present. 
% 'medFiltSample' - False by default. If true, the sample image is filtered with a 3D median
%             filter of width 7 before registration. If medFiltSample is an integer greater 
%             than 1, then the sample image is filtered by this amount instead. 
%             NOTE: The *unfiltered* result image will appear in the registration directory 
%             as "result.tiff".
% 'action' - If a registration already has been done, then ARAregister does nothing. This is 
%            over-ridden by the "action" argument:
%            'delete' -- deletes existing registrations (WITH NO CONFIRMATION) and replace all with a new one. 
%            'keep' -- retain existing registrations but add a new one.
%            'tidy' -- delete all registrations apart from a named one which is chosen at the CLI. Then do nothing.
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
% - Run on channel 4
% >> ARAregister('channel',4)
%
% - Run registration with a filtered sample stack (this may improve the registration significantly)
% >> ARAregister('medFiltSample',true)
%
% Rob Campbell - Basel, 2015
%
% Also see from this repository:
% invertExportedSparseFiles (and transformSparsePoints), aratools.rescaleAllSparsePoints
%
% Changes
% 2020/03/18 - Modifies the parameters automaticaly for the correct voxel size. It does this
%              by loading them into a structure, altering this, then feeding this into the 
%              elastix function.


%Parse input arguments
S=settings_handler('settingsFiles_ARAtools.yml');

params = inputParser;
params.CaseSensitive=false;

params.addParamValue('downsampleDir', aratools.getDownSampledDir,@ischar)
params.addParamValue('ara2sample', true, @(x) islogical(x) || x==1 || x==0)
params.addParamValue('sample2ara', true, @(x) islogical(x) || x==1 || x==0)
params.addParamValue('channel', [], @(x) isnumeric(x) && isscalar(x))
params.addParamValue('suppressInvertSample2ara', false, @(x) islogical(x) || x==1 || x==0)
params.addParamValue('medFiltSample', false, @(x) islogical(x) || (isint(x) && x>=0))
params.addParamValue('action', 'none', @(x) ischar(x) && (strcmpi('none',x) || strcmpi('delete',x) || strcmpi('keep',x) || strcmpi('tidy',x)))


toolboxPath = fileparts(which(mfilename));
toolboxPath = fileparts(fileparts(toolboxPath));
elastix_params_default = {fullfile(toolboxPath,'elastix_params','01_ARA_affine.txt'),
                fullfile(toolboxPath,'elastix_params','02_ARA_bspline.txt')};
params.addParamValue('elastixParams',elastix_params_default,@iscell)


params.parse(varargin{:});
downsampleDir = params.Results.downsampleDir;
ara2sample = params.Results.ara2sample;
sample2ara = params.Results.sample2ara;
channel = params.Results.channel;
suppressInvertSample2ara = params.Results.suppressInvertSample2ara;
elastixParams = params.Results.elastixParams;
medFiltSample = params.Results.medFiltSample;
action = lower(params.Results.action);

if ~exist(downsampleDir,'dir')
    fprintf('%s failed to find downsampled directory "%s"\n', mfilename, downsampleDir), return
end


% Make the registration directory if needed
existingRegDir=aratools.findRegDirs;

if isempty(existingRegDir)
    % If no registration directories exist, we make one
    regDir = aratools.makeRegDir;

elseif ~isempty(existingRegDir) && strcmp('delete',action)
    % Delete existing registration directory tree and build a new one
    if exist(S.regDir,'dir')
        fprintf('Deleting all existing registrations\n')
        rmdir(S.regDir,'s')
    end
    regDir = aratools.makeRegDir;

elseif ~isempty(existingRegDir) && strcmp('keep',action)
    % Add a new registration directory
    regDir = aratools.makeRegDir;
    fprintf('Registering into new directory %s\n', regDir)

elseif ~isempty(existingRegDir) && strcmp('tidy',action)
    % Delete all but one registration
    aratools.tidyRegistrations
    return

else
    % Otherwise we ask the user what to do
    fprintf('\nFound the following existing registration directories:\n')
    cellfun(@(x) fprintf('%s\n',x), existingRegDir)
    fprintf('\nDoing nothing!\nIf you wish, you may re-run ARAregister using the ''action'' parameter to do one of the following:\n')
    fprintf('1. DELETE existing registrations and replace all with a NEW one.\n')
    fprintf('2. KEEP existing registrations but ADD a new one.\n')
    fprintf('3. TIDY by DELETING all registrations apart from a named one.\n')
    return
end


if sample2ara && suppressInvertSample2ara
    invertSample2ara = false;
else
    invertSample2ara = true ;
end

% Set median filter width to a default value if the user set this input argument to true
if medFiltSample==true
    medFiltSize=7;
end

% Handle scenario where the user supplied a width to filter by
if medFiltSample>1
    medFiltSize = medFiltSample;
    medFiltSample = true;
    if mod(medFiltSample,2)==0
        medFiltSize=medFiltSize+1;
    end
end


%Check that the elastixParams are there
for ii=1:length(elastixParams)
    if ~exist(elastixParams{ii},'file')
        error('Can not find elastix param file %s',elastixParams{ii})
    end
end

% We will now load the parameters into a cell array of structures and then modify it
% so that the correct pixel size is used. 
for ii=1:length(elastixParams)
    elastixParams{ii}=elastix_parameter_read(elastixParams{ii});
    if isfield(elastixParams{ii},'FinalGridSpacingInVoxels')
        elastixParams{ii}.FinalGridSpacingInVoxels(:) = S.ARAsize;
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
    elseif ~isempty(channel)
        % Find the selected channel in the list of file names
        tok=cellfun(@(x) regexp(x,'.*_\d+_\d+_ch(\d+)\..+','tokens'),dsFile,'UniformOutput',false);
        matchChans = cellfun(@(x) strcmp(x,sprintf('%02d',channel)),[tok{:}]);
        if ~any(matchChans)
            % Requested channel not found
            fprintf('Requested channel %d does not exist. Available files:\n',channel);
            cellfun(@(x) fprintf('%s\n',x), dsFile)
            return
        end
        if sum(matchChans)>1
            % Multiple channels found
            fprintf('Multiple channels match requested channel number %d. Available files:\n',channel);
            cellfun(@(x) fprintf('%s\n',x), dsFile)
            return
        end
        dsFile = dsFile{find(matchChans)};

    else

        %Display choices to screen and allow user to choose which volume to register
        fprintf('\n Which volume do you want to use for registration?\n')
        for ii=1:length(dsFile)
            fprintf('%d. %s\n',ii,dsFile{ii})
        end
        qs=sprintf('[1 .. %d]? ', length(dsFile));
        userAnswer = [];
        while isempty(userAnswer)
            userAnswer = input(qs,'s');
            userAnswer = str2num(userAnswer);
            if ~isempty(userAnswer) && userAnswer>=1 && userAnswer<=length(dsFile)
                break
            else
                userAnswer=[];
            end
        end

        dsFile = dsFile{userAnswer};

    end

end

fprintf('\nRunning registration on volume %s\n\n',dsFile)


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


% If median filtering was requested, filter the sample image using a filter
% of the desired width.
if medFiltSample
    origVol = sampleVol;
    sampleVol = medfilt3(sampleVol, repmat(medFiltSize,1,3));
end


% Log to a file the registration parameters
logFname = fullfile(regDir,'registration_log.txt');
logRegInfoToFile(logFname,sprintf('Analysis carried out: %s\n', datestr(now,'yyyy-mm-dd_HH-MM-SS')),true)
logRegInfoToFile(logFname,sprintf('Directory: %s\n', regDir))
logRegInfoToFile(logFname,sprintf('Voxel size: %d microns\n', S.ARAsize))
logRegInfoToFile(logFname,sprintf('Sample volume file: %s\n', sampleFile))
logRegInfoToFile(logFname,sprintf('Template file: %s\n', templateFile))

elastix_version=elastix('version');
logRegInfoToFile(logFname,sprintf('Registration software: %s\n', elastix_version))
if ~medFiltSample
    logRegInfoToFile(logFname,sprintf('Filtering of sample volume: none\n'))
else
    logRegInfoToFile(logFname,sprintf('Filtering of sample volume: medfilt3 with filter size %d\n',medFiltSize))
end

logRegInfoToFile(logFname,sprintf('\n\n**************  LOGGING  **************\n\n'))

%We should now be able to proceed with the registration. 
elastixDir = {};
if ara2sample
    %make the directory in which we will conduct the registration
    elastixDir{end+1} = fullfile(regDir,S.ara2sampleDir);
    if ~mkdir(elastixDir{end})
        fprintf('Failed to make directory %s',elastixDir{end})
    else

        writeLoggingLine(logFname,sprintf('Beginning registration of ARA to sample\n'))
        writeLoggingLine(logFname,sprintf('Conducting registration in %s\n',elastixDir{end}))
        [~,params]  = elastix(templateVol,sampleVol,elastixDir{end},-1,'paramstruct',elastixParams);
        writeLoggingLine(logFname,sprintf('Finished registration of ARA to sample\n'))

        if ~iscell(params.TransformParameters)
            msg=sprintf('\n\n\t** Transforming the ARA to the sample failed (see above).\n\t** Check Elastix parameters and your sample volumes\n\n');
            writeLoggingLine(logFname,msg)
        else
            if medFiltSample
                nonFiltFname = fullfile(elastixDir{end},'result.tiff');
                writeLoggingLine(logFname,sprintf('Tansforming the original dataset to generate a non-filtered image: %s\n',nonFiltFname))
                RES = transformix(origVol,elastixDir{end});
                save3Dtiff(RES,nonFiltFname);
            end
        end

        %optionally remove files used to conduct registration 
        if S.removeMovingAndFixed
            delete(fullfile(elastixDir{end},[S.ara2sampleDir,'_moving*']))
            delete(fullfile(elastixDir{end},[S.ara2sampleDir,'_target*']))
        end
    end

end


if sample2ara
    %make the directory in which we will conduct the registration
    elastixDir{end+1} = fullfile(regDir,S.sample2araDir);
    if ~mkdir(elastixDir{end})
        writeLoggingLine(logFname,sprintf('Failed to make directory %s\n',elastixDir{end}))

    else
        writeLoggingLine(logFname,sprintf('Beginning registration of sample to ARA\n'))
        writeLoggingLine(logFname,sprintf('Conducting registration in %s\n',elastixDir{end}))
        [~,params]=elastix(sampleVol,templateVol,elastixDir{end},-1,'paramstruct',elastixParams); 
        writeLoggingLine(logFname,sprintf('Finished registration of sample to ARA\n'))

        if ~iscell(params.TransformParameters)
            writeLoggingLine(logFname,sprintf('\n\n\t** Transforming the sample to the ARA failed (see above).\n\t** Check Elastix parameters and your sample volumes\n'))
            writeLoggingLine(logFname,sprintf('\t** Not initiating inverse transform.\n\n'))
            return
        else
            if medFiltSample
                nonFiltFname = fullfile(elastixDir{end},'result.tiff');
                writeLoggingLine(logFname,sprintf('Tansforming the original dataset to generate a non-filtered image: %s\n',nonFiltFname))
                RES = transformix(origVol,elastixDir{end});
                save3Dtiff(RES,nonFiltFname);
            end
        end

    end

if ~suppressInvertSample2ara
        writeLoggingLine(logFname,sprintf('Beginning inversion of sample to ARA\n'))
        inverted=invertElastixTransform(elastixDir{end});
        save(fullfile(elastixDir{end},S.invertedMatName),'inverted')

        %Now we can transform the sparse points files 
        invertExportedSparseFiles(inverted)
        writeLoggingLine(logFname,sprintf('Finished inversion of sample to ARA\n'))
    end
    if S.removeMovingAndFixed
        delete(fullfile(elastixDir{end},[S.sample2araDir,'_moving*']))
        delete(fullfile(elastixDir{end},[S.sample2araDir,'_target*']))
    end
end

logRegInfoToFile(logFname,sprintf('\n\nCompleted at: %s\n', datestr(now,'yyyy-mm-dd_HH-MM-SS')))

% Copy log files into all reg-sub-dirs
cellfun(@(x) copyfile(logFname,x), elastixDir)

fprintf('\nFinished\n')




function logRegInfoToFile(fname,dataToLog,flush,echo)
    %Write string dataToLog to fname.
    %This little function is just to make it easier to log identity of the channel being registered
    %
    % fname - file to which we will log stuff
    % dataToLog - text to write
    % flush - optional. False if missing or empty. If true, we wipe file "fname" and start over.
    %         i.e. if flush is false we append.
    % echo - true by default. copies to screen the line written to file

    if nargin<3 || isempty(flush)
        flush=false;
    end

    if nargin<4
        echo=true;
    end

    if flush
        fid = fopen(fname,'w+');
    else
        fid = fopen(fname,'a+');
    end

    if fid<0
        fprintf('FAILED TO WRITE LOG DATA TO FILE %s\n',fname)
        return
    end

    fprintf(fid,dataToLog);

    fclose(fid);

    if echo
        fprintf(dataToLog)
    end


function writeLoggingLine(fname,messageToLog)
    % Function writes a line to the logging file, fname, in the format:
    % yyy-mm-dd_HH:MM:SS - INFO - mfilename - message
    % echos to screen
    % 
    % messageToLog - a string. e.g. output of sprintf. It is chomped. 

    fid = fopen(fname,'a+');
    msg = sprintf('%s - INFO - %s - %s\n', ...
        datestr(now,'yyyy-mm-dd_HH-MM-SS'), ...
        mfilename, chomp(messageToLog));
    fprintf(fid,msg);
    fclose(fid);

    fprintf(msg) % write to screen
