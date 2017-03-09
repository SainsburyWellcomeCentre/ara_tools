function out = determineNearestBorderForARApoints(obj,pointsInARA,verbose)
    % Determine the location of the closest border for each traced point
    %
    % function out = determineNearestBorderForARApoints(pointsInARA,verbose)
    % 
    %
    % Purpose
    % For each point we want to calculate its distance to the nearest border
    % with another brain area. So we don't count borders with the edge of the 
    % brain and also we don't count borders with white matter. Using the 
    % resulting distances, it is possible to exlude points based on their
    % distance to a border. 
    %
    % 
    % - Using this method
    % In general, this method is called by xylem.addBorderInfoToFilteredData
    % 
    % It takes as input one pointsInARA structure and from this calculate
    % the distance between each data point and it's border edge and the 
    % identity of the area on the other side of the border. In other 
    % words, this method takes an input something like obj.data(1).pointsInARA.rawSparseData
    % or use the output of returnData method to get the filtered data
    % We will ignore points that are in the white matter
    %
    % The verbose argument is false (0) by default. If true (1), it shows a *lot* 
    % of stuff and runs slower as a result. 
    %
    %
    %
    % - Related methods
    % The borders are calculated by xylem.getBorderPixelsForArea
    % Points can be removed with xylem.removePointsNearBorders

    if nargin<3
        verbose=false;
    end


    out.d = zeros(size(pointsInARA.hemisphere)); %pre-allocate the distance matrix
    out.ARAindex = zeros(size(pointsInARA.hemisphere)); %pre-allocate the border index matrix
    out.borderCoords = zeros(length(pointsInARA.hemisphere),3); %the coordinates of the nearest border
    aVol = obj.atlas.atlasVolume; %The atlas volume


    for ii=1:length(pointsInARA.ARAindex)

        %Skip any points that are in the white matter or out of the brain
        if pointsInARA.isWhiteMatter(ii)==1 || pointsInARA.ARAindex(ii)==0
            continue
        end

        L = pointsInARA.sparsePointMatrix(ii,:); %The coordinates of the point in the atlas
        indexOfPoint = aVol(L(1),L(2),L(3));

        if indexOfPoint ~= pointsInARA.ARAindex(ii)
            % Should never happen if everything is being run correctly. If this happens only 
            % once, we will drop out of processing the sample. We need, after all, to report
            % no errors. So we should fix it. 
            fprintf('Point area stored as %d (%s) but determineNearestBorderForARApoints thinks it is %d (%s). SKIPPING. BAD.\n',....
                pointsInARA.ARAindex(ii), structureID2name(pointsInARA.ARAindex(ii)), indexOfPoint, structureID2name(indexOfPoint))
            return
        end
        
        %Find border of this area
        if ~obj.borders.isKey(indexOfPoint)
            fprintf('Can not find a border for area %d (%s) in the borders map structure. SKIPPING. BAD.\n', ...
             indexOfPoint, structureID2name(indexOfPoint))
             continue
        end

        [II,JJ,KK]=ind2sub(size(aVol),obj.borders(indexOfPoint));
        borderCoords = [II,JJ,KK];

        m = bsxfun(@minus,borderCoords,L);
        m = sqrt(sum(m.^2,2));
        [mm,ind]=min(m);

        nearestVoxelCoords = borderCoords(ind,:);
        nearestVoxelIndex = aVol(nearestVoxelCoords(1), nearestVoxelCoords(2), nearestVoxelCoords(3));

        if verbose
            fprintf('%d/%d %d (%s) -- Closest distance: %0.1f voxels at index %d (%s) \n', ...
                ii, length(pointsInARA.hemisphere), indexOfPoint, ...
                structureID2name(indexOfPoint), mm, nearestVoxelIndex, structureID2name(nearestVoxelIndex))
        end
        out.d(ii) = mm;
        out.ARAindex(ii) = nearestVoxelIndex;
        out.borderCoords(ii,:) = nearestVoxelCoords;
    end %for ii=1:length(pointsInARA.ARAindex)
end % determineNearestBorderForARApoints

