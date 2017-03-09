function varargout=highlightAreaPlot(projectionStructure,highlightList)
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


    %If the user supplied a list of areas to highlight, then we go through the list, find the 
    %areas and set up the colors
    if ~isempty(highlightList)
        if ~iscell(highlightList)
            fprintf('** highlightList should be a cell array\n')
            return
        end

        hlitedInds = []; %List of indexes in the structure list that we will highlight
        for ii=1:length(highlightList)
            IND = strmatch(highlightList{ii}, projectionStructure.structureList.name);
            if isempty(IND)
                fprintf('Failed to find brain area for name %s. Skipping\n', highlightList{ii});
                continue
            end
            hlitedInds=[hlitedInds;IND];
        end

        if length(hlitedInds)==1
            hlightCols=[1,0,0];
        else
            hlightCols = parula(length(hlitedInds));
        end

    end




    % - - - - - - - - 
    set(gcf,'Color','w')
    basicProjectionColor = [1,1,1]*0.5;

    hold on

    nB=1;
    nP=1;
    H.plottedNames={}; %The areas plotted in order
    for ii = 1:height(projectionStructure.structureList);
        B = projectionStructure.structureList.areaBoundaries{ii}; %Collect the border data for this area

        if any(hlitedInds==ii)
            H.plottedNames{end+1}=projectionStructure.structureList.name{ii};
            makeArea(B)
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

    function makeArea(B)
       for k = 1:length(B)
         thisBoundary = B{k};
         H.hLight(nP,k)=patch(thisBoundary(:,2), thisBoundary(:,1),hlightCols(nP,:));
       end
       nP=nP+1;
    end

end
