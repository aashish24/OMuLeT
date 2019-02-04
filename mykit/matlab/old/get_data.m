function data = get_data(opts)
%GET_HURRICANE_TRACK Summary of this function goes here
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

    process = 'Get LSTM data';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/forecast.mat',filename_all.data_dir));
    load(sprintf('%s/model.mat',filename_all.data_dir));
    load(sprintf('%s/hurricane_track.mat',filename_all.data_dir));
    load(sprintf('%s/forecast_label.mat',filename_all.data_dir));
    
    [~,model_ids] = ismember(opts.models, extractfield(model,'id'));
    
    idx = forecast(:,4)==opts.forecast_time & ismember(forecast(:,2),model_ids) & forecast_label>0;
    forecast = forecast(idx,:);
    hurricane_track = hurricane_track(forecast_label(idx),:);
    
    hurricane_ids = unique(forecast(:,1));
    
    data_num=0;
%     lstm_data.lon.X=[];
%     lstm_data.lat.X=[];
%     lstm_data.lon.Y=[];
%     lstm_data.lat.Y=[];
    X=[];
    y=[];
    for h = 1:length(hurricane_ids)
        idx = forecast(:,1)==hurricane_ids(h);
        fc = forecast(idx,:);
        ht = hurricane_track(idx,:);
        
        current_time = unique(fc(:,3));
        for t = 1:length(current_time)
            idx = fc(:,3)==current_time(t);
            fc2 = fc(idx,:);
            ht2 = ht(idx,:);
            if size(fc2,1)==numel(opts.models)
                [~, idx_s]=sort(fc2(:,2));
                fc2 = fc2(idx_s,:);
                ht2 = ht2(idx_s,:);
                X=[X; fc2(:,5)'];
                y=[y; ht2(1,3)'];
            end
        end
    end
    
    save(sprintf('%s/data.mat',filename_all.data_dir),'X','y');
%     csvwrite(sprintf('%s/lstm_data.csv',filename_all.data_dir),lstm_data);
    
    fprintf('---------- %s / End ----------\n', process);
end

