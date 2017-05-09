function downsampleVolumeAndData(channel,targetDims,dataFilename,forceOverWriteVol,verbose)
% Downsample sample brain and derived data to Allen Atlas (ARA)
%
% function downsampleVolumeAndData(channel,targetDims,dataFilename,forceOverWriteVol)
%
% Purpose
% Given a channel number, target image dimensions and the name of the
% derived data file name, downsample the sample brain and the derived 
% data to the Allen Atlas (ARA) size. 
%
%
% INPUTS
% channel - which channel to resize (e.g. 1 or 2). If -1 we don't attempt to downsample image data.
% targetDims - vector of length 2 defining the pixel resolution in [xy,z]
%              to which we will resample. If the user enters a scalar (e.g. 25) then this is expanded to 
%              a vector of length 2 and produces isotropic pixels. 
% dataFileName - the file name of the traced tree or identifed cell locations produced by
%                MaSIV. If missing or empty, the sparse data file is not processed and only
%                the volume is resampled.
% forceOverWriteVol - [optional, 0 by default] If the downsampled volume already exists we 
%                     we only over-write it if this input argument is 1.
%
%
% EXAMPLES
% downsampleVolumeAndData(2, 25, 'XY34_cell_1.mat') %resample data and volume
% downsampleVolumeAndData(-1, 25, 'XY34_cell_1.mat') %resample only sparse data
% downsampleVolumeAndData(2, 25) %resample only volume
% downsampleVolumeAndData(2, 25, 'XY34_cell_1.mat',1) %force volume resample
%
%
% Rob Campbell - Basel 2015


S=settings_handler('settingsFiles_ARAtools.yml');

if nargin==0
  help(mfilename)
  return
end

%Do not resample the volume if the user set channel to -1
if channel==0
  doResampleVolume=-1;
else
  doResampleVolume=1;
end

if nargin<3
  dataFilename=[];
end

if ~isempty(dataFilename) && ~exist(dataFilename,'file')
  fprintf('Could not find %s. Not down sampling data file\n',dataFilename)
  dataFilename=[];
end

if nargin<4
  forceOverWriteVol=0;
end

if nargin<5
  verbose=1;
end

%If necessary, create the down-sampled directory in which we will store stuff
downsampledDir = fullfile(pwd,S.downSampledDir);
if ~exist(downsampledDir,'dir')
  if ~mkdir(downsampledDir)
    error('Failed to make downsampled directory')
  else
    fprintf('Created %s\n',downsampledDir)    
  end
  
else
  d=dir(fullfile(downsampledDir,'ds*_*_*_*.mhd'));
  if ~isempty(d)
    if length(d)>1
      fprintf('There are multiple downsampled files. You should sort this out! Quitting\n')
      return
    end

    [~,volFname] = fileparts(d.name);
    if verbose
      fprintf('Found existing downsampled file %s\n',d.name)
    end
    if forceOverWriteVol==0
      if verbose
        fprintf('Not over-writing volume file. See help %s if you want to do this.\n',mfilename)
      end
      doResampleVolume=-1;
    else
      fprintf('Over-writing resampled volume file\n')
    end
  end
end


%Resample the volume data
if doResampleVolume==1
  [~,volFname]=resampleVolume(channel,targetDims,S.volFormat);
end


logFileName = S.dsVolLogName;
fid=fopen(fullfile(S.downSampledDir,logFileName),'w');
fprintf(fid,'volFname: %s\n',volFname);

%Move the resampled volume to the settings directory
if doResampleVolume==1
  if ~movefile([volFname,'.*'],S.downSampledDir)
    fclose(fid);
    error('failed to move %s.* to directory %s',volFname,S.downSampledDir)
  end
end
fclose(fid);



%Resample the sparse data
if isempty(dataFilename)
  fprintf('Not creating down-sampled sparse data file .\n')
  return
end

logFileName = S.sparseDataLogName;
fid=fopen(fullfile(S.downSampledDir,logFileName),'w');

%downsample data using exportSparseMaSIVData, which gets the downsampling factor
%from the downsampled log file. e.g. if you downsampled MHD file is called
%XY102_25_25_01.mhd then the downsampled log file will be called XY102_25_25_01.txt
logging = exportSparseMaSIVData(dataFilename, fullfile(S.downSampledDir,[volFname,'.txt']));

if ~isstruct(logging) && logging<0
  return
end

%loop through logging and copy to downsampled directory
for ii=length(logging):-1:1
  if isempty(logging(ii).fname)
    logging(ii)=[];
    continue
  end
  movefile(logging(ii).fname, fullfile(S.downSampledDir,logging(ii).fname) )
  msg = sprintf('Wrote "%s" data to: %s\n', logging(ii).type, logging(ii).fname);
  fprintf(fid,msg);
end
save(fullfile(S.downSampledDir,S.sparseDataMatLogFname),'logging')

fprintf('Downsampling finished. Wrote log to %s\n', logFileName)
fclose(fid);


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