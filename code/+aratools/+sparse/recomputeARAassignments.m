function data = recomputeARAassignments(data,varargin)
% Determine the location of a set of points in the ARA and return in a consistent way for other functions
%
%
% Purpose
% Takes as input the output of pointsInARA (one structure) and a raw sparse point array that
% is transformed to the ARA space. Determines the location of each point in the ARA and then
% organises data in a consistent manner that can be used by other functions. 
%
%
% Inputs (requried)
% data - the output of processTreeData
%
%
%
% Inputs (optional - param/value pairs)
% 'useCachedAtlas' - false by default. If false, we use the atlas defined in the input structure, data.
%                    if true, we use whatever atlas is cached currently and replace the listed
%                    one with this one. 
% 


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
%Parse optional arguments
params = inputParser;

params.CaseSensitive=false;
params.addParamValue('useCachedAtlas', false, @(x) islogical(x) | x==1 | x==0);
params.parse(varargin{:});

useCachedAtlas = params.Results.useCachedAtlas;
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 




%If we have asked for the workspace atlas to be used, then replace the stored one with that 
if useCachedAtlas==true
    fprintf('Updating atlas\n')
    CACHED_ATLAS = aratools.atlascacher.getCachedAtlas;
    CACHED_ATLAS.atlasVolume=[];
    for ii=1:length(data)
        data(ii).atlas = CACHED_ATLAS;
    end
end

S=settings_handler('settingsFiles_ARAtools.yml');
fprintf('Recomputing')
for ii=1:length(data)
    dataMetrics = fields(data(ii).pointsInARA);
    if mod(ii,5)
        fprintf('.')
    end

    for jj=1:length(dataMetrics)
        data(ii).pointsInARA.(dataMetrics{jj}) =  aratools.sparse.assignToARA(data(ii), ...
                                    data(ii).pointsInARA.(dataMetrics{jj}).sparsePointMatrix, ...
                                    'details',data(ii).pointsInARA.(dataMetrics{jj}).details, ...
                                    'dataColumns',1:3,...
                                    'ARAsettings',S);

        %if there are up-sampled data, check that they appear consistent with the raw data
        if strcmp(dataMetrics{jj},'upSampledPoints')
            uUp = unique(data(ii).pointsInARA.upSampledPoints.ARAindex);
            uInd = unique(data(ii).pointsInARA.rawSparseData.ARAindex);

            delta=setdiff(uInd,uUp);
            if ~isempty(delta)
                fprintf('*** WARNING: %s finds that points in original data not present in the upsampled data. ***\n',mfilename)
                for ii=1:length(delta)
                    fprintf('\tArea %d (%s)\n',delta(ii), structureID2name(delta(ii)))
                end
            end %if isempty(delta)
        end %if strcmp
    end %for jj=

end
fprintf('\n')
