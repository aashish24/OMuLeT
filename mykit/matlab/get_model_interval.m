function get_model_interval(opts)
%READKML Summary of this function goes here
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

    process = 'Get model interval';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/model.mat',filename_all.data_dir));
    load(sprintf('%s/forecast.mat',filename_all.data_dir));
    fc=[];
    for h=1:numel(forecast)
        fc=[fc;forecast{h}];
    end
    for m=1:numel(model)
        idx=fc(:,1)==m;
        interval=fc(idx,3);
        n6=sum(interval==6);
        n12=sum(interval==12);
        if n6==0 && n12==0
            model(m).interval=0;
        elseif n6>=n12*0.5
            model(m).interval=1;
        else
            model(m).interval=2;
        end
%         [n6 n12]
    end
    
    save(sprintf('%s/model.mat',filename_all.data_dir),'model');
    
    fprintf('---------- %s / End ----------\n', process);
end

