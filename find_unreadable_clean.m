d = dir('/Volumes/projects/LEAP/EEG/mmn/02_clean_stdpos_100hz/*.mat');
suc = false(length(d), 1);
parfor i = 1:length(d)
    WaitSecs(rand);
    disp(i)
    try
        tmp = load(fullfile(d(i).folder, d(i).name));
        suc(i) = true;
    catch ERR
        suc(i) = false;
    end
end