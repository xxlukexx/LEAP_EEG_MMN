ft_defaults
file_in = '/Users/luke/Downloads/Luke_EEG/935036952888_MMN_EEG.set';
cfg = [];
cfg.dataset = file_in;
cfg.trialdef.eventtype = 'EEGcode';
cfg.trialdef.eventvalue = '201';
cfg.trialdef.prestim = .2;
cfg.trialdef.poststim = .6;
cfg = ft_definetrial(cfg);

cfg.lpfilter = 'yes';
cfg.lpfreq = 40;
cfg.hpfilter = 'yes';
cfg.hpfreq = 1;
cfg.baselinewindow = [-0.200, 0.800];
cfg.layout = 'EEG1010.lay';
data = ft_preprocessing(cfg);
data = eegRemoveNaNChannels(data);

cfg = [];
cfg.lpfilter = 'yes';
cfg.lpfreq = 30;
cfg.hpfilter = 'yes';
cfg.hpfreq = 1;
cfg.layout = 'EEG1010.lay';
cfg.reref = 'yes';
cfg.refchannel = 'all';
dataf = ft_preprocessing(cfg, data);

cfg = [];
avg = ft_timelockanalysis(cfg, data);
avgf = ft_timelockanalysis(cfg, dataf);

cfg = [];
cfg.baseline = [-.1, 0];
avg = ft_timelockbaseline(cfg, avg);
avgf = ft_timelockbaseline(cfg, avgf);


cfg = [];
cfg.channel = 'Fz';
figure
ft_singleplotER(cfg, avg)
figure
ft_singleplotER(cfg, avgf)
figure
ft_singleplotER(cfg, avgref)

[p1, f1] = pwelch(data.trial{1}(2, :)', [], [], [], data.fsample);
[p2, f2] = pwelch(dataf.trial{1}(2, :)', [], [], [], data.fsample);
figure, plot(f1, p1), hold on, plot(f2, p2)