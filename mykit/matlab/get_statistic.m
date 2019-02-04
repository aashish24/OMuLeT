function M = get_statistic(opts)
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
    
    [~,model_ids] = ismember(opts.models, extractfield(model,'id'));
    
    num=12;
    M=zeros(2,2,num,num);

    for h=1:numel(forecast)
        idx = ismember(forecast{h}(:,1),model_ids) & forecast_label{h}>0;
        if sum(idx)==0
            continue;
        end
        fc=forecast{h}(idx,:);
        bt=best_track{h}(forecast_label{h}(idx),:);
        t1=min(fc(:,2));
        t2=max(fc(:,2));
        for t=t1:0.25:t2
            for ii=1:num
                for jj=1:num
                    idx1 = find(fc(:,2)==t &fc(:,3)==ii*6);
                    idx2 = find(fc(:,2)==t+ii*0.25 &fc(:,3)==jj*6);
                    if length(idx1)>0 && length(idx2)>0
                        M(1,1,ii,jj)=M(1,1,ii,jj)+1;
                        M(1,2,ii,jj)=M(1,2,ii,jj)+1;
                        fc1=median(fc(idx1,[4 5]));
                        fc2=median(fc(idx2,[4 5]));
                        bt1=bt(idx1(1),[2,3]);
                        bt2=bt(idx2(1),[2,3]);
                        v=(fc1-bt1).*(fc2-bt2);
                        if v(1)>=0
                            M(2,1,ii,jj)=M(2,1,ii,jj)+1;
                        end
                        if v(2)>=0
                            M(2,2,ii,jj)=M(2,2,ii,jj)+1;
                        end
                    end
                end
            end
        end
    end
        
    
    fprintf('---------- %s / End ----------\n', process);
end

