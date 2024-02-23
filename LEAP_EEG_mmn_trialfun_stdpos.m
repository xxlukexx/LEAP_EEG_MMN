function [trl, event] = LEAP_EEG_mmn_trialfun_stdpos(cfg)

    % define trial events
    events = {...
        'MMN_ONSET_STD',                    201,    'STD'       ;...
        'MMN_ONSET_DEV_FREQ',               202,    'DEVF'      ;...
        'MMN_ONSET_DEV_DURATION',           203',   'DEVD',     ;...
        'MMN_ONSET_DEV_COMBINED',           204,    'DEVFD',    ;...
        };

    % define ERP correction factor by site in seconds
    switch cfg.site
        case 'KCL'
            corr = 0.008 ;
            
        case 'Mannheim'
            corr = 0.008;
            
        case 'Nijmegen'
            corr = 0.006;
            
        case 'Rome'
            corr = 0.000;
            
        case 'Utrecht'
            corr = 0.003;
            
        otherwise
            corr = 0.0000;
            warning('Site %s not recognised, applying a default correction factor of %.5fs',...
                site, corr)
            
    end
    
    % read events
    event = ft_read_event(cfg.dataset);
    
    % recode std events for distance from next deviant
    tab = struct2table(event);
    tab = tab(strcmpi(tab.type, 'EEGcode'), :);
    
    % events may be string or numeric
    vals = cell2mat(extractNumeric(tab.value));
    
    pos = 0;
    for i = 1:height(tab)
%         if strcmpi(tab.value{i}, '201')
        if vals(i) == 201
            % if this is a standard, increment the position counter (it
            % starts at zero)
            pos = pos + 1;
        else
            % if this is not a standard, set the position counter back to
            % zero
            pos = 0;
        end
        % store the position relative to the next deviant
        tab.pos(i) = pos;        
    end
    
    % keep only standards
    tab(tab.pos == 0, :) = [];
    
    % convert timing error correction to samples
    corr_samps = round(corr * cfg.fsample);

    % define trial duration and baseline
    duration_secs = 1.500;
    baseline_secs = 1.000;
    duration_samps = round(duration_secs * cfg.fsample);
    baseline_samps = round(baseline_secs * cfg.fsample);

    % define trials
    tab.s1 = round(tab.sample - baseline_samps) + corr_samps;
    tab.s2 = round(tab.sample + duration_samps) + corr_samps;
    tab.offset = repmat(-baseline_samps, height(tab.s1), 1);
    
    % make trl
    trl = [tab.s1, tab.s2, tab.offset, tab.pos];
    
    
    
%     
%     % apply timing test correction 
%     corr_samps = round(corr * cfg.fsample);
%     tab.s1 = round(tab.samples - baseline_samps) + corr_samps;
%     
%     
%     % add duration to table, convert to samples
%     tab.s1 = tab.sample;
%  
%     
%     % loop through events and make trl
%     trl = cell(height(events), 1);
%     for e = 1:height(events)
% 
%         % get trial onset samples and event values
%         samps = [event.sample]';
%         vals = str2double({event.value}');          
%         
%         idx = vals == events{e, 2};
%         samps = samps(idx);
%         vals = vals(idx);
%         
%         % convert timing error correction to samples
%         corr_samps = round(corr * cfg.fsample);
% 
%         % define trial duration and baseline
%         duration_secs = .500;
%         baseline_secs = .100;
%         duration_samps = round(duration_secs * cfg.fsample);
%         baseline_samps = round(baseline_secs * cfg.fsample);
% 
%         % define trials
%         s1 = round(samps - baseline_samps) + corr_samps;
%         s2 = round(samps + duration_samps) + corr_samps;
%         offset = repmat(-baseline_samps, size(s1));
% 
%         % return fieldtrip trial definition
%         eval(sprintf('trl_%s = [s1, s2, offset, vals];', lower(events{e, 3})))
%         
%     end
%     
%     trl_all = [trl_std; trl_devf; trl_devd; trl_devfd];
    
end