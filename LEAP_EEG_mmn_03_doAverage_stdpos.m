function [erps, ops] = LEAP_EEG_mmn_03_doAverage(path_in, path_out)
        
    % get ID
    [~, id, ~] = fileparts(path_in);
    
    % make output filename
    file_out = [id, '.average', '.mat'];
    
    % summary defaults 
    ops.file_erps = '';
    erps = [];
    ops.avgValid = false;
    ops.avgError = 'Unknown error';
    ops.avg_PathOut = path_out;
    ops.avg_FileOut = file_out;
    
    % load
    data = [];
    if ~exist(path_in, 'file')
        ops.avgValid = false;
        ops.avgError = sprintf('File not found: %s', path_in);
        return
    end
    
    load(path_in);
    if isempty(data)
        ops.avgValid = false;
        ops.avgError = 'Load error';
        return
    end
        
    % get audit and summary structs from data 
    if isfield(data, 'summary')
        ops = catstruct(data.summary, ops);
        art = data.art;
        chanExcl = data.chanExcl;
        data = rmfieldIfPresent(data, {'interp', 'interpNeigh', 'cantInterp',...
            'summary', 'chanExcl', 'art_type', 'art'});
    end

    % check output path exists
    if ~exist(path_out, 'dir')
        ops.avgError = 'Output path does not exist.';
        return
    end
    
%     try
        
        %% make ERPs
        
        try
        
            % flatten arterfact matrix
            art = any(art, 3);

            % drop trials with artefacts
            cfg = [];
            badTrials = any(art(~chanExcl, :), 1);
            if sum(badTrials) == length(data.trial)
                ops.avgValid = false;
                ops.avgError = 'No good trials';
                return
            end
            cfg.trials = ~badTrials;
            if any(badTrials), data = ft_selectdata(cfg, data); end

            % avg ref
            cfg = [];
            cfg.reref = 'yes';
            cfg.refchannel = data.label(~chanExcl);
            data = ft_preprocessing(cfg, data);
            
            % average by std pos
            [sp_u, ~, sp_s] = unique(data.trialinfo);
            numPos = length(sp_u);
            for p = 1:numPos
                
                cfg = [];
                cfg.trials = find(sp_s == p);
                varName = sprintf('pos%02d', p);
                if ~isempty(cfg.trials)
                    erps.(varName) = ft_timelockanalysis(cfg, data);
                    cfg = [];
                    cfg.baseline = [-.2, 0];
                    erps.(varName) = ft_timelockbaseline(cfg, erps.(varName));
                else
                    erps.(varName) = [];
                end  
                
            end     
            
        catch ERR
            
            ops.avgValid = false;
            ops.avgError = ERR.message;
            
        end

       % todo DEVIANTS
        
%         if isempty(erps.face_up) || isempty(erps.face_inv)
%             ops.avgValid = false;
%             ops.avgError = 'At least one condition has zero trials.';
%             return
%         end
        
        %% find peaks
        
%         erps = LEAP_EEG_faces_findPeaks(erps);
        
        %% store
        
        ops.avgValid = true;
        ops.avgError = 'None';
    
        % store summary and audit
        erps.summary = ops;
        
        % save
        save(fullfile(path_out, file_out), 'erps', '-v6');
        
%     catch ERR
%         
%         ops.avgError = ERR.message;
%         ops.avgValid = false;
%         erps = [];
%         return
%         
%     end
    


end