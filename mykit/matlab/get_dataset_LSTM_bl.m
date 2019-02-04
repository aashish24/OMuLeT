function get_dataset_LSTM_bl(opts)
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
    train_csv.X=[];
    train_csv.y=[];
    test_csv.X=[];
    test_csv.y=[];

    num=0;
    for p=1:length(train_idx)
        h=train_idx(p);
        idx = forecast{h}(:,3)<=opts.forecast_time & mod(forecast{h}(:,3),6)==0 & ismember(forecast{h}(:,1),model_ids) & forecast_label{h}>0;
        if sum(idx)==0
            continue;
        end
        fc = forecast{h}(idx,:);
        ht = best_track{h}(forecast_label{h}(idx),:);
        [C,ia,ic] = unique(fc(:,[2 3]),'rows');
        fc2 = [];
        ht2 = [];
        for ii = 1:length(C)
            idx = find(ic==ii);
            fc2 = [fc2; fc(idx(1),[2 3]) median(fc(idx,4:end),1)];
            ht2 = [ht2; ht(idx(1),:)];
        end
        time=unique(fc2(:,1));
        s=opts.forecast_time/6+1;
        for t=1:numel(time)
            idx=fc2(:,1)==time(t);
            if sum(idx)==s
                num=num+1;
                train.X=[train.X; reshape(fc2(idx,[3:4]),1,s*2)];
                train.y=[train.y; reshape(ht2(idx,[2:3]),1,s*2)];
                train_csv.X=[train_csv.X; reshape(fc2(idx,[3:4])',1,s*2)];
                train_csv.y=[train_csv.y; reshape(ht2(idx,[2:3])',1,s*2)];
            end
        end
    end

    num=0;
    for p=1:length(test_idx)
        h=test_idx(p);
        idx = forecast{h}(:,3)<=opts.forecast_time & mod(forecast{h}(:,3),6)==0 & ismember(forecast{h}(:,1),model_ids) & forecast_label{h}>0;
        if sum(idx)==0
            continue;
        end
        fc = forecast{h}(idx,:);
        ht = best_track{h}(forecast_label{h}(idx),:);
        [C,ia,ic] = unique(fc(:,[2 3]),'rows');
        fc2 = [];
        ht2 = [];
        for ii = 1:length(C)
            idx = find(ic==ii);
            fc2 = [fc2; fc(idx(1),[2 3]) median(fc(idx,4:end),1)];
            ht2 = [ht2; ht(idx(1),:)];
        end
        time=unique(fc2(:,1));
        s=opts.forecast_time/6+1;
        for t=1:numel(time)
            idx=fc2(:,1)==time(t);
            if sum(idx)==s
                num=num+1;
                test.X=[test.X; reshape(fc2(idx,[3:4]),1,s*2)];
                test.y=[test.y; reshape(ht2(idx,[2:3]),1,s*2)];
                test_csv.X=[test_csv.X; reshape(fc2(idx,[3:4])',1,s*2)];
                test_csv.y=[test_csv.y; reshape(ht2(idx,[2:3])',1,s*2)];
            end
        end
    end
    
    filename=sprintf('dataset_LSTM_bl_%d_%d',opts.window_size,opts.forecast_time);
    save(sprintf('%s/%s.mat',filename_all.data_dir,filename),'train','test');
    
    csvwrite(sprintf('%s/%s_train_X.csv',filename_all.data_dir,filename),train_csv.X);
    csvwrite(sprintf('%s/%s_train_y.csv',filename_all.data_dir,filename),train_csv.y);
    csvwrite(sprintf('%s/%s_test_X.csv',filename_all.data_dir,filename),test_csv.X);
    csvwrite(sprintf('%s/%s_test_y.csv',filename_all.data_dir,filename),test_csv.y);
    
    fprintf('---------- %s / End ----------\n', process);
end

