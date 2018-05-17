function varargout=highlightAreaPlot(projectionStructure, highlightList, whichHem)
    %% Plot projected Allen Atlas with named brain area highlighted
    %
    % function H=aratools.projectAtlas.highlightAreaPlot(projectionStructure,highlightList)
    % 
    %
    % Purpose
    % Draw outlines around each brain using structure produced by aratools.projectAtlas.generate
    % Areas listed in colorAreas are highlighted by filling in these areas. Handles to plotted
    % data are optionally returned.
    %
    %
    % Inputs [required]
    %   projectionStructure - output of aratools.projectAtlas.generate
    %   highlightList - cell array of strings of area names. If missing then nothing is highlighted
    %                   and no error is generated.
    %
    % Inputs [optional]
    %   whichHem - 1 for left, 2 for right, 3 for both. Can be combined
    %
    % Outputs
    % H - optionally a structure containing the handles for the plotted objects and other associated
    %     data used to make the plot. This makes it easier for the plot to be further modifed and have
    %     other information added on top of the areas. 
    %
    %
    % Example
    % ATLAS=mhd_read('~/tvtoucan/Mrsic-Flogel/ReferenceAtlas/ARA_CCFv3/ARA_25_micron_mhd/atlas_smooth1_corrected.mhd');
    % out = aratools.projectAtlas.generate(ATLAS);
    % aratools.projectAtlas.highlightAreaPlot(out,{'Primary visual area', 'Primary auditory area'})
    %
    % 
    %
    % Rob Campbell - 2017
    %
    %
    % Also see:
    % aratools.projectAtlas.generate, % aratools.projectAtlas.simplePlotter



    if nargin<2
        help mfilename
        return
    end
    if ~exist('whichHem', 'var')
        whichHem = [];
    end

    %If the user supplied a list of areas to highlight, then we go through the list, find the 
    %areas and set up the colors
    if ~isempty(highlightList)
        if ~iscell(highlightList)
            fprintf('** highlightList should be a cell array\n')
            return
        end
        if length(highlightList)==1
            hlightCols=[1,0,0];
        else
            hlightCols = parula(length(highlightList));
        end
        hlitedInds = nan(1, length(highlightList)); %List of indexes in the structure list that we will highlight
        for ii=1:length(highlightList)
            IND = strmatch(highlightList{ii}, projectionStructure.structureList.name);
            if isempty(IND)
                fprintf('Failed to find brain area for name %s. Skipping\n', highlightList{ii});
                continue
            end
            hlitedInds(ii)=IND;
        end

     

    end




    % - - - - - - - - 
    set(gcf,'Color','w')
    basicProjectionColor = [1,1,1]*0.5;

    hold on

    nB=1;
    H.plottedNames={}; %The areas plotted in order
    for ii = 1:height(projectionStructure.structureList);
        B = projectionStructure.structureList.areaBoundaries{ii}; %Collect the border data for this area

        if any(hlitedInds==ii)
            if ~isempty(whichHem)
                hemInfo = projectionStructure.structureList.areaHemisphere{ii};
                okHem = ismember(hemInfo, whichHem);
                makeLineBoundary(B(~okHem))
                B = B(okHem);
            end
            H.plottedNames{end+1}=projectionStructure.structureList.name{ii};
            makeArea(B, find(hlitedInds==ii))
        else
            makeLineBoundary(B)
        end
    end

    hold off
    axis equal off

    if nargout>0
        varargout{1}=H;
    end



    %---------------------------------------------------------
    function makeLineBoundary(B)
       for k = 1:length(B)
         thisBoundary = B{k};
         H.borders(nB)=plot(thisBoundary(:,2), thisBoundary(:,1), 'color', basicProjectionColor, 'LineWidth', 1);
         nB=nB+1;
       end

    end

    function makeArea(B, colorIndex)
       for k = 1:length(B)
         thisBoundary = B{k};
         H.hLight(colorIndex,k)=patch(thisBoundary(:,2), thisBoundary(:,1),hlightCols(colorIndex,:));
       end
    end

end
