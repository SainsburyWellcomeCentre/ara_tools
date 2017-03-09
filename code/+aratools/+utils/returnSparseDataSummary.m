function [summary,byAnimal,byCell,unprocessed] = returnSparseDataSummary
% Call from root dir of an anatomy experiment project. Returns structure containing traced cell details
%
% function [summary,byAnimal,byCell,unprocessed] = returnSparseDataSummary
%
%
% Purpose
% Builds a structure that serves as a simple database of traced cells. It does this
% using the details.ini files that are present in the raw traced cell directory. 
%
%
% Inputs
% none
%
%
% Outputs
% summary - a vector of structures containing the database
% byAnimal - the same data as "summary" but a single structure with fields named by animal IDs
% byCell - the same data as "summary" but a single structure with fields named by cell IDs
% unprocessed - the list of unprocessed directories from aratools.utils.returnProcessedExperiments
%
%
% Example
% >> s=returnSparseDataSummary;
% >> s(10)
%
% ans = 
%
%            animal: 'YH140'
%   sparseDataType: 'traced cells'
%             notes: 'two cells. small amount of local axon left untraced; as well as a few small fragments in target areas that don't appear to connect to anything'
%            traces: [1x1 struct]
%
% >> s(10).traces
%
% ans = 
%
%                 cellID: 'YH140-01'
%        localIncomplete: 1
%    excludeFromAnalysis: 0
%             forceNotV1: 0
%          isBackLabeled: 0
%                 flipDV: 0
%
%
%
% Rob Campbell - Basel 2016


[dirs,details,unprocessed] = aratools.utils.returnProcessedExperiments;


S=settings_handler('settingsFiles_ARAtools.yml');
extractedDataDir = S.extractedDataDir;

detailsFname = 'details.yml';


n=1; %counter for summary (output structure)

for ii=1:length(dirs)
    dataDir = fullfile(dirs{ii},extractedDataDir);

    if ~exist(dataDir,'dir')
        fprintf('No directory %s found for sample ID. Skipping.\n', dataDir,details.animalID{ii})
        continue
    end

    detailsPath = fullfile(dataDir,detailsFname);
    if ~exist(detailsPath,'file')
        fprintf('No %s file found in %s. Skipping.\n', detailsFname, dataDir)
        continue
    end

    %load the YML
    Y=yaml.ReadYaml(detailsPath);

    Y = validateData(Y,details(ii),detailsPath); %Add missing fields and process the structure into a standard form
    Y.dataDir = dirs{ii};
    Y.processed = details(ii).processed;
    Y.animNotes = details(ii).notes;

    if ~isempty(Y)
        summary(n)=Y;
        n=n+1;
    end

end

%re-arrange summary so it's indexed by animal's name
for ii=1:length(summary)
    byAnimal.(summary(ii).animal) = summary(ii);
end


%re-arrange summary so it's indexed by cellID name
for ii=1:length(summary)
    for kk=1:length(summary(ii).traces)


        cellID = summary(ii).traces(kk).cellID;
        cellID = strrep(cellID,'-','_');
        byCell.(cellID) = summary(ii).traces(kk);
        f=fields(summary(ii));

        for jj=1:length(f)
            thisField = f{jj};
            if strcmp('traces',thisField)
                continue
            end
            byCell.(cellID).(thisField) = summary(ii).(thisField);
        end

    end
end




function out = validateData(Y,details,detailsFname)
    %Add missing fields and process the structure into a standard form

    requriedFields = {'animal','sparseDataType'};

    for ii = 1:length(requriedFields)
        if ~isfield(Y,requriedFields{ii})
            fprintf('No field %s in sample %s. Please check %s. SKIPPING\n',...
             requriedFields{ii},details,detailsFname)
            out=[];
            return
        end
    end

    if ~strcmp(Y.animal,details.animalID)
        fprintf('File %s lists animal ID as %s but expected %s. Please check. SKIPPING\n',...
         detailsFname, Y.animal, details.animalID)
        out=[];
        return
    end


    %Add optional fields that may be missing
    optFields = {'notes'};
    for ii = 1:length(optFields)
        if ~isfield(Y,optFields{ii})
            Y.(optFields{ii})='';
        end
    end

    %Now we build the output structure (this ensures we have only these fields and we have them in a consistent order)
    allFields = [requriedFields, optFields];
    for ii=1:length(allFields)
        out.(allFields{ii}) = Y.(allFields{ii});
    end


    %Finally, we perform any operations specific to this data type
    switch lower(Y.sparseDataType)
    case 'traced cells'
        out=validateTracedCells(Y,out); %validate traced cell data and add to structure
    otherwise
        fprintf('File %s defines its data type as "%s". No processing operation known for this. SKIPPING\n',...
         detailsFname, Y.sparseDataType)
        out=[];
        return 
    end





function out = validateTracedCells(Y,out)
    f=fields(Y);
    ind=strmatch('cell',f);

    if isempty(ind)
        return
    end


    out.traces=struct;
    for ii=1:length(ind)
        thisField=(f{ind(ii)});
        tmp = Y.(thisField);

        %set defaults
        if ~isfield(tmp,'excludeFromAnalysis')
            tmp.excludeFromAnalysis=0;
        end
        if ~isfield(tmp,'localIncomplete')
            tmp.localIncomplete=0;
        end
        if ~isfield(tmp,'forceNotV1')
            tmp.forceNotV1=0;
        end
        if ~isfield(tmp,'isBackLabeled')
            tmp.isBackLabeled = 0;
        end
        if ~isfield(tmp,'flipDV')
            tmp.flipDV=0;
        end

        %get the cell number within this sample
        tok=regexp(thisField,'cell *(\d+)','tokens');
        cellNum = str2num(tok{1}{1});
        out.traces(cellNum).cellNum = cellNum;

        %Create a unique cell ID
        out.traces(cellNum).cellID = sprintf('%s_%02d', out.animal,cellNum);

        tmpFields=fields(tmp);
        for kk=1:length(tmpFields)
            out.traces(cellNum).(tmpFields{kk}) = tmp.(tmpFields{kk});
        end


    end
