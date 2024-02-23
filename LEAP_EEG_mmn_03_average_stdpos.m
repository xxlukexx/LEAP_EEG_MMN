% try

    clear variables
%     lm_addCommonPaths
    tic

    stat = ECKStatus('Starting up...');

    % output path
    path_out = '/Volumes/scratch/mmntmp/03_avg_stdpos';
    tryToMakePath(path_out)

    % input path
    path_clean = '/Volumes/scratch/mmntmp/02_clean_stdpos';
    path_cleanRes = [path_clean, filesep, '_results.mat'];
    clean = load(path_cleanRes);
    files_clean = cellfun(@(x) horzcat(path_clean, filesep, x),...
        clean.res.clean_FileOut, 'uniform', false);
    clean_val = true(size(clean.res, 1), 1);
%     clean_val = cellfun(@isempty, clean.res.error);
    files_clean = files_clean(clean_val);
    numFiles = length(files_clean);

    % send data to workers
    futCounter = 0;
    for f = 1:numFiles
        futCounter = futCounter + 1;
        path_in = files_clean{f};
        fut(futCounter) =...
            parfeval(@LEAP_EEG_mmn_03_doAverage_stdpos, 2, path_in, path_out);
        stat.Status =...
            sprintf('Load: Sending dataset %d to workers...', futCounter);
    end
    stat.Status = 'Waiting for first job to complete...';

    % retrieve loaded data
    summaries = cell(futCounter, 1);
    for f = 1:futCounter
        try
            [idx, ~, tmpSummary] = fetchNext(fut);
        catch ERR
            summaries{f} = struct;
            summaries{f}.error = ERR.message;
        end
        summaries{f} = tmpSummary;
        stat.Status =...
            sprintf('Load: Received dataset %d from worker (%.1f%% | %.1f datasets/m)...',...
            idx, (f / futCounter) * 100, f / (toc / 60));
    end

    res = teLogExtract(summaries);
    save([path_out, filesep, '_results.mat'], 'res', 'summaries');

    toc
    
% catch ERR
%     
% %     notifyByEmail('Error', evalc('disp(ERR)'));
%     rethrow ERR
%     
% end

% msg = tabulate(res.avgError);
% notifyByEmail('LEAP_EEG_faces_02_average - COMPLETE', evalc('disp(msg)'));
