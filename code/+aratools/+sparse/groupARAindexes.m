function [data,areaReassignmentInds] = groupARAindexes(data,groupingRule,verbose,structures)
% Group Allen Reference Atlas (ARA) indexes (e.g. layers) to higher order structures
%
% function [data,areaReassignmentInds] = groupARAindexes(data,groupingRule,verbose,structures)
%
%
% Purpose
% The Allen Atlas brain areas are arranged hierarchically in a tree format. 
% For example, primary visual cortex layer 2/3 is a child of primary visual cortex.
% When we assign brain areas to objects such as imaged cell body locations or 
% neurite trees, we do so on the level of the most detailed structure available.
% In other words, to the leaves (terminal nodes) of the Allen brain areas tree. 
% We might, however, want to pool layers or other structures to analyse data on a 
% more coarse level. This function aggregates data according to certain rules. 
% These are defined by the groupingRule input argument.
%
% 
% Inputs
% data - The output of aratools.sparse.processTreeData or pointsInARA. 
%        So it can be a vector of structures or just one structure.
%        TODO: If the areaVolume field is also present, then it updates this.  [NO IT DOESN'T]
%
% groupingRule - a string or cell array corresponding to valid grouping 
%                actions. If this is a cell array  the actions are applied
%                in the order they appear in the array. 
%                - 'layers' - groups cortical layers
%                - group arbitrary areas and rename: {'grouped_name',{'name1','name2',...}}
%                  e.g. to group V1 under cortex: {'cortex',{'Primary visual'}}
%
% verbose - [optional] reports to screen what the function is doing.
%
%
% Outputs
% data - The input structure, but with the data.ind field (and the areaVolume field) updated.
% areaReassignmentInds - An n by 2 array where each row is one index. The first column
%                        is the original value of the index. The second is what we have assigned it to,
%
%
% Rob Campbell - Basel 2015


if nargin<2
    fprintf('\nNo grouping rule supplied to %s. Quitting.\n\n',mfilename)
    return
end

if nargin<3
    verbose=0;
end

if nargin<4
    structures = getAllenStructureList; %get the Allen structure names
end


%Loop through all structures with a recursive call
if length(data)>1
    areaReassignmentInds=[];
    for ii=1:length(data)
        [data(ii),theseReassignedInds]=aratools.sparse.groupARAindexes(data(ii),groupingRule,verbose,structures);
        areaReassignmentInds = [areaReassignmentInds;theseReassignedInds];
    end
    
    areaReassignmentInds = unique(areaReassignmentInds,'rows');

    return
end



%If the grouping rule is a cell array, we loop through it via a recursive function call
if iscell(groupingRule)
    for ii=1:length(groupingRule)
        thisRule = groupingRule{ii};
        [data,areaReassignmentInds] = applyRule(data,thisRule,structures,verbose);
    end
elseif ischar(groupingRule)
    [data,areaReassignmentInds] = applyRule(data,groupingRule,structures,verbose);
end


%-------------------------------------------------------------------------------
function [data,IDsBeforeAndAfter] = applyRule(data,groupingRule,structures,verbose)

if verbose
    fprintf('\n----------------------------------------\nWe begin with these areas:\n')
    try
        arrayfun(@(x) fprintf(' %s\n',structures.name{structures.id==x}), unique(data.ind))
        fprintf('\n')
    catch
        fprintf('AREA DISPLAY FAILED\n')
    end
end


% -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  
% Keep only the subset of the structures table that contains the index values that are present in 
% in this sample. To make this choice we select the points data set that contains the most 
% different areas. This will be largest set. All the ones with fewer points will just be a subset
% of this larger set. If the upsampled tree was calculated, the following lines will inevitably 
% choose this data set. 
dataSetType = fields(data.pointsInARA)';
n=zeros(1,length(dataSetType));
for ii=1:length(dataSetType)
    n(ii)=length(data.pointsInARA.(dataSetType{ii}).ARAindex);
end
[~,indToChoose]=max(n);
subset = structures(ismember(structures.id, data.pointsInARA.(dataSetType{indToChoose}).ARAindex),:);


% -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  
% We now figure out which index values need to be replaced with which other index values
if isstr(groupingRule)

    switch lower(groupingRule)
        case 'layers' %Group layers by name

            % Here will will group both layer and also group all the retrosplenial areas together

            %Get all retrosplenial sub-regions and call them retrosplenial
            if verbose
                disp('-------------------------------')
            end

            f=strmatch('Retrosplenial area,',subset.name);
            if ~isempty(f)

                origIDsR = subset.id(f); %These are the IDs that we want to change
                origNamesR = subset.name(f);

                fRetro = strmatch('Retrosplenial area',structures.name,'exact');
                retroID  = structures.id(fRetro);

                %loop through these and find their parents
                newIDsR=zeros(size(origNamesR));
                newNamesR=cell(size(origNamesR));
                for ii=1:length(origIDsR);
                    f=find(structures.id==origIDsR(ii));
                    newIDsR(ii) = retroID;
                    newNamesR{ii} = 'Retrosplenial area';
                end
                if verbose
                    fprintf('Pooled retrosplenial areas\n')
                end
            else
                origIDsR=[];
                origNamesR={};
                newIDsR=[];
                newNamesR={};
            end



            %depth 8 contains the cortical layers for the visual areas, and most somatosensory are in 9
            f=find(subset.depth==9 | subset.depth==8 | subset.depth==7);

            if ~isempty(f)
                origIDsL = subset.id(f); %These are the IDs that we want to change
                origNamesL = subset.name(f);

                %loop through those and find their parents
                newIDsL=zeros(size(origNamesL));
                newNamesL=cell(size(origNamesL));
                for ii=1:length(origIDsL);
                    %If this ID is a retrosplenial area, we skip it
                    if strfind(origNamesL{ii},'Retrosplenial')
                       origIDsL(ii)=-1;
                       origNamesL{ii}=nan;
                       continue
                    end
                    f=find(structures.id==origIDsL(ii));
                    thisNewID=structures.parent_structure_id(f);
                    newIDsL(ii) = thisNewID;
                    newNamesL{ii} = structures.name{structures.id == thisNewID};
                end

                %remove rows related to retrosplenial areas, since we have dealt with those already
                f=find(origIDsL<0);
                if ~isempty(f)
                    origIDsL(f)=[];
                    newIDsL(f)=[];
                    origNamesL(f)=[];
                    newNamesL(f)=[];
                end
            else
                fprintf('Found no points in any cortical layers.\n')
                origIDsL=[];
                newIDsL=[];
                origNamesL=[];
                newNamesL=[];
            end

            origIDs = [origIDsL;origIDsR];
            origNames = [origNamesL;origNamesR];
            newIDs = [newIDsL;newIDsR];
            newNames = [newNamesL;newNamesR];

            if verbose
                [~,ind]=sort(origNames);

                for ii=1:length(ind)
                    fprintf('%s \t-->\t %s\n',origNames{ind(ii)}, newNames{ind(ii)})
                end
            end

        otherwise
            fprintf('Skipping unknown grouping rule "%s"\n ', groupingRule);
    end

elseif iscell(groupingRule)

    %Group a set of named areas into a different named area
    if length(groupingRule) ~= 2
        error('Expected groupingRule to have a length of 2 if it is a cell array')
    end

    newIndex = strmatch(groupingRule{1},structures.name,'exact');

    if length(newIndex)>1
        fprintf('Found more than one ID for %s. Please use the exact string. Skipping\n',groupingRule{1})
        return
    end
    if isempty(newIndex)
        if verbose
            fprintf('Failed to find target ID for name %s. Skipping\n',groupingRule{1})
        end
        return
    end

    newNames = structures.name(newIndex);

    if ~iscell(groupingRule{2})
        groupingRule{2}={groupingRule{2}};
    end

    oldID=[];
    oldInd=[];

    for ii=1:length(groupingRule{2})
        thisInd=strmatch(groupingRule{2}{ii},structures.name);
        if isempty(thisInd)
            if verbose
                fprintf('Failed to find source ID for name %s. Skipping this id.\n',groupingRule{2}{ii})
            end
            continue
        end

        oldInd=[oldInd; thisInd]; %The index in the array
        oldID = [oldID; structures.id(thisInd)]; %The ID in the atlas
    end

    %Keep only those IDs that we have in our data
    keep = ismember(oldID,data.ind);
    oldInd = oldInd(find(keep)); %The index in the array
    oldID = oldID(find(keep));   %The area ID in the atlas

    origNames = structures.name(oldInd);

    if isempty(oldID)
        if verbose
            fprintf('Found no IDs to set to %s. Skipping\n',groupingRule{1});
        end
        return
    end

    origIDs = oldID;

    newIDs = repmat(structures.id(newIndex),1,length(origIDs));


    newNames = repmat(newNames,1,length(origNames));
end

% - - - - - - - - - -
% Sanity check
% If the original and new ID vectors aren't the same length then something has gone wrong
if length(origIDs) ~= length(newIDs)
    error('length(origIDs) is %d but length(newIDs) is %d. They should be the same', length(origIDs), length(newIDs))
end


% -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
% Now we can perform the replacement for each data set (e.g. leaves, upsampled points, etc)
for thisType=dataSetType
    for ii = 1:length(origIDs)
        f=find(data.pointsInARA.(thisType{:}).ARAindex==origIDs(ii));
        data.pointsInARA.(thisType{:}).ARAindex(f) = newIDs(ii);

        if verbose
            %Count how many times each original ID appears in the terminal node data
            if strcmp('leaves',thisType{:})
                numIDs{ii} = length(f);
            end
        end

    end
end

if verbose
    fprintf('\nConverting the following names:\n')
    cellfun(@(x,y,z) fprintf('%s \t->  %s (#%d) \n',x,y,z), origNames(:),newNames(:), numIDs(:))

    fprintf('\nWe now have the following areas present:\n')
    try
        arrayfun(@(x) fprintf(' %s\n',structures.name{structures.id==x}), unique(data.ind))
        fprintf('\n')
    catch
        fprintf('AREA DISPLAY FAILED\n')
    end
end



% Make an n by 2 array where each row is one index. The first column
% if the before id and the second the after id
IDsBeforeAndAfter = [origIDs(:),newIDs(:)];
