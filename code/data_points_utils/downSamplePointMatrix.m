function data=downSamplePointMatrix(data,downSampleAmount)
% downsample z,x,y matrix to Allen Reference Atlas (ARA) voxel size
%
% function downSampled=downSamplePointMatrix(data,downSampleAmount)
%
% Purpose
% Accepts a matrix of n-by-3 matrix of voxels coordinates (columns are z,x,y)
% and downsamples this by downSampleAmount vector of length 2: [xy,z].
%
% Inputs
% data - n-by-3 matrix of voxel coordinates or a csv file name. If a CSV file,
%        checks that data have only three columns.
% downSampleAmount - Vector of length 2 that defines degree of downsampling in 
%                    xy and z. So to downsample 20 times in xy and 5 times in z 
%                    you woul do [20,5]. 
%
% Outputs
% downSampled - The downsampledVersion of the input data array. Values are rounded
%               Zeros are removed. Returns locations as uint16. 
%
%
% Rob Campbell - Basel 2015

if nargin<2
    help(mfilename)
    return
end

if ischar(data)
    if ~exist(data,'file')
        fprintf('%s finds no data file %s\n', mfilename, data)
        data=[];
        return
    end
    data=csvread(data);
    if size(data,2) ~= 3
        fprintf('%s expected CSV file to contain 3 columns. It contains %d\n', ...
            mfilename, size(data,2))
        data=[];
        return
    end
end


data(:,1)=data(:,1)/downSampleAmount(2);
data(:,2:3)=data(:,2:3)/downSampleAmount(1);

data=uint16(round(data));


%First check if we will run into indexing errors and correct
f=find(data==0);
if ~isempty(f)

    [I,J]=ind2sub(size(data),f);
    I=unique(I);
    fprintf('Removing %d rows which have index values of zero\n',length(I))
    data(I,:)=[];

end