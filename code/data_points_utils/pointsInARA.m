 function varargout=pointsInARA(pointsData)
% generate a structure listing the brain area associated with each sparse data point
%
%
% function out=pointsInARA(pointsData)
%
%
% Purpose 
% Generate a structure listing the brain area index associated with each sparse data point.
% This is a fairly low-level function called by other analysis functions, but you may
% use it directly if needed. 
%
%
% Inputs
% pointsData - one of: 
%          a) the relative or absolute path to a csv file containing data exported 
%          from a tree .mat file or a MaSIV points .yml file. The only constraint 
%          is that the last three columns of this file should be the z, x, and y
%          locations of the data point. 
%          ** If it was a tree AND we run in batch mode then we also resample the tree to **
%          ** a resolution of 5 microns and get the area associated with each point.      **
%          b) the imported matrix from one of the above points files.
%          c) a path within a sample directory (BATCH MODE). e.g. 'downsampled/sample2ARA/'
%             In this case pointsInARA is called from the root dir of all experiments 
%             and iterates through all experiments, processing each in turn. See example 2, 
%             below. When called this way, results are saved as mat files in each directory.
%
%
% Outputs
% out - a structure with the following fields
%       out.ind  - [n-by-1 vector] The index in the atlas with which this point
%                  is associated.
%       pointsFname - [csv file name]
%       out.voxelSize - the voxel size of the atlas
%
%  *no outputs in batch mode: saves .mat files in the same directory as each CSV file* 
%
%
% Examples
% 1. 
% >> aratools.cacheAtlasToWorkSpace(25)
% >> cd YH163
% >> out=pointsInARA('downsampled/sample2ARA/YH163_traced_cells_tree_01.csv')
%
% out = 
%
%         ind: [981x1 double]
% pointsFname: [csv file name]
%       notes: ''
%   voxelSize: [string]
%
%
% 2.  (BATCH MODE)
% >> cd ~/sonastv/Data/Mrsic-Flogel/hanyu
% >> pointsInARA('downsampled/sample2ARA')
%
% ENTERING BATCH MODE
% 1/14. analysing YH102_150615/downsampled/sample2ARA/YH102_traced_cells.csv
% 2/14. analysing YH121_150707/downsampled/sample2ARA/YH121_traced_cells_01.csv
% 3/14. analysing YH124_150713/downsampled/sample2ARA/YH124_traced_cells_01.csv
% ...
%
% %Here is where the data are saved: 
% >>  ls YH102_150615/downsampled/sample2ARA/YH102_*mat
% YH102_150615/downsampled/sample2ARA/YH102_traced_cells_pointsInARA.mat
%
%
% --
% Rob Campbell - Basel 2105
%
%
% See also: brainAreaBarChart, pointsByAreaPlot


CACHED_ATLAS = aratools.atlascacher.getCachedAtlas;

if isempty(CACHED_ATLAS)
    fprintf('Please cache an atlas using aratools.cachceAtlasToWorkSpace\n')
    return
end


if nargin<1
    fprintf('Function requires one input argumement. see help %s\n',mfilename)
    return
end




%------------------------------------------------------------------------------------------------------------
% 
% read data if the user has supplied a path to a points file
if isstr(pointsData) %enter recursive function call
    if isempty(strfind(pointsData,'.csv'))
        fprintf('ENTERING BATCH MODE\n\n')

        [dirs,details] = aratools.utils.returnProcessedExperiments(pointsData); %Read csv file "analysis_log.csv" and process all cells listed within it
        if isempty(dirs)
            fprintf('Found no directories with pattern %s\n',pointsData)
            return
        end
        fprintf('Found %d data directories\n',length(dirs))

        for ii=1:length(dirs)
            csvFiles = dir(fullfile(dirs{ii},'*.csv'));
            if ~isempty(csvFiles)
                for jj=1:length(csvFiles)
                    pathToCSV = fullfile(dirs{ii},csvFiles(jj).name);
                    fprintf('%d/%d. analysing %s -- %s\n',ii,length(dirs),pathToCSV, details(ii).notes)
                    ARApoints = pointsInARA(pathToCSV);
                    ARApoints.pointsDataArg=pointsData;
                    ARApoints.notes = details(ii).notes;
                    saveName = strrep(csvFiles(jj).name,'.csv','_pointsInARA.mat');
                    saveName = fullfile(dirs{ii},saveName);
                    fprintf(' ==> saving to %s\n\n',saveName)
                    save(saveName,'ARApoints')
                end
            end
        end
        
        fprintf('\nAll samples processed and data saved.\n ')
        return
    end
    if ~exist(pointsData,'file')
        fprintf('%s: can not find points file %s. Quitting\n', mfilename, pointsData)
        return
    end
    pointsFname = pointsData;
    pointsData = csvread(pointsFname);

    if nargout>0
        varargout{1}=[];
    end
else
    pointsFname='';
end
%------------------------------------------------------------------------------------------------------------


%Remove the atlas data from the atlas data structure and store the remanining meta-data
%alongside the points data. 
atlasVolume=CACHED_ATLAS.atlasVolume;
CACHED_ATLAS.atlasVolume=[];


%Start building the output structure
out.pointsFname=pointsFname;  %File name of the downsampled (and likely transformed) sparse points file
out.pointsDataArg=[];  %This is the argument with which we we called pointsInARA. If we did batchmode, we'll know what was done with this arg
out.voxelSize=getSampleVoxelSize(strtok(pointsFname,filesep));
out.atlas=CACHED_ATLAS; %The atlas data minus the actual atlas volume
out.rawSparseData=pointsData; %The raw points data from the original points file


%The order of the columns used to determine the brain area location. Must be ordered in the dims of the MHD
%The last three columns should be the point location data. 
%With a tree file, there will be 5 columns as the first two are the node ID and parent node ID. 
%With a MaSIV points file, the first column will be the cell series ID
out.rawSparseDataColumns=bsxfun(@plus, size(pointsData,2)-3,[3,2,1]);
out.notes='';


%This is a map that contains the different data formats
out.pointsInARA.rawSparseData = aratools.sparse.assignToARA(out,pointsData);



%Now we save a copy of the original traces from the neurite tracer

%Step 1: find the orginal sparse data file
tok=regexp(pointsFname,['(.*?',filesep,')'],'tokens');
pathToSparseData = fullfile(tok{1}{1},'sparsedata');

[~,tracedCSVfName] = fileparts(pointsFname);
originalSparseDataFile = fullfile(pathToSparseData, regexprep(tracedCSVfName,'_tree.*','.mat'));


%Step 2: if it's available, we load it, find the correctr trace and store this in the output structure
if exist(originalSparseDataFile,'file')
    tok=regexp(pointsFname,'_tree_(\d+)','tokens'); %Get the trace number
    traceNumber = str2num(tok{1}{1});
    fprintf('Incorporating original trace data from trace %d of this sample\n',traceNumber)
    load(originalSparseDataFile)
    out.origTrace=neurite_markers{traceNumber};
else
    fprintf('Can not find original sparse data file at %s\n')
end


if nargout>0
    varargout{1}=out;
end