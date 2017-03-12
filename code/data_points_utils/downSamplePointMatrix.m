function data=downSamplePointMatrix(data,downSampleAmount)
% downsample z,x,y matrix to Allen Reference Atlas (ARA) voxel size
%
% function downSampled=downSamplePointMatrix(data,downSampleAmount)
%
% Purpose
% Accepts a matrix of n-by-3 matrix of voxels coordinates (columns are z,x,y)
% and downsamples this by downSampleAmount vector of length 2: [xy,z] or
% by the degree of downsampling of the downsampled MHD file in the 
% experiment ./downsampled directory. Cell locations and trees exported
% by MaSIV will already have been downsampled (see downsampleVolumeAndData)
% but if other data, e.g. locations of bright pixels, have been automatically
% extracted then we will need to downsample them. 
%
%
% Inputs
% data - n-by-3 matrix of voxel coordinates.
% downSampleAmount - [optional] vector of length 2 that defines degree of 
%                    downsampling in xy and z. So to downsample 20 times
%                    in xy and 5 times in z you woul do [20,5]. If downSampleAmount
%                     is empty or missing then we attempt to figure out how much
%                    to downsample based on the contents of the downsample
%                    directory. 
%
% Outputs
% downSampled - The downsampledVersion of the input data array. Values are rounded
%               Zeros are removed. Returns locations as uint16. 
%
%
% Rob Campbell - Basel 2015




if nargin<2
    downSampleAmount=[];
end

if isempty(downSampleAmount)
    S=settings_handler('settingsFiles_ARAtools.yml');
    downsampledDir = fullfile(pwd,S.downSampledDir);
    d=dir(fullfile(S.downSampledDir,'ds*_*_*_*.mhd'));
    if length(d)~=1
        error('Failed to find just one down-sampled MHD file in %s\n',S.downSampledDir)
    end

    [~,fName]=fileparts(d.name);
    downSampledTextFile=fullfile(S.downSampledDir,[fName,'.txt']);

    if ~exist(downSampledTextFile,'file')
        fprintf('%s can not find file %s. Aborting.\n',mfilename,downSampledTextFile)
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
else
    fprintf('Please specify how much to downsample\n')
    return
end


fprintf('Down-sampling by %0.3f in x/y and %0.3f in z\n',downSample)


data(:,1)=data(:,1)/downSample(2);
data(:,2:3)=data(:,2:3)/downSample(1);

data=uint16(round(data));


%First check if we will run into indexing errors and correct
f=find(data==0);
if ~isempty(f)

    [I,J]=ind2sub(size(data),f);
    I=unique(I);
    fprintf('Removing %d rows which have index values of zero\n',length(I))
    data(I,:)=[];

end