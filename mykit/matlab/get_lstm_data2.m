function lstm_data = get_lstm_data2(opts)
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
    
    idx = ismember(forecast(:,2),model_ids) & forecast_label>0;
    forecast = forecast(idx,:);
    hurricane_track = hurricane_track(forecast_label(idx),:);
    
    hurricane_ids = unique(forecast(:,1));
    
    data_num=0;
%     lstm_data.lon.X=[];
%     lstm_data.lat.X=[];
%     lstm_data.lon.Y=[];
%     lstm_data.lat.Y=[];
    lstm_data=[];
    for h = 1:length(hurricane_ids)
        idx = forecast(:,1)==hurricane_ids(h);
        fc = forecast(idx,:);
        ht = hurricane_track(idx,:);
        forecast_time = fc(:,3)+fc(:,4)/24;
        forecast_utime = unique(forecast_time);
        for t= 1:length(forecast_utime)
            idx = find(forecast_time==forecast_utime(t));
            if length(idx)>=opts.window_size;
                fc2 = fc(idx,:);
                ht2 = ht(idx,:);
                [~, idx_s]=sort(fc2(:,4));
                fc2 = fc2(idx_s,:);
                ht2 = ht2(idx_s,:);
                ldata=fliplr(fc2(1:opts.window_size,5:6)');
                lstm_data=[lstm_data; ldata(:)'];
            end
        end
    end
        
%         t = min(fc(:,3));
%         idx = fc(:,3)==t;
%         num = 0;
%         lon_x = [];
%         lat_x = [];
%         wind_x = [];
%         pre_x = [];
%         lon_y = [];
%         lat_y = [];
%         wind_y = [];
%         pre_y = [];
%         while sum(ismember(fc(idx,2),model_ids))==length(model_ids)
%             num = num+1;
%             lon_x = [lon_x fc(idx,5)];
%             lat_x = [lat_x fc(idx,6)];
%             wind_x = [wind_x fc(idx,7)];
%             pre_x = [pre_x fc(idx,8)];
%             lon_y = [lon_y ht(idx,3)];
%             lat_y = [lat_y ht(idx,4)];
%             wind_y = [wind_y fc(idx,5)];
%             pre_y = [pre_y ht(idx,6)];
%             t = t+opts.forecast_time/24;
%             idx = fc(:,3)==t;
%         end
% %         if num>=opts.window_size
% %             data_num = data_num+1;
% %             lstm_data.lon.X{data_num}=lon_x;
% %             lstm_data.lat.X{data_num}=lat_x;
% %             lstm_data.lon.Y{data_num}=lon_y;
% %             lstm_data.lat.Y{data_num}=lat_y;
% %             lstm_data_x{data_num}=lon_x(1,:)';
% %             lstm_data_y{data_num}=lon_y(1,:)';
% %         end
%         if num>=opts.window_size
%             for ii=1:num-opts.window_size+1
%                 data_num = data_num+1;
%                 ldata=[];
%                 for jj=ii:ii+opts.window_size-1
%                     ldata=[ldata lon_y(jj) lat_y(jj)];
%                 end
%                 lstm_data=[lstm_data; ldata];
%             end
%         end
%     end
    
    save(sprintf('%s/lstm_data.mat',filename_all.data_dir),'lstm_data');
    csvwrite(sprintf('%s/lstm_data.csv',filename_all.data_dir),lstm_data);
    
    fprintf('---------- %s / End ----------\n', process);
end

