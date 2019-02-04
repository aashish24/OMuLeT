function M = get_statistic_win(opts)
%GET_best_track Summary of this function goes here
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

    process = 'Get dataset';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/forecast.mat',filename_all.data_dir));
    load(sprintf('%s/model.mat',filename_all.data_dir));
    load(sprintf('%s/best_track.mat',filename_all.data_dir));
    load(sprintf('%s/forecast_label.mat',filename_all.data_dir));
    
    M=zeros(numel(model),3);

    for h=1:numel(forecast)
        idx = forecast{h}(:,3)~=0 & forecast_label{h}>0;
        if sum(idx)==0
            continue;
        end
        fc=forecast{h}(idx,[1 3 4 5]);
        bt=best_track{h}(forecast_label{h}(idx),[1 2 3]);
        fc=[fc bt];
        [~, ia, ic]=unique(fc(:,[2 5]),'rows');
        for ii=1:max(ic)
            idx=ic==ii;
            p1=fc(idx,[3 4]);
            p2=fc(idx,[6 7]);
            m=fc(idx,1);
            dis=get_distance(p1,p2);
            [~, idx_min]=min(idx);
            m_best=m(idx_min);
            M(m,1)=M(m,1)+1;
            M(m_best,2)=M(m_best,2)+1;
            M(m_best,3)=M(m_best,3)+length(m);
%            length(m)
        end
    end
        
    
    fprintf('---------- %s / End ----------\n', process);
end

