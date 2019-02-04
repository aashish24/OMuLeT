function get_forecast_online_PA(opts)
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

    process = 'Run online multi-task forecasting';
    fprintf('---------- %s / Begin ----------\n', process);
    
%     load(sprintf('%s/forecast.mat',filename_all.data_dir));
%     load(sprintf('%s/model.mat',filename_all.data_dir));
%     load(sprintf('%s/best_track.mat',filename_all.data_dir));
    load(sprintf('%s/train_test_idx.mat',filename_all.data_dir));
    filename=sprintf('forecast_tensor_%d_%d',opts.t,opts.beta);
    load(sprintf('%s/%s.mat',filename_all.data_dir,filename));
    
%     [~,model_ids] = ismember(opts.models, extractfield(model,'id'));
    Omega = ones(length(opts.models),1);
    
    t1=clock;
    % num = numel(forecast_tensor);
    idx_all=[train_idx,vali_idx,test_idx];
    num = length(idx_all);
    O_all=zeros(num,length(opts.models));
    for p=1:num
        h=idx_all(p);
        if mod(p,20)==0
            t2=clock;
            fprintf('%s / Runs:%d/%d / Timeleft:%s\n', process, p, num, get_timeleft(p,num,t1,t2));
        end
        n = length(forecast_tensor(h).models);
        [~, idx_models] = ismember(forecast_tensor(h).models, opts.models);
        O = Omega(idx_models);
        ratio=sum(O);
        O = O/ratio;  
        W_r = O;
        for t=1:size(forecast_tensor(h).X,4)
            W = W_r;
            for t_r=max(1,t-opts.beta):t-1
                idx=sum(forecast_tensor(h).X_flag(:,:,t_r),2);
                if sum(idx)==0
                    if t_r == max(1,t-opts.beta+1)
                        W_r=W;
                    end
                    continue;
                end
                for tau=1:opts.alpha
                    X_flag=forecast_tensor(h).X_flag(:,tau,t_r);
                    if forecast_tensor(h).label(tau,t_r)>0 && sum(X_flag)>=opts.models_min && sum(W(X_flag))>0
                        r=1/sum(W(X_flag));
                        X=forecast_tensor(h).X(:,:,tau,t_r);
                        X(:,~X_flag)=0;
                        L=forecast_tensor(h).label(tau,t_r);
                        Y=forecast_tensor(h).Y(:,L);
                        X=[X(1,:); X(2,:)*cosd(Y(1))];
                        Y=[Y(1); Y(2)*cosd(Y(1))];
                        Z=r*X*W;
                        l=abs(Z-Y)-opts.epsilon;
                        l(l<=opts.epsilon)=0;
                        s=sign(Y-Z);
                        tao=l./sum((r*(X-Y)).^2,2);
                        dW=sum(s.*tao.*(r*(X-Y)))';
                        dW(~X_flag)=0;
                        W=W+dW;
%                         Y
%                         Z
%                         r*X*W
                        W(W<0)=0;
                        W=W/sum(W);
                    end
                end
                if t_r == max(1,t-opts.beta+1)
                    W_r=W;
                end
            end
            % predict
            for tau=1:opts.beta
                X_flag=forecast_tensor(h).X_flag(:,tau,t);
                if forecast_tensor(h).label(tau,t)>0 && sum(X_flag)>=opts.models_min && sum(W(X_flag))>0
                    r=1/sum(W(X_flag));
                    X=forecast_tensor(h).X(:,:,tau,t);
                    X(:,~X_flag)=0;
                    forecast_tensor(h).predict(:,tau,t)=r*X*W;
%                     fprintf('%.2f ',get_distance(forecast_tensor(h).predict(:,tau,t)',forecast_tensor(h).Y(:,t+tau)'));
                else
%                     fprintf('NA ');
                end
            end
%             fprintf('\n');
        end
        % renew Omega
        [~, idx_models] = ismember(forecast_tensor(h).models, opts.models);
        % O = Omega(idx_models);
        O = (1-opts.rho)*O+opts.rho*W;
        O(O<=0)=0;
        O=O./sum(O);
        Omega(idx_models)=O*ratio;
        O_all(p,:)=Omega;
%         idx=U<0;
%         rho=min(-O(idx)./U(idx));
%         if isempty(rho)
%             rho=opts.rho;
%         else
%             rho=min(opts.rho,rho);
%         end
%         O = O+rho*U;
    end
%     Omega'
    save(sprintf('%s/%s.mat',filename_all.data_dir,filename),'forecast_tensor');
end

