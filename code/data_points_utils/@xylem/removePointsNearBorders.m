function data = removePointsNearBorders(obj,data,borderDistance,verbose)
    % Return a data set with points near borders removed
    %
	% function data = removePointsNearBorders(data,borderDistance,verbose)
    %
    %
    % Purpose
    %  Accepts as input a data structure (generally the output of xylem.returnData)
	%  and removes all points within a given distance of a border. The method then
    %  returns these data to the user. It doesn't modify the data stored as a 
    %  property in the xylem object.
	%
    % 
    % Inputs
	%  data - the data structure
	%  borderDistance - scalar that defines which points to remove (in voxels).
	%  verbose - [optional, false by default]
    %
    % 
    % Outputs
    %  data - the filtered data with the border points removed
	% 
    %
    % Related methods
    %   xylem.determineNearestBorderForARApoints 
    %   xylem.getBorderPixelsForArea
    %
    %

	if nargin<4
		verbose=false;
	end


	for fII = 1:length(data)

		if verbose
	        fprintf('Doing cell %d/%d\n', fII, length(obj.filteredData))
	    end

        dataFields = fields(data(fII).pointsInARA);

        for pKK = 1:length(dataFields)
            tmp=data(fII).pointsInARA.(dataFields{pKK});
            
            if ~isfield(tmp,'border')
            	error('No borders calculated: see obj.addBorderInfoToFilteredData')
            end

            f=find(tmp.border.d<borderDistance);
            if length(f)==length(tmp.isWhiteMatter)
            	fprintf('WARNING - removing all data from sample %d due to points being near borders\n', fII)
            end

            if verbose
            	fprintf('Removing %d of %d points due to border proximity\n', length(f), length(tmp.isWhiteMatter))
            end

            if ~isempty(f)
            	tmp.sparsePointMatrix(f,:)=[];
            	tmp.hemisphere(f)=[];
            	tmp.ARAindex(f)=[];
            	tmp.isWhiteMatter(f)=[];
            	data(fII).pointsInARA.(dataFields{pKK}) = tmp;
            end


        end  % for pKK = 1:length(dataFields)
    end % for fII = 1:length(data)
 
 end %removePointsNearBorders
