function [trl_all, trl_std, trl_devf, trl_devd, trl_devfd, event] = LEAP_EEG_mmn_trialfun(cfg)

    % define trial events
    wanted_events = {...
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
    
    % filter for just numeric events in range
    idx_numeric_event = cellfun(@isnumeric, {event.value});
    event(~idx_numeric_event) = [];
    event_values = cell2mat(extractNumeric({event.value}));
    idx_event_in_range = ismember(event_values, cell2mat(wanted_events(:, 2)));
    event(~idx_event_in_range) = [];
    
    % loop through events and make trl
    trl = cell(height(wanted_events), 1);
    for e = 1:height(wanted_events)

        % get trial onset samples and event values
        samps = [event.sample]';
        vals = cell2mat(extractNumeric({event.value}))';
        
        idx = vals == wanted_events{e, 2};
        samps = samps(idx);
        vals = vals(idx);
        
        % convert timing error correction to samples
        corr_samps = round(corr * cfg.fsample);

        % define trial duration and baseline
        duration_secs = .500;
        baseline_secs = .100;
        duration_samps = round(duration_secs * cfg.fsample);
        baseline_samps = round(baseline_secs * cfg.fsample);

        % define trials
        s1 = round(samps - baseline_samps) + corr_samps;
        s2 = round(samps + duration_samps) + corr_samps;
        offset = repmat(-baseline_samps, size(s1));

        % return fieldtrip trial definition
        eval(sprintf('trl_%s = [s1, s2, offset, vals];', lower(wanted_events{e, 3})))
        
    end
    
    trl_all = [trl_std; trl_devf; trl_devd; trl_devfd];
    
end