function get_model_linear(opts)
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
   
    load(sprintf('%s/raw/best_track_2010.mat',filename_all.data_dir));

    num=numel(best_track);
    X=[];
    Y=[];
    t1=clock;
    for p=1:num
        if mod(p,100)==0
            t2=clock;
            fprintf('%s / Runs:%d/%d / Timeleft:%s\n', process, p, num, get_timeleft(p,num,t1,t2));
        end
        bt=best_track{p};
        for t=1:size(bt,1)-7
%             X=[X; reshape(bt(t:t+3,2:3),1,8)];
%             Y=[Y; reshape(bt(t+4:t+7,2:3),1,8)];
            X=[X; bt(t:t+3,2)'-bt(t:t+3,2); bt(t:t+3,3)'];
            Y=[Y; bt(t+4:t+7,2)'; bt(t+4:t+7,3)'];            
        end
    end
    model=inv(X'*X)*X'*Y;
    save(sprintf('%s/linear.mat',filename_all.data_dir),'model');
    load(sprintf('%s/linear.mat',filename_all.data_dir));
    
    load(sprintf('%s/raw/best_track.mat',filename_all.data_dir));
    X=[];
    Y=[];
    t1=clock;
    num=numel(best_track);
    for p=1:num
        if mod(p,100)==0
            t2=clock;
            fprintf('%s / Runs:%d/%d / Timeleft:%s\n', process, p, num, get_timeleft(p,num,t1,t2));
        end
        bt=best_track{p};
        data=[];
        for t=1:size(bt,1)-7
            X=bt(t:t+3,2:3);
            Y=X'*model;
            Y=Y';
            data=[data; ones(4,1)*158 ones(4,1)*bt(t+3,1) (12:12:48)' Y ones(4,1)*-1000 ones(4,1)*-1000];
        end
        forecast{p}=data;
    end
    save(sprintf('%s/raw/forecast_linear.mat',filename_all.data_dir),'forecast');
    
    fprintf('---------- %s / End ----------\n', process);
end

