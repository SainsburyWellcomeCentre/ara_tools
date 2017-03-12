function isWithin = ARAindexIsWithin(ind,thisArea,skipChecks,labels)
% Check if a given Allen area area is a descendant of another area.
%
% function isWithin = ARAindexIsWithin(ind,thisArea,skipChecks)
%
%
% Purpose
% Given imported ARA JSON structure, labels, is the atlas index 
% "ind" a child of "thisArea"?
% 
% The Allen brain areas are arranged hierarchically in a JSON file. Thus, 
% for example, 'primary visual cortex' is a descendant of 'cerebral cortex'
% This function tests whether a given Allen Atlas index (i.e. the number that
% you read off the atlas volume) is a descendant of another area. 
% This function simply returns 1 or 0 depending on whether or not this is
% true. 
%
%
% Uses
% Building arbirtary boundaries around things like the coretx or the 
% the somatosensory areas. 
%
% 
% Inputs
% ind - a scalar index (e.g. value from the atlas volume)
% thisArea - an index or area name to search for on the path 
%            to the root node. If string, not case sensitive
%            and will treat it is a substring. So if thisArea
%            is 'auditory cortex' it will match 'Auditory cortex layer 2'
% skipChecks - 0 by default. if 1 we skip checks to ensure that the area
%              name exists. Dangerous as means we can get stuck in a loop.
%              saves time, though, if caller function calls this function 
%              many times. 
% labels - if supplied we don't have to load them here (use getAllenStructureList)
%
% e.g.
% The following return false because index 452 is the Median preoptic nucleus
% ARAindexIsWithin(452, 'cerebral cortex') 
% ARAindexIsWithin(452, 90)
%
% The following returns true because index 279 is part of retrosplenial 
% ARAindexIsWithin(279, 'retrosplenial') 
%
%
% Rob Campbell - Basel 2015



%Check that thisArea exists
if nargin<3
    skipChecks=0;
end

if nargin<4
    labels = getAllenStructureList;
end

if ~skipChecks
    if isnumeric(thisArea)
        f=find(labels.id==thisArea);
        if isempty(f)
            fprintf('Can not find area %s\n',thisArea)
            return
        end
    elseif isstr(thisArea)
        f = isAreaPresent(labels,thisArea);
        if isempty(f)
            fprintf('Can not find area %s\n',thisArea)
            return
        end
    end
end


isWithin = 0;
currentID = ind;
verbose=0;
while isWithin==0 & currentID~=997 %997 is the root id (for some reason)
    f=find(labels.id==currentID);
    if isempty(f)
        error('Can not find index %d in brainIndex',currentID)
    end
    parentID = labels.parent_structure_id(f);
    parentname = labels.name{find(labels.id==parentID)};
    if verbose
        fprintf('%s (%d) is within %s (%d)\n',labels{f,4}{1}, currentID, parentname, parentID) 
    end
    if isnumeric(thisArea)
        if thisArea==currentID
            isWithin=1;
        end
    elseif isstr(thisArea)
        t = regexpi(parentname,['^',thisArea]); %CAUTION: is this regex is wrong then areas will be erroneously assigned
        if ~isempty(t)
            isWithin=1;
        end
    end

    currentID = parentID;
end
