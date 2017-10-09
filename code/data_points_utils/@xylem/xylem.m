classdef xylem < handle 

% The xlyem class handles traced tree data 
%
%
% Example of how to build an instance of the xylem data object:
% For example, you might do:
% cd ~/tvtoucan/Mrsic-Flogel/hanyu
% pointsInARA('downsampled/sample2ARA') %Batch mode extract data from each each sample
% data=aratools.sparse.processTreeData('downsampled/sample2ARA') %group those data into a structure
% X=xylem(data); %build the object
%
%
% The Raw Data:
% The purpose of the class is to hold the original traced data and conduct operations
% on it to sort it (filter it) for plotting and further analysis. The raw data consist
% of a set of points aranged in a tree structure. The points were obtained by manually
% tracing an axonal tree of a single neuron. We care about where the projection targets
% of the neuron, but we don't have labelling of the terminals. The most simple approach
% to estimating the locations of the terminations is to find the locations of the 
% "leaves" or "terminal nodes" of the tree structure. Another approach to calculate 
% the length of axon in each brain area. Possibly only counting brain areas that contain
% the terminal node. 
%
%
% The Organisation of the Raw Data within the Xylem class:
% The data all house in the structure xylem.data, and each entry in this structure represents
% one neuron. The field xylem.data.pointsInARA contains the traced data. Since these data
% can be represented in different ways, pointsInARA contains multiple structures.
% Each of these structures corresponds to a different representation of the data. 
% For example:
% >> X.data(1).pointsInARA
%  ans = 
%   struct with fields:
%      rawSparseData: [1x1 struct]
%             leaves: [1x1 struct]
%    upSampledPoints: [1x1 struct]
%
% The field "rawSparseData" contains the points originally clicked during tracing. 
% The field "leaves" contains the terminal nodes only. The field "upSampledPoints"
% contains a version of the neurite tree that has been up-sampled so that there 
% is a point ever n microns. The degree of upsampling is defined in
% xylem.data.pointsInARA.upSampledPoints.details.upSampleResolution
%
% 
% The Reference Space:
% All the above data are registered into the space of the Allen atlas. So all 
% points from all samples are in the same reference space. 
%
%
% The Contents of the pointsInARA structures:
% Each of the fields within pointsInARA are organised in the same way:
% >> X.data(1).pointsInARA.rawSparseData
% ans = 
%  struct with fields:
%    sparsePointMatrix: [1440x3 double]
%              details: []
%           hemisphere: [1440x1 double]
%             ARAindex: [1440x1 double]
%        isWhiteMatter: [1440x1 logical]
%
% "sparsePointMatrix" contains the coordinates of each point. 
% "hemisphere" indicates the side of the brain that each point is in. 
% "ARAindex" defines the brain area of each point. You can convert these
% into names using the structureID2name from the AllenAPI package on 
% Mrsic-Flogel lab GitHub page. 
% "isWhiteMatter" defines whether each point resides in an area that is 
% classified as white matter. See: help aratools.utils.whiteMatterInds
%
%
% Addressing the Data in the ARA Space and Filtering data:
% The ARA is partitioned into about 1000 different areas but these are grouped
% according to a tree structure of labels. The smallest unit is generally the
% cortical layer. Cortical layers are grouped into cortical areas (e.g. Primary 
% visual cortex), and cortical areas are all grouped together under "isocortex".
% We don't care about cortical layers and we may even want to group together 
% different cortical areas. To achieve this, xylem uses the function 
% aratools.sparse.groupARAindexes to group layers or areas. This function is
% called in the method xylem.processData, which does the grouping and stores
% the results in xylem.filteredData. This property is hidden and you 
% access it with the xylem.returnData method, which outputs the filtered
% data (filtering it if necessary using xylem.processData before returning it). 
% How it's filtered is determined by the properties xylem.groupLayers and 
% xylem.groupAreas.
%
% The object also stores the ARA and xylem.processData will re-assign the 
% ARA index values as well as as the ARAindex field in the traced cell data. 
% The reason for this is that we're now able to identify the borders of all
% the areas in the data set (xylem.refreshStoredAreaBorders) and then calculate
% the distance of each data point to each border xylem.addBorderInfoToFilteredData
% With this information in place our down-stream plotting functions can
% remove data points according to how close they are to a neighbouring brain are.
%
% 
% Notes;
% The ARA is loaded and filtered when the object is instantiated.
% The ARA is not saved along with a xylem object. Following re-loading,
% the atlas is automatically re-loaded and re-processed. This takes under a minute.
%
%
% Rob Campbell - Basel 2016 



    properties (SetAccess=public)
        data                % The existing data structure
        groupLayers = true  % If true, xylem.returnData will merge cortical layers of each area. 
        groupAreas  = {}    % Cell array describing how areas are two be grouped. see help aratools.sparse.groupARAindexes
    end %properties

    properties (Hidden, SetAccess=public)
        borders % This map structure will hold the border pixels of the brain areas that contain nodes
    end %hidden properties

    properties (Hidden, SetAccess=protected)
        filteredData % A copy of the previously grouped data. If the checksum on the public filtering properties matches obj.filteringChecksum, then we can re-use these.
        areaReassignmentInds % Matrix showing the area re-assignments. e.g. the before and after filtering IDs of each area.
        filteringChecksum    % Checksum generated from all of the grouping and filtering properties the last time they were run
    end %hidden properties

    %This version of the atlas will be filtered according to the rules defined by groupAreas and groupLayers
    properties (SetAccess=public, Transient=true)
        atlas
    end

    %This is the original version of the atlas
    properties (Hidden, Transient=true)
        originalAtlas
        whiteMatterInds %temporarily store the white matter index values here
    end






    methods

        function obj = xylem(data)
            % function obj = xylem(data)
            % 
            % An instance of xylem is instantiated based upon a neurite tree data set.
            % For example, you might do:
            % cd ~/tvtoucan/Mrsic-Flogel/hanyu
            % pointsInARA('downsampled/sample2ARA') %Batch mode extract data from each each sample
            % data=aratools.sparse.processTreeData('downsampled/sample2ARA') %group those data into a structure
            % X=xylem(data); %build the object


            %Attach the data and establish a link to the ARA we will use
            obj.data = data;

            %Initialise the map structure
            obj.borders = containers.Map('KeyType','int32','ValueType','any');


            %Make sure the correct atlas has been cached and we have processed data ready to go
            fprintf('Adding ARA to xylem\n')
            aratools.cacheAtlasToWorkSpace(obj.data(1).atlas)
            obj.originalAtlas = aratools.atlascacher.getCachedAtlas;
            fprintf('Conducting initial data processing based on existing area grouping rules\n')            
            obj.processData %
        end %CONSTRUCTOR
        
        

        function refreshStoredAreaBorders(obj)
            % Calculate border pixels for all areas where we have projections
            %
            %   function refreshStoredAreaBorders
            %
            %
            % Purpose
            % Runs through all of the index values that contain data points
            % and calculates their border pixels. Stores these in the borders
            % property, which is a map where the index is the key and the borders
            % the value. So the borders for V1 are in the key obj.borders(385)
            % because ID=385 is V1.            

            %TODO: should we have a way of re-calculating the results if the ARA is changed?

            obj.borders=containers.Map('KeyType','int32','ValueType','any');
            fprintf('Re-calculating borders:\n')
            currentIndexValues = obj.getUniqueAreas;
            for ii=1:length(currentIndexValues)
                %This proceeds in a multi-threaded fashion, so no need for a parfor
                ind=currentIndexValues(ii);
                fprintf('%d/%d - Finding border pixels for index %d\n',ii,length(currentIndexValues),ind)
                obj.borders(ind) = obj.getBorderPixelsForArea(ind);
            end
            fprintf('\n')
        end % refreshStoredAreaBorders



        function addBorderInfoToFilteredData(obj)
            % For each point calculate the distance to the area border
            %
            % function addBorderInfoToFilteredData
            %
            % Purpose and usage
            % This method populates the *filtered* data with the distances to area borders. 
            % We won't bother doing this with the unfiltered data, since we will always
            % in practice want the data grouped by at least layer. To get at the results
            % of addBorderInfoToFilteredData you will need to use the returnData method. 
            % (Not a great solution, TBH, but for now this is what we do. TODO: move the borders to original data?)
            %
            %
            % Also see the following methods:
            % determineNearestBorderForARApoints, getBorderPixelsForArea, removePointsNearBorders
            %
            obj.returnData; %Ensures we have a filtered data set

            for fII = 1:length(obj.filteredData)
                fprintf('Doing cell %d/%d\n', fII, length(obj.filteredData))
                dataFields = fields(obj.filteredData(fII).pointsInARA);
                for pKK = 1:length(dataFields)
                    tmp=obj.filteredData(fII).pointsInARA.(dataFields{pKK});
                    obj.filteredData(fII).pointsInARA.(dataFields{pKK}).border = obj.determineNearestBorderForARApoints(tmp);
                end
            end
        end %addBorderInfoToFilteredData


    end %methods



    methods (Static)

        %We must re-run the ARA filtering and loading/caching when a xlyem object is loaded from disk
        function obj=loadobj(obj)
            % re-runs filtering of ARA on loading of the object. The filtered ARA is not saved with the object.
            fprintf('Loaded xylem object: adding ARA to xylem\n')

            pathToAtlas = fullfile(obj.data(1).atlas.pathToFile,obj.data(1).atlas.fname);
            if ~exist(pathToAtlas,'file')
                fprintf(['This xylem object is looking for an atlas in %s but this is missing.\n',...
                    'SOLUTION: edit the path to the ARA in xylem.data(1).atlas\n', ...
                    'You will likely get major failures using the object if you do not address this\n', ...
                    'Suggest you fix the paths and rerun the "filterAtlas" method until you get no errors.\n', ...
                    'Then save the corrected object.\n'],pathToAtlas)
                return
            end

            try
                obj.filterAtlas;
            catch 
                L=lasterror;
                fprintf('*** Atlas loading and re-processing failed with error:\n%s\n\n',L.message)

                aratools.utils.logger(L) %Display the full stack trace
            end
        end %load obj

    end %static methods





    methods (Hidden)
    
        function checksum = returnChecksum(obj,grpTmp,checksum)
            % Produce a long string that is a serialization of the groupingRule
            % property. This acts as a checksum so we can see if the the user has
            % changed grouping since the grouped data were last cached.

            if nargin<2
                grpTmp=obj.groupingRule;
            end
            if nargin<3
                checksum='';
            end

            %Recursively scan the structure
            for ii=1:length(grpTmp)
                if isstr(grpTmp{ii})
                    checksum = [checksum,grpTmp{ii}];
                elseif iscell(grpTmp{ii})
                    checksum = obj.returnChecksum(grpTmp{ii},checksum);
                end
            end

            %returns the "checksum" as the concatenated lower case string minus white-space
            checksum = lower(checksum);
            checksum = strrep(checksum,' ','');
        end %returnChecksum


        function checkSumMatches = checkSumMatchesCurrentGroupingRule(obj)
            %Does the stored checksum match that produced by the current grouping rules?
            if isempty(obj.filteringChecksum)
                checkSumMatches=false;
                return
            end
            if strcmp(obj.returnChecksum,obj.filteringChecksum)
                checkSumMatches=true;
            else
                checkSumMatches=false;
            end
        end 


        function grpRule = groupingRule(obj)
            % Returns a grouping rule cell array that we can feed to 
            % aratools.sparse.groupARAindexes
            grpRule={};
            if obj.groupLayers
                grpRule{end+1}='layers';
            end
            if ~isempty(obj.groupAreas)
                grpRule{end+1}=obj.groupAreas;
            end
        end %groupingRule


        function uniqueAreas = getUniqueAreas(obj)
            % Get the full list of unique areas in the filtered data set
            obj.returnData; %ensure there will be filtered data
            allAreas = [] ;
            if isfield(obj.filteredData(1).pointsInARA, 'upSampledPoints')
                dataField = 'upSampledPoints';
            else
                fprintf('Can not find upSampledPoints. Using rawSparseData instead to estimate unique areas\n')
                dataField = 'rawSparseData';
            end

            for fII = 1:length(obj.filteredData)
                tmp=obj.filteredData(fII).pointsInARA.(dataField).ARAindex;
                tmp(obj.filteredData(fII).pointsInARA.(dataField).isWhiteMatter)=[]; %get rid of white matter
                tmp=unique(tmp(:));
                allAreas = [allAreas;tmp];
            end

            uniqueAreas = unique(allAreas);
            uniqueAreas(uniqueAreas==0)=[]; %get rid of points out of the brain

        end %getUniqueAreas

    end %hidden methods


   
end %classdef xylem