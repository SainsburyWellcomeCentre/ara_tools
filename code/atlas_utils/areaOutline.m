function out = areaOutline(atlasVolume, thisArea, layers, doPlot)
% Generate brain area boundary outline from ARA by pooling all child brain areas that lie within thisArea
%
% areaOutlines = areaOutline(atlasVolume, thisArea, layers, doPlot)
%
%
% Purpose
% Produce an x/y data describing an outline of a given brain area or groups of areas 
% (e.g. primary visual cortex layer 4, primary visual cortex, or cerebral cortex) 
% given a particular brain atlas and set of labels. 
%
% By default the function does a maximum intensity projection in the coronal axis 
% only. In other words, atlasVolume is a 3-D matrix containing the ARA area boundaries.
% Each 2-D slice a coronal section. By default the function loops through each section 
% and identifies all pixels that are part of thisArea. This produces a 3-D matrix of 
% zeros (not in the area) and ones (in the area). The boundaries are drawn on the 
% maximum intensity projection of this matrix. You can optionally restrict the 
% calculation to subset of layers and/or request the analysis to be performed on the 
% other two projections: sagittal and transverse (see layers, below).
%
%
% Inputs
% atlasVolume - The Allen brain atlas volume. e.g.  atlasVolume = mhd_read('atlas.mhd');
% thisArea - an index or area name to draw the boundary around. If thisArea is a string,
%            areaOutline will treat it is a substring (not case sensitive). e.g. if 
%            thisArea is 'auditory cortex', it will match 'Auditory cortex layer 2'
% layers - Cell array defining which layers from which of the three directions are to be 
%          used in calculating the max intensity projections. Examples:
%          a) Use all layers from all three directions (coronal, sagittal, transverse):
%             {-1,-1,-1}  %so -1 means all layers
%             Three separate sets of boundaries will be returned. 
%          b) Use all coronal layers only (DEFAULT):
%             {-1, [], 0} %zero or empty causes that axis to be ignored
%          c) Calculate coronal and sagittal directions only using all layers:
%             {-1, -1, 0}
%          d) Calculate for all three directions, using a different set of layers for each:
%             {100:200, 80:110, [200,220,300]} 
%          e) if layers is empty the default behavior is performed (all coronal sections only)
%          NOTE: to choose reasonable values for the layers option you can use Lasagna. 
%                e.g. for visual areas with the 25 micron voxel size use something like this:
%                {100:2:250,220:2:380,1:2:130}
%
%
% doPlot - Optionally plot the maximum intensity projection and outlines of each requested
%          direction for diagnostic purposes [Optional, 0 by default].
%
%
% Outputs
% areaOutlines - a structure containing the outlines of the brain areas for each direction
%                as well as the name and index of the requested area names. Contains the 
%                following fields:
%                out.ID - area index (scalar)
%                out.name - area name (string)
%                out.coronalBounds - cell array of matrices containing data that can be plotted
%                out.sagittalBounds - cell array of matrices containing data that can be plotted
%                out.transverselBounds - cell array of matrices containing data that can be plotted
%
%
% Examples
% 1. Calculate boundaries of the cortex in a subset of coronal and transverse slices:
% OUT = areaOutline(atlas, 'cerebral cortex', {300:10:400,[],30:10:100});
% Note it is often sufficient not to take every slice. 
%
% 1. Calculate cerebellum boundaries in all coronal sections and make diagnostic plot:
% OUT = areaOutline(atlas, 'cerebellum', [], 1);
%
%
% Rob Campbell - Basel 2015


% Error check
if ~isnumeric(atlasVolume)
    fprintf('atlasVolume needs to be an atlas matrix. %s is quitting\n',mfilename)
    out=[];
    return
end

if ~isscalar(thisArea) & ~isstr(thisArea)
    fprintf('thisArea should be a scalar index value or a string. %s is quitting\n',mfilename)
    out=[];
    return
end

if nargin<3 | isempty(layers)
    layers = {-1,0,0};
end

if ~iscell(layers)
    fprintf('layers should be a cell array. %s is quitting\n',mfilename)
    out=[];
    return
end

if length(layers) ~= 3
    fprintf('layers should be a cell array of length 3. %s is quitting\n',mfilename)
    out=[];
    return
end


%Extract labels information if needed   
labels=getAllenStructureList; %load the allen structure list because we need to find areas that are white matter


if nargin<4
    doPlot=0;
end




%We will be repeatedly calling ARAindexIsWithin, and so to speed things up we will
%not perform error checks each time in that function. So instead we must check here
%that the brain area we are looking for exists. 
if isnumeric(thisArea)
    f=find(labels.id==thisArea);
    if isempty(f)
        fprintf('Can not find area ID %d. Quitting\n',thisArea)
        return
    end
    %Store area ID and name in output structure
    out.ID=thisArea;
    out.name=labels.name{f};
elseif isstr(thisArea)
    [p,ind] = isAreaPresent(labels,thisArea);
    if p==0
        fprintf('Can not find area name "%s". Quitting\n',thisArea)
        return
    end
    %Store area ID and name in output structure
    out.ID=ind;
    out.name=thisArea;
end


%Loop through the requested axes and calculate the boundaries
out.coronal=[];
out.sagittal=[];
out.transverse=[];
dimensionNames = {'coronal', 'sagittal', 'transverse'};
calculatedAxes=0; %counter so we know how many sub-plots do make
masks={}; %The calculated masks (used for the optional plotting)


for ii=1:length(layers)
    theseLayers = layers{ii};

    if isempty(theseLayers) | theseLayers==0
        continue
    end
    fprintf('Finding %s projection\n',dimensionNames{ii})

    if strcmp('coronal', dimensionNames{ii})
        tmpAtlas = atlasVolume;
    elseif strcmp('sagittal', dimensionNames{ii})
        tmpAtlas = permute(atlasVolume,[1,3,2]); %Nose-right sagittal
    elseif strcmp('transverse', dimensionNames{ii})
        tmpAtlas = permute(atlasVolume,[3,2,1]); %Nose-down transverse
    end

    %loop through all requested layers of this mask
    thisMask = zeros(size(tmpAtlas));
    theseLayers = layers{ii};
    if theseLayers==-1
        theseLayers = 1:size(tmpAtlas,3); %always 3 because we have permuted the dimension of the original atlas 
    end
    for jj=1:length(theseLayers)
        thisLayer = theseLayers(jj);
        thisMask(:,:,thisLayer) = isThisArea(tmpAtlas(:,:,thisLayer),labels,thisArea);
    end

    thisMask = any(thisMask,3);
    out.(dimensionNames{ii}) = bwboundaries(thisMask,'noholes');

    masks{ii} = thisMask;
    calculatedAxes=calculatedAxes+1;
end



if doPlot
    clf
    if calculatedAxes==1
        S=[1,1];
    elseif calculatedAxes==2
        S=[1,2];
    else 
        S=[2,2];
    end

    n=1; %subplot counter
    for ii=1:length(layers)
        if isempty(layers{ii}) | layers{ii}==0
            continue
        end
        bound = out.(dimensionNames{ii}); %The boundaries for this dimension
        if isempty(bound)
            fprintf('Boundary plot requested for %s but no boundary found\n',dimensionNames{ii})
            continue
        end

        subplot(S(1),S(2),n)    

        if isempty(masks{ii})
            continue
        end

        imagesc(masks{ii})
        axis equal tight
        hold on

        for jj=1:length(bound)
            plot(bound{jj}(:,2), bound{jj}(:,1), '-r','linewidth',2)
        end
        hold off
        n=n+1;

    end
        
    colormap gray
end




%-------------------------------------------------------------
function mask = isThisArea(atlasSlice,labels,thisArea)

    u = unique(atlasSlice(:));
    u(u==0)=[];

    mask = zeros(size(atlasSlice));
    for ii=1:length(u)
        if ARAindexIsWithin(u(ii),thisArea,1,labels)
            f=find(atlasSlice==u(ii));
            mask(f)=1;
        end
    end

