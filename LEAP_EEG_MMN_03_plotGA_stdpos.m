path_avg = '/Volumes/scratch/mmntmp/03_avg_stdpos';
d = dir([path_avg, filesep, '*.mat']);
numFiles = length(d);

rows = cell(numFiles, 1);
suc = false(numFiles, 1);
oc = cell(numFiles, 1);
parfor i = 1:numFiles
    [rows{i}, suc(i), oc{i}] = LEAP_EEG_MMN_indAvg2struct(fullfile(d(i).folder, d(i).name), {'Fz', 'Cz'});
end

tab = teLogExtract(vertcat(rows{:}));

tab.posnum = cell2mat(extractNumeric(tab.cond));
tab8 = tab(tab.posnum <= 8, :);
tab8 = LEAP_appendMetadata_t1t2(tab8, 'id');
eegPlotFactorialGA2(tab8, 'erp', 'compare', 'cond', 'plotSEM', false, 'colMap', @parula, 'linewidth', 2, 'cols', 'elec', 'fontsize', 20, 'rows', 'diag')