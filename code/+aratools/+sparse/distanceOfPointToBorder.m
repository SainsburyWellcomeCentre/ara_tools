function pointsInARA=distanceOfPoinToBorder(pointsInARA)
% How far is each point from the border of the region to which it is assigned?
%
%
% function [ARApoints,treeData]=distanceOfPoinToBorder(pointsInARA)
%
%
% Purpose 
% Test function to get this working. How far is each point from the border of the area to
% which it is assigned? 
%
%
% Inputs
% pointsInARA is data(1).pointsInARA.leaves (or .upSampledPoints) 


CACHED_ATLAS = aratools.atlascacher.getCachedAtlas;
atlasVolume=CACHED_ATLAS.atlasVolume;
CACHED_ATLAS.atlasVolume=[];





%pre-allocate empty binarized atlasses
for ii = 1:length( pointsInARA.ARAindex )
    binarized_atlases{pointsInARA.ARAindex(ii)} = [];
end


for ii=1:size(pointsInARA.sparsePointMatrix,1)
    ind = pointsInARA.sparsePointMatrix(ii,:);
    myIndex=atlasVolume(ind(1),ind(2),ind(3));
    if myIndex ~= pointsInARA.ARAindex(ii)
        fprintf('Calculated index does not equal the stored value. Somthing is wrong\n')
    end

    if isempty(binarized_atlases{myIndex})
        binarized_atlases{myIndex} = zeros(size(atlasVolume), 'logical');
        binarized_atlases{myIndex}(atlasVolume==myIndex)=1;
    end

    %then also we need to know what's on the other side of the boundary. 
    %we can't exclude a point that is on the border of, say, VI and no brain or V1 and white matter


end



