function [train_X, train_Y, test_X, test_Y] = get_lstm_nhc(opts)
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
    
    filename=sprintf('best_track',opts.t,opts.beta);
    load(sprintf('%s/raw/%s.mat',filename_all.data_dir,filename));   
    filename=sprintf('hurricane',opts.t,opts.beta);
    load(sprintf('%s/raw/%s.mat',filename_all.data_dir,filename));   
    t1=clock;
    num = numel(best_track);
    train_num=0;
%     test_num=0;
    for p=1:num
        h=p;
        if mod(p,100)==0
            t2=clock;
            fprintf('%s / Runs:%d/%d / Timeleft:%s\n', process, p, num, get_timeleft(p,num,t1,t2));
        end
        if opts.location~=0 && hurricane(h).location~=opts.location
            continue;
        end
        bt=best_track{h};
        for t=1:size(bt,1)-2*opts.beta+1
            X=bt(t:t+opts.beta*2-1,2:3);
            if sum(sum(X==-1000))==0
                train_num=train_num+1;
                train_X(train_num,:,:)=X(1:opts.beta,:);
                train_Y(train_num,:,:)=X(opts.beta+1:2*opts.beta,:);
            end
        end
    end
    
    load(sprintf('%s/train_test_idx.mat',filename_all.data_dir));
    filename=sprintf('best_track',opts.t,opts.beta);
    load(sprintf('%s/%s.mat',filename_all.data_dir,filename));   
    filename=sprintf('hurricane',opts.t,opts.beta);
    load(sprintf('%s/%s.mat',filename_all.data_dir,filename));   
    t1=clock;
    % num = numel(forecast_tensor);
    idx_all=[train_idx,vali_idx,test_idx];
    tt=length([train_idx,vali_idx]);
    num = length(idx_all);
%     train_num=0;
    test_num=0;
    for p=1:num
        h=idx_all(p);
        if mod(p,20)==0
            t2=clock;
            fprintf('%s / Runs:%d/%d / Timeleft:%s\n', process, p, num, get_timeleft(p,num,t1,t2));
        end
        if opts.location~=0 && hurricane(h).location~=opts.location
            continue;
        end
        bt=best_track{h};
        for t=1:size(bt,1)-2*opts.beta+1
            X=bt(t:t+opts.beta*2-1,2:3);
            if sum(sum(X==-1000))==0
                if p<=tt
%                     train_num=train_num+1;
%                     train_X(train_num,:,:)=X(1:opts.beta,:);
%                     train_Y(train_num,:,:)=X(opts.beta+1:2*opts.beta,:);
                else
                    test_num=test_num+1;
                    test_X(test_num,:,:)=X(1:opts.beta,:);
                    test_Y(test_num,:,:)=X(opts.beta+1:2*opts.beta,:);
                end
            end
        end
    end
    
    filename=sprintf('lstm_data_%d_%d',opts.alpha,opts.beta);
    save(sprintf('%s/%s.mat',filename_all.data_dir,filename),'train_X', 'train_Y', 'test_X', 'test_Y');
    
    fprintf('---------- %s / End ----------\n', process);
end

