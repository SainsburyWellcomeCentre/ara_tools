function flattened = flattenARAjson(fname,verbose)
% Read in the Allen Reference Atlas JSON and convert to a flattened structure for easy searching
%
% function flattened = flattenARAjson(fname)
%
% ** NOTE: this function is being replaced by getAllenStructureList **
% 
% Purpose
% Returns a cell array that is a flattened version of the 
% hierachical JSON structure returned by importing the ARA JSON
% file with loadjson from the JSONlab tools on the FEX.
%
%
% Inputs
% fname - the path to the JSON or the structure containing the json
% verbose - [optional, 0 by default] reports what function is doing if 1.
%         
% Outputs
% flattened - a table where the columns are as follows:
%             1. area ID
%             2. parent area
%             3. area short name
%             4. area long name
%              5. (node) depth
%
% Examples
% flattened = flattenARAjson('./labels.json');
%
% labels = loadjson('./labels.json');
% flattened = flattenARAjson(labels);
%
%
% Rob Campbell - Basel 2015
%
% Also see:
% buildTreeFromARALabels, loadjson, getAllenStructureList

fprintf('\n  * NOTE: %s is a legacy function. Please use getAllenStructureList instead *\n\n',mfilename)


if ~exist('loadjson','file')
    fprintf('\n\t * function loadjson is missing. Install JSONlab from the FileExchange * \n\n');
end

if nargin<1
    fprintf('No inputs supplied to %s. Quitting.\n',mfilename)
    flattened=[];
    return
end

if nargin<2
    verbose=0;
end

%Load json file is a string was provided. 
if isstr(fname)
    if exist(fname,'file')
        if verbose
            fprintf('Extracting data from %s\n',fname)
        end
        json = loadjson(fname);
    else
        fprintf('%s not in path. quitting %s\n', fname, mfilename)
        flattened = [];
        return
    end
elseif isstruct(fname)
    json = fname;
end



%Loop through the json and pull out the brain area names and labels
%using a recursive function call
if verbose
    fprintf('Flattening\n')
end
flattened = looper(json.msg{1});


flattened = cell2table(flattened,'VariableNames',{'id','parent_id','acronym','name','depth'});

function out = looper(json,out,node_depth)
% looper searches recursively through the structure to build the flattened cell array
%
% json - the json tree structure imported from the json file
% out - the output of the last call of the function (we call recursively)
% node_depth - the current node depth with respect to the root 

if nargin<2
    out{1,1} = json.id;
    out{1,2} = -1; %otherwise this row of the table will be a cell array. 
    out{1,3} = json.acronym;
    out{1,4} = json.name;
    node_depth = 1;
    out{1,5} = node_depth;
    looper(json,out,node_depth);
end

node_depth = node_depth+1;
for ii=1:length(json.children)
    c = json.children{ii};
    tmp{1,1} = c.id;
    tmp{1,2} = c.parent_structure_id;
    tmp{1,3} = c.acronym;
    tmp{1,4} = c.name;
    tmp{1,5} = node_depth;

    out = [out;tmp];
    out = looper(c,out,node_depth);
end

