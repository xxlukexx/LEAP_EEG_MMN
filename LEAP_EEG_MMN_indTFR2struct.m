function [s, suc, oc] = LEAP_EEG_MMN_indTFR2struct(file_tfr, chan)

    s = {};
    
    if ~exist(file_tfr, 'file')
        suc = false;
        oc = sprint('file not found: %s', file_tfr);
        return
    end
    
    try
        tmp = load(file_tfr);
    catch ERR
        suc = false;
        oc = sprintf('load error: %s', ERR.message);
        return
    end
    
    if ~isfield(tmp, 'tfr') || isempty(tmp.tfr)
        suc = false;
        oc = 'no data';
        return
    end
    
    if ~iscell(chan), chan = {chan}; end
    numChans = length(chan);
    
    % split filename to find ID
    [~, fil] = fileparts(file_tfr);
    parts = strsplit(fil, '.');
    id = parts{1};
    
    % find conditions
    conds = fieldnames(tmp.tfr);
    idx = strcmpi(conds, 'summary');
    conds(idx) = [];
    numConds = length(conds);
    s = cell(numConds * numChans, 1);
    
    % loop through conditions and build struct cell array
    idx = 1;
    for i = 1:numConds
        
        for c = 1:numChans
            
            cfg = [];
            cfg.channel = chan{c};
            tmp_chan = ft_selectdata(cfg, tmp.tfr.(conds{i}));

            s{idx} = struct;
            s{idx}.id = id;
            s{idx}.cond = conds{i};
            s{idx}.elec = chan{c};
            s{idx}.tfr = tmp_chan;
            
            idx = idx + 1;
            
        end
        
    end
    
    clear tmp
    suc = true;
    oc = 'ok';
    
end