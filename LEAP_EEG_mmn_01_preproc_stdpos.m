% setup

    clear variables
%     lm_addCommonPaths
    ft_defaults
    if isempty(gcp('nocreate')), parpoolnum(16), end
    
% params
    
    lp_freq = 100;

% paths

    path_raw = '/Volumes/scratch/mmntmp/00_raw';
    path_preproc = '/Volumes/scratch/mmntmp/01_preproc_stdpos_100hz';
    path_master = '/Volumes/projects/LEAP/_preproc/in/eeg/LEAP_EEG_master.preproc.xlsx';
                              
    % try to make any paths that may not yet exist
    tryToMakePath(path_preproc)

% load master table of IDs

    tab_master = readtable(path_master, 'Sheet', 'Sheet1');
    numSubs = size(tab_master, 1);
    
    % convert empty (loaded as nan by readtable) task presence to false
    idx_nan = isnan(tab_master.TaskPresent_MMN);
    tab_master.TaskPresent_MMN(idx_nan) = false;
    
    % init blank operations structure
    ops = cell(numSubs, 1);
    
% preprocess

    parfor d = 1:numSubs
        
        % determine whether face ERP task was present
        if tab_master.TaskPresent_MMN(d)
            ops{d}.MMN_Present = true;
            
        else
            ops{d}.MMN_Present = false;
            continue
            
        end
        
        % get ID and site
        id = tab_master.Clinical_Subjects{d};
        site = tab_master.site{d};
        
        % get and check data path
        file_raw = fullfile(path_raw, sprintf('%s_mmn.set', id));
        ops{d}.FaceERP_FoundRawFile = exist(file_raw, 'file') == 2;
        if ~ops{d}.FaceERP_FoundRawFile, continue, end
        
        % temp serial function call
        [~, file_out, ops{d}] =...
            LEAP_EEG_mmn_01_doPreProc_stdpos(ops{d}, file_raw, site, id,...
            path_preproc, lp_freq);
        
        if mod(d, 20) == 0
            fprintf('Dataset %d of %d (%.2f%%)...\n', d, numSubs, (d / numSubs) * 100);
        end
       
    end