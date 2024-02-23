path_avg = '/Volumes/scratch/mmntmp/03_avg';
path_plot = fullfile(path_avg, 'plots');
tryToMakePath(path_plot)
d = dir([path_avg, filesep, '*.mat']);
data = cell(length(d), 1);
oc = cell(length(d), 1);
parfor i = 1:length(d)
    fprintf('%s\n', fullfile(d(i).folder, d(i).name));
    try
        data{i} = load(fullfile(d(i).folder, d(i).name));
        oc{i} = 'success';
    catch ERR
        oc{i} = ERR.message;
    end
end

idx = ~strcmpi(oc, 'success');
oc(idx) = [];
data(idx) = [];
d(idx) = [];



clear vis
sca
vis = ECKEEGVis;
numData = length(data);
for i = 1:numData
    try
        vis.Data = data{i}.erps.std;
        file_out = fullfile(path_plot, sprintf('%s.plot.png', d(i).name));
        vis.SaveScreenshot(file_out);
    catch ERR
    end
end