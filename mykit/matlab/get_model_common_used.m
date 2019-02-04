function get_model_common_used(opts)
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

    process = 'Get plot for forecast with different lead time';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/forecast_tensor_6_8.mat',filename_all.data_dir));
    load(sprintf('%s/hurricane.mat',filename_all.data_dir));
    load(sprintf('%s/model.mat',filename_all.data_dir));
    
    model_counts=zeros(numel(model),2);
    for h=1:numel(forecast_tensor)
        fc=forecast_tensor(h);
        num_model=size(fc.X,1);
        model_ids=fc.models;
        for t=1:size(fc.X,4)
            for tau=1:size(fc.X,3)
                fc2=fc.X(:,:,tau,t);
                idx=sum(fc2~=-1000,2)==2;
                model_counts(model_ids(idx),1)=model_counts(model_ids(idx),1)+1;
                model_counts(model_ids,2)=model_counts(model_ids,2)+1;
            end
        end
    end
    
    fprintf('---------- %s / End ----------\n', process);

end

