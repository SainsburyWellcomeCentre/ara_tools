function out = readLogFile(fname)
    % ARA helper function. Reads the ARAregister log file into a structure
    %
    % function out = aratools.readLogFile
    %
    % Purpose
    % Return a structure containing the info in the ARAregister log file
    %
    %
    % Inputs
    % fname - relative or absolute path to an ARAregister log file.
    %
    %
    % Outputs
    % out - A structure containing the info from the log file
    %
    %
    % Rob Campbell - SWC 2020
    %
    % See also: ARAregister


    if nargin==0
        help(mfilename)
        out=[];
        return
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