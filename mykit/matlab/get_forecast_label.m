function forecast_label = get_forecast_label(opts)
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

    process = 'Get forecast label';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/forecast.mat',filename_all.data_dir));
    load(sprintf('%s/best_track.mat',filename_all.data_dir));
    
    for h=1:numel(best_track)
        [~, label] = ismember(forecast{h}(:,2)+forecast{h}(:,3)/24, best_track{h}(:,1));
        forecast_label{h}=label;
%         idx=find(label>0);
%         if max(forecast{h}(idx,4)-best_track{h}(label(idx),2))>100
%             a=forecast{h}(idx,4);
%             b=best_track{h}(label(idx),2);
%             c=forecast{h}(idx,3);
%             [a b c];
%             [~, idx2]=max(forecast{h}(idx,4)-best_track{h}(label(idx),2));
%             h
%             idx(idx2)
%        end
    end
    
    save(sprintf('%s/forecast_label.mat',filename_all.data_dir),'forecast_label');
    fprintf('---------- %s / End ----------\n', process);
end

