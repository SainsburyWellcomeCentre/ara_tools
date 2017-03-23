function [out,atlas] = generate(atlas, dim, varargin)
%% Project Allen atlas surface annotation along a given dimension
%
% function out = aratools.projectAtlas.generate(atlas,dim,'PARAM1','VAL1')
% 
% Inputs
%   atlas   - A 3D matrix of area labels
%   dim     - [1 by default] dimension to projected along. 1 for top-down view.
%
% Inputs [param/val]
% 'verbose' - false by default.
% 'surfaceDepth' - 3 by default. If >1 we collect the first n=surfaceDepth pixel
%                  values below the surface, take the mode, and assign this as the
%                  projected value. This helps get rid of some of the "noise" in 
%                  the first non-zero pixel by grabbing the first n non-zero pixels 
%                  and taking the mode. For top-down this isn't really needed but 
%                  for the side view it's helpful to surfaceDepth to 15.
% 'groupChildren' - A cell array (or a single string) of area names whose children 
%                   are to be grouped to form a single boundary. e.g. "cerebellum"
%                   will group all cerebellar areas together and create a single
%                   boundary for this structure. 
% 'removeAreaWithChildren' - A cell array (or a single string) of area names 
%                   to remove. e.g. "cerebellum" will remove the cerebellum and all
%                   child areas. NOTE: this may clash with groupChildren.
% 'groupLayers' - [true] if false we don't group cortical layers. 
% 'groupIndsInProjection' - a cell array of numeric vectors. In each vector, all values 
%                           set to be equal to the target value in the projected image.
% 'dilateSize' - default 4. the degree of smoothing in generating the boundaries. 
%
% Outputs
% A structure containing the following fields:
%  out.projectedAtlasRaw  - a matrix (an image, effectively) showing the area-index 
%       of each pixel from the raw atlas
%  out.projectedAtlas  - a matrix (an image, effectively) showing the area-index 
%       of each pixel with layers pooled. 
%  out.dim - scalar defining the dimension over which we projected. 
%  out.structureList - A table containing the ARA meta-data for the areas shown in 
%       projectedAtlas. *IN ADDITION* this table contains a variable called "areaBoundaries"
%       that contains the bwboundary-obtained outline for each area. e.g. it is possible
%       to plot all the boundaries by doing:
%  clf
%  hold on
%  for ind = 1:height(OUT.structureList)
%     B = OUT.structureList.areaBoundaries{ind};
%     for k = 1:length(B)
%       thisBoundary = B{k};
%       plot(thisBoundary(:,2), thisBoundary(:,1), 'r', 'LineWidth', 1)
%     end
%  end
%  hold off
% 
% The above is pretty much what is done in the example plotting function:
% aratools.projectAtlas.simplePlotter 
%
%
% We also return the atlas, which may have been modifed by the function (grouped layers, removed areas, etc)
%
%
% Example
% 1) basic example
% ATLAS=mhd_read('~/tvtoucan/Mrsic-Flogel/ReferenceAtlas/ARA_CCFv3/ARA_25_micron_mhd/atlas_smooth1_corrected.mhd');
% out = aratools.projectAtlas.generate(ATLAS);
%
% 2) Group all cerebellar areas together
% out = aratools.projectAtlas.generate(ATLAS,1,'groupChildren','Cerebellum');
% 
% Petr Znamenskiy - 2016
% Rob Campbell - 2017
%
%
% Also see:
% mhd_read, getAllenStructureList, aratools.projectAtlas.simplePlotter, aratools.projectAtlas.createBoundaries



if nargin<2 || isempty(dim)
    dim=1;
end

%Handle variable input arguments
params = inputParser;
params.CaseSensitive=false;
params.addParameter('verbose',false, @(x) islogical(x) || x==1 || x==0)
params.addParameter('groupLayers',true, @(x) islogical(x) || x==1 || x==0)
params.addParameter('surfaceDepth',3,@(x) isnumeric(x) && isscalar(x))
params.addParameter('dilateSize',4,@(x) isnumeric(x) && isscalar(x))
params.addParameter('groupChildren',{},@(x) ischar(x) || isnumeric(x) || iscell(x))
params.addParameter('removeAreaWithChildren',{},@(x) ischar(x) || isnumeric(x) || iscell(x))
params.addParameter('groupIndsInProjection',{},@(x) iscell(x))
params.parse(varargin{:});

verbose = params.Results.verbose;
surfaceDepth = params.Results.surfaceDepth;
groupChildren = params.Results.groupChildren;
removeAreaWithChildren = params.Results.removeAreaWithChildren;
groupLayers = params.Results.groupLayers;
groupIndsInProjection = params.Results.groupIndsInProjection;
dilateSize = params.Results.dilateSize;

if ischar(groupChildren)
    groupChildren = {groupChildren};
end
if ischar(removeAreaWithChildren)
    removeAreaWithChildren = {removeAreaWithChildren};
