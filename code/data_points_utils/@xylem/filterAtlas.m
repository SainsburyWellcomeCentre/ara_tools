function filterAtlas(obj)
    % Loads the ARA if needed then filters it according to the current rules
    %
    % function filterAtlas
    %
    % 
    % Purpose
    % Ensures that the atlas attached to the xylem object has brain areas
    % grouped in the same way as the traced data.


    %Make sure the correct atlas is loaded
    aratools.cacheAtlasToWorkSpace(obj.data(1).atlas)
    obj.originalAtlas = aratools.atlascacher.getCachedAtlas;

    if isempty(obj.whiteMatterInds)
        obj.whiteMatterInds = aratools.utils.whiteMatterInds;
    end

    verbose=false;

    %Run filtering rules on the atlas
    fprintf('Changing atlas indexes based on grouping rules.')
    obj.atlas = obj.originalAtlas;
    for ii=1:length(obj.areaReassignmentInds)
        if mod(ii,3)==0, fprintf('.'), end
        origID = obj.areaReassignmentInds(ii,1);
        newID = obj.areaReassignmentInds(ii,2);
        f=find(obj.originalAtlas.atlasVolume==origID);
        obj.atlas.atlasVolume(f)=newID;
        if verbose
            fprintf('Replaced %d (%s) with %d (%s)\n', origID, structureID2name(origID), newID, structureID2name(newID))
        end
    end
    fprintf('\n')

end %filterAtlas
