path_clean = '/Users/luke/Desktop/mmntmp/02_clean';
d = dir([path_clean, filesep, '*.mat']);
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


%%

smry = cell(length(data), 1);
propGood = nan(length(data), 1);
numGood = zeros(length(data), 1);
for i = 1:length(data)
    disp(i)
    smry{i} = eegAR_Summarise(data{i}.data);
    if isTableVar(smry{i}.event, 'Cond_201')
        propGood(i) = smry{i}.event.Cond_201(3);
        numGood(i) = smry{i}.event.Cond_201(2);
    else
        propGood(i) = 0;
    end
end