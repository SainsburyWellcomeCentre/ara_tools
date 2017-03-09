function varargout=getBorderPixelsForArea(obj,areaIndex,displayBorderAreaNames)
    % getBorderPixelsForArea
    %
    % function varargout=getBorderPixelsForArea(obj,areaIndex,displayBorderAreaNames)
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
    % areaIndex - the index of the area for which we will find borers
    % displayBorderAreaNames - optional bool. false by default. if true, print 
    %                          to screen the names of the border areas
    %
    %
    % Outputs (optional)
    % borderIndexes = index values corresponding to the edges in the atlas volume.
    %
    % 
    % Also see:
    % xylem.refreshStoredAreaBorders
    % xylem.addBorderInfoToFilteredData
    % xylem.removePointsNearBorders

    verbose=false;

    if nargin<3
        displayBorderAreaNames=false;
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
        fprintf('Found no border for area %d. ODD.\n',areaIndex)
    end

    if verbose
        n=length(borderIndexes);
        fprintf('There are %d border pixels\n',n)
    end

    % Strip out the index values that are white matter and out of the brain
    f = ~ismember(obj.atlas.atlasVolume(borderIndexes), [0;obj.whiteMatterInds]); %f is non-white matter
    borderIndexes = borderIndexes(f);

    if displayBorderAreaNames

        u=unique(obj.atlas.atlasVolume(borderIndexes));
        if isempty(u)
            fprintf('Nothing found\n')
        end

        fprintf('Selected area "%s" (%d) is bordered by:\n',...
            structureID2name(areaIndex),areaIndex)
        S=structureID2name(u);
        if iscell(S)
            disp(S')
        else
            disp(S)
        end
    end

    if nargout>0
        varargout{1} = borderIndexes;
    end

end %getBorderPixelsForArea
