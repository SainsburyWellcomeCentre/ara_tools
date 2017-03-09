function flipDownSampledVolumeAndData(dim,doNotFlipVolume,doNotFlipData)
% flip or rotate downsampled volume and data so they are in the same orientation as the Allen Reference Atlas (ARA)
%
% function flipDownSampledVolumeAndData(dim,doNotFlipVolume,doNotFlipData)
%
% Purpose
% Some samples may have been acquired in a different orientation and then annotated in this 
% different orientation. We need to flip/rotate both the samples and the annotations so 
% that they are in the same orientation as the ARA (or as each other, in the event that
% you aren't working with a reference atlas at all). The workflow is therefore to annotate 
% the sample in the orientation it was in originally. Then downsample the volume and 
% annotations (sparsedata). Then flip both the annotations and the volume, once they have
% been generated. 
% 
% The MHD file name is found automatically using getDownSampledMHDFile
%
% INPUTS
% dim - Which dimensions to flip, rotate, or swap and in what order to do these operations.
%       dim is a cell array of 1-by-3 vectors. The axis order of each vector is rows, 
%       columns, z planes. There are three forms that each vector can take:
%       a) flipping : a 1 means flip that axis, 0 means don't flip. 
%       b) rotation : 90 means rotate by 90 degrees clockwise, 180 means 
%          rotate by 180 degrees and 270 means rotate by 270 degrees clockwise. Vectors 
%          are processed in order.
%     	c) swapping axes: if two axes are tagged by -1 they are swapped. The third value 
%  		   must be zero.
% doNotFlipVolume - [optional, 0 by default]. If 1 we do not flip the volume.
% doNotFlipData - [optional, 0 by default]. If 1 we do not flip the sparse data.
%     
%
% Examples of first input argument:
% 1. flip rows then rotate rows by 90 degrees:
% dim = {[1,0,0]; [90,0,0]};
%
% 2. flip rows and then rotate columns by 90 degrees:
% dim = {[1,0,0], [0,90,0]};
% dim = {[1,90,0]}; 
% dim = [1,90,0]; 
%
% 3. swap dimension 1 and 2 then flip dimension 1
% dim = {[-1,-1,0], [1,0,0]};
%
%
% Usage example:
% cd /path/to/exp/RootDir
% flipDownSampledVolumeAndData([1,0,0],1) %flip only sparse data
%
%
%
% Rob Campbell - Basel 2015

if nargin==0
	help(mfilename)
	return
end

if nargin<2 | isempty(doNotFlipVolume)
	doNotFlipVolume=0;
end

if nargin<3 | isempty(doNotFlipData)
	doNotFlipData=0;
end


if ~iscell(dim)
	dim = {dim};
end

%Error check
for ii=1:length(dim)
	tmp=dim{ii};

	f=find(tmp==-1);
	if length(f)==1 | length(f)==3
		error('only two -1 per vector are allowed')
	elseif length(f)==2
		if length(find(tmp==0)) ~= 1
			error('third number of a swap axis vector must be zero')
		end
	end

end


mhdName=getDownSampledMHDFile;
if isempty(mhdName)
	return
end

S=settings_handler('settingsFiles_ARAtools.yml');

mhdName=fullfile(S.downSampledDir,mhdName);
mhdVol=mhd_read(mhdName);
dimString = repmat('%d ',1,ndims(mhdVol));
fprintf(['Loaded MHD volume with dimensions ',dimString,'\n'], size(mhdVol))

%load sparse data
[data,fnames]=loadDownSampledData;

%re-arrange the data columns from z,x,y to x,y,z (this makes it easier to write the rest of the code
%because now the volume dimensions and matrix columns are in the same order). 

initialDataDims=cell(size(data)); %store the size of the data arrays here, so we can generate an error if they change
for ii=1:length(data)
	%The +(size(data,2)-3) handles the fact that tree data have 5 columns 
	%with voxel position in cols 3 to 5 but cell location data have just 
	%the three voxel colummns.
	initialDataDims{ii} = size(data{ii});
	initCols = size(data{ii},2)-3;
	data{ii}(:,1+initCols:end) = data{ii}(:,[3,2,1]+initCols);
end

fprintf('Loaded %d sparse data set',length(data))
if length(data)==1
	fprintf(':\n')
else
	fprintf('s:\n')
end

