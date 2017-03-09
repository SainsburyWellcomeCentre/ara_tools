function cacheAtlasToWorkSpace(voxelSize,ARA_SETTINGS)
% Load the Allen Atlas to the workspace
%
% function cacheAtlasToWorkSpace(voxelSize,ARA_SETTINGS)
%
% Purpose
% Various functions in ARA_tools require the Allen Reference Atlas (ARA)
% to be loaded into RAM. Further, we might want to use different versions
% of this Atlas at different times. This function does the following:
% a) Given a voxel size and the toolbox settings, lists all available versions of the Atlas. 
% b) The user selects and loads one.
% c) The atlas is loaded into a structure that is called LOADED_ARA and placed in the 
%    base workspace.
% d) This structure has fields: .voxelSize, .atlasVolume, .fname, .pathToFile
% e) All other functions that need the atlas will look for this variable in the base workspace 
%    and load it. They will then store along with their data the location of the atlas. 
%
%
% Inputs
% voxelSize - 
% If the function is provided with an integer, it assumes this is a voxel size and tries
% to load the atlas. 
%
% If the function is provided with a structure (minus the volume data) from a previous
% atlas attachment then it checks whether this already exists in the base workspace. 
% If not, it tries to reload. If it already exists, it does nothing.
%
% ARA_SETTINGS -
% This is output of settings_handler('settingsFiles_ARAtools.yml');
% It's an optional argument. If provided when this function is called from within a loop
% it saves a lot of time. 
%
%
% Outputs
% None - results saved to base workspace.
%
%
% Rob Campbell - Basel 2016

if nargin<1
  fprintf('Please supply the voxel size of the ARA you wish to cache\n')
  return
end

if nargin<2 || isempty(ARA_SETTINGS)
  ARA_SETTINGS = settings_handler('settingsFiles_ARAtools.yml');
end


atlasFormat='mhd'; %let's just work with this for now
varName='LOADED_ARA';


if isnumeric(voxelSize)
  %Get an atlas file to load based on a voxel size
  LOADED_ARA.voxelSize = voxelSize;
  voxelSize=num2str(voxelSize);

  atlasDir = fullfile(ARA_SETTINGS.araDir, sprintf(ARA_SETTINGS.araSubDirFormat,voxelSize));
  filesInDir=dir(fullfile(atlasDir, ['*atlas*.',atlasFormat]));

  if isempty(filesInDir)
    fprintf('Found no %s files in directory %s\n', ...
      atlasFormat, atlasDir)
    return
  end


  if length(filesInDir)==1
    atlasFileToLoad = filesInDir(1).name;
    fprintf('Found only "%s" in directory %s. Using this atlas. \n', atlasFileToLoad, atlasDir)
  else
    fprintf('\nFound %d atlas files in %s.\nPlease choose one:\n',length(filesInDir),atlasDir)
    for ii=1:length(filesInDir)
      fprintf('%d. %s\n',ii,filesInDir(ii).name)
    end
    a=str2num(input('? ','s'));

    while 1
      if a>0 && a<=length(filesInDir)
        atlasFileToLoad=filesInDir(a).name;
        fprintf('Using %s\n',atlasFileToLoad)
        break
      end
      fprintf(' Please enter a number between %d and %d\n',1,length(filesInDir))
      a=str2num(input('? ','s'));
    end

  end

  LOADED_ARA.fname = atlasFileToLoad;
  LOADED_ARA.pathToFile = atlasDir;

  LOADED_ARA = aratools.atlascacher.loadARAbasedOnStructure(LOADED_ARA);

  fprintf('Placing atlas in variable %s in base workspace\n', varName)
  assignin('base',varName,LOADED_ARA)


elseif isstruct(voxelSize)

  %We enter this if the user has supplied an structure that defines which atlas was previously used
  ARA_TO_LOAD = voxelSize;
  ARA_IN_BASE=aratools.atlascacher.getCachedAtlas;

  %If no atlas is loaded, then we just load one and exit
  if isempty(ARA_IN_BASE)
      LOADED_ARA =  aratools.atlascacher.loadARAbasedOnStructure(ARA_TO_LOAD);
      fprintf('Placing atlas in variable %s in base workspace\n', varName)
      assignin('base',varName,LOADED_ARA)
      return
  end

  if strcmp(ARA_IN_BASE.fname,ARA_TO_LOAD.fname) && strcmp(ARA_IN_BASE.pathToFile, ARA_TO_LOAD.pathToFile)
    % If the cached atlas in the workspace is the same as the one we want to load
    % then we don't proceed
    return
  end

  LOADED_ARA =  aratools.atlascacher.loadARAbasedOnStructure(ARA_TO_LOAD);

  %Produce a clear on-screen warning to indicate that the cached ARA is being replaced
  fprintf('\n\n')
  fprintf(repmat('-',1,70))
  fprintf('\n*** Replacing existing atlas in base workspace ***\n')
  fprintf('\tBase workspace contained: %s\n',ARA_IN_BASE.fname)
  fprintf('\tReplacing this with: %s\n\n',ARA_TO_LOAD.fname)
  fprintf(repmat('-',1,70))
  fprintf('\n\n')

  assignin('base',varName,LOADED_ARA)

else
  fprintf('%s -- Unknown input argument type. Doing nothing\n', mfilename)  
end



