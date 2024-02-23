ids = {...
    '184577901153',...
    '206523187654',... 
    '220947892915',...
    '224830515714',...
    '227007190710',...
    '229884376245',...
    '229951973089',...
    '230568388344',... 
    '232366221199',...
    '234478915322',...
    '235350958604',...
    '236256460571',...
    '236929058799',...
    '241215701017',...
    '242792262922',...
    '243617148831',...
    '244104527152',...
    '250798494359',...
    '251317189021',...
    '256029070030',...
    '259866841106',...
    '261242874734',...
    '261249677383',... 
    '263248965095',...
    '268166735779',...
    '277866455055',...
    '605316136288',...
    '702091185251',...
}

num_ids = length(ids);

path_raw_src = '/Volumes/projects/LEAP/EEG/mmn/00_raw';
path_raw_dest = '/Volumes/projects/LEAP/EEG/mmn/_redo_corrupted/00_raw';

for i = 1:num_ids
    
    src_set = fullfile(path_raw_src, sprintf('%s_mmn.set', ids{i}));
    src_fdt = strrep(src_set, '.set', '.fdt');
    dest_set = fullfile(path_raw_dest,  sprintf('%s_mmn.set', ids{i}));
    dest_fdt = strrep(dest_set, '.set', '.fdt');
    
    fprintf('Copying %s to %s\n', src_set, dest_set)
    fprintf('Copying %s to %s\n', src_fdt, dest_fdt)
    
    copyfile(src_set, dest_set)
    copyfile(src_fdt, dest_fdt)
    
end
