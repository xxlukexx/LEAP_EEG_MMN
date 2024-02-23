function [data, file_out, ops] =...
    LEAP_EEG_mmn_02_doClean(ops, path_in, id, path_out, manualArt,...
    dataVarName, opt)

    if exist('dataVarName', 'var') && ~isempty(dataVarName)
        renameData = true;
    else
        dataVarName = 'data';
        renameData = false;
    end
    
    if ~exist('opt', 'var') || isempty(opt)
        opt.alpha = false;
        opt.minmax = true;
        opt.range = true;
        opt.eog = true;
        opt.flat = false;
    end

    if ~isfield(opt, 'alpha'),          opt.alpha = false;          end
    if ~isfield(opt, 'alphamaxsd'),     opt.alphamaxsd = 6;         end
    if ~isfield(opt, 'minmaxmin'),      opt.minmaxmin = -100;        end
    if ~isfield(opt, 'minmaxmax'),      opt.minmaxmax = 100;         end
    if ~isfield(opt, 'minmax'),         opt.minmax = true;          end
    if ~isfield(opt, 'range'),          opt.range = true;           end
    if ~isfield(opt, 'rangeval'),       opt.rangeval = 150;         end
    if ~isfield(opt, 'eog'),            opt.eog = true;             end
    if ~isfield(opt, 'eogmaxsd'),       opt.eogmaxsd = 6;           end
    if ~isfield(opt, 'flat'),           opt.flat = true;            end

    art_minMax = [];
    art_range = [];
    art_flat = [];
    art_alpha = [];
    art_eog = [];

    % define AR criteria
    ar_min = opt.minmaxmin;
    ar_max = opt.minmaxmax;
    ar_range = opt.rangeval;
    ar_eog_z = opt.eogmaxsd;
    alphaMaxSD = opt.alphamaxsd;
    
    % interpolation distance (mm)
    interp_dist = 60; 
       
    % split input path
    [filePath, fileName, fileExt] = fileparts(path_in);
    file_in = [fileName, fileExt];
    
