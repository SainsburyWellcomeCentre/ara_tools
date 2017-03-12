function jsonTree=buildTreeFromARALabels(fname,verbose)
% import ARA labels file as a tree structure
%
% function jsonTree=buildTreeFromARALabels(fname,verbose)
%
%
% Purpose
% Read the ARA labels as a tree structure
%
% Inputs
% fname - the path to the JSON or the structure containing the json
% verbose - [optional, 0 by default] reports what function is doing if 1.
%
% Outputs
% jsonTree - the flattened data in a hiearchical tree form.
%
%
% Examples
% out = buildTreeFromARALabels('./labels.json');
%
% labels = loadjson('./labels.json');
% out = buildTreeFromARALabels(labels);
%
%
% Rob Campbell - Basel 2015
%
% Also see:
% flattenARAjson, loadjson



if ~exist('loadjson','file')
    fprintf('function loadjson is missing. Download JSONlab from the FileExchange\n');
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
        jsonTree = [];
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
jsonTree = looper(json.msg{1});



function out = looper(json,out,ind)
% looper searches recursively through the structure to build the tree
if nargin<2
    node.id = json.id;
    node.acronym = json.acronym;
    node.name = json.name;

    out = tree(node);
    ind=1;
    looper(json,out,ind);
end

for ii=1:length(json.children)
    c = json.children{ii};
    node.id = c.id;
    node.acronym = c.acronym;
    node.name = c.name;

    [out,ind] = out.addnode(ind,node);

    out = looper(c,out,ind);
end