end


% Project the atlas
permvec = [ 1 2 3 ];
permvec(3) = dim;
permvec(dim) = 3;

atlas = permute(atlas, permvec);
[nx, ny, ~] = size(atlas);

%Area 698 is the annoying olfactory horn thing. Get rid of it. 
atlas(atlas==698)=0;



SL=getAllenStructureList;

%Figure out which areas are to be removed (if any) according to the command-line args
removeInds=[];
for ii=1:length(removeAreaWithChildren)
    [tmp,ind]=getAllenStructureList('childrenOf',removeAreaWithChildren{ii},'excludeReferenceArea',false);
    removeInds = [removeInds,ind];
end
for ii=1:length(removeInds)
    f=find(atlas==SL.id(removeInds(ii)));
    if verbose && length(f)>0
        fprintf('REMOVING area %s (%d voxels)\n', SL.name{removeInds(ii)}, length(f))
    end

    atlas(f)=0;
end


projectedAtlas = zeros(nx, ny);

for indX = 1:nx
    for indY = 1:ny
        firstValue = find(atlas(indX,indY,:),surfaceDepth,'first');
        if ~isempty(firstValue)
            if length(firstValue)>1
                vals=atlas(indX,indY,firstValue);
                projectedAtlas(indX, indY) = mode(vals);
            else
                projectedAtlas(indX, indY) = atlas(indX,indY,firstValue);
            end
        end
    end
end





%Figure out which areas are to be merged (if any) according to the command-line args
for ii=1:length(groupChildren)
    [tmp,ind]=getAllenStructureList('childrenOf',groupChildren{ii},'excludeReferenceArea',true);
    groupingStruct(ii).areaName = groupChildren{ii};
    rowInTable = strmatch(groupChildren{ii},SL.name);
    groupingStruct(ii).ARAindex = SL.id(rowInTable);
    groupingStruct(ii).children = tmp.id;

    %Now apply this
    for jj=1:length(groupingStruct(ii).children)
        f=find(projectedAtlas==groupingStruct(ii).children(jj));
        if length(f)>1
            projectedAtlas(f)=groupingStruct(ii).ARAindex;
        end
    end
end


for ii=1:length(groupIndsInProjection)
    inds=groupIndsInProjection{ii};
    for ii=2:length(inds)
        projectedAtlas(projectedAtlas==inds(ii))=inds(1);
    end
end


out.projectedAtlasRaw=projectedAtlas; %create output structure
out.projectedAtlas=projectedAtlas;
out.dim=dim;
out.areaReMapping = containers.Map('KeyType','int32','ValueType','int32'); %map to store the remapping of each area

%Group layers
N=unique(out.projectedAtlas(:)); %All unique values in projected atlas
allInds = zeros(1,length(N));


for ii=1:length(N)
    if N(ii)==0
        continue
    end

    indsInAtlas = out.projectedAtlas == N(ii);

    if isempty(indsInAtlas)
        fprintf('Odd: unique value %d was found in atlas and is now missing. Skipping\n',N(ii));
        continue
    end

    indInTable = find(SL.id==N(ii)); %Row in the table
    if  isempty(indInTable)
        if verbose
            %Is probably just caused by grouped areas
            fprintf('No index value %d found in index structure. Skipping\n',N(ii));
        end
        continue        
    end

    % Do not re-assign if the depth in the ARA label tree is shallower than 7, since it's then not a layer.
    if SL.depth(indInTable)<7 || ~groupLayers % groupLayers blocks layer grouping from command line argument 
        allInds(ii)=indInTable; %Leave it as before
        if verbose
            fprintf(' RETAINING "%s" (%d,%d)\n',...
                SL.name{indInTable}, SL.id(indInTable), SL.depth(indInTable) )
        end
        continue
    end

    % Replace 
    out.projectedAtlas(indsInAtlas) = SL.parent_structure_id(indInTable);

    f=find(SL.id==SL.parent_structure_id(indInTable));

    if isempty(f)
        fprintf('Failed to find index values for area %s in this projection. Skipping\n', SL.name{indInTable})
        continue
    end

    if verbose
       fprintf('Reassigning "%s" (%d,%d) to "%s" (%d,%d)\n', ...
       SL.name{indInTable}, SL.id(indInTable), SL.depth(indInTable), ...
       SL.name{f}, SL.id(f), SL.depth(f))
    end

    allInds(ii)=f;

    % Keep a log of which areas were converted to which
    out.areaReMapping(SL.id(indInTable)) = SL.id(f);


end

allInds(allInds==0)=[]; %remove any zeros due to missing areas
allInds = unique(allInds);

%Keep only the entries in the structure that contain labels in the grouped data
out.structureList = SL(allInds,:);




%Calculate the smoothed boundaries
out=aratools.projectAtlas.createBoundaries(out,dilateSize);

