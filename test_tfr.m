% load('/Volumes/scratch/mmntmp/03_avg_stdpos/100693509718.clean.average.mat')
load('/Volumes/scratch/mmntmp/03_avg_stdpos/100693509718.clean.average.mat')

%%

cfg = [];
cfg.method = 'wavelet';
cfg.output = 'pow';
% cfg.foi = [1, 3, 4, 7, 8, 12, 15, 20, 25, 30, 35, 40, 45, 50];
cfg.foilim = [30, 50];
cfg.toi = -0.100:0.010:0.500;
cfg.channel = {'Cz', 'Fz'};
% cfg.t_ftimwin    = ones(length(cfg.foi),1).*0.5;
% cfg.pad = 5;
tfr = ft_freqanalysis(cfg, data);


%%

cfg = [];
cfg.baseline = [-0.100, 0.000];
cfg.baselinetype = 'absolute';
cfg.showlabels = 'yes';
% cfg.layout = 'EEG1010.lay';
figure
ft_singleplotTFR(cfg, tfr.pos01);
figure
ft_singleplotTFR(cfg, tfr.pos02);