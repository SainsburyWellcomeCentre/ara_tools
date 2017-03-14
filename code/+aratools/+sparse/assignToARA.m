function assignedPointStructure = assignToARA(pointsInARAstructure,sparsePointMatrix,varargin)
% Determine the location of a set of points in the ARA and return in a consistent way for other functions
%
%
% function assignedPointStructure = assignToARA(pointsInARAstructure,sparsePointMatrix,'param1',val1,...)
%
%
% Purpose
% Takes as input the output of pointsInARA (one structure) and a raw sparse point array that
% is transformed to the ARA space. Determines the location of each point in the ARA and then
% organises data in a consistent manner that can be used by other functions. 
%
%
% Inputs (required)
% pointsInARAstructure - the output of pointsInARA. This is used to load the ARA, amongst 
%                        other things.
% sparsePointMatrix - a matric of sparse points to assign. e.g. pointsInARA.rawSparseData
%                     Each row is an observations. There should be three columns that 
%                     determine the location of each point in the atlas. The ordering 
%                     of these (which dimensions they correspond to in the ARA) is defined
%                     by the dataColumns argument. Note that sparsePointMatrix can have 
%                     more than three columns, containing data other than location in atlas,
%                     but assignToARA needs to know which are the three columns that define
%                     location in the atlas and in what order they appear. Again, see the
%                     dataColumns argument. 
%
%
% Inputs (optional - param/value pairs)
% 'dataColumns' - The raw sparse data columns are often stored in a different order to that
%                 which is needed to index the atlas. This argument allows the user to specify
%                 which columns in sparsePointMatrix correspond to which dimensions in the ARA.
%                 Default values for this are in pointsInARAstructure.rawSparseDataColumns
%                 For example, traced neurite trees contain the location of the point in the last
%                 three columns. The first  two columns are point node index, and parent node. 
%                 For these data, dataColumns should be [5,4,3], because that this the ordering 
%                 of the columns that gives us X, Y, and Z. 
%                 If the pointsInARAstructure.rawSparseDataColumns is invalid for the sparse data 
%                 you are feeding the function or you need to otherwise re-define it, then you should
%                 define this argument here. 
% 'diagnosticPlot' - false by default. If true, we show the location of the points in the brain.
%                    This is useful your're worried about dataColumns being specified incorrectly,
%                    or if there are concerns about gross misalignment between the atlas and the 
%                    sparse data points. 
% 'ARAsettings' - empty by default. If provided, it should be the output of settings_handler('settingsFiles_ARAtools.yml')
%                 and is just used to speed up code. 
% 'useCachedAtlas' - false by default. If true we assign points based on the atlas currently cached in the base
%                    workspace. This allows us to, for instamce, switch between smoothed and on-smoothed atlasses. 
% 'details' - a structure with extra information. empty by default
%
%
%
% Outputs
% An output structure with the following fields is returned
% indexInARA
% coordsInARA
% hemisphere
% 


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
%Parse optional arguments
params = inputParser;

params.CaseSensitive=false;
params.addParamValue('dataColumns', pointsInARAstructure.rawSparseDataColumns, @(x) isvector(x) & length(x)==3);
params.addParamValue('diagnosticPlot', false, @(x) islogical(x) | x==1 | x==0);
params.addParamValue('useCachedAtlas', false, @(x) islogical(x) | x==1 | x==0);
params.addParamValue('ARAsettings', [], @(x)  isempty(x) | isa(x,'settings_handler'))
params.addParamValue('details', [], @(x)  isempty(x) | isstruct(x) )
params.parse(varargin{:});

dataColumns = params.Results.dataColumns;
diagnosticPlot = params.Results.diagnosticPlot;
useCachedAtlas = params.Results.useCachedAtlas;
ARAsettings = params.Results.ARAsettings;
details = params.Results.details;

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

if ~useCachedAtlas
    % If we aren't using the currently cached atlas then we attempt to cache the 
    % atlas defined by the pointsInARAstructure
    aratools.cacheAtlasToWorkSpace(pointsInARAstructure.atlas,ARAsettings)
