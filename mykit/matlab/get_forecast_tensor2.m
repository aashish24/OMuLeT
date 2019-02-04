function [train, test] = get_forecast_tensor(opts)
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

    process = 'Get forecast_tensor';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/forecast.mat',filename_all.data_dir));
    load(sprintf('%s/model.mat',filename_all.data_dir));
    load(sprintf('%s/best_track.mat',filename_all.data_dir));
    
%     [~,model_ids] = ismember(opts.models, extractfield(model,'id'));

    model_nhc=1;
    
    forecast_tensor=[];
    t1=clock;
    num = numel(forecast);
    for h=1:num
        if mod(h,20)==0
            t2=clock;
            fprintf('%s / Runs:%d/%d / Timeleft:%s\n', process, h, num, get_timeleft(h,num,t1,t2));
        end
        idx = forecast{h}(:,3)<=opts.beta*opts.t & forecast{h}(:,3)>0 & mod(forecast{h}(:,2),opts.t/24)==0 & mod(forecast{h}(:,3),opts.t)==0 & ismember(forecast{h}(:,1),opts.models);
        idx_nhc = forecast{h}(:,3)<=opts.beta*opts.t & forecast{h}(:,3)>0 & mod(forecast{h}(:,2),opts.t/24)==0 & mod(forecast{h}(:,3),opts.t)==0 & forecast{h}(:,1)==model_nhc;
        if sum(idx)==0
            continue;
        end
        fc_b = forecast{h}(idx,:);
        fc_b_nhc = forecast{h}(idx_nhc,:);
%         ht_b = best_track{h}(forecast_label{h}(idx),:);
%         idx = fc_b(:,3)<=opts.alpha*opts.t;
%         fc_a = fc_b(idx,:);
%         ht_a = ht_b(idx,:);
        t_min = min(fc_b(:,2));
        t_max = max(fc_b(:,2));
        t_all = t_min:(opts.t/24):t_max;
        t_num = length(t_all);
        flag = true(1,length(t_all));
        
        model_ids = sort(unique(fc_b(:,1)));
        n = length(model_ids);
        forecast_tensor(h).models = model_ids;
        forecast_tensor(h).X = ones(n,4,opts.beta+1,t_num)*-1000;
        forecast_tensor(h).nhc = ones(4,opts.beta+1,t_num)*-1000;
        forecast_tensor(h).Y = ones(4,t_num+opts.beta)*-1000;
        forecast_tensor(h).label = zeros(opts.beta,t_num);
        forecast_tensor(h).predict = ones(4,opts.beta,t_num)*-1000; 
        forecast_tensor(h).time = t_all;
%         forecast_tensor(h).X = ones(t_num,opts.beta+1,n,2)*-1000;
%         forecast_tensor(h).Y = ones(t_num+opts.beta,2)*-1000;
%         forecast_tensor(h).label = zeros(t_num,opts.beta);
%         forecast_tensor(h).forecast = ones(t_num,opts.beta,n,2)*-1000;

        % get Y
        bt=best_track{h};
        for p = 1:size(bt,1)
            t = (bt(p,1)-t_min)*4 + 1;
            if abs(floor(t)-t)<0.01 && t>0 && t<t_num+opts.beta
                forecast_tensor(h).Y(:,t)=bt(p,2:5);
            end
        end
        
        % get X
        for p = 1:size(fc_b,1)
            [~,m] = ismember(fc_b(p,1),model_ids);
            t = (fc_b(p,2)-t_min)*4 + 1;
            tau = fc_b(p,3)/opts.t + 1;
            if abs(floor(t)-t)<0.01 && abs(floor(tau)-tau)<0.01
                forecast_tensor(h).X(m,:,tau,t)=fc_b(p,4:7);
            end
        end
        for t=1:size(forecast_tensor(h).X,4)
            forecast_tensor(h).X(:,1,1,t)=forecast_tensor(h).Y(1,t);
            forecast_tensor(h).X(:,2,1,t)=forecast_tensor(h).Y(2,t);
            forecast_tensor(h).X(:,3,1,t)=forecast_tensor(h).Y(3,t);
            forecast_tensor(h).X(:,4,1,t)=forecast_tensor(h).Y(4,t);
        end
        
        % get nhc
        for p = 1:size(fc_b_nhc,1)
            t = (fc_b_nhc(p,2)-t_min)*4 + 1;
            tau = fc_b_nhc(p,3)/opts.t + 1;
            if t>0 && abs(floor(t)-t)<0.01 && abs(floor(tau)-tau)<0.01
                forecast_tensor(h).nhc(:,tau,t)=fc_b_nhc(p,4:7);
            end
        end
        for t=1:size(forecast_tensor(h).nhc,3)
            if t<=size(forecast_tensor(h).Y,2)
                forecast_tensor(h).nhc(1,1,t)=forecast_tensor(h).Y(1,t);
                forecast_tensor(h).nhc(2,1,t)=forecast_tensor(h).Y(2,t);
                forecast_tensor(h).nhc(3,1,t)=forecast_tensor(h).Y(3,t);
                forecast_tensor(h).nhc(4,1,t)=forecast_tensor(h).Y(4,t);
            end
        end        
        
        % randomize all ensemble members
