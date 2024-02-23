% setup

%     lm_addCommonPaths
    
% try
    
    tic

    stat = ECKStatus('Starting up...');

    % output path
    path_clean = '/Volumes/scratch/mmntmp/02_clean';
    tryToMakePath(path_clean)

    % input path
    path_preproc = '/Volumes/scratch/mmntmp/01_preproc';
    d = dir([path_preproc, filesep, '*.mat']);
    numFiles = length(d);
    
    parts = cellfun(@(x) strsplit(x, '.'), {d.name}, 'uniform', false);
    ids_all = cellfun(@(x) x{1}, parts, 'uniform', false);

    % filter to only process certain datasets (if required)
    sel = true(length(d), 1);
%     sel(51:end) = true;
    sched = find(sel); 
    numSched = length(sched);
    
%     % set ar options
%     options.minmax = true;
%     options.range = true;
%     options.flat = true;
%     options.eog = true;
%     options.alpha = false;

    % send data to workers
    futCounter = 0;
    for f = 1:numSched
        if ~strcmp(d(f).name(1), '_')
            futCounter = futCounter + 1;
            path_in = [path_preproc, filesep, d(sched(f)).name];
            ops = struct;
            fut(futCounter) =...
                parfeval(@LEAP_EEG_mmn_02_doClean, 3, ops, path_in,...
                ids_all{f}, path_clean, [], [], []);
            
%             [dta, fo, opz] = LEAP_EEG_mmn_02_doClean(ops, path_in,...
%                 ids_all{f}, path_clean, [], [], []);
            
            
            stat.Status =...
                sprintf('Load: Sending dataset %d to workers...', futCounter);
        end
    end
    stat.Status = 'Waiting for first job to complete...';

    % retrieve loaded data
    summaries = cell(futCounter, 1);
    numSched = 4;
    for f = 1:futCounter
        [idx, ~, ~, tmpSummary] = fetchNext(fut);
        summaries{f} = tmpSummary;
        stat.Status =...
            sprintf('Load: Received dataset %d from worker (%.1f%% | %.1f datasets/m)...',...
            idx, (f / futCounter) * 100, f / (toc / 60));
    end

    toc

%     tmp = vertcat(summaries{:});
    res = teLogExtract(summaries);


    % figure('menubar', 'none')
    % subplot(2, 3, 1)
    % histogram(res.ar_eog, 70)
    % title('AR - EOG')
    % xlabel('Num good trials')
    % 
    % subplot(2, 3, 2)
    % histogram(res.ar_preInterp, 70)
    % title('AR - pre-interp')
    % xlabel('Num good trials')
    % 
    % subplot(2, 3, 3)
    % histogram(res.ar_postInterp, 70)
    % title('AR - post-interp')
    % xlabel('Num good trials')
    % 
    % subplot(2, 3, 4)
    % histogram(res.numChanExcl)
    % title('Num chans excluded')
    % 
    % subplot(2, 3, 5)
    % histogram(res.tpc_inv)
    % title('tpc INV')
    % xlabel('Num good trials')
    % 
    % subplot(2, 3, 6)
    % histogram(res.tpc_up)
    % title('tpc UP')
    % xlabel('Num good trials')
% 
%     cutoff_tpc = 20;
%     met_tpc = res.tpc_inv >= cutoff_tpc & res.tpc_up >= cutoff_tpc;
%     fprintf('Met 20tpc cutoff for both conditions: %d of %d (%.1f%%)\n',...
%         sum(met_tpc), length(met_tpc), (sum(met_tpc) / length(met_tpc)) * 100)
% 
%     cutoff_interp = 10;
%     met_interp = res.numChanInterp <= cutoff_interp;
%     fprintf('Met <10 channels interpolated cutoff: %d of %d (%.1f%%)\n',...
%         sum(met_interp), length(met_interp), (sum(met_interp) / length(met_interp)) * 100)
% 
%     cutoff_excl = 10;
%     met_excl = res.numChanExcl <= cutoff_excl;
%     fprintf('Met <10 channels excluded cutoff: %d of %d (%.1f%%)\n',...
%         sum(met_excl), length(met_excl), (sum(met_excl) / length(met_excl)) * 100)
% 
%     met = met_tpc & met_excl * cutoff_interp;
%     fprintf('Met all cutoff criteria: %d of %d (%.1f%%)\n',...
%         sum(met), length(met), (sum(met) / length(met)) * 100)
% 
%     res = [res,...
%         table(met_tpc, met_interp, met_excl, met, 'variablenames',...
%         {'Met_Cutoff_TPC20', 'Met_Cutoff_Interp10', 'Met_Cutoff_Excl10', 'Met_All_Cutoffs'})];

    res.Met_All_Cutoffs = true(size(res, 1), 1);

    % % get metadata
    % parts = cellfun(@(x) strsplit(x, '_'), res.id, 'uniform', false);
    % ids = cellfun(@(x) x{1}, parts, 'uniform', false);
    % md = LEAP_getMetadataFromID(ids);
    % res = [res, struct2table(md)];

    save([path_clean, filesep, '_results.mat'], 'res', 'summaries');


    % % bin by 2-yr age
    % valAge = ~cellfun(@isempty, res.age);
    % ages = cell2mat(res.age(valAge)) / 365;
    % ages_bin = 6:2:32;
    % ages_bin_idx = discretize(ages, ages_bin);
    % metAge = accumarray(ages_bin_idx, res.Met_All_Cutoffs(valAge), [], @(x) sum(x) / length(x));
    % metTpcUp = accumarray(ages_bin_idx, res.tpc_up(valAge), [], @(x) sum(x) / length(x));
    % metTpcInv = accumarray(ages_bin_idx, res.tpc_inv(valAge), [], @(x) sum(x) / length(x));
    % nAge = accumarray(ages_bin_idx, ones(sum(valAge, 1), 1), [], @sum);
    % figure('menubar', 'none', 'name', 'Cleaning outcome by age')
    % 
    % subplot(2, 1, 1)
    % h = bar(ages_bin(1:end - 1), nAge);
    % h.FaceAlpha = .25;
    % hold on
    % plot(ages_bin(1:end - 1), 100 * (1 - metAge))
    % ylabel('% datasets excluded')
    % set(gca, 'xtick', ages_bin)
    % legend('N', '% excluded')
    % 
    % subplot(2, 1, 2)
    % h = bar(ages_bin(1:end - 1), nAge);
    % h.FaceAlpha = .25;
    % hold on
    % plot(ages_bin(1:end - 1), metTpcUp)
    % plot(ages_bin(1:end - 1), metTpcInv)
    % set(gca, 'xtick', ages_bin)
    % xlabel('age')
    % ylabel('trials per condition')
    % legend('N', 'TPC upright', 'TPC inverted')
    % 

% catch ERR
%     
%     notifyByEmail('Error', evalc('disp(ERR)'));
%     rethrow ERR
%     
% end
% 
% notifyByEmail('LEAP_EEG_faces_02_clean', 'Complete');


