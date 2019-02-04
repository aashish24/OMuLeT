function get_lon_fix(opts)
%GET_best_track Summary of this function goes here
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

    process = 'Get dataset';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/forecast.mat',filename_all.data_dir));
    load(sprintf('%s/best_track.mat',filename_all.data_dir));
    
    for h=1:numel(forecast)
        if size(forecast{h},1)==0
            continue;
        end
        idx = forecast{h}(:,5)>90;
        forecast{h}(idx,5)=forecast{h}(idx,5)-360;
    end
    
    for h=1:numel(best_track)
        if size(best_track{h},1)==0
            continue;
        end
        idx = best_track{h}(:,3)>90;
        best_track{h}(idx,3)=best_track{h}(idx,3)-360;
    end
    
    save(sprintf('%s/forecast.mat',filename_all.data_dir),'forecast');
    save(sprintf('%s/best_track.mat',filename_all.data_dir),'best_track');
    
    fprintf('---------- %s / End ----------\n', process);
end