%         for t=1:t_num
%             for tau=1:opts.beta+1
%                 forecast_tensor(h).X(:,:,tau,t)=forecast_tensor(h).X(randperm(numel(model_ids)),:,tau,t);
%             end
%         end
        
        % Interpolation for X
        for t = 1:size(forecast_tensor(h).X,4)
            for m = 1:size(forecast_tensor(h).X,1)
                X = squeeze(forecast_tensor(h).X(m,:,:,t));
                X_missing = sum(X==-1000);
                idx = find(X_missing==0);
                if sum(X_missing)>0 && length(idx)>=2
                    for p=1:length(idx)-1
                        for ii = idx(p)+1:idx(p+1)-1
                            forecast_tensor(h).X(m,:,ii,t)=(forecast_tensor(h).X(m,:,idx(p),t)*(idx(p+1)-ii)+forecast_tensor(h).X(m,:,idx(p+1),t)*(ii-idx(p)))/(idx(p+1)-idx(p));
                        end
                    end
                end
            end
        end
        forecast_tensor(h).X = forecast_tensor(h).X(:,:,2:end,:);
        
        % Interpolation for nhc
        for t = 1:size(forecast_tensor(h).nhc,3)
            X = squeeze(forecast_tensor(h).nhc(:,:,t));
            X_missing = sum(X==-1000);
            idx = find(X_missing==0);
            if sum(X_missing)>0 && length(idx)>=2
                for p=1:length(idx)-1
                    for ii = idx(p)+1:idx(p+1)-1
                        forecast_tensor(h).nhc(:,ii,t)=(forecast_tensor(h).nhc(:,idx(p),t)*(idx(p+1)-ii)+forecast_tensor(h).nhc(:,idx(p+1),t)*(ii-idx(p)))/(idx(p+1)-idx(p));
                    end
                end
            end
        end
        forecast_tensor(h).nhc = forecast_tensor(h).nhc(:,2:end,:);
        
%         % get maxinum complete part of X
%         forecast_bool=reshape(forecast_tensor(h).X,[m,size(forecast_tensor(h).X,4)*size(forecast_tensor(h).X,3)*size(forecast_tensor(h).X,2)])~=-1000;
%         idx=false(m,1);
%         count=0;
%         while(true)
%             m_add_max=0;
%             for m_add=1:m
%                 if idx(m_add)
%                     continue;
%                 end
%                 idx2=idx;
%                 idx2(m_add)=true;
%                 count2=sum(sum(forecast_bool(idx2,:)==0,1)==0)*sum(idx2);
%                 if count2>count
%                     count=count2;
%                     m_add_max=m_add;
%                 end
%             end
%             if m_add_max==0
%                 break;
%             else
%                 idx(m_add_max)=true;
%             end
%         end
%         forecast_tensor(h).X=forecast_tensor(h).X(idx,:,:,:);
%         forecast_tensor(h).models=forecast_tensor(h).models(idx);
        
        % get label
        for t = 1:size(forecast_tensor(h).X,4)
            for tau = 1:size(forecast_tensor(h).X,3)
                if forecast_tensor(h).Y(1,t+tau)~=-1000 && forecast_tensor(h).Y(2,t+tau)~=-1000
                    forecast_tensor(h).label(tau,t)=t+tau;
                else
                    forecast_tensor(h).label(tau,t)=-1;
                end
                if ~isempty(find(forecast_tensor(h).X(:,1:2,tau,t)==-1000,1))
                    forecast_tensor(h).label(tau,t)=-2;
                end
            end
        end
    end

    filename=sprintf('forecast_tensor_%d_%d',opts.t,opts.beta);
    save(sprintf('%s/%s.mat',filename_all.data_dir,filename),'forecast_tensor');
    
%     size_A = opts.s*opts.alpha*opts.p*opts.f;
%     size_B = opts.s*opts.beta*opts.p*opts.f;
%     size_Y = opts.s*opts.f;
%     size_L = opts.s*opts.beta*opts.f;
%     size_l = opts.beta*opts.f;
%     train_A = reshape(train.A, num_train, size_A);
%     train_B = reshape(train.B, num_train, size_B);
%     train_Y = reshape(train.Y, num_train, size_Y);
%     train_L = reshape(train.label, num_train, size_L);
%     train_l = reshape(train.l, num_train, size_l);
%     test_A = reshape(test.A, num_test, size_A);
%     test_B = reshape(test.B, num_test, size_B);
%     test_Y = reshape(test.Y, num_test, size_Y);
%     test_L = reshape(test.label, num_test, size_L);
%     test_l = reshape(test.l, num_test, size_l);
%     
%     csvwrite(sprintf('%s/%s/train_A.csv',filename_all.data_dir,folder),train_A);
%     csvwrite(sprintf('%s/%s/train_B.csv',filename_all.data_dir,folder),train_B);
%     csvwrite(sprintf('%s/%s/train_Y.csv',filename_all.data_dir,folder),train_Y);
%     csvwrite(sprintf('%s/%s/train_L.csv',filename_all.data_dir,folder),train_L);
%     csvwrite(sprintf('%s/%s/train_l.csv',filename_all.data_dir,folder),train_l);    
%     csvwrite(sprintf('%s/%s/test_A.csv',filename_all.data_dir,folder),test_A);
%     csvwrite(sprintf('%s/%s/test_B.csv',filename_all.data_dir,folder),test_B);
%     csvwrite(sprintf('%s/%s/test_Y.csv',filename_all.data_dir,folder),test_Y);
%     csvwrite(sprintf('%s/%s/test_L.csv',filename_all.data_dir,folder),test_L);
%     csvwrite(sprintf('%s/%s/test_l.csv',filename_all.data_dir,folder),test_l);       
    
    fprintf('---------- %s / End ----------\n', process);
end

