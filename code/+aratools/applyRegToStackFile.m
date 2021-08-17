function success = applyRegToStackFile(dsStackFname,regDir)
    % Apply a transformation in regDir to file dsStackFname the output is saved to regDir
    %
    % function success = aratools.applyRegToStackFile(dsStackFname,regDir)
    %
    % Purpose
    % Typically the downsampled stack chosen for registration is that with little or no signal. 
    % You may, therefore, want to also register a stack that does contain signal. This function
    % takes the path to that stack as input argument along with the registration directory that
    % contains your parameter files. Typically this will be a sample2ARA directory, as it makes 
    % no sense to do theis for ARA2sample. 
    %
    % Inputs
    % dsStackFname - relative or absolute path to a downsampled tiff stack
    % regDir - relative or absolute path to a sample2ARA directory
    %
    % Outputs
    % success - true if command ran to completion
    %
    % Example
    % >> cd /mnt/data/mySampleDir
    % >> dsFile='downsampled_stacks/025_micron/ds_XY_sample_25_25_ch02_chan_2_red.tif'
    % >> regDir='registration/reg_01__2021_08_16_a/sample2ARA/';
    % >> aratools.applyRegToStackFile(dsFile,regDir)



    success = false;

    if ~exist(dsStackFname,'file')
        fprintf('Can not find file %s\n', dsStackFname)
        return
    end

    if ~exist(regDir,'dir')
        fprintf('Can not find directory %s\n', regDir)
        return
    end


    % Load the stack
    im = aratools.loadTiffStack(dsStackFname);



    % Get the transform parameters
    d=dir(fullfile(regDir,'TransformParameters.*.txt'));
    if isempty(d)
        fprintf('Found no transform parameter files in %s\n', regDir)
        return
    end


    melastix.updateTransformFileDirFields(regDir) %ensure that paths in param files are updated


    pathToTransformFile = fullfile(regDir,d(end).name);

    OUT=transformix(im,pathToTransformFile);

    if isempty(OUT)
        fprintf('Transform failed. transformix returned an empty array\n')
        return
    end


    % Copy the transformed file to the correct location
    [~,fname,ext]=fileparts(dsStackFname);
    fname = fullfile(regDir,[fname,ext]);

    fprintf('Saving to %s\n',fname)
    aratools.save3Dtiff(OUT,fname)

    success = true;
