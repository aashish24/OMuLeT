function get_forecast_lr(opts)
% get ensemble median mean for AP and CP
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

    process = 'Get ensemble linear regression';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/forecast_tensor_6_8.mat',filename_all.data_dir));
    load(sprintf('%s/hurricane.mat',filename_all.data_dir));
    load(sprintf('%s/model.mat',filename_all.data_dir));
    load(sprintf('%s/train_test_idx.mat',filename_all.data_dir));
    
    num = numel(forecast_tensor);
    num_model = length(opts.models);
    
    error=zeros(num_model,8);
    count=zeros(num_model,8);
    
    forecast_train = forecast_tensor(train_idx);
    forecast_test = forecast_tensor(test_idx);
    
    train=[];
    test=[];
    
    num=numel(forecast_train);
    for h=1:num
        fc=forecast_train(h);
        for t=1:size(fc.X,4)
            for tau=1:size(fc.X,3)
                X=fc.X(:,:,tau,t);
                Y=fc.Y(:,t+tau);
                if isempty(find(X==-1000)) && isempty(find(Y==-1000))
                    if numel(train)<tau
                        train(tau).X=[];
                        train(tau).Y=[]; 
                    end
                    if opts.percentile
                        X=sort(X);
                    end
                    train(tau).X=[train(tau).X; ones(2,1) X'];
                    train(tau).Y=[train(tau).Y; Y];
                end
            end
        end
    end
    
    num=numel(forecast_test);
    for h=1:num
        fc=forecast_test(h);
        for t=1:size(fc.X,4)
            for tau=1:size(fc.X,3)
                X=fc.X(:,:,tau,t);
                Y=fc.Y(:,t+tau);
                if isempty(find(X==-1000)) && isempty(find(Y==-1000))
                    if numel(test)<tau
                        test(tau).X=[];
                        test(tau).Y=[];  
                    end
                    if opts.percentile
                        X=sort(X);
                    end
                    test(tau).X=[test(tau).X; ones(2,1) X'];
                    test(tau).Y=[test(tau).Y; Y];
                end
            end
        end
    end
    
    for tau=1:8
        w=inv(train(tau).X'*train(tau).X)*train(tau).X'*train(tau).Y;
        predict_test=test(tau).X*w;
        num=length(test(tau).Y)/2;
        dis = get_distance(reshape(predict_test,2,num)', reshape(test(tau).Y,2,num)');
        fprintf('%.2f & ',sqrt(mean(dis.^2)));
    end
    fprintf('\n');
    
    fprintf('---------- %s / End ----------\n', process);
end