end


CACHED_ATLAS = aratools.atlascacher.getCachedAtlas;
atlasVolume = CACHED_ATLAS.atlasVolume;

if isempty(CACHED_ATLAS)
    fprintf(['%s can not find a cached atlas.\n', ...
        'Please cache an atlas using aratools.cachceAtlasToWorkSpace\n'], ... 
        mfilename)
    return
end






%Process sparse data so we can index the ARA volume with it
sparsePointMatrix = sparsePointMatrix(:,dataColumns);
sparsePointMatrix = round(sparsePointMatrix); %Forces values to reside in a single voxel in the ARA

assignedPointStructure.sparsePointMatrix = sparsePointMatrix; %Store in output data structure
assignedPointStructure.details = details;
%Declare other fields
assignedPointStructure.hemisphere=[];
assignedPointStructure.ARAindex=[];



%Do diagnostic plot here
if diagnosticPlot
    clf

    subplot(2,2,1)
    imagesc(any(atlasVolume,3))
    hold on
    plot(sparsePointMatrix(:,2),sparsePointMatrix(:,1),'.r')
    axis ij equal tight

    subplot(2,2,2)
    imagesc(squeeze(any(atlasVolume,1)))
    hold on
    plot(sparsePointMatrix(:,3),sparsePointMatrix(:,2),'.r')
    axis ij equal tight

    subplot(2,2,3)
    imagesc(squeeze(any(atlasVolume,2)))
    hold on
    plot(sparsePointMatrix(:,3),sparsePointMatrix(:,1),'.r')
    axis ij equal tight

    colormap gray
end


% Remove rows with an matrix indexing value of zero.
f=find(any(sparsePointMatrix==0,2));
if ~isempty(f)
    fprintf('\n\n *** Removing %d points which have index values of zero. Removing them. *** \n\n',length(f))
    sparsePointMatrix(f,:)=[];
end


% Check if we will run into indexing errors and correct.
% i.e. we remove points that are outside of the volume (not outside of the atlas, but outside of the
%      image in which the atlas sits. This is unlikely to every happen, but we check anyway.
%TODO: remove coords with index values <1
mP=max(atlasVolume,[],1);
for ii=1:size(atlasVolume,2)
    f=find(atlasVolume(:,ii)>size(atlasVolume,ii));
    if ~isempty(f)
        fprintf('\n\n *** Found %d points that exceed dimension %d size (%d). Removing them. THIS IS BAD. *** \n\n', length(f), size(atlasVolume,ii), ii)
        atlasVolume(f,:)=[];
    end
end
if size(atlasVolume,1)==0
    fprintf(' ========>  WARNING: all points have been removed! (THIS IS REALLY, REALLY, BAD) <======== \n\n\n')
    return
end


%-------------------------------------------------------------------------
% Get the index of each point and also which side of the brain it's on

% ARAindex contains the value in the ARA volume that is associated with each data point.
% These values can (at a later point) be cross-referenced with the labels file to determine which brain area 
%t he are associated with.

assignedPointStructure.ARAindex=ones(size(sparsePointMatrix,1),1);
for ii=1:length(assignedPointStructure.ARAindex)
    assignedPointStructure.ARAindex(ii) = ...
            atlasVolume(sparsePointMatrix(ii,1),... 
                        sparsePointMatrix(ii,2),...
                        sparsePointMatrix(ii,3));
end


%Which hemisphere is the data point in?
assignedPointStructure.hemisphere=zeros(size(sparsePointMatrix,1),1);
midline=size(atlasVolume,2)/2;

f=sparsePointMatrix(:,2)>midline;
assignedPointStructure.hemisphere(f) = 1;

f=sparsePointMatrix(:,2)<midline;
assignedPointStructure.hemisphere(f) = 2;




%A bool to indicate which clicked nodes are definitely in white matter
whiteMatterInd = aratools.utils.whiteMatterInds; 
assignedPointStructure.isWhiteMatter = logical(ismember(assignedPointStructure.ARAindex, whiteMatterInd));


