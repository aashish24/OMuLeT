function get_dataset_X(opts)
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
    load(sprintf('%s/model.mat',filename_all.data_dir));
    load(sprintf('%s/best_track.mat',filename_all.data_dir));
    load(sprintf('%s/forecast_label.mat',filename_all.data_dir));
    load(sprintf('%s/train_test_idx.mat',filename_all.data_dir));
    
    [~,model_ids] = ismember(opts.models, extractfield(model,'id'));
    
    train.X=[];
    train.y=[];
    test.X=[];
    test.y=[];

    for p=1:length(train_idx)
        h=train_idx(p);
        idx = forecast{h}(:,3)==opts.forecast_time & ismember(forecast{h}(:,1),model_ids) & forecast_label{h}>0;
        fc = forecast{h}(idx,:);
        ht = best_track{h}(forecast_label{h}(idx),:);
        t = unique(fc(:,2));
        num = 0;
        x = [];
        y = [];
        for ii=1:length(t)
            idx = find(fc(:,2)==t(ii));
        	if sum(ismember(fc(idx,1),model_ids))==length(model_ids)
                num = num+1;
                if opts.sort
                    train.X = [train.X; reshape(sort(fc(idx,4:5)),1,length(model_ids)*2)];
                else
                    train.X = [train.X; reshape(fc(idx,4:5),1,length(model_ids)*2)];
                end
                train.y = [train.y; ht(idx(1),2:3)];
            end
        end
    end
    for p=1:length(test_idx)
        h=test_idx(p);
        idx = forecast{h}(:,3)==opts.forecast_time & ismember(forecast{h}(:,1),model_ids) & forecast_label{h}>0;
        fc = forecast{h}(idx,:);
        ht = best_track{h}(forecast_label{h}(idx),:);
        t = unique(fc(:,2));
        num = 0;
        x = [];
        y = [];
        for ii=1:length(t)
            idx = find(fc(:,2)==t(ii));
        	if sum(ismember(fc(idx,1),model_ids))==length(model_ids)
                num = num+1;
                if opts.sort
                    test.X = [test.X; reshape(sort(fc(idx,4:5)),1,length(model_ids)*2)];
                else
                    test.X = [test.X; reshape(fc(idx,4:5),1,length(model_ids)*2)];
                end
                test.y = [test.y; ht(idx(1),2:3)];
            end
        end
    end
    
    filename=sprintf('dataset_%d_%d',opts.window_size,opts.forecast_time);
    save(sprintf('%s/%s.mat',filename_all.data_dir,filename),'train','test');
    
    fprintf('---------- %s / End ----------\n', process);
end

