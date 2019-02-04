function opts = get_hurricane_time(opts)
%READKML Summary of this function goes here
%   Detailed explanation goes here
    if nargin<1
        fprintf('Not enough input arguments!\n');
        return;
    end
    if ~isfield(opts, 'config_filename')
        fprintf('Configure Filename Not Found!\n');
        return;
    end
    if isfield(opts, 'config_add')
        [configure_all, filename_all] = get_configure(opts.config_filename, opts.config_add);
    else
        [configure_all, filename_all] = get_configure(opts.config_filename);
    end

    process = 'get hurricane_time';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/hurricane.mat',filename_all.data_dir));
    load(sprintf('%s/best_track.mat',filename_all.data_dir));
    
    for h=1:numel(hurricane)
        hurricane(h).start_time=best_track{h}(1,1);
        hurricane(h).end_time=best_track{h}(end,1);
    end
    
    save(sprintf('%s/hurricane.mat',filename_all.data_dir),'hurricane');
    fprintf('---------- %s / End ----------\n', process);
end

