function plot_forecast_topk_from_t(opts)
%GET_STAT Summary of this function goes here
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

    process = 'Get win rate of models';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/forecast_tensor_%d_%d.mat',filename_all.data_dir,opts.t,opts.beta));
    load(sprintf('%s/hurricane.mat',filename_all.data_dir));
    load(sprintf('%s/model.mat',filename_all.data_dir));
    
    num = numel(forecast_tensor);
    num_model = length(opts.models);
    
    top=zeros(num_model,8,8);
    top_all=zeros(num_model,8,8);
    
    t1=clock;
    for h=1:num
        if mod(h,20)==0
            t2=clock;
            fprintf('%s / Runs:%d/%d / Timeleft:%s\n', process, h, num, get_timeleft(h,num,t1,t2));
        end
        fc=forecast_tensor(h);
        num_model = length(fc.models);
        k=floor(opts.k*num_model);
        if k<1
            continue;
        end
        [~,idx]=ismember(fc.models, opts.models);
        for t=1:size(fc.X,4)
            dis_all=-ones(num_model,8);
            flag=false(8,1);
            for tau=1:size(fc.X,3)
                if t<=tau
                    continue;
                end
                X=fc.X(:,:,tau,t-tau);
                Y=fc.Y(:,t);
                if isempty(find(X==-1000)) && isempty(find(Y==-1000))
                    dis=get_distance(X,Y');
                    dis_all(:,tau)=dis;
%                     [~,idx]=sort(dis);
%                     top(idx(1:opts.k),tau)=top(idx(1:opts.k),tau)+1;
                    flag(tau)=true;
                end
            end
            for tau1=1:8
                for tau2=1:8
                    if flag(tau1) && flag(tau2)
                        dis1=dis_all(:,tau1);
                        dis2=dis_all(:,tau2);
                        [~,idx1]=sort(dis1);
                        [~,idx2]=sort(dis2);
                        idx3=intersect(idx1(1:k),idx2(1:k));
                        top(idx(idx3),tau1,tau2)=top(idx(idx3),tau1,tau2)+1;
                        top_all(idx(idx1(1:k)),tau1,tau2)=top_all(idx(idx1(1:k)),tau1,tau2)+1;
                    end
                end
            end
        end
    end
    top=squeeze(sum(top,1));
    top_all=squeeze(sum(top_all,1));
    top=top./top_all
    figure;
    imagesc(top');
    colorbar;
    caxis([0 1])
    title(['P(rank \leq ', num2str(opts.k), ',\tau_2 | rank \leq ', num2str(opts.k), ',\tau_1) for model forecasts AP 01 to 20']);
    xlabel('Lead time \tau_1');
    ylabel('Lead time \tau_2')
    
    fprintf('---------- %s / End ----------\n', process);

end

