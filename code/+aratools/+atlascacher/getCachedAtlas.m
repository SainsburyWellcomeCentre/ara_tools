function DATA = getCachedAtlas
% Look for a cached atlas on the base workspace and return it if possible
%

%
% Example
% LOADED_ARA = aratools.atlascacher.getCachedAtlas(LOADED_ARA)
%
% Rob Campbell - Basel 2015.
%
% Also See:
% cachceAtlasToWorkSpace

    varName='LOADED_ARA'; %The name of the cached atlas
    W=evalin('base','whos');
    ind = strmatch(varName,{W.name});

    if ~isempty(ind)
        DATA=evalin('base',varName);
    else
        DATA=[];
    end
