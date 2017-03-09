function [ARApoints,treeData]=processTreeData(points,varargin)
% Generate a structure that quantifies neurite trees by brain in a variety of different ways
%
%
% function [ARApoints,treeData]  aratools.sparse.processTreeData(points,'param1',val1,...)
%
%
% Purpose 
% Uses the structures produced by pointsInARA to determine the brain area associated
% with each leaf in a neurite tree. Also upsamples neurite trees and assigns each point
% to a brain area. This is used to work out length of tree by area. 
%
%
% Inputs (required)
% points - one of: 
%          a) the relative or absolute path to a csv file containing data exported 
%          from a tree .mat file or a gogglePoint .yml file. The only constraint 
%          is that the last three columns of this file should be the z, x, andy y
%          locations of the data point. 
%          b) a path within a sample directory (BATCH MODE). e.g. 'downsampled/sample2ARA/'
%             In this case processTreeData is called from the root dir of all experiments 
%             and iterates through all experiments, processing each in turn. See example 2, 
%             below. When called this way, results are saved as mat files in each directory.
%
% Inputs (optional - param/value pairs)
% 'useCachedAtlas' - false by default. If true we assign points based on the atlas currently 
%                    cached in the base workspace. This allows us to, for instamce, switch 
%                    between smoothed and on-smoothed atlasses. 
%
%
% Outputs
% ARApoints - a structure containing the processed data. w
% treeData - the output of exportedCSV2tree 
%
%
% Examples
% 1. 
% >> cd YH163
% >> out = aratools.sparse.processTreeData('downsampled/sample2ARA/YH163_traced_cells_tree_01.csv')
% out = 
%
%          ind: [72x1 double]
%          ...
%
%
% 2.  (BATCH MODE - returns array of the above output structures)
% >> cd ~/sonastv/Data/Mrsic-Flogel/hanyu
% >> out = aratools.sparse.processTreeData('downsampled/sample2ARA');
%
% ENTERING BATCH MODE
% 1/14. analysing YH102_150615/downsampled/sample2ARA/YH102_traced_cells.csv
% 2/14. analysing YH121_150707/downsampled/sample2ARA/YH121_traced_cells_01.csv
% 3/14. analysing YH124_150713/downsampled/sample2ARA/YH124_traced_cells_01.csv
% ...
%
%
%
% NOTE:
% If you have produced a processed tree data set and wish to change atlas, 
% you should run aratools.sparse.recomputeARAassignments. e.g.
%  dataSmoothed = aratools.sparse.recomputeARAassignments(dataOrig,'useCachedAtlas',true)
%
%
% --
% Rob Campbell - Basel 2105
%
% See also:
% groupARAindexes, pointsByAreaPlot, aratools.sparse.recomputeARAassignments, exportedCSV2tree,
% upsampleNeuriteTree



% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
%Parse optional arguments
params = inputParser;

params.CaseSensitive=false;
params.addParamValue('useCachedAtlas', false, @(x) islogical(x) | x==1 | x==0);
params.parse(varargin{:});

useCachedAtlas = params.Results.useCachedAtlas;



%-----------------------------------------------------------------------------------------------
if isempty(strfind(points,'.csv'))

	fprintf('ENTERING BATCH MODE\n')

	[allCells,summary,byAnimal,byCell] = listAllTracedCells(points);

	%recursive call of processTreeData
	n=1;

	cellIDs = allCells.keys;
	for ii=1:length(cellIDs)
		fprintf('\n%d/%d. Getting data from %s\n',ii,length(cellIDs),allCells(cellIDs{ii}) )
		tmp = aratools.sparse.processTreeData(allCells(cellIDs{ii}),varargin{:});
		if isempty(tmp)
			continue
		end
		tmp.details = byCell.(cellIDs{ii});
		ARApoints(n) = tmp;
		n=n+1;
	end

	fprintf('Added %d traced cells\n',n-1)
	return

end %if isempty(strfind(points,'.csv'))
%-----------------------------------------------------------------------------------------------






ARApoints=struct;

if ~exist(points,'file')
	fprintf('%s: can not find points file %s. Quitting\n', mfilename, points)
	return
end

%generate ARApoints file path to load
pathToMAT = strrep(points,'.csv','_pointsInARA.mat');
if ~exist(pathToMAT,'file')
	fprintf('No file %s. Skipping. Did you run pointsInARA?\n',pathToMAT)
	ARApoints=[];
	return
end

treeData=exportedCSV2tree(points);
load(pathToMAT) %Loads ARApoints 

if length(treeData.Node) ~= length(ARApoints.pointsInARA.rawSparseData.ARAindex)
	fprintf('Imported tree is of length %d and ARApoints is of length %d. They must be equal. Skipping.\n',...
		length(treeData.Node),length(ARApoints.pointsInARA.rawSparseData.ARAindex))
	return
end


%Get the total length of the tree in microns
voxelSize = str2num(ARApoints.voxelSize);
segments = treeData.getsegments;
d=0;
for thisSegment=segments
	d = d+pathDistance(treeData,thisSegment{1},voxelSize);
end
ARApoints.totalDistance=d;


%Log the ID of the soma location
ARApoints.somaIndex=ARApoints.pointsInARA.rawSparseData.ARAindex(1);
ARApoints.neuriteTree = treeData; %Add tree data to structure


%Now calculate the stats again for the leaves only
leafIndexes = [1,treeData.findleaves];
leafRawMatrix = ARApoints.rawSparseData(leafIndexes,:);
ARApoints.pointsInARA.leaves = aratools.sparse.assignToARA(ARApoints, leafRawMatrix,'useCachedAtlas',useCachedAtlas);



%Now we up-sample and calculate the stats for the upsampled data
details.upSampleResolution=0.2;
upSampledPoints=upsampleNeuriteTree(treeData,details.upSampleResolution);
upSampledPoints = round(upSampledPoints);
 fprintf('Upsampled from %d points to %d points with upsample factor %0.2f.\n', ...
            length(ARApoints.rawSparseData), length(upSampledPoints), details.upSampleResolution)

ARApoints.pointsInARA.upSampledPoints = aratools.sparse.assignToARA(ARApoints,upSampledPoints,...
	'details',details, ...
	'useCachedAtlas',useCachedAtlas, ...
	'dataColumns',ARApoints.rawSparseDataColumns-2);



%check that all non-downsampled points are in the upsampled points
uUp = unique(ARApoints.pointsInARA.upSampledPoints.ARAindex);
uInd = unique(ARApoints.pointsInARA.rawSparseData.ARAindex);

%Check whether there are values in the raw data that are not in the upsampled data. 
delta=setdiff(uInd,uUp);
if ~isempty(delta)
	fprintf('*** WARNING: %s finds that points in original data not present in the upsampled data. ***\n',mfilename)
	for ii=1:length(delta)
		fprintf('\tArea %d (%s)\n',delta(ii), structureID2name(delta(ii)))
	end
end


%log that we used the cached atlas if this was requested
if useCachedAtlas
	ATLAS = aratools.atlascacher.getCachedAtlas;
	ATLAS.atlasVolume = [];
	ARApoints.atlas = ATLAS;
end





function d=pathDistance(treeData,pth,voxelSize)
	%Sum the euclidean distance along the path of points defined by pth
	d=0;

	for ii=1:length(pth)-1
		m = [treeData.Node{pth(ii)};
			treeData.Node{pth(1+ii)}];
		d=d+pdist(m*voxelSize);
	end
	d=round(d);

