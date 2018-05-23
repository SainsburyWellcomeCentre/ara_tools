function [inds,areaNames] = whiteMatterInds
% return the index values and names of ARA areas that are white matter
%
% 
% function [inds,areaNames] = aratools.utils.whiteMatterInds
%
% Purpose
% In some applications we want to remove fibre tracts. This function
% returns the names and indexes of areas that are such, to allow us
% to do this easily.
%
%
% Inputs
% none
%
% 
% Outputs
% inds - a vector of index values corresponding to areas that are white matter
% areaNames - a cell array the same size as inds, where each cell contains to 
%             the area name of the corresponding value in inds.
%
%
% Rob Campbell - Basel 2016



% Load the Allen structure list (pull from web if needed)
labels=getAllenStructureList; 

id_fibre = labels.id(strcmp(labels.name, 'fiber tracts'));
vbDescendant = cellfun(@(x) contains(x, sprintf( '/%.0f/', id_fibre)), ...
    labels.structure_id_path, 'un', 1);
areaNames = labels.name(vbDescendant);
inds = labels.id(vbDescendant);