sCodeFolder = '/mnt/data/blota/Matlab';

addpath(genpath(fullfile(sCodeFolder, 'AllenBrainAPI')))
addpath(genpath(fullfile(sCodeFolder, 'settings_handler')))
addpath(genpath(fullfile(sCodeFolder, 'jsonlab-1.5')))
addpath(genpath(fullfile(sCodeFolder, 'yamlmatlab')))
addpath(genpath(fullfile(sCodeFolder, 'StitchIt')))
addpath(genpath(fullfile(sCodeFolder, 'matlab_elastix')))
addpath(genpath(fullfile(sCodeFolder, 'matlab-tree')))
addpath(genpath(fullfile(sCodeFolder, 'ara_tools', 'code')))


if false
    % example code
    rootPath = '/home/blota/tvtoucan/Mrsic-Flogel/rothmo/';
    done = {'AMo_09', 'AMo_13', 'AMo_15',};
    mouseNames = { 'AMo_17', 'MoA_01b', ...
        'MoA_02', 'MoA_07'};
    for iMouse = 1:length(mouseNames)
        mouseName = mouseNames{iMouse};
        fprintf('\n\nDoing %s\n', mouseName)
        cd(fullfile(rootPath, mouseName))
        downsampleVolumeAndData(2,25);
        %  3 steps registration:
        elastix_parms = {'01_ARA_translate.txt',  '02_ARA_rigid.txt' , ...
                    '03_ARA_affine.txt'};
        transPath = '/home/blota/tvtoucan/Mrsic-Flogel/rothmo/elastix_transforms';
        elastix_parms = cellfun(@(x) fullfile(transPath, x), elastix_parms, 'un', 0);
        ARAregister('elastixParams', elastix_parms)
        % For the other just ARA
        % ARAregister()
    end
end
    
    