for ii=1:length(data)
	initCols = size(data{ii},2)-3;
	fprintf('%s has points with a maximum range of x: %0.2f, y: %0.2f, z: %0.2f\n', fnames{ii}, max(data{ii}(:,1+initCols:end)) )
end

fprintf('\n')


%let's do the reshuffle!
for ii=1:length(dim)
	tmp=dim{ii};
	if length(tmp)>ndims(mhdVol)
		error('data manipulation vector has a length of %d but the MHD volume has a length of only %d',...
			length(tmp),ndims(mhdVol))
	end

	if any(tmp==-1)
		%swap volume axes
		f=find(tmp==-1);
		dimOrder=1:ndims(mhdVol);
		dimOrder(f)=fliplr(f);
		fprintf('Doing volume permutation between axes %d and %d\n',dimOrder(f))
		mhdVol = permute(mhdVol,dimOrder);

		%swap sparse data
		for d=1:length(data)
			fprintf('Swapping columns %d and %d from file %s\n',dimOrder(f),fnames{d})
			data{d} = data{d}(:,dimOrder);
		end
		continue
	end


	for jj=1:length(tmp)
		t=tmp(jj);
		if t==0
			continue
		end

		%These are the axes along which we need to work
		volDim = jj;

		if t==1
			%flip this volume axis
			fprintf('Flipping dimension %d in volume\n',jj)
			mhdVol = flipdim(mhdVol,jj);

			%flip this sparse data axis
			for d=1:length(data)
				fprintf('Flipping data in column %d in file %s\n',jj,fnames{d})
				initCols = size(data{d},2)-3;
				data{d}(:,jj+initCols) = flipSparsePoints(data{d}(:,jj+initCols),size(mhdVol,jj));
			end


		elseif t==0
			continue
		elseif t>1
			fprintf('Can not handle rotation yet. Hope I never need to.')
			continue
		end

	end

end

%Put the data columns back to z,x,y from x,y,z
for ii=1:length(data)
	initCols = size(data{ii},2)-3;
	data{ii}(:,1+initCols:end) = data{ii}(:,[3,2,1]+initCols);
end


%Check that no sparse data have changed size
for ii=1:length(data)
	if 	~all(size(data{ii}) ==	initialDataDims{ii})
		error('\n * Data dimensions have changed for file %s!\n * Not saving. Not changing volume on disk. Quitting.',fnames{ii});
	end
end

fprintf('\n')


%Overwrite the sparse data
if ~doNotFlipData
	for ii=1:length(data)
		fprintf('Replacing %s\n',fnames{ii})
		csvwrite(fnames{ii},data{ii})
	end
end

%overwrite the image volume
if ~doNotFlipVolume
	mhd_write(mhdVol,mhdName)
	fprintf('Replacing %s\n',mhdName)
end

%show lasagna commands to screen 
fnames = cellfun(@(x) fullfile(pwd,x)  ,fnames, 'UniformOutput',false);
fprintf('\nTo confirm the flipping of the tree worked you may run lasagna with:\n\n')
fprintf('lasagna -im %s %s -T %s\n\n',getARAfnames, fullfile(pwd,mhdName), fnames{:})


%Make a log in the directory of what the downsampling was
downsampledDir = fileparts(fnames{1});
logFname = fullfile(downsampledDir,'flipDimsArray');
fprintf('Saving variable dim to %s for logging purposes\n', logFname)
save(logFname,'dim')


function data = flipSparsePoints(data,dimLength)
% Flip absolute values of data points in column vector data
%
% Purpose
% You have sparse points in a space and you want to flip that space. 
% For matrices you can use MATLAB's matrix-flipping commands. This
% function flips sparse points so they remain in register with the
% flipped volume matrix.
%
% Inputs
% data - vector of voxel positions
% dimLength - the maximum value of the matrix along this dimension
%
% Outputs
% data - the flipped data

f=find(data>dimLength);
if f>0
	fprintf('\n * Found %d data values in vector that are larger than %d, which is supposed to be the dimension''s largest value\n',length(f),dimLength)
	d=data(f);
	fprintf(' * Values range from %0.2f to %0.2f\n\n',min(d),max(d))
	error('')
end

data = abs(data-dimLength)+1; %perform the flip

f=find(data<0.5);
if f>0
	fprintf('Warning, found %d voxel coordinates that will round down to zero\n', length(f))
end

