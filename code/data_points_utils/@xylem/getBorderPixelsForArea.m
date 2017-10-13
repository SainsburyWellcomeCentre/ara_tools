function varargout=getBorderPixelsForArea(obj,areaIndex,displayBorderAreaNames,verbose)
    % getBorderPixelsForArea
    %
    % function varargout=getBorderPixelsForArea(obj,areaIndex,displayBorderAreaNames,verbose)
    %
    %
    % Purpose
    % Search the atlas for index "areaIndex", find its border with
    % neighboring areas that are not white matter or out of brain,
    % and store all voxels corresponding to these locations in a sparse
    % matrix. The matrix is stored in a map structure that is indexed by 
    % its areaIndex.
    % This method is run by xylem.refreshStoredAreaBorders
    %
    %
    % Inputs
    % areaIndex - The index of the area for which we will find borders
    % displayBorderAreaNames - optional bool. false by default. If true, print 
    %                          to screen the names of the border areas
    % verbose - false by default
    %
    %
    % Outputs (optional)
    % borderIndexes - index values corresponding to the edges in the atlas volume.
    % borderingStructureIDs - the structure IDs of the areas bordering "areaIndex"
    %
    % 
    % Also see:
    % xylem.refreshStoredAreaBorders
    % xylem.addBorderInfoToFilteredData
    % xylem.removePointsNearBorders


    if nargin<3 || isempty(displayBorderAreaNames)
        displayBorderAreaNames=false;
    end

    if nargin<4
        verbose=false;
    end


    %Create a new volume with only this area
    BW=zeros(size(obj.atlas.atlasVolume),'int8');
    f=find(obj.atlas.atlasVolume==areaIndex);
    BW(f)=1;

    if verbose
        fprintf('Area index %d contains %d pixels\n',areaIndex,length(f))
    end

    %Extract the border pixels            
    dilated=imdilate(BW, ones([3,3,3]) );

    if verbose
        n=length(find(dilated==1));
        fprintf('After dilation we have %d pixels\n',n)
    end

    dilated = (BW - dilated) * -1;

    TMP=dilated-BW;
    TMP(TMP<0)=0; %All ones are border pixels and will be in a different brain area

    borderIndexes=find(TMP==1);

    if length(borderIndexes)==0
        fprintf('Found no border for area %d. This is odd.\n',areaIndex)
    end

    if verbose
        n=length(borderIndexes);
        fprintf('There are %d border pixels\n',n)
    end

    % Strip out the index values that are white matter and out of the brain
    f = ~ismember(obj.atlas.atlasVolume(borderIndexes), [0;obj.whiteMatterInds]); %f is non-white matter
    borderIndexes = borderIndexes(f);


    u=unique(obj.atlas.atlasVolume(borderIndexes));
    if isempty(u)
        fprintf('No border indexes found in xylem.refreshStoredAreaBorders\n')
    end

    if displayBorderAreaNames
        ARA=getAllenStructureList;
        fprintf('\nSelected area "%s" (%d) is bordered by:\n',...
            structureID2name(areaIndex,ARA),areaIndex)
        S=structureID2name(u,ARA);
        if ~iscell(S)
            S={S};
        end
        for thisArea = 1:length(S)
            fprintf('  %s (%d)\n',S{thisArea}, u(thisArea))
        end
        fprintf('\n')
    end

    if nargout>0
        varargout{1} = borderIndexes;
    end
    if nargin>1
        varargout{2} = u;
    end
end %getBorderPixelsForArea
