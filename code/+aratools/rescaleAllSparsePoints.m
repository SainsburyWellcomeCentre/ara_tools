function rescaleAllSparsePoints()
% Downsample sparse point data to ARA voxel size
%
% function rescaleAllSparsePoints()
%
% Purpose
% Loop through all sparse data in the "sparsedata" directory and rescale it
% to the ARA voxel size. Save rescaled versions in the downsampled data directory.
%
%
%
%
% Rob Campbell - SWC - June, 2019
%
% NOTE: also see downsampleVolumeAndData, which handles MaSIV data trees

% or
% by the degree of downsampling of the downsampled MHD file in the 
% experiment ./downsampled directory. Cell locations and trees exported
% by MaSIV will already have been downsampled (see downsampleVolumeAndData)
% but if other data, e.g. locations of bright pixels, have been automatically
% extracted then we will need to downsample them. 
%



S=settings_handler('settingsFiles_ARAtools.yml');

verbose=true;


downsampledDir = aratools.getDownSampledDir;
if isempty(downsampledDir)
    return
end

dsFiles = aratools.getDownSampledFile;

if isempty(dsFiles)
    return
end

% The downsampled text file contains information on how much the image
% stacks in this downsample directory were downsampled
[~,fName]=fileparts(dsFiles{1});
downSampledTextFile=fullfile(downsampledDir,[fName,'.txt']);

%Attempt to extract downsampled data from the text file
downSample = getDownSampleAmountFromFile(downSampledTextFile);


fprintf('Down-sampling by %0.3f in x/y and %0.3f in z\n',downSample)


%Resample the sparse data


logFileName = S.sparseDataLogName;
fid=fopen(fullfile(downsampledDir,logFileName),'w');

if ~exist('sparsepoints','dir')
    fprintf('%s finds no sparsepoints directory\n',mfilename)
    return
end

spFiles = dir(fullfile('sparsepoints', '*.csv'));

if length(spFiles)==0
    fprintf('%s finds no sparse points in directory "sparsepoints"\n',...
        mfilename)
end

for ii=1:length(spFiles)
    tFname = fullfile('sparsepoints',spFiles(ii).name);
    data = downSamplePointMatrix(tFname,downSample);
    csvwrite(fullfile(downsampledDir,spFiles(ii).name),data)
    msg = sprintf('Wrote data to: %s\n', tFname);
    fprintf(fid,msg);
end


fprintf('Downsampling finished. Wrote log to %s\n', logFileName)
fclose(fid);



return
%Report lasagna commands to view data to screen
[~,~,ext]=fileparts(dataFilename);
if strcmp(ext,'.yml')
  flag='S';
elseif strcmp(ext,'.csv')
  flag='T';
else
  return
end

fprintf('Can view downsampled data in Lasagna with these commands:\n')
cmd = sprintf('lasagna -im %s -%s ', fullfile(S.downSampledDir,volFname),flag);
for ii=1:length(logging)
  fprintf('%s%s\n',cmd,fullfile(S.downSampledDir,logging(ii).fname))
end




function downSampleAmount = getDownSampleAmountFromFile(fname)
    % Read downsample text file and extract how much it has been downsampled by


    if ~exist(fname,'file')
        fprintf('Can not find file %s\n',fname)
        return
    end

    fid = fopen(fname);
    tline = fgetl(fid);
    downSampleAmount = [nan,nan];

    while ischar(tline)

        if strfind(tline,'x/y: ')
            downSampleAmount(1) = str2num(tline(5:end));
        end

        if strfind(tline,'z: ')
            downSampleAmount(2) = str2num(tline(3:end));
        end

        if strcmpi('Loading and ',tline)
            break
        end
        tline = fgetl(fid);
    end
    fclose(fid);
