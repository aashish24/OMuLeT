function get_forecast_ens(opts)
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

    process = 'Get ensemble median and mean';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/model.mat',filename_all.data_dir));
    load(sprintf('%s/forecast.mat',filename_all.data_dir));
    
    num=numel(model);
    
    model(num+1).id=[opts.model_ens{1}];
    model(num+1).type=3;
    model(num+2).id=[opts.model_ens{2}];
    model(num+2).type=3;
    [~,model_ids] = ismember(opts.models, extractfield(model,'id'));
    for h=1:numel(forecast)
        idx = ismember(forecast{h}(:,1),model_ids);
        fc = forecast{h}(idx,:);
        [~, ia, ic] = unique(fc(:,[2 3]), 'rows');
        for ii = 1:length(ia)
            idx = ic==ii;
            fc_t = median(fc(idx,:),1);
            fc_t(1)=num+1;
            forecast{h} = [forecast{h}; fc_t];
        end
        for ii = 1:length(ia)
            idx = ic==ii;
            fc_t = mean(fc(idx,:),1);
            fc_t(1)=num+2;
            forecast{h} = [forecast{h}; fc_t];
        end
    end
    
    save(sprintf('%s/model.mat',filename_all.data_dir),'model');
    save(sprintf('%s/forecast.mat',filename_all.data_dir),'forecast');
    
    fprintf('---------- %s / End ----------\n', process);
end

