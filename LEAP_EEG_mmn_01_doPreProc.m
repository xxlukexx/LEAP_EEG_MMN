function [data, file_out, ops] = LEAP_EEG_mmn_01_doPreProc(ops,...
    path_in, site, id, path_out, lpFreq)

    debug = true;
    data = [];
    file_out = [];
    
    % summary variables
    ops.preProcValid = false;
    ops.preProcError = 'Unknown error.';
    
    % determine where we are reading from a folder or filename
    if exist(path_in, 'dir')
        % folder - extract filename
        filePath = path_in;
        fileName = findFilename('.set', path_in);
        fileExt = '';
    else
        % file  - extract file path
        fileName = path_in;
        [filePath, fileName, fileExt] = fileparts(fileName);
    end
    
    % split input path to filename and path
    file_in = [fileName, fileExt];
    path_in = [filePath, filesep, file_in];
    
    % make output folder
%     file_out = [id, '.preproc.%dhz', '.mat'];    
    file_out = sprintf('%s.preproc.%dhz.mat', id, lpFreq);

    ops.preProc_FileIn = file_in;
    ops.preProc_PathIn = filePath;
    ops.preProc_FileOut = file_out;
    ops.preProc_PathOut = path_out;

    % check input file exists
    if isempty(path_in) || ~exist(path_in, 'file')
        ops.preProcError = 'File does not exist.';
        return
    end
    
    % check output path exists
    if ~exist(path_out, 'dir')
        ops.preProcError = 'Output path does not exist.';
        return
    end
    
    % if output file exists
    if exist(fullfile(path_out, file_out), 'file') 
        ops.SkippedFileExists = true;
        return
    else
        ops.SkippedFileExists = false;
    end
    
    % process
%     try

        % copy to temp file
        [curPath, curFile, ~] =...
            fileparts([filePath, filesep, file_in]);
        if debug, fprintf('Copying %s to temp folder...\n', curFile); end
        copyfile([curPath, filesep, curFile, '.set'], tempdir);
        copyfile([curPath, filesep, curFile, '.fdt'], tempdir);
        
        % load raw continuous data, do hp filter at 0.1 Hz (since this will
        % apply to data used for ERP and ERO)
        if debug, fprintf('Loading raw data...\n'); end
        cfg = struct;
        cfg.dataset = fullfile(tempdir, file_in);
        cfg.layout = 'EEG1010.lay';
        data_c = ft_preprocessing(cfg);
        
        % replace NaNs with zeros
        idx_nan = isnan(data_c.trial{1});
        data_c.trial{1}(idx_nan) = 0;
        
        % define trial structure and segment
        if debug, fprintf('Running trial function...\n'); end        
        cfg = struct;
        cfg.id = id;
        cfg.site = site;
        cfg.fsample = data_c.fsample;
        cfg.dataset = fullfile(tempdir, file_in);
        cfg.trl = LEAP_EEG_mmn_trialfun(cfg);
        data_seg = ft_redefinetrial(cfg, data_c);
        
        % find channels with NaNs in - these are those channels not present
        % at a particular site
        idx_nanChan = any(isnan(data_seg.trial{1}), 2);
        lab_nanChan = data_seg.label(~idx_nanChan);
        
        % preproc
        if debug, fprintf('Preprocessing...\n'); end        
        cfg = struct;
        cfg.lpfilter = 'yes';
        cfg.lpfreq = lpFreq;
        cfg.lpfiltord = 4; 
        cfg.hpfilter = 'yes';
        cfg.hpfreq = .1;
        cfg.hpfiltord = 4; 
        cfg.dftfilter = 'yes';        
        cfg.padding = 2;
        cfg.channel = lab_nanChan;
        data = ft_preprocessing(cfg, data_seg);
        
        % resample to 500Hz
        if data.fsample ~= 500
            if debug, fprintf('Resampling...\n'); end            
            cfg = struct;
            cfg.resamplefs = 500;
            cfg.detrend = 'no';
            data = ft_resampledata(cfg, data);
        end        
        
        if debug, fprintf('Saving...\n'); end        
        save([path_out, filesep, file_out], 'data', '-v6')
        
        % delete temp file
        delete([tempdir, curFile, '.set']);
        delete([tempdir, curFile, '.fdt']);
        
        ops.preProcValid = true;
        ops.preProcError = 'None';
        
%     catch ERR
%         
%         ops.preProcError = ERR.message;
%         return
%         
%     end

end