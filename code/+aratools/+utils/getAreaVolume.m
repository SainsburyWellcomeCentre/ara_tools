function vol = getAreaVolume(areaName,verbose)
%% Get the volume of an area from the ARA in mm^3
%
% function vol = getAreaVolume(areaName)
%
% Purpose
% Return volume of an area in mm^3
% 
% Inputs
%   areaName   - String or area ID from ARA 3D matrix of area labels
%   verbose - true by default
%
% Outputs
% vol - area volume in sq mm
%
%
% Examples
% >> aratools.utils.getAreaVolume(385)                  
%  ans =
%   3.6841
%
% >> aratools.utils.getAreaVolume('Primary visual area')
%  ans =
%   3.6841
%
% Rob Campbell 


if nargin<2
    verbose=false;
end

vol=[]; % so if there is an error we just return empty
if ischar(areaName)
    areaID = name2structureID(areaName);
    if isempty(areaID)
        return
    end
elseif isnumeric(areaName)
    areaID = areaName;
else
    error('Unknown class for input argument "areaName"')
end


% The child areas as a table (returns named area if there are no children)
childTable = getAllenStructureList('childrenOf',areaID);

if verbose
    disp(childTable)
end

ARA = aratools.atlascacher.getCachedAtlas;

% Find the number of voxels associated with each ID and multiply by voxel size
numVoxelsChildren=0;
numVoxelsParent=0;
for ii=1:length(childTable.id)
    thisID = childTable.id(ii);

    n = length(find(ARA.atlasVolume==thisID));

    if size(childTable,1)>1 && thisID == areaID
        fprintf('Parent area %s (ID=%d) volume: %d voxels\n', childTable.name{ii}, thisID, n)
        numVoxelsParent=n;
        continue
    end


    if verbose
        fprintf('Area %s (ID=%d) as %d voxels\n', childTable.name{ii}, thisID, n)
    end
    numVoxelsChildren = numVoxelsChildren + n;
end

if numVoxelsChildren==0 && numVoxelsParent>0
    numVoxels=numVoxelsParent;
elseif numVoxelsChildren>0
    numVoxels=numVoxelsChildren;
end


% Number of square mm (so E-3 instead of E-6) per side of the brain (0.5)
vol = numVoxels * (ARA.voxelSize * 1E-3)^3 * 0.5;