%     % get ID
%     [~, id, ~] = fileparts(path_in);
    
    % make output filename
    file_out = [id, '.clean', '.mat'];
            
    % check output path exists
    if ~exist(path_out, 'dir')
        ops.cleanError = 'Output path does not exist.';
        return
    end
    
    % summary defaults
    ops.clean_FileIn = file_in;
    ops.clean_PathIn = filePath;
    ops.clean_FileOut = file_out;
    ops.clean_PathOut = path_out;
    ops.numChanInterp = 0;
    ops.chanInterp = '';
    ops.totInterp = 0;
    ops.propInterp = 0;
    ops.numChanExcl = 0;
    ops.chanExcl = '';
    ops.P7Bad = false;
    ops.P8Bad = false;
    ops.O1Bad = false;
    ops.O2Bad = false;
    ops.ar_postInterp = 0;
    ops.totaltrials = 0;
    ops.tpc_up = 0;
    ops.tpc_inv = 0;
    
    file_out = fullfile(path_out, file_out);
    if exist(file_out, 'file')
        ops.cleanError = 'File exists, skipping';
        data = [];
        return
    end
    
    % load
    data = [];
    load(path_in);
    
    % if a different variable name has been passed for date (e.g.
    % data_face) then rename this to data
    if renameData
        eval(sprintf('data = %s;', dataVarName));
    end
        
    if isempty(data)
        ops.cleanValid = false;
        ops.cleanError = 'Load error';
        return
    end
    data = rmfield(data, 'cfg');
    
    % get audit and summary structs from data 
    if isfield(data, 'summary')
        ops = catstruct(data.summary, ops);
        data = rmfield(data, 'summary');
    end
    
    try
        
        % check for all flat channels
        allFlat = all(cellfun(@(x) all(x(:) == 0), data.trial));
        if allFlat
            ops.cleanError = 'All channels flat';
            ops.cleanValid = false;
            return
        end
        
        % remove additional channels (just keep 10-20)
        if isfield(data, 'elec')
            cfg = [];
            cfg.channel = data.elec.label;
            data = ft_selectdata(cfg, data);
        end
        
        % make channel neighbours struct for later use in interpolation
        cfg = [];
        cfg.method = 'distance';
        cfg.layout = data.elec;
        cfg.neighbourdist = interp_dist;
        nb = ft_prepare_neighbours(cfg, data); 
        
        % artefact detection to mark trial/channel combinations that need
        % interpolation. don't look at eog here, since we don't want to
        % interpolate those artefacts
        smry = [];
        chanExcl = false(length(data.label), 1);
        runMainAR
        
        % find channels with >80% bad trials, and intepolate the entire
        % channel for all trials (this is faster than doing it
        % trial-by-trial, which is what we do for more sparse aretfacts in
        % the next stage)
        chanInterp = smry.channels.trialProp > .8;
        chanInterpLabs = data.label(chanInterp);
        interp = false(length(data.label), length(data.trial));
        interp(chanInterp, :) = true;
        
        % interpolate any bad channels
        if any(chanInterp)
            
            % interpolate
            cfg = [];
            cfg.method = 'spline';
            cfg.badchannel = chanInterpLabs;
            cfg.neighbours = nb;
            data = ft_channelrepair(cfg, data);
            ops.numChanInterp = length(chanInterpLabs);
            ops.chanInterp = cell2char(chanInterpLabs);
            
            % run AR-D again to update artefacts post-interpolation
            runMainAR
            
        else
            ops.chanInterp = 'none';
        end

        % interpolate trials with detected artefacts on a per-channel basis
        [data, ~, ~,...
            ops.totInterp, ops.propInterp, trInterp,...
            data.interpNeigh, data.cantInterp] =...
            eegInterpTrial(data, data.art, interp_dist, nb);
        interp = interp | trInterp;

        % post-interpolation, rerun AR-D in order to detect those channels
        % with so many artefacts that they should be exluded from avg ref,
        % and from future AR-D
        runMainAR
        
        % exclude channels with >40% bad trials (but not EOG channels, since
        % these pollute other channels, so should be dropped when bad)
        labels_eog = {'FP1', 'FP2', 'FPz', 'AF7', 'AF8'};
        idx_eog = cellfun(@(x) strcmpi(data.label, x), labels_eog,...
            'uniform', false);
        idx_eog = any(horzcat(idx_eog{:}), 2);        
        propBad = smry.channels.trialProp > .4;            
        chanExcl = ~idx_eog & propBad > .4;
        ops.numChanExcl = sum(chanExcl);
        if any(chanExcl)
            ops.chanExcl = cell2char(data.label(chanExcl));
        else
            ops.chanExcl = [];
        end
        
        % mark whether key channels are bad
        ops.P7Bad = strcmpi(ops.chanExcl, 'P7');
        ops.P8Bad = strcmpi(ops.chanExcl, 'P8');
        ops.O1Bad = strcmpi(ops.chanExcl, 'O1');
        ops.O2Bad = strcmpi(ops.chanExcl, 'O2');    
        
        % AR - just frontal channels for blinks
        if opt.eog
            data = eegAR_Detect(data, 'method', 'eogstat',...
                'maxsd', ar_eog_z, 'excluded_channels', ~idx_eog); 
        end
        smry = eegAR_Summarise(data);

        % AR - to drop trials
        runMainAR
        ops.ar_postInterp = smry.trials.good;
        
        % count trials per condition
        if isfield(smry, 'event') && ~isempty(smry.event)
            conds = smry.event.Properties.VariableNames;
            idx_up = cellfun(@(x) strcmpi(conds, x),...
                {'Cond_223', 'Cond_224', 'Cond_225'}, 'uniform', false);
            idx_inv = cellfun(@(x) strcmpi(conds, x),...
                {'Cond_226', 'Cond_227', 'Cond_228'}, 'uniform', false);
            idx_up = any(vertcat(idx_up{:}), 1);
            idx_inv = any(vertcat(idx_inv{:}), 1);
            ops.totaltrials = sum(smry.event{1, :});
            ops.tpc_up = sum(smry.event{2, idx_up});
            ops.tpc_inv = sum(smry.event{2, idx_inv});       
        else
            ops.totaltrials = length(data.trial);
            ops.tpc_up = 0;
            ops.tpc_inv = 0;
        end
        
        % store audit and summary structs
        data.summary = ops;
        
        % store artefact detection matrices 
%         data.art = art_drop.matrix;
%         if isfield(art_drop, 'type')
%             data.artType = art_drop.type;
%         end
        data.interp = interp;
        data.chanExcl = chanExcl;

        % save
        if renameData, eval(sprintf('%s = data;', dataVarName)); end
        save(file_out, dataVarName, '-v6')
        
    catch ERR
        
        ops.cleanError = ERR.message;
        return
        
    end
    
    ops.cleanValid = true;
    ops.cleanError = 'None';
    
    function runMainAR
        
        % run separate AR methods
        if opt.minmax
            data = eegAR_ResetArt(data, 'minmax');
            data = eegAR_Detect(data, 'method', 'minmax',...
                'threshold', [ar_min, ar_max],...
                'excluded_channels', chanExcl,...
                'time_range', [-0.2, 0.6]);
        end
        if opt.range
            data = eegAR_ResetArt(data, 'range');
            data = eegAR_Detect(data, 'method',...
                'range', 'threshold', ar_range,...
                'excluded_channels', chanExcl,...
                'time_range', [-0.2, 0.6]);
        end
        if opt.flat
            data = eegAR_ResetArt(data, 'flat');
            data = eegAR_Detect(data, 'method', 'flat',...
                'excluded_channels', chanExcl,...
                'time_range', [-0.2, 0.6]);
        end
        if opt.alpha
            data = eegAR_ResetArt(data, 'alpha');
            data = eegAR_Detect(data, 'method', 'alpha',...
                'maxsd', alphaMaxSD,...
                'excluded_channels', chanExcl,...
                'time_range', [-0.2, 0.6]);            
        end
        
        % summarise
        smry = eegAR_Summarise(data);
        
    end

end