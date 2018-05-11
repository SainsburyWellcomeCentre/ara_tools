function varargout = exportMaSIVNeuriteTree2SWC(neuriteTree,fname)
% export a neurite tree to an SWC text file or return it as a matrix
%
% function logging = aratools.utils.exportMaSIVNeuriteTree2SWC(neuriteTree,fname)
%
%
% Purpose
% Clicked point data are stored in a YAML file that lists the voxels that contain 
% clicked points, the series of the points, and color associated with them. This 
% function exports the point list to a csv file that is in SWC format.
% http://www.neuronland.org/NLMorphologyConverter/MorphologyFormats/SWC/Spec.html
%
%
% Inputs
% neuriteTree - an instance of the neurite tree class. (i.e. not the cell array
%               returned by the MaSIV neurite tracer but one of its cells)
% fname - path to the csv file that will contain the exported data. 
% 
%
% Output CSV format
% The returned the exported data are in following format:
% Columns are in the order: ID,tag,X,Y,Z,r,P
% ID  - Tracing point number (sequential integers, starting from 1)
% Tag - The structural domain: 1 for soma, 2 for axon, 3 for dendrite, 4 for apical dendrite, 5 custom, 6 unspecified neurites, 7 glia processes
% X - X position in microns
% Y - Y position in microns
% Z - Z position in microns
% R - The local radius of the branch (also in microns)
% P - The ID of the parent node to which the current point is attached
% 
% The root node has an ID of 1 and a P of -1
%
%
% Outputs
% logging - [optional] contains the names of the files that were created 
%
%
% Examples
% mySWC=aratools.utils.exportMaSIVNeuriteTree2SWC(xylemObject.data(1).neuriteTree);
%
%
%
% Rob Campbell - Basel 2017
%
% See also: convertMarkerStructToTable, readSimpleYAML, exportMaSIVPoints2Lasagna




if ~strcmp(class(neuriteTree),'tree')
    fprintf('neuriteTree should be of class "tree", it is of class %s\n',class(neuriteTree))
    return
end

if nargin<2
    fname = [];
end

if nargin<3
    downSample=[1,1];
end


if isempty(fname) & nargout==0
    fprintf('No outputs requested\n')
    return
end



% If the nodes are not structures, then this is a registered tree
% Dump tree to a string using the dumptree method in matlab-tree
if isstruct(neuriteTree.Node{1})
    treeAsTextDump = neuriteTree.dumptree( @(n) sprintf('%0.3f,%0.3f,%0.3f',n.zVoxel,n.xVoxel,n.yVoxel) );
else
    voxelSize = 25; %TODO: hard-coded voxel size
    treeAsTextDump = neuriteTree.dumptree( @(n) sprintf('%0.3f,%0.3f,%0.3f',[n(3),n(1),n(2)]*voxelSize) );
end



% treeAsTextDump has columns:
% id, parent, z, x, y

if length(treeAsTextDump)==0
    fprintf('Something went wrong with the tree dump: no data were returned\n')
    return
end

treeAsTextDump = str2num(treeAsTextDump);
%Re-arrange the columns for SWC happiness
swcDump = zeros(size(treeAsTextDump,1),7);
swcDump(:,1) = treeAsTextDump(:,1);
swcDump(1,2) = 1; %soma
swcDump(2:end,2) = 2; %axon
swcDump(:,3) = treeAsTextDump(:,4);
swcDump(:,4) = treeAsTextDump(:,5);
swcDump(:,5) = treeAsTextDump(:,3);
swcDump(:,6) = 1; %set everything to 1 micron. We don't have a measure of this. 

swcDump(:,7) = treeAsTextDump(:,2);
swcDump(1,7) = -1; %root is -1




%Save to a file 
if ~isempty(fname)
    dlmwrite(fname, swcDump, 'delimiter', ' ', 'precision', 6);
end



%Return as a matrix if the user asked for this
if nargout>0
    varargout{1}=swcDump;
end
