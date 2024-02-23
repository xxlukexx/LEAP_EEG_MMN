function [s, suc, oc] = LEAP_EEG_MMN_indAvg2struct(file_avg, chan)

    s = {};
    
    if ~exist(file_avg, 'file')
        suc = false;
        oc = sprint('file not found: %s', file_avg);
        return
    end
    
    try
        tmp = load(file_avg);
    catch ERR
        suc = false;
        oc = sprintf('load error: %s', ERR.message);
        return
    end
    
    if ~isfield(tmp, 'erps') || isempty(tmp.erps)
        suc = false;
        oc = 'no data';
        return
    end
    
    if ~iscell(chan), chan = {chan}; end
    numChans = length(chan);
    
    % split filename to find ID
    [~, fil] = fileparts(file_avg);
    parts = strsplit(fil, '.');
    id = parts{1};
    
    % find conditions
    conds = fieldnames(tmp.erps);
    idx = strcmpi(conds, 'summary');
    conds(idx) = [];
    numConds = length(conds);
    s = cell(numConds * numChans, 1);
    
    % loop through conditions and build struct cell array
    idx = 1;
    for i = 1:numConds
        
        for c = 1:numChans

            idx_chan = strcmpi(tmp.erps.(conds{i}).label, chan{c});        

            s{idx} = struct;
            s{idx}.id = id;
            s{idx}.cond = conds{i};
            s{idx}.elec = chan{c};
            s{idx}.comp = 'erp';
            s{idx}.erp_avg = tmp.erps.(conds{i}).avg(idx_chan, :);
            s{idx}.erp_time = tmp.erps.(conds{i}).time;
            s{idx}.lat = nan;
            s{idx}.mamp = nan;
            s{idx}.pamp = nan;
            
            idx = idx + 1;
            
        end
        
    end
    
    suc = true;
    oc = 'ok';
    
end