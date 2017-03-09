function processData(obj,forceRerun,supressAtlasFiltering)
    % Run processing rules on data and cache the results.
    %
    % function processData(forceRerun,supressAtlasFiltering)
    %
    % The method implements the "instructions" in the layers and groupAreas 
    % properties by running aratools.sparse.groupARAindexes on the contents
    % of xylem.data The results are stored in the hidden property "filteredData"
    % and accessed using the returnData method. 
    % 
    % This method creates a simple checksum in xylem.filteringChecksum
    % after it is run. This indicates what rule was last run on the data. 
    % If processData is re-run, it will only do anything if the current 
    % rules are different from the stored rules. The checksum doesn't 
    % change if the dataset changes. 
    %
    % This method also filters the ARA index data in the atlas. 
    %
    % Inputs 
    % forceRerun - [false by default] Unless forceRerun is true, the method 
    %               re-runs only if the grouping rule differs to what has 
    %               already been cached.
    %
    % supressAtlasFiltering - [false by default] If true, the atlas index values 
    %                         are not updated along with the data points. 

    if nargin<2 || isempty(forceRerun)
        forceRerun=false;
    end

    if nargin<3 || isempty(supressAtlasFiltering)
        supressAtlasFiltering=false;
    end

    if isempty(obj.groupingRule)
        fprintf('No grouping rule. Will return un-grouped raw data and use original atlas\n')
        obj.filteredData = obj.data;
        obj.filteringChecksum = obj.returnChecksum;
        obj.areaReassignmentInds=[];
        obj.atlas = obj.originalAtlas;
        return
    end

    if ~obj.checkSumMatchesCurrentGroupingRule || forceRerun
        fprintf('Applying grouping rules and caching results\n')
        [obj.filteredData,obj.areaReassignmentInds] = ...
                aratools.sparse.groupARAindexes(obj.data,obj.groupingRule);

        if ~supressAtlasFiltering
            obj.filterAtlas
        end

        %assign the new checksum only once everything is complete. 
        obj.filteringChecksum = obj.returnChecksum;
        return
    end


    if isempty(obj.atlas)
        fprintf('Point data are up to date but no atlas is attached. Attempting to load one.\n')
        obj.filterAtlas
    else
        fprintf('Nothing to do\n')
    end

end        
