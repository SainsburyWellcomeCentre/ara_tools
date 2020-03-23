function out = readLogFile(fname,reportToScreen)
    % ARA helper function. Reads the ARAregister log file into a structure
    %
    % function out = aratools.readLogFile(fname, reportToScreen)
    %
    % Purpose
    % Return a structure containing the info in the ARAregister log file
    %
    %
    % Inputs
    % fname - relative or absolute path to an ARAregister log file.
    % reportToScreen - false by default. If true, print to screen the key information 
    %                  from this log file.
    %
    % Outputs
    % out - A structure containing the info from the log file
    %
    %
    % Rob Campbell - SWC 2020
    %
    % See also: ARAregister, aratools.tidyRegistrations


    if nargin==0
        help(mfilename)
        out=[];
        return
    end

    if nargin<1
        reportToScreen=false;
    end

    if ~exist(fname,'file')
        fprintf('Unable to find file %s\n',fname);
        out=[];
        return
    end


    out = struct;

    fid=fopen(fname,'r');

    tLine = fgetl(fid);
    addLineToStruct

    loggingLines = ''; % All logging lines will be placed here


    while ischar(tLine)
        tLine = fgetl(fid);


        if isempty(strfind(tLine,' LOGGING ')) && isempty(strfind(tLine,' INFO '))
            % If this is a regular <KEY>: <VALUE> line we add it to the structure
            addLineToStruct
        elseif isempty(strfind(tLine,' LOGGING '))
            % If this is a logging line we append to the string containing these
            loggingLines = [loggingLines,sprintf('%s\n',tLine)];
        end
    end

    % Add all logging lines to structure
    out.loggingLines = loggingLines;
    fclose(fid);


    % Do a little post-processing to make things easier for down-stream functions.
    if isfield(out,'Sample_volume_file')
        tok=regexp(out.Sample_volume_file,'.*_ch(\d+)_(.*)\.\w+','Tokens');
        out.channelID = str2num(tok{1}{1});
        out.channelName = tok{1}{2};
    end

    % Optionally print info to screen
    if reportToScreen
        fprintf(' Date conducted: %s\n', out.Analysis_carried_out)
        fprintf(' Channel #%d (%s)\n', out.channelID, out.channelName)
        fprintf(' Voxel size: %s\n', out.Voxel_size)
        if isempty(out.Filtering_of_sample_volume)
            fprintf(' Filtering of sample volume: none\n')
        else
            fprintf(' Filtering of sample volume: %s\n', out.Filtering_of_sample_volume)
        end

        fprintf(' Registrations conducted:\n')
        if ~isempty(strfind(out.loggingLines,'ARAregister - Finished registration of ARA to sample'))
            fprintf('   ARA to sample\n')
        end
        if ~isempty(strfind(out.loggingLines,'ARAregister - Finished registration of sample to ARA'))
            fprintf('   sample to ARA\n')
        end
        if ~isempty(strfind(out.loggingLines,'ARAregister - Finished inversion of sample to ARA'))
            fprintf('   Inversion of sample to ARA\n')
        end
    end



    % Internal nested functions follow
    function addLineToStruct
        if isempty(tLine) || ~ischar(tLine)
            return
        end
        tok=regexp(tLine,'^(.*?): *(.*)$','tokens');
        tKey = strrep(tok{1}{1},' ','_');
        tVal = tok{1}{2};

        out.(tKey) = tVal;
    end %addLineToStruct

end