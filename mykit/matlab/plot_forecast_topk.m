function plot_forecast_topk(opts)
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
    
    top=zeros(num_model,8);
    
    t1=clock;
    for h=1:num
        if mod(h,20)==0
            t2=clock;
            fprintf('%s / Runs:%d/%d / Timeleft:%s\n', process, h, num, get_timeleft(h,num,t1,t2));
        end
        fc=forecast_tensor(h);
        for t=1:size(fc.X,4)
            for tau=1:size(fc.X,3)
                X=fc.X(:,:,tau,t);
                Y=fc.Y(:,t+tau);
                if isempty(find(X==-1000)) && isempty(find(Y==-1000))
                    dis=get_distance(X,Y');
                    [~,idx]=sort(dis);
                    top(idx(1:opts.k),tau)=top(idx(1:opts.k),tau)+1;
                end
            end
        end
    end
    top=sum(top,2);
    top=top/sum(top)*100;
    bar(1:20,top);
    title(sprintf("Top %d rate of model AP 01 to 20",opts.k));
    xlabel("Model number");
    ylabel("Rate (%)")
    set(gca,'XTick',1:1:20);
    
    
    fprintf('---------- %s / End ----------\n', process);

end

