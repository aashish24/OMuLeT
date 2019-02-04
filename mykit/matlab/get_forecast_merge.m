function get_forecast_merge(opts)
% get ensemble median mean for AP and CP
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

    process = 'Get ensemble median and mean';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/raw/forecast_nhc.mat',filename_all.data_dir));
    forecast_nhc=forecast;
    load(sprintf('%s/raw/forecast_uwm.mat',filename_all.data_dir));
    forecast_uwm=forecast;
    load(sprintf('%s/raw/forecast_linear.mat',filename_all.data_dir));
    forecast_linear=forecast;
    flag=false(numel(forecast_nhc),1);
    for h=1:numel(forecast_nhc)
        if size(forecast_nhc{h},1)>0 && size(forecast_uwm{h},1)>0
            flag(h)=true;
        end
    end
    flag=find(flag>0);
    forecast=[];
    for ii=1:numel(flag)
        h=flag(ii);
        forecast{ii}=[forecast_nhc{h}; forecast_uwm{h};forecast_linear{h}];
    end
    load(sprintf('%s/raw/hurricane.mat',filename_all.data_dir));
    hurricane=hurricane(flag);
    load(sprintf('%s/raw/best_track.mat',filename_all.data_dir));
    best_track=best_track(flag);
    save(sprintf('%s/forecast.mat',filename_all.data_dir),'forecast');
    save(sprintf('%s/hurricane.mat',filename_all.data_dir),'hurricane');
    save(sprintf('%s/best_track.mat',filename_all.data_dir),'best_track');
    
    fprintf('---------- %s / End ----------\n', process);
end

