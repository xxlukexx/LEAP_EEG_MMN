path_avg = '/Users/luke/Desktop/mmntmp/04_freq_stdpos_100';
d = dir([path_avg, filesep, '*.mat']);
numFiles = length(d);

rows = cell(numFiles, 1);
suc = false(numFiles, 1);
oc = cell(numFiles, 1);
% numFiles = 64;
parfor i = 1:numFiles
    [rows{i}, suc(i), oc{i}] = LEAP_EEG_MMN_indTFR2struct(fullfile(d(i).folder, d(i).name), {'Fz', 'Cz'});
    fprintf('%d of %d...\n', i, numFiles);
end

tab = teLogExtract(vertcat(rows{:}));

tab.posnum = cell2mat(extractNumeric(tab.cond));
tab8 = tab(tab.posnum <= 8, :);
tab8 = LEAP_appendMetadata_t1t2(tab8, 'id');


idx_asd = strcmpi(tab8.diag, 'ASD');
idx_nt = strcmpi(tab8.diag, 'NT');

idx_cz = strcmpi(tab8.elec, 'Cz');
idx_fz = strcmpi(tab8.elec, 'Fz');

cfg = [];
cfg.baseline = [-0.200, 0.000];
tfr_all = tab8.tfr;
tfr_bl = cell(size(tab8, 1), 1);
clear cfg
parfor i = 1:size(tab8, 1)
    cfg = [];
    cfg.baseline = [-0.200, 0.000];
    cfg.baselinetype = 'relative';
    tfr_bl{i} = ft_freqbaseline(cfg, tfr_all(i));
end
    
% tfr_asd = arrayfun(@(x) x, tab8.tfr(idx_asd & idx_fz), 'UniformOutput', false);
% tfr_nt= arrayfun(@(x) x, tab8.tfr(idx_nt & idx_fz), 'UniformOutput', false);

tfr_asd = num2cell(tfr_all(idx_asd & idx_cz));
tfr_nt = num2cell(tfr_all(idx_nt & idx_cz));

cfg = []; 
cfg.channel = 'Cz';
ga_tfr_asd = ft_freqgrandaverage(cfg, tfr_asd{:});
ga_tfr_nt = ft_freqgrandaverage(cfg, tfr_nt{:});


%%

% figure
cfg = [];
cfg.baseline = [-0.100, 0.000];
cfg.baselinetype = 'absolute';
cfg.showlabels = 'yes';
cfg.zlim = [-3, 2];
% cfg.layout = 'EEG1010.lay';
figure
ft_singleplotTFR(cfg, ga_tfr_asd);

% figure
cfg = [];
cfg.baseline = [-0.100, 0.000];
cfg.baselinetype = 'absolute';
cfg.showlabels = 'yes';
cfg.zlim = [-3, 2];
% cfg.layout = 'EEG1010.lay';
figure
ft_singleplotTFR(cfg, ga_tfr_nt);