path_avg = '/Volumes/scratch/mmntmp/03_avg';
d = dir([path_avg, filesep, '*.mat']);
numFiles = length(d);

data_fz = cell(numFiles, 1);
chan = 'Fz';
parfor f = 1:numFiles
    
    tmp = load(fullfile(d(f).folder, d(f).name));
    if ~isfield(tmp, 'erps') || ~isfield(tmp.erps, 'std') || isempty(tmp.erps.std)
        data_fz{f}.suc = false;
        data_fz{f}.oc = 'no data';
        continue
    end
    
    idx_chan = strcmpi(tmp.erps.std.label, chan);
    data_fz{f} = struct;
    
    parts = strsplit(d(f).name, '.');
    data_fz{f}.id = parts{1};
    
    data_fz{f}.cond = 'std';
    data_fz{f}.elec = chan;
    data_fz{f}.comp = 'erp';
    data_fz{f}.erp_avg = tmp.erps.std.avg(idx_chan, :);
    data_fz{f}.erp_time = tmp.erps.std.time;
    data_fz{f}.lat = nan;
    data_fz{f}.mamp = nan;
    data_fz{f}.pamp = nan;
    
    data_fz{f}.suc = true;
    data_fz{f}.oc = 'ok';
    
end

data_cz = cell(numFiles, 1);
chan = 'Cz';
parfor f = 1:numFiles
    
    tmp = load(fullfile(d(f).folder, d(f).name));
    if ~isfield(tmp, 'erps') || ~isfield(tmp.erps, 'std') || isempty(tmp.erps.std)
        data_cz{f}.suc = false;
        data_cz{f}.oc = 'no data';
        continue
    end    
    
    idx_chan = strcmpi(tmp.erps.std.label, chan);
    data_cz{f} = struct;
    
    parts = strsplit(d(f).name, '.');
    data_cz{f}.id = parts{1};
    
    data_cz{f}.cond = 'std';
    data_cz{f}.elec = chan;
    data_cz{f}.comp = 'erp';
    data_cz{f}.erp_avg = tmp.erps.std.avg(idx_chan, :);
    data_cz{f}.erp_time = tmp.erps.std.time;
    data_czdata_cz{f}.lat = nan;
    data_cz{f}.mamp = nan;  
    data_cz{f}.pamp = nan;    

    data_cz{f}.suc = true;
    data_cz{f}.oc = 'ok';
        
end


data = [data_fz; data_cz];
tab = teLogExtract(data);

fprintf('%d datasets removed\n', sum(~tab.suc));
tab(~tab.suc, :) = [];

tab = LEAP_appendMetadata_t1t2(tab, 'id');

eegPlotFactorialGA2(tab, 'erp', 'compare', 'diag', 'rows', 'elec', 'ttest', false, 'linewidth', 3)
