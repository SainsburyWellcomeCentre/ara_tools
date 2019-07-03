 function varargout=pointsInARA(pointsData, varargin)
% generate a structure listing the brain area associated with each sparse data point
%
%
% function out=pointsInARA(pointsData)
%
%
% Purpose 
% Generate a structure listing the brain area index associated with each sparse data point.
% This is a fairly low-level function called by other analysis functions, but you may
% use it directly if needed. 
%
%
% Inputs
% pointsData - one of: 
%          a) the relative or absolute path to a csv file containing data exported 
%          from a tree .mat file or a MaSIV points .yml file. The only constraint 
%          is that the last three columns of this file should be the x, y, and z
%          locations of the data point. 
%          b) the imported matrix from one of the above points files.
%
% Inputs (optional - param/value pairs)
% 'voxelSize' - The size of the voxel of the ara used. If not provided will
%               guess from the local file names
% 'diagnosticPlot' - false by default. If true, we show the location of the points in the brain.
%                    This is useful your're worried about dataColumns being specified incorrectly,
%                    or if there are concerns about gross misalignment between the atlas and the 
%                    sparse data points. 
%
% Outputs
% out - a structure with the following fields
%       out.ind  - [n-by-1 vector] The index in the atlas with which this point
%                  is associated.
%       pointsFname - [csv file name]
%       out.voxelSize - the voxel size of the atlas
%
%  *no outputs in batch mode: saves .mat files in the same directory as each CSV file* 
%
%
% Examples
% 1. 
% >> aratools.cacheAtlasToWorkSpace(25)
% >> cd XYZ_163
% >> out=pointsInARA('downsampled/sample2ARA/XYZ_163_traced_cells_tree_01.csv')
%
% out = 
%
%         ind: [981x1 double]
% pointsFname: [csv file name]
%       notes: ''
%   voxelSize: [string]
%
%
% 2. 
% >> dat = cscread('/path/to/data.csv');
% >> out=pointsInARA(dat);
%
% 3. 
% Finding the brain area associated with each point using a function from
% https://github.com/SainsburyWellcomeCentre/AllenBrainAPI
% >> out=pointsInARA('downsampled/sample2ARA/XYZ_163_traced_cells_tree_01.csv')
% >> >> structureID2name( unique(out.pointsInARA.rawSparseData.ARAindex))'
%
% ans =
%
%  18x1 cell array
%
%    {'Superior colliculus, motor related, intermediate gray layer'            }
%    {'Superior colliculus, motor related, intermediate white layer'           }
%    {'Superior colliculus, motor related, deep gray layer'                    }
%    {'posteromedial visual area, layer 2/3'                                   }
%    {'ventricular systems'                                                    }
%    {'Midbrain reticular nucleus'                                             }
%    {'Retrosplenial area, dorsal part, layer 6a'                              }
%    etc, etc ...
%
%
% --
% Rob Campbell - Basel 2105
% Rob Campbell - SWC 2019 -- gut function of batch stuff and simplify **BREAKS OLD BEHAVIOR**
%
%
% See also: brainAreaBarChart, pointsByAreaPlot, aratools.sparse.assignToARA


CACHED_ATLAS = aratools.atlascacher.getCachedAtlas;

if isempty(CACHED_ATLAS)
    fprintf('Please cache an atlas using aratools.cacheAtlasToWorkSpace\n')
    return
end


if nargin<1
    fprintf('Function requires one input argumement. see help %s\n',mfilename)
    return
end

 % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
%Parse optional arguments
params = inputParser;

params.CaseSensitive=false;
params.addParamValue('voxelSize', [], @(x) isnumeric(x));
params.addParamValue('diagnosticPlot', false, @(x) islogical(x) | x==1 | x==0);
params.parse(varargin{:});

voxelSize = params.Results.voxelSize;
diagnosticPlot = params.Results.diagnosticPlot;
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 




%Remove the atlas data from the atlas data structure and store the remanining meta-data
%alongside the points data. 
atlasVolume=CACHED_ATLAS.atlasVolume;
CACHED_ATLAS.atlasVolume=[];

if ~ischar(pointsData)
    pointsFname='';
else
    pointsFname=pointsData;
    pointsData=csvread(pointsFname);
end

%Start building the output structure
out.pointsFname=pointsFname;  %File name of the downsampled (and likely transformed) sparse points file
out.pointsDataArg=[];  %This is the argument with which we we called pointsInARA. If we did batchmode, we'll know what was done with this arg


if isempty(voxelSize)
    voxelSize=getSampleVoxelSize;
end
out.voxelSize = voxelSize;
out.atlas=CACHED_ATLAS; %The atlas data minus the actual atlas volume
out.rawSparseData=pointsData; %The raw points data from the original points file


%The order of the columns used to determine the brain area location. 
%Must be ordered in the dims of the MHD
%The last three columns should be the point location data. 
%With a tree file, there will be 5 columns as the first two are the node ID and parent node ID. 
%With a MaSIV points file, the first column will be the cell series ID
out.rawSparseDataColumns=bsxfun(@plus, size(pointsData,2)-3,[3,2,1]);
out.notes='';


%This is a map that contains the different data formats
out.pointsInARA.rawSparseData = aratools.sparse.assignToARA(out,pointsData, ...
    'diagnosticPlot', diagnosticPlot);


if nargout>0
    varargout{1}=out;
end