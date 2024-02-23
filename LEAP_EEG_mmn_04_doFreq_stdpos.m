function [erps, ops] = LEAP_EEG_mmn_04_doFreq_stdpos(path_in, path_out)

    try
        
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
        if ~exist('data', 'var') || isempty(data)
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
                
        %% make TFRs
        
%         try
            
            tfr = struct;
        
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
            
            % TFR by std pos
            [sp_u, ~, sp_s] = unique(data.trialinfo);
            numPos = length(sp_u);
            if numPos > 6, numPos = 6; end
            for p = 1:numPos
                                    
                cfg = [];
                cfg.trials = find(sp_s == p);
                varName = sprintf('pos%02d', p);                
                cfg.method = 'wavelet';
                cfg.output = 'pow';
                cfg.foilim = [1, 100];
                cfg.toi = -0.200:0.002:0.600;
%                 cfg.channel = {'Cz', 'Fz'};
                % cfg.t_ftimwin    = ones(length(cfg.foi),1).*0.5;
                % cfg.pad = 5;
                
                if ~isempty(cfg.trials)
                    % do freq analysis
                    tfr.(varName) = ft_freqanalysis(cfg, data);
%                     % chop off padding
%                     cfg = [];
%                     cfg.latency = [-0.2, 0.6];
%                     tfr.(varName) = ft_selectdata(cfg, tfr.(varName));
                else
                    tfr.(varName) = [];
                end  
                
            end     
            
%         catch ERR
%             
%             ops.avgValid = false;
%             ops.avgError = ERR.message;
%             
%         end

        %% store
        
        ops.avgValid = true;
        ops.avgError = 'None';
    
        % store summary and audit
        tfr.summary = ops; 
        
        % save
        save(fullfile(path_out, file_out), 'tfr', '-v6');
        
    catch ERR
        
        ops.avgError = ERR.message;
        ops.avgValid = false;
        erps = [];
        return
        
    end
    
end