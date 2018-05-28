function [corticalAreas] = corticalLayerTable
% return a table with a line per cortical area per layer.
%
% 
% function [corticalAreas] = aratools.utils.corticalLayerTable
%
% Purpose
% In some applications we want to group cortical areas per layer or
% group some of the layers of one cortical areas. Return a table with
% cortical area info associated to the layers
%
% Inputs
% none
%
% 
% Outputs
% corticalAreas - A table with the following fields: 'cortical_area', 
%      'cortical_area_id', 'layer', 'layer_part', 'sub_area_id', 'sub_area_name'
%
%
% To get all the index corresponding the area # `id`:
% allSubIds = unique(corticalAreas(corticalAreas.cortical_area_id == id, 'sub_area_id'))
%
% To find all the name of the area that have a layer 6b defined
% area6bIds = corticalAreas((corticalAreas.layer==6) & ...
%                           (strcmp(corticalAreas.layer_part, 'b')), 'cortical_area')
%
%
% Currently (24/05/2018) the allen brain atlas separates layer 6a and b but
% not layer 5. Layer 2 and 3 are almost always grouped together and there
% are therefore two lines in the output tables with the same 'sub_area_id'
%
%
% Antonin Blot - London 2018



% Load the Allen structure list (pull from web if needed)
labels=getAllenStructureList; 

% Find all the children of isocortex
id_ctx = labels.id(strcmp(labels.name, 'Isocortex'));
vbDescendant = cellfun(@(x) contains(x, sprintf( '/%.0f/', id_ctx)), ...
    labels.structure_id_path, 'un', 1);
structureCortex = labels(vbDescendant,:);


% Iterate on them and if it has layer info add them to the table
csCorticalAreasTableHeader = {'cortical_area', 'cortical_area_id', 'layer', ...
    'layer_part', 'sub_area_id', 'sub_area_name'};
corticalAreas = cell([0, numel(csCorticalAreasTableHeader)]);
for iS = 1:size(structureCortex,1)
    area = structureCortex.name{iS};
    area_id = structureCortex.id(iS);
    layer_index_in_area_name = strfind(lower(area), 'layer');
    if ~isempty(layer_index_in_area_name)
        % find parent and attribute
        cortical_parent_id = structureCortex.parent_structure_id(iS);
        cortical_parent_name = structureID2name(cortical_parent_id);
        
        layer = area(layer_index_in_area_name:end);
        layer_number = regexp(layer, '(\d)([a-b]?)', 'tokens');
        for iL = 1:numel(layer_number)
            layer_info = layer_number{iL};
            corticalAreas(end + 1,:) = {cortical_parent_name, ...
                cortical_parent_id, str2double(layer_info{1}), layer_info{2}, area_id, area};
        end
    end
end

corticalAreas = cell2table(corticalAreas, 'VariableNames', csCorticalAreasTableHeader);
