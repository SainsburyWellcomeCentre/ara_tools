function varargout=dump2LasagnaPointsFile(data,varargin)
% Dump a single ARA points structure to file that lasagna can read
%
%   function dump2LasagnaPointsFile(data,varargin)
%
%
% Purpose
% Dump to disk a CSV file that contains the point data from a single
% leaves, upsampledPoints, etc, structure. The dumped data will be 
% in the format z,x,y,point_series
% This is designed to be read by the Lasagna sparse points reader:
% https://github.com/raacampbell/lasagna/blob/master/IO/sparse_point_reader_plugin.py
%
%
% 
% Inputs (required)
% araPoints - This should be, for example thisXylem.data(1) or the output of thisXylem.returnData 
%             By default the rawSparseData structure is dumped to disk. If you want a different 
%             one, use the dataseries optional argument. You may need to use the returnData method
%             if you want to use the hlightborders argument. 
%
%
%
% Inputs (optional param/val pairs)
% 'filename' - [string, undefined by default]. If undefined data are dumped to a 
%              file in the system's temporary directory. The location of this file is
%              which is printed to screen and optionally returned as an output argument.
%              If defined, the data are saved where the user specifies.
% 'dataseries' - ['rawSparseData' by default]. Can be a string corresponding to a field name
%                in data.pointsInAra
% 'hlightborders' - [scalar, -1 by default] if this is value is > 0 and the border distance
%                   data area available in araPoints.border.d, then points with border distances
%                   < hlightborders (in voxel) are saved to a different point_series index so 
%                   lasagna will color them differently.
% 'hlightexcluded' - [false by default] Save points that are in the white matter and out of the 
%                    brain in a different point_series index. This takes precendence over 
%                    hlightborders.
%
%
%
% Examples
% >> D=X.returnData % extract filtered data with border information
%
% % Dump the first cell and highlight all points within 3 voxels
% >> aratools.sparse.dump2LasagnaPointsFile(D(10),3)
% Dumping points to /tmp/YH102_traced_cells_tree_01-border0.4.csv

params = inputParser;
params.CaseSensitive=false;

params.addParamValue('fname','',@ischar)
params.addParamValue('dataseries','rawSparseData',@ischar)
params.addParamValue('hlightborders',-1,@isscalar)
params.addParamValue('hlightexcluded',false,@islogical)
params.parse(varargin{:})

fname = params.Results.fname;
dataseries = params.Results.dataseries;
hlightborders = params.Results.hlightborders;
hlightexcluded = params.Results.hlightexcluded;


%process input arguments
if ~isstruct(data)
    fprintf('data must be a structure\n')
    return
end

if ~isfield(data,'pointsInARA')
    fprintf('data must contain field "pointsInARA\n')
    return
end

if ~isfield(data.pointsInARA,dataseries)
    fprintf('\ndata.pointsInARA contains no field "%s"\nAvailable fields are:\n\n', dataseries)
    cellfun(@(x) fprintf(' -  %s\n',x), fields(data.pointsInARA));
    fprintf('\n')
    return
end

if hlightborders>0
    if ~isfield(data.pointsInARA.(dataseries),'border')
        fprintf(' ** hlightborders was set to %0.1f but no border data present.\n\t See: thisXylem.addBorderInfoToFilteredData\n',hlightborders)
        hlightborders=-1;
    end
end

if isempty(fname)
    [~,fname] = fileparts(data.pointsFname);
    if hlightborders>0
        fname = sprintf('%s-border%0.1f',fname,hlightborders);
    end
    fname = fullfile(tempdir,[fname,'.csv']);
    fprintf('Dumping points to %s\n',fname)
end    




fid = fopen(fname,'w+');

for ii=1:size(data.pointsInARA.(dataseries).sparsePointMatrix,1)
    tmp=data.pointsInARA.(dataseries).sparsePointMatrix(ii,:);

    pointSeries=1;

    if hlightborders>0
        if data.pointsInARA.(dataseries).border.d(ii) <= hlightborders
            pointSeries=2;
        end
    end

    if hlightexcluded
        if data.pointsInARA.(dataseries).ARAindex(ii)==0 || data.pointsInARA.(dataseries).isWhiteMatter(ii)
            pointSeries=3;
        end
    end

    fprintf(fid,'%0.2f,%0.2f,%0.2f,%0.2f\n', fliplr(tmp),pointSeries);
end

fclose(fid);



if nargout>0
    varargout{1} = fname;
end