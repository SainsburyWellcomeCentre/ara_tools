function [ARApoints,treeData]=getLeavesInARA(points,labels)
% generate a structure listing the brain area associated with each leaf
%
%
% function out=getLeavesInARA(points)
%
%
% Purpose 
% Uses the point sturcture calculated by pointsInARA to determine the brain area associated
% with each leaf. 
%
%
% Inputs
% points - one of: 
%          a) the relative or absolute path to a csv file containing data exported 
%          from a tree .mat file or a MaSIV points .yml file. The only constraint 
%          is that the last three columns of this file should be the z, x, andy y
%          locations of the data point. 
%          b) a path within a sample directory (BATCH MODE). e.g. 'downsampled/sample2ARA/'
%             In this case getLeavesInARA is called from the root dir of all experiments 
%             and iterates through all experiments, processing each in turn. See example 2, 
%             below. When called this way, results are saved as mat files in each directory.
%
%
% Outputs
% out - a structure with the following fields
%       out.ind  - [n-by-1 vector] The index in the atlas with which this point
%                  is associated. Each point is a leaf. The first point, however,
%                  is the root node!
%  		pointsFname - [csv file name]
%       out.voxelSize - the voxel size of the atlas
%       out.isWhiteMatter - a vector of length out.ind indicate which members of out.ind 
%						   correspond to a white matter termination.
%       out.distToRoot - the distance between each leaf and the root in microns
%       out.distToNearestBranch - the distance between each leaf and its nearest branch node
%       out.totalDistance - the total traced length of the tree in microns
%
%
% Examples
% 1. 
% >> cd YH163
% >> out=getLeavesInARA('downsampled/sample2ARA/YH163_traced_cells_tree_01.csv')
% out = 
%
%          ind: [72x1 double]
%          ...
%
%
% 2.  (BATCH MODE - returns array of the above output structures)
% >> cd ~/sonastv/Data/Mrsic-Flogel/hanyu
% >> out=getLeavesInARA('downsampled/sample2ARA');
%
% ENTERING BATCH MODE
% 1/14. analysing YH102_150615/downsampled/sample2ARA/YH102_traced_cells.csv
% 2/14. analysing YH121_150707/downsampled/sample2ARA/YH121_traced_cells_01.csv
% 3/14. analysing YH124_150713/downsampled/sample2ARA/YH124_traced_cells_01.csv
% ...
%
%
% --
% Rob Campbell - Basel 2105
%
% See also:
%
% groupARAindexes, pointsByAreaPlot

if nargin<2
	labels=getAllenStructureList; %load the Allen structure list because we need to find areas that are white matter
end

if isempty(strfind(points,'.csv'))

	fprintf('ENTERING BATCH MODE\n')

	[allCells,summary,byAnimal,byCell] = listAllTracedCells(points);

	%recursive call of getLeavesInARA
	n=1;
	labels = getAllenStructureList; %ensures that we don't have to load this each time 

	cellIDs = allCells.keys;
	for ii=1:length(cellIDs)
		fprintf('%d/%d. Getting data from %s\n',ii,length(cellIDs),allCells(cellIDs{ii}) )
		tmp = getLeavesInARA(allCells(cellIDs{ii}),labels);
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


ARApoints=struct;
if ~exist(points,'file')
	fprintf('%s: can not find points file %s. Quitting\n', mfilename, points)
	return
end

%generate ARApoints file path
pathToMAT = strrep(points,'.csv','_pointsInARA.mat');
if ~exist(pathToMAT,'file')
	fprintf('No file %s. Skipping. Did you run pointsInARA?\n',pathToMAT)
	ARApoints=[];
	return
end

treeData=exportedCSV2tree(points);
load(pathToMAT) %Loads ARApoints

if length(treeData.Node) ~= length(ARApoints.ind)
	fprintf('Imported tree is of length %d and ARApoints is of length %d. They must be equal. Skipping.\n',...
		length(treeData.Node),length(ARApoints.ind))
	return
end


%Record the brain area associated with each leaf and the root node (index 1)
ARApoints.allNodeInd = ARApoints.ind; %The index associated with each node
ARApoints.ind = ARApoints.ind([1,treeData.findleaves]); 
ARApoints.dataType = 'leaves';

%A bool to indicate which of these is definitely a white matter termination
whiteMatterInd = labels.id([strmatch('corpus callosum',labels.name );...
				strmatch('fiber',labels.name );...
				strmatch('internal capsule',labels.name );...
				strmatch('cingulum bundle',labels.name )]);
ARApoints.isWhiteMatter = logical(ismember(ARApoints.ind, whiteMatterInd))';


%Calculate some stats
%Get the distance from each leaf to the root node and also to the nearest branch
L=[1,treeData.findleaves];


voxelSize = str2num(ARApoints.voxelSize);
for ii=1:length(L)
	pth = treeData.pathtoroot(L(ii));
	ARApoints.distToRoot(ii) = pathDistance(treeData,pth,voxelSize); %distance to root
	%find nearest branch node
	for kk=1:length(pth)
		if length(treeData.getchildren(pth(kk)))>1
			break
		end
	end
	ARApoints.distToNearestBranch(ii) = pathDistance(treeData,pth(1:kk),voxelSize); %distance to root
end

%Get the total length of the tree in microns
segments = treeData.getsegments;
d=0;
for thisSegment=segments
	d = d+pathDistance(treeData,thisSegment{1},voxelSize);
end
ARApoints.totalDistance=d;

%Log the ID of the soma location
ARApoints.somaIndex=ARApoints.ind(1);
ARApoints.neuriteTree = treeData;

% We can't meaningfully calculate axon length by area at this point, since areas
% will likely be pooled and this will change the way this calculation is performed. 


function d=pathDistance(treeData,pth,voxelSize)
%Sum the euclidean distance along the path of points defined by pth
d=0;

for ii=1:length(pth)-1
	m = [treeData.Node{pth(ii)};
		treeData.Node{pth(1+ii)}];
	d=d+pdist(m*voxelSize);
end
d=round(d);