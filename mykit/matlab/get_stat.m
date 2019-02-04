function error = get_stat(opts)
%GET_STAT Summary of this function goes here
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

    process = 'Get statistic';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/forecast.mat',filename_all.data_dir));
    load(sprintf('%s/model.mat',filename_all.data_dir));
    load(sprintf('%s/hurricane_track.mat',filename_all.data_dir));
    load(sprintf('%s/forecast_label.mat',filename_all.data_dir));
    
    [~,model_ids] = ismember(opts.models, extractfield(model,'id'));
    
    idx = forecast(:,4)==opts.forecast_time & ismember(forecast(:,2),model_ids) & forecast_label>0;
    forecast = forecast(idx,:);
    hurricane_track = hurricane_track(forecast_label(idx),:);
    
    if opts.method == 1
        error.lon=forecast(:,5)-hurricane_track(:,3);
        error.lat=forecast(:,6)-hurricane_track(:,4);
        error.dis=get_distance(forecast(:,5),forecast(:,6),hurricane_track(:,3),hurricane_track(:,4));
    elseif opts.method == 2
        forecast_ids = unique(forecast(:,[1,3]), 'rows');
        for h=1:size(forecast_ids,1)
            idx = find(forecast(:,1)==forecast_ids(h,1) & forecast(:,3)==forecast_ids(h,2));
            error.lon(h) = median(forecast(idx,5))-hurricane_track(idx(1),3);
            error.lat(h) = median(forecast(idx,6))-hurricane_track(idx(1),4);
            dis=get_distance(forecast(idx,5),forecast(idx,6),hurricane_track(idx,3),hurricane_track(idx,4));
            error.dis(h) = median(dis);
        end
    elseif opts.method == 3
        forecast_ids = unique(forecast(:,[1,3]), 'rows');
        for h=1:size(forecast_ids,1)
            idx = find(forecast(:,1)==forecast_ids(h,1) & forecast(:,3)==forecast_ids(h,2));
            error.lon(h) = min(forecast(idx,5))-hurricane_track(idx(1),3);
            error.lat(h) = min(forecast(idx,6))-hurricane_track(idx(1),4);
            dis=get_distance(forecast(idx,5),forecast(idx,6),hurricane_track(idx,3),hurricane_track(idx,4));
            error.dis(h) = min(dis);
        end
    end
    
    fprintf('---------- %s / End ----------\n', process);

end

