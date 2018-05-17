function projectedAtlasStuct = createBoundaries(projectedAtlasStuct,dilateSize)
%% Draw boundaries around projected Allen Reference atlas
%
% function projectedAtlas = createBoundaries(projectedAtlasStuct,dilateSize)
% 
% Purpose
% This is a helper function for aratools.projectAtlas.generate but it might be
% useful on its own too, in case the boundaries need to be re-created. Adds
% the dilateSize variable to the structure for logging purposes. 
%
%
% Inputs
%   projectedAtlasStuct - the output of aratools.projectAtlas.generate
%   dilateSize - [optional, 4 by default] the size of the structured disk 
%                used for smoothing
%
% Rob Campbell - 2017
%
%
% Also see:
% mhd_read, getAllenStructureList, aratools.projectAtlas.generate


if nargin<2
    dilateSize = 4;
end


warning('off','MATLAB:table:RowsAddedNewVars')
out.structureList.areaBoundaries(:)={};
out.structureList.areaHemisphere(:)={};
for ind = 1:height(projectedAtlasStuct.structureList)
    R = projectedAtlasStuct.projectedAtlas==projectedAtlasStuct.structureList.id(ind);

    R = imerode(imdilate(R,strel('disk',dilateSize)),strel('disk',dilateSize));
    [B,L] = bwboundaries(R);

    if isempty(B)
        fprintf('WARNING: failed to draw boundary for area %d (%s). Skipping\n',...
         projectedAtlasStuct.structureList.id(ind),...
         projectedAtlasStuct.structureList.name{ind})
        continue
    end

    %Store the boundaries in the table
    projectedAtlasStuct.structureList.areaBoundaries{ind}=B;
    
    % Find on which hemisphere each of the boundary is
    if projectedAtlasStuct.dim == 2
        % it is a sagital view. Hemisphere doesn't make sense
        whichHem = nan(size(B));
    elseif projectedAtlasStuct.dim == 1
        % it is a dorsal view. 
        whichHem = zeros(size(B));
        midLine = size(projectedAtlasStuct.projectedAtlas,2)/2;
        for iB =1:numel(B)
            b = B{iB};
            inLeftHem = double(any(b(:,2)<=midLine));
            inRightHem = double(any(b(:,2)>=midLine));
            whichHem(iB) = inLeftHem + 2 * inRightHem;
        end
    elseif  projectedAtlasStuct.dim == 3
        %if is a coronal view
        whichHem = zeros(size(B));
        midLine = size(projectedAtlasStuct.projectedAtlas,2)/2;
        for iB =1:numel(B)
            b = B{iB};
            inLeftHem = double(any(b(:,2)<=midLine));
            inRightHem = double(any(b(:,2)>=midLine));
            whichHem(iB) = inLeftHem + 2 * inRightHem;
        end
    end
    projectedAtlasStuct.structureList.areaHemisphere{ind} = whichHem;
end

warning('on','MATLAB:table:RowsAddedNewVars')


out.dilateSize=dilateSize; %log the dilate size


