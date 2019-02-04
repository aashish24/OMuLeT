function get_forecast_online_ORION(opts)
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
        U = O;
        V = zeros(n,opts.beta);
        % task relationships:
        T=opts.beta;
        S = zeros(T, T);
        for i = 1:T
            for j = 1:T
                if i==j+1 || i==j-1
                    S(i,j) = 1;
                elseif i == j
                    S(i,j) = -1;
                end
            end
        end
        S(1,1) = 0;
        S(T, T) = 0;
        U_r = U;
        V_r = V;
        for t=1:size(forecast_tensor(h).X,4)
            U = U_r;
            V = V_r;
            for t_r=max(1,t-opts.beta):t-1
                idx=sum(forecast_tensor(h).X_flag(:,:,t_r),2);
                if sum(idx)==0
                    if t_r == max(1,t-opts.beta+1)
                        U_r=U;
                        V_r=V;
                    end
                    continue;
                end
                X1=[];
                Y1=[];
                X2=[];
                Y2=[];
                L1=[];
                L2=[];
                for tau=1:opts.alpha
                    X_flag=forecast_tensor(h).X_flag(:,tau,t_r);
                    W=U+V(:,tau);
                    if forecast_tensor(h).label(tau,t_r)>0 && sum(X_flag)>=opts.models_min && sum(W(X_flag))>0
                        r=1/sum(W(X_flag));
                        X=forecast_tensor(h).X(:,:,tau,t_r);
                        X(:,~X_flag)=0;
                        L=forecast_tensor(h).label(tau,t_r);
                        Y=forecast_tensor(h).Y(:,L);
                        X=[X(1,:); X(2,:)*cosd(Y(1))];
                        Y=[Y(1); Y(2)*cosd(Y(1))];
                        X=X*r;
                        X1=[X1;X(1,:)];
                        Y1=[Y1;Y(1)];
                        X2=[X2;X(2,:)];
                        Y2=[Y2;Y(2)];
                        L1=[L1;1];
                    else
                        X1=[X1;zeros(1,size(X,2))];
                        Y1=[Y1;0];
                        X2=[X2;zeros(1,size(X,2))];
                        Y2=[Y2;0];
                        L1=[L1;0];
                    end
                end
                [U, V]=ORION(U, V', L1, X1, Y1, opts.mu, opts.lambda, opts.beta2, opts.epsilon, S);
                V=V';
                [U, V]=ORION(U, V', L2, X2, Y2, opts.mu, opts.lambda, opts.beta2, opts.epsilon, S);
                V=V';
                if t_r == max(1,t-opts.beta+1)
                    U_r=U;
                    V_r=V;
                end
            end
            % predict
            for tau=1:opts.beta
                X_flag=forecast_tensor(h).X_flag(:,tau,t);
                if forecast_tensor(h).label(tau,t)>0 && sum(X_flag)>=opts.models_min
                    W=U+V(:,tau);
%                     W'
                    r=1/sum(W(X_flag));
                    X=forecast_tensor(h).X(:,:,tau,t);
                    X(:,~X_flag)=0;
                    X=X*r;
                    forecast_tensor(h).predict(:,tau,t)=X*W;
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
        O = (1-opts.rho)*O+opts.rho*U;
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

