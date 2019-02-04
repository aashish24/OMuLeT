function get_model_select(opts)
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
    
    load(sprintf('%s/hurricane.mat',filename_all.data_dir));
    load(sprintf('%s/model.mat',filename_all.data_dir));
    load(sprintf('%s/forecast.mat',filename_all.data_dir));
    hm=zeros(numel(hurricane),numel(model));
    for h=1:numel(forecast)
        fc=forecast{h};
        idx=mod(fc(:,3),6)==0;
        fc=fc(idx,:);
        hm(h,:)=histcounts(fc(:,1),'BinWidth',1,'BinLimits',[1 numel(model)+1]);
    end
    show=sum(hm>0);
    rate=sum(hm)./sum(hm>0);
    rate(sum(hm)==0)=0;
%    hm(:,extractfield(model,'interval')~=1)=0;
%     hm(extractfield(hurricane,'location')~=2,:)=0;
    model_select=[];
    for s=1:50
        [r,idx]=max(rate);
        fprintf('%s %d %f\n',model(idx).id,idx,r);
        rate(idx)=0;
        model_select{s}=model(idx).id;
    end
    
    save(sprintf('%s/model_select.mat',filename_all.data_dir),'model_select');
    
    fprintf('---------- %s / End ----------\n', process);
end

