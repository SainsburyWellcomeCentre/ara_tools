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
end

warning('on','MATLAB:table:RowsAddedNewVars')


out.dilateSize=dilateSize; %log the dilate size


