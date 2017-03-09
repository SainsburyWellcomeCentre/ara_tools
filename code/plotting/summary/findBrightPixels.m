function varargout = findBrightPixels(dataDir,pixVals)
% Finds bright pixels in all tiff stacks in a directory
%
% function fnames = findBrightPixels(dataDir,pixVals)
%
%
% Purpose
% Loop through all tiff stacks in a directory, find the z, x, and y coords
% of each pixel greater then pixVals in each image. Save the results as a mat
% file which contains a matrix called theseData which has columns: z, x, y 
% pixel locations saved as uint16
%
% Inputs
% dataDir - string defining relative or absolute path to directory containing 
%  			TIFF images. e.g. 'stitchedImages_100/1'
% pixVals - scalar or vector defining the pixel threshold value. If a vector
%           of length n, we save n .mat files each with values thresholded at 
%           a different pixVal
%
%
% Outputs 
% fnames - optionally returns the saved file names as a cell array.
%
%
% Examples
% >> findBrightPixels('stitchedImages/2',[7E3,9E3])
% This produced files called:
% pixLocs_7000.mat and pixLocs_9000.mat
% 
%
% Rob Campbell - Basel 2015


S=settings_handler('settingsFiles_ARAtools.yml');

tiffs = dir(fullfile(dataDir,'*.tif*'));

if isempty(tiffs)
	fprintf('No tiffs found in %s\n',dataDir);
	return
end


ST = struct('x',[],...
		'y',[],...
		'z',[],...
		'thresh',0);


allSections={};

fprintf('Looping through %d sections to find bright pixels\n',length(tiffs))
parfor ii=1:length(tiffs)
	out = repmat(ST,1,length(pixVals));
	T=openTiff(fullfile(dataDir,tiffs(ii).name));

	for kk=1:length(pixVals)
		[y,x]=ind2sub(size(T),find(T>pixVals(kk)));

		out(1,kk).x = x;
		out(1,kk).y = y;
		out(1,kk).z = ii;
		out(1,kk).thresh=pixVals(kk);

	end
	allSections{ii}=out;

end



%We now need to collate the stuff in the cell array into single matrices
fprintf('collating bright pixel data\n')
sparsedataDir='sparsedata';
if ~exist(sparsedataDir,'dir')
	mkdir(sparsedataDir)
end

fnames = {};
parfor p=1:length(pixVals)

	%figure out the size of the final array
	s=0;
	for ii=1:length(allSections)
		s=s+length(allSections{ii}(p).x);
	end


	thresh = allSections{1}(p).thresh;
	fname = sprintf('pixLocs_%d',thresh);

	theseData=ones(s,3,'uint16');
	n=1; %the starting index

	for ii=1:length(allSections)
		tmp = allSections{ii}(p);
		t=uint16([repmat(tmp.z,length(tmp.x),1),tmp.x,tmp.y]);
		theseData(n:n+length(tmp.x)-1,:) = t;
		n=n+length(tmp.x);
	end

	saver(fname,theseData,sparsedataDir)
	fnames{p}=fname;

end


if nargout>0
	varargout{1}=fnames;
end



function saver(fname,pixelLocations,sparsedataDir)
	fname=[fname,'.mat'];
	fprintf('Saving data as %s\n',fname)
	save(fullfile(sparsedataDir,fname),'pixelLocations')
