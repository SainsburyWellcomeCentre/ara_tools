function [data,fnames]=loadDownSampledData
% Uses the downsampled log file to load all downsampled data 
%
% function data=loadDownSampledData    
%
% Purpose
% Returns all downsampled data as a cell array of matrices
% If there is more than one downsampled file (more than one traced cell)
% then the function returns one matrix per file.
%
% Inputs
% none
%
% 
% Outputs
% data - a cell array of arrays of sparse data.
% fnames - the names of each file that contributed to each matrix.
% 
% Rob Campbell - Basel 2015


S=settings_handler('settingsFiles_ARAtools.yml');

logName=fullfile(S.downSampledDir,S.sparseDataLogName);

if ~exist(logName,'file');
    error('Can not find down-sample log file at %s. You may need to re-run downSampleVolumeAndData.m\n', logName)
end



fid = fopen(logName,'r');

tline = fgetl(fid);
fnames={};
data={};
while ischar(tline)

    if length(tline)==0
        tline = fgetl(fid);
        continue
    end

    %Extract the name of the downsampled file
    tok=regexp(tline,'Wrote .*: (.*.csv)','tokens');
    if ~isempty(tok)
        tok=tok{1};
    end

    %Record the file name and load the data from the CSV file
    if length(tok)==1
        fnames{length(fnames)+1} = fullfile(S.downSampledDir,tok{1});
        [~,~,ext] = fileparts(fnames{end});

        if ~strcmpi('.csv',ext)
            error('%s can not load %s, it is not a csv file.\n',mfilename,fnames{end})
        end

        data{length(data)+1} = csvread(fnames{end});
    else
        fprintf('Did not find only one token in line %s of file %s\n',tline,logName)
    end

    tline = fgetl(fid);
end

fclose(fid);

if length(fnames)==0
    error('Found no downsampled files in %d. You may need to re-run downSampleVolumeAndData.m\n', S.downSampledDir)
end