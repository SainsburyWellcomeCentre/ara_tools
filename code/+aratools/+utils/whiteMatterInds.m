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

searchTerms = {...
    'alveus', ...
    'corpus callosum',...
    'fiber',...
    'nerve',...
    'tract',...
    'pathway',...
    'peduncle',...
    'commissure',...
    'internal capsule',...
    'lateral lemniscus',...
    'cingulum bundle'};


f=[]; %rows that contain one of the above terms get appended to f

for ii=1:length(searchTerms)    
    C=cellfun(@(x) strfind(lower(x),searchTerms{ii}), labels.name, 'uniformoutput',false); %search for string 
    f = [f; find(~cellfun(@isempty,C))];
end

f = unique(f); %just in case

inds = labels.id(f); %These are the ARA index values
areaNames = labels.name(f); %These are the area names

% Remove nuclie that shouldn't be there
C=cellfun(@(x) strfind(lower(x),'nucleus of the '), ...
            areaNames, 'uniformoutput',false);
f=find(~cellfun(@isempty,C));
inds(f) = [];
areaNames(f) = [];
