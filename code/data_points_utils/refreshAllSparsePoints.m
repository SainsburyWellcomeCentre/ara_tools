function refreshAllSparsePoints
% Re-build all downsampled CSV files from MaSIV .mat files
%
% function refreshAllSparsePoints
%    
% Purpose
% Loop through all experiment directories and re-build all the cell 
% CSV files from MaSIV .mat files. 
% *** HARDCODED 25 MICRON ATLAS VOXEL SIZE ***
%
% Inputs
% None - just call from experiment root directory. 
%
% 


voxSize=25;

S=settings_handler('settingsFiles_ARAtools.yml');

[dirs,details] = aratools.utils.returnProcessedExperiments; %Read csv file "analysis_log.csv" and process all cells listed within it

fprintf('Found %d data directories\n',length(dirs))

try %so we don't change the path if there is an error
    ROOT_DIR = pwd;
    for ii=1:length(dirs)
        fprintf('\nRefreshing %s\n', dirs{ii});
        cd(dirs{ii});
        
        spFname=getSparseDataFileName;
        if isempty(spFname)
            fprintf('Unable to find sparse data in directory %s. SKIPPING\n',dirs{ii})
            cd(ROOT_DIR)
            continue
        end

        exportedTreesOrig=returnExportedSparseDataPaths(S.downSampledDir);

        downsampleVolumeAndData(-1,voxSize,spFname,0,0);

        exportedTreesNow=returnExportedSparseDataPaths(S.downSampledDir);

        if length(exportedTreesOrig) ~= length(exportedTreesNow)
            fprintf('The number of exported trees has changed from %d to %d\n',...
                length(exportedTreesOrig),length(exportedTreesNow))
        end


        %If necessary, flip the tree
        if exist(fullfile(S.downSampledDir,'flipDimsArray.mat'))
            fprintf('Flipping the tree\n')
            load(fullfile(S.downSampledDir,'flipDimsArray.mat'))
            flipDownSampledVolumeAndData([1,0,0],1) 
        end
        
        %If there is sample2ara directory with a transform, we transform the sparse points
        if ~exist(fullfile(S.downSampledDir,S.sample2araDir),'dir') %continue if no sample2ara directory exists
            continue
            cd(ROOT_DIR)
        end
        invertedFile = fullfile(S.downSampledDir,S.sample2araDir,'inverted.mat');
        if ~exist(invertedFile,'file') %continue if no MelastiX file exists in the directory
            continue
            cd(ROOT_DIR)
        end

        fprintf('Transforming sparse points...\n')
        L=load(invertedFile);
        f=fields(L);
        if length(f)>1
            error('More than one variable in inverted file %s\n', invertedFile)
        end
        inverted = L.(f{1});
        %Now we can transform the sparse points files 
        invertExportedSparseFiles(inverted)

        cd(ROOT_DIR)
    end
catch
    cd(ROOT_DIR)
    rethrow(lasterror)
end


cd(ROOT_DIR) %Be extra-sure

end %function refreshAllSparsePoints



function spFname=getSparseDataFileName
    D = dir(fullfile('sparsedata','*.mat'));
    if isempty(D)
        spFname=[];
        return;
    elseif length(D)>1
        fprintf('More than one mat file found in ./sparsedata\n')
        spFname=[];
        return
    else
        spFname = fullfile('sparsedata',D(1).name);        
    end
end


function out=returnExportedSparseDataPaths(downSampledDir)
    %Look for and return the paths of sparse data that were exported 
    out={};
    if ~exist(downSampledDir,'dir')
        fprintf('No "downsampled" directory in %s\n',pwd)
        return 
    end

    logFile = fullfile('downsampled','exportedDataLog.mat');
    if ~exist(logFile,'file')
        fprintf('No log file %s\n', logFile)
        return 
    end

    load(logFile)

    %Are all trees present? 
    for ii=1:length(logging)
        thisFile = fullfile(downSampledDir,logging(ii).fname);
        if ~exist(thisFile,'file')
            fprintf('Can not find %s\n', thisFile)
        end
        out{length(out)+1} = thisFile;
    end

 end