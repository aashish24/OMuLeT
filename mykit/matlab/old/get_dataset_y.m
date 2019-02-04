function get_dataset_y(opts)
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
    
%     load(sprintf('%s/forecast.mat',filename_all.data_dir));
%     load(sprintf('%s/model.mat',filename_all.data_dir));
    load(sprintf('%s/best_track.mat',filename_all.data_dir));
%     load(sprintf('%s/forecast_label.mat',filename_all.data_dir));
    load(sprintf('%s/train_test_idx.mat',filename_all.data_dir));
    
%     [~,model_ids] = ismember(opts.models, extractfield(model,'id'));
    
    train=[];
    test=[];

    for p=1:length(train_idx)
        h=train_idx(p);
        ht=best_track{h};
        t = min(ht(:,1));
        num = 0;
        x = [];
        y = [];
        idx = find(ht(:,1)==t);
        while ~isempty(idx)
            num = num+1;
            y = [y; ht(idx,2:3)];
            t = t+0.25;
            idx = find(ht(:,1)==t);
        end
        if num>=opts.window_size
            for ii=1:num-opts.window_size+1
                data=[];
                for jj=ii:ii+opts.window_size-1
                    data=[data y(jj,:)];
                end
                train=[train; data];
            end
        end
    end
    for p=1:length(test_idx)
        h=test_idx(p);
        ht=best_track{h};
        t = min(ht(:,1));
        num = 0;
        x = [];
        y = [];
        idx = find(ht(:,1)==t);
        while ~isempty(idx)
            num = num+1;
            y = [y; ht(idx,2:3)];
            t = t+0.25;
            idx = find(ht(:,1)==t);
        end
        if num>=opts.window_size
            for ii=1:num-opts.window_size+1
                data=[];
                for jj=ii:ii+opts.window_size-1
                    data=[data y(jj,:)];
                end
                test=[test; data];
            end
        end
    end
    
    filename=sprintf('dataset_%d_%d',opts.window_size,opts.forecast_time);
    save(sprintf('%s/%s.mat',filename_all.data_dir,filename),'train','test');
    
    fprintf('---------- %s / End ----------\n', process);
end

