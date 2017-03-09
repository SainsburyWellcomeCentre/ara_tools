function varargout = exportSparseMaSIVData(dataFname,downSampledTextFile,verbose)
% Export cell locations or neurite trees from goggleViewer to a text file
%
% logging = exportSparseMaSIVData(dataFname,downSampledTextFile,verbose)
%
% Purpose
% Export cell locations or neurite trees from goggleViewer to a text file.
% Optionally, data are down-sampled for projection on Allen Space. Likely
% you will always want to do this, but nonetheless this remains optional. 
%
%
% Inputs
% dataFname - The relative or absolute path to the file that contains
%           the sparse point data (either a neurite tree file or a 
%           cell location file.
% downSampledTextFile - [optional, empty by default] The relative or 
%			absolute path to the the text file produced by resampleVolume. 
%			exportSparseMaSIVData extracts the x/y and z downsample factors from 
%			this file. Alternatively, should this fail, this argument can
%           also be a vector of length 2 (e.g. [25,2.5]).
% verbose - [optional, 1 by default] if 0 supresses all text output to terminal
%
%
% Outputs
% logging - A structure containing the nature (e.g. points or trees) of the 
%		 exported files and and where they are located. 
%
%
% Examples
% exportSparseMaSIVData('traced_cell_XY123.mat','ds_XY123.txt') %traced neurons
% exportSparseMaSIVData('clicked_cells_XY123.yml','ds_XY123.txt') %cell locations
% exportSparseMaSIVData('clicked_cells_XY123.yml',[25,5]) 
%
%
% Note:
% the downsampled log file is produced by resampleVolume
%
% Rob Campbell - Basel 2015
%
% Also see:
% resampleVolume, downsampleVolumeAndData

if nargin==0
	help(mfilename)
	return
end

if nargin<2
	downSampledTextFile = [];
end

if nargin<3
	verbose=1;
end

if ~exist(dataFname,'file')
	if verbose
		fprintf('FAILED: %s can not find file %s. Aborting.\n',mfilename,dataFname)
	end
	if nargout>0
		varargout{1}=-1;
	end
	return
end


if ~isempty(downSampledTextFile) | isstr(downSampledTextFile)
	if ~exist(downSampledTextFile,'file')
		if verbose
			fprintf('FAILED: %s can not find file %s. Aborting.\n',mfilename,downSampledTextFile)
		end
		if nargout>0
			varargout{1}=-2;
		end
		return
	end

	%Attempt to extract downsampled data from the text file
	fid = fopen(downSampledTextFile);
	tline = fgetl(fid);
	downSample = [nan,nan];
	while ischar(tline)

		if strfind(tline,'x/y: ')
			downSample(1) = str2num(tline(5:end));
		end

		if strfind(tline,'z: ')
			downSample(2) = str2num(tline(3:end));
		end

		if strcmpi('Loading and ',tline)
			break
		end
		tline = fgetl(fid);
	end
	fclose(fid);
elseif isnumeric(downSampledTextFile)
	downSample = downSampledTextFile;	
end


%Check that all this makes sense. 
if any(isnan(downSample))
	if verbose
		fprintf('FAILED: %s failed to find downsample data in %s. Please supply the values manually.\n',mfilename,downSampledTextFile)
	end
	if nargout>0
		varargout{1}=-3;
	end
	return
else
	if verbose
		fprintf('Dowsampling points by a factor of %0.3f in xy and %0.3f in z.\n',downSample)
	end
end



%We'll assume that a .mat file is a tree structure of neuriteTracerNodes and a .yml is an exported set of MaSIV points
[~,fname,ext] = fileparts(dataFname);

if strcmpi(ext,'.yml')

	if verbose
		fprintf('Reading YAML...\n')
	end
	data = readSimpleYAML(dataFname);
	logging = aratools.utils.exportMaSIVPoints(data,[fname,'.csv'],downSample,1);

elseif strcmpi(ext,'.mat')
 	if ~exist('neuriteTracerNode') 
 		fprintf(['ERROR: you don not have the neuriteTracerNode class in your path.\n',...
 			'This part of the neuriteTracer plugin from MaSIV. It should be added to your path\n'])
 		return
 	end

	M=load(dataFname);
	f=fields(M);
	if length(f)>1
		error('More than one variable stored in %s', dataFname)
	end
	data = M.(f{1});

	for ii=1:length(data)
		if isa(data{ii},'tree')
			outFname = sprintf('%s_tree_%02d.csv',fname,ii);
			aratools.utils.exportNeuriteTree(data{ii},outFname,downSample)
			logging(ii).fname = outFname;
			logging(ii).downsample=downSample;
			logging(ii).type = 'tree';
		end
	end

else

	if verbose
		fprintf('%s does not know what to do with file types of type %s. Aborting.\n',mfilename,ext)	
		if nargout>0
			varargout{1}=-4;
		end
		return
	end

end

if nargout>0
	varargout{1} = logging;
end