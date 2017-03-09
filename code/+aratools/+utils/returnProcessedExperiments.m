function [dirs,details,unprocessed] = returnProcessedExperiments(subdir)
% Call from root dir of an anatomy experiment project. Returns names of directories containing processed data by ARAtools
%
% function dirs =  aratools.utils.returnProcessedExperiments(subdir)
%
% 
% Purpose
% Called from the experiment root directory. Looks for analysis_log.csv and finds the name 
% of the animals listed within it. Finds the directories that contain these brains and returns 
% their paths. This function is used by others functions to allow for batch processing. 
%
% analysis_log.csv should be aranged as follows:
% sample name, contains analysed sparse data [0 or 1], notes [optional]
% e.g.
% YH102|1|needs flipping
% YH121|1|ds cell missing
% YH124|0| 
% YH129|1|second cell is not tracebable fully
%
% There should be no header line. Just data. 
%
%
% 
% Inputs
% subdir - [string, optional] If present, looks for the presence of this 
%          subdirectory within the animal directory. Only returns sample
%          directories that contain this sub-directory.
%
% Outputs
% dirs - a cell array of strings defining paths to directories conataining traced cells
% details - a structure containing other fields of interest: which cells have completed trees
%           and the notes string. 
% unprocessed - a list of animal directory names containing unprocessed data
%
% Example
% 1. 
% >> cd ~/sonastv/Data/Mrsic-Flogel/hanyu
% >> A=aratools.utils.returnProcessedExperiments;
% >> A'
% ans = 
%
%    'YH102_150615'
%    'YH121_150707'
%    'YH124_150713'
%    'YH129_150803'
%	 ...
%
% 2. 
% >> S=settings_handler('settingsFiles_ARAtools.yml');
% >> overlaysDir = fullfile(S.downSampledDir, S.sample2araDir, 'overlays');
% >> cd ~/sonastv/Data/Mrsic-Flogel/hanyu
% >> A=aratools.utils.returnProcessedExperiments(overlaysDir);
% >> A'
% ans = 
%
%    'YH102_150615/downsampled/sample2ARA/overlays'
%    'YH121_150707/downsampled/sample2ARA/overlays'
%    'YH124_150713/downsampled/sample2ARA/overlays'
%    'YH129_150803/downsampled/sample2ARA/overlays'
%	 ...
%
% 
% Also see:
% makeSummaryHTML
%
%
% Rob Campbell - Basel 2105


if nargin<1
	subdir=[];
end

fname='./analysis_log.csv'; 
if ~exist(fname)
	error('Can not find %s. Are you in the correct directory?',fname)
end

fid = fopen(fname);
csv = textscan(fid,'%s%d%s\n','Delimiter','|');
fclose(fid);

animal=csv{1};
processed=csv{2};
notes=csv{3};	


allDirs=dir('./*'); %all files in current directory
allDirs={allDirs.name};

dirs = {};
n=1;
unprocessed = {};
for ii=1:length(animal)

	dirInd = strmatch(animal{ii},allDirs);
	if isempty(dirInd)
		fprintf('Can not find directory for animal %s\n',animal{ii});
		continue
	end
	dirName=allDirs{dirInd};

	if ~isempty(subdir)
		thisDirName = fullfile(dirName,subdir) ;
	else
		thisDirName = dirName;
	end


	if ~processed(ii)
		unprocessed{length(unprocessed)+1}=thisDirName;
		continue %Skip unprocessed directories
	end

	if ~exist(thisDirName,'dir')
		fprintf('No directory %s\n',thisDirName)
		continue
	end

	%Log the processed data directories
	dirs{n}=thisDirName;


	%Log the other parameters stored in the text file
	details(n).animalID=animal{ii};
    details(n).processed=processed(ii);
	details(n).notes=notes{ii};

	n=n+1;

end

if isempty(dirs)
	fprintf('\n\n ***  %s found no data at all! ***\n\n',mfilename)
end