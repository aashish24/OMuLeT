function get_hurricane_rm(opts)
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

    process = 'Removie hurricane without model forecast or best track';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/hurricane.mat',filename_all.data_dir));
    load(sprintf('%s/model.mat',filename_all.data_dir));
    load(sprintf('%s/forecast.mat',filename_all.data_dir));
    load(sprintf('%s/best_track.mat',filename_all.data_dir));
    flag=true(numel(hurricane),1);
    
    [~,model_ids] = ismember(opts.models, extractfield(model,'id'));
    for h=1:numel(hurricane)
        idx = ismember(forecast{h}(:,1),model_ids);
        if sum(idx)==0
            flag(h)=false;
        end
    end
    
    for h=1:numel(hurricane)
       if size(best_track{h},1)==0
           flag(h)=false;
       end
    end
    hurricane_all = extractfield(hurricane,'id');
    hurricane_rm = hurricane_all(~flag);
    hurricane=hurricane(flag);
    forecast=forecast(flag);
    best_track=best_track(flag);

    save(sprintf('%s/hurricane_rm.mat',filename_all.data_dir),'hurricane_rm');
    save(sprintf('%s/hurricane.mat',filename_all.data_dir),'hurricane');
    save(sprintf('%s/forecast.mat',filename_all.data_dir),'forecast');
    save(sprintf('%s/best_track.mat',filename_all.data_dir),'best_track');

    fprintf('---------- %s / End ----------\n', process);
end

