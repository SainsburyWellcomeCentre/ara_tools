function varargout=checkRegisteredAtlasAreas(registered,atlas)
% check if any brain areas are missing from the registered atlas
%
% function missing=checkRegisteredAtlasAreas(registered,atlas)
%
%
% Purpose
% Following registration of the atlas to a sample, it is possible (perhaps likely)
% that some brain areas will somehow go missing. This may simply be because the 
% sample brain is not complete (e.g. missing cerebellum) and so the registered atlas
% is truncated. However, it's also possible that something more serious has happened
% and so it's useful to have a function that checks for this. Results are printed
% to screen and optionally to a an output cell array.
%
%
% Inputs
% registered - a) relative or absolute path to the registered atlas
%              b) atlas volume read in with mhd_read
% atlas - [optional]
% 		  a) relative or absolute path to the original atlas image
%         b) original atlas volume read in with mhd_read
%		  c) empty or missing: the default image is read
%
%
% Outputs
% missing - output cell array contain the missing areas. The collumn order:
%           {area id, parent id, area acronym, area name}
%
%
% Rob Campbell - Basel 2015


if nargin<2 | isempty(atlas)
	[~,atlas]=getARAfnames;
end


if isstr(registered)
	if ~exist(registered,'file')
		fprintf('Can not find file %s\n',registered)
		return
	end
	registered = mhd_read(registered);
end

if isstr(atlas)
	if ~exist(atlas,'file')
		fprintf('Can not find file %s\n',atlas)
		return
	end
	atlas = mhd_read(atlas);
end


%get the unique brain areas in the two volumes
uAtlas = unique(atlas(:));
uRegis = unique(registered(:));


if length(uAtlas) == length(uRegis)
	fprintf('The number of brain areas is identical between the two files\n')
	return
end

if length(uRegis)>length(uAtlas)
	fprintf('The registered atlas contains areas not found in the atlas. ODD.\n')
	return
end

%Load the brain area names
[~,~,atlasDir]=getARAfnames;
load(fullfile(atlasDir,'flattened.mat'))

%Find which areas are missing
fprintf('The following areas are missing from the registered atlas:\n') 

ind = [flattened{:,1}];
missingIndsInFlattened = [];
for ii=1:length(uAtlas)
	f=find(uRegis==uAtlas(ii));
	if ~isempty(f)
		continue
	end

	f=find(ind==uAtlas(ii));
	fprintf('%d. %s\n', uAtlas(ii), flattened{f,4})

	if nargout>0
		missingIndsInFlattened(length(missingIndsInFlattened)+1) = f;
	end

end


if nargout>0
	varargout{1}=flattened(missingIndsInFlattened,:);
end