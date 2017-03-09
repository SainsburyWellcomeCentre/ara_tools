function data = returnData(obj, varargin)
    % Returns the cached, filtered, data if these are available. 
    % Otherwise process and then return the filtered data. By "filtered"
    % we mean that the data have been grouped in various ways, e.g. by layer. 
    %
    %
    % function data = returnData(obj, varargin)
    %
    %
    % This command also accepts other arguments to further filter the returned
    % data. Currently:
    %
    % * 'excludeBorders' - Disabled by default. Otherwise this is a scalar that defines
    %                      which points are going to be excluded based on their proximity to a 
    %                      a border that is not white matter or out of the brain. e.g. if
    %                      exludeBorders is 3 then all points within 3 voxels of a border
    %                      do not contribute to the plot. This is -1 by default so nothing
    %                      is removed
    % * 'verbose'        - false by default
    %
    % e.g.
    %      data = obj.returnData('excludeBorders',3);
    %      data = obj.returnData; %no addtional filtering
    %

    
    params = inputParser;
    params.CaseSensitive=false;
    params.addParamValue('excludeBorders',-1,@isscalar)
    params.addParamValue('verbose',false,@islogical)
    params.parse(varargin{:})


    if obj.checkSumMatchesCurrentGroupingRule
        data = obj.filteredData;
    elseif ~obj.checkSumMatchesCurrentGroupingRule || isempty(obj.filteredData)
        obj.processData;
        data = obj.filteredData;
    end

    %Exlude points within a given distance of the border if this is what was asked for            
    if params.Results.excludeBorders > -1
        fprintf('xylem.return data is excluding points based on distance to border\n')
        data = obj.removePointsNearBorders(data,...
                params.Results.excludeBorders,...
                params.Results.verbose);
    end

end %returnData
