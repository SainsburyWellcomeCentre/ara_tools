function treeData=exportedCSV2tree(fname)
% re-import a tree structrue that was exported as a csv file
%
% function treeData=exportedCSV2tree(fname)	
%
% Purpose
% re-import a tree from a csv file. Useful if the tree data were 
% modified in some way and we want to re-import to make use of
% the tree structure (e.g, to extract segments)
% 
%
% Inputs
% fname - relative or absolute path to the csv file
%
% Outputs
% treeData - the re-imported tree
%
%
% Rob Campbell - Basel 2015


if ~exist(fname)
	fprintf('%s - Can not find %s\n',mfilename,fname)
	return
end


%read data
data=csvread(fname);

treeData = tree(data(1,3:end));

for ii=2:size(data,1)
	prevNode = data(ii,2);
	treeData = treeData.addnode(prevNode,data(ii,3:end));
end
