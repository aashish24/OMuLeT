function error = get_forecast_nhc_error_years(opts)
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

    process = 'Calculate prediction error';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/hurricane.mat',filename_all.data_dir));
%     load(sprintf('%s/forecast.mat',filename_all.data_dir));
%     load(sprintf('%s/model.mat',filename_all.data_dir));
%     load(sprintf('%s/best_track.mat',filename_all.data_dir));
    load(sprintf('%s/train_test_idx.mat',filename_all.data_dir));
    filename=sprintf('forecast_tensor_%d_%d',opts.t,opts.beta);
    load(sprintf('%s/%s.mat',filename_all.data_dir,filename));
    
    num=length(year_idx);
    error_mean=zeros(num,opts.beta);
    error_median=zeros(num,opts.beta);
    error_online=zeros(num,opts.beta);
    error_nhc=zeros(num,opts.beta);
    counts=zeros(num,opts.beta);
    for ii=1:num
        current_idx=year_idx{ii};
        t1=clock;
        num2 = length(current_idx);
        for jj=1:num2
            h=current_idx(jj);
%             if hurricane(h).location~=1
%                 continue;
%             end
    %         if mod(p,20)==0
    %             t2=clock;
    %             fprintf('%s / Runs:%d/%d / Timeleft:%s\n', process, p, num2, get_timeleft(p,num2,t1,t2));
    %         end
            n = length(forecast_tensor(h).models);
            for t=1:size(forecast_tensor(h).X,4)
                for tau=1:opts.beta
                    if ~isempty(forecast_tensor(h).label) && forecast_tensor(h).label(tau,t)>0
                        Y=forecast_tensor(h).Y(:,t+tau)';
                        nhc=forecast_tensor(h).nhc(:,tau,t);
                        if nhc(3)==-1000 || Y(3)==-1000
                            continue;
                        end
                        error_nhc(ii,tau)=error_nhc(ii,tau)+abs(Y(3)-nhc(3));
                        counts(ii,tau)=counts(ii,tau)+1;
                    end
                end
            end
        end
        error_nhc(ii,:)=error_nhc(ii,:)./counts(ii,:);
    end

    tau=8
    fprintf('\n');
    fprintf('$NHC$ & ');
    for k=1:7
        fprintf('%.2f ',error_nhc(k,tau));
        if k<7
            fprintf(' & ');
        else
            fprintf(' \\\\\\hline');
        end
    end
    fprintf('\n');
    
    tau=12
    fprintf('\n');
    fprintf('$NHC$ & ');
    for k=1:7
        fprintf('%.2f ',error_nhc(k,tau));
        if k<7
            fprintf(' & ');
        else
            fprintf(' \\\\\\hline');
        end
    end
    fprintf('\n');
    
end

