function vol = getAreaVolume(areaName)
%% Get the volume of an area from the ARA in mm^2
%
% function vol = getAreaVolume(areaName)
%
% 
% Inputs
%   areaName   - String or area ID from ARA 3D matrix of area labels
%
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

ARA = aratools.atlascacher.getCachedAtlas;

verbose=0;

% Find the number of voxels associated with each ID and multiply by voxel size
numVoxels=0;
for ii=1:length(childTable.id)
    thisID = childTable.id(ii);
    if size(childTable,1)>1 && thisID == areaID
        continue
    end
    if verbose
        fprintf('Area %s as %d voxels\n', childTable.name{ii}, length(find(ARA.atlasVolume==thisID)))
    end
    numVoxels = numVoxels + length(find(ARA.atlasVolume==thisID));
end


% Number of square mm (so E-3 instead of E-6) per side of the brain (0.5)
vol = numVoxels * (ARA.voxelSize * 1E-3)^3 * 0.5;
