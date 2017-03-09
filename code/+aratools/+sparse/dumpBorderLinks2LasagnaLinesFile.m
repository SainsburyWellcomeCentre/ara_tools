function varargout=dumpBorderLinks2LasagnaLinesFile(data,varargin)
% Dump the links between each point and its assigned nearest border to a single ARA points structure
%
%  function varargout=dumpBorderLinks2LasagnaLinesFile(data,varargin)
%
%
% Purpose
% Dump to disk a CSV file that contains the data from a single leaves, upsampledPoints, 
% etc, structure showing how each point is related to its border in the format:
% line_series,z,x,y
%
% This is designed to be read by the Lasagna sparse points reader:
% https://github.com/raacampbell/lasagna/blob/master/IO/line_reader_plugin.py
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
%
%
% Examples
% >> D=X.returnData % extract filtered data with border information
%
% % Dump the first cell 
% >> aratools.sparse.dump2LasagnaPointsFile(D(10))
% Dumping points to /tmp/YH102_traced_cells_tree_01-border0.4.csv

params = inputParser;
params.CaseSensitive=false;

params.addParamValue('fname','',@ischar)
params.addParamValue('dataseries','rawSparseData',@ischar)
params.parse(varargin{:})

fname = params.Results.fname;
dataseries = params.Results.dataseries;



%process input arguments
if ~isstruct(data)
    fprintf('data must be a structure\n')
    return
end

if ~isfield(data,'pointsInARA')
    fprintf('data must contain field "pointsInARA\n')
    return
end

if ~isfield(data.pointsInARA.(dataseries),'border')
    fprintf(' ** no border data present.\n\t See: thisXylem.addBorderInfoToFilteredData\n')
end

if ~isfield(data.pointsInARA,dataseries)
    fprintf('\ndata.pointsInARA contains no field "%s"\nAvailable fields are:\n\n', dataseries)
    cellfun(@(x) fprintf(' -  %s\n',x), fields(data.pointsInARA));
    fprintf('\n')
    return
end

if isempty(fname)
    [~,fname] = fileparts(data.pointsFname);
    fname = [fname,'-lines.csv'];

    fname = fullfile(tempdir,fname);
    fprintf('Dumping points to %s\n',fname)
end    




fid = fopen(fname,'w+');

for ii=1:size(data.pointsInARA.(dataseries).sparsePointMatrix,1)

    point = data.pointsInARA.(dataseries).sparsePointMatrix(ii,:);
    border = data.pointsInARA.(dataseries).border.borderCoords(ii,:);

    fprintf(fid,'%0.2f,%0.2f,%0.2f,%0.2f\n', ii, fliplr(point));
    fprintf(fid,'%0.2f,%0.2f,%0.2f,%0.2f\n', ii, fliplr(border));
end

fclose(fid);



if nargout>0
    varargout{1} = fname;
end