function error = get_forecast_online_error_years(opts)
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
    for ii=1:num
        counts=zeros(num,opts.beta);
        current_idx=year_idx{ii};
        t1=clock;
        num2 = length(current_idx);
        for jj=1:num2
            h=current_idx(jj);
    %         if mod(p,20)==0
    %             t2=clock;
    %             fprintf('%s / Runs:%d/%d / Timeleft:%s\n', process, p, num2, get_timeleft(p,num2,t1,t2));
    %         end
            n = length(forecast_tensor(h).models);
            for t=1:size(forecast_tensor(h).X,4)
                for tau=1:opts.beta
                    if forecast_tensor(h).label(tau,t)>0
                        X=forecast_tensor(h).X(:,:,tau,t);
                        X_flag=forecast_tensor(h).X_flag(:,tau,t);
                        nhc=forecast_tensor(h).nhc(:,tau,t);
                        Y=forecast_tensor(h).Y(:,t+tau);
                        label=forecast_tensor(h).label(tau,t);
                        if label==0 || sum(X_flag)<opts.models_min || sum(nhc==-1000)>0
                            continue;
                        end
                        predict_mean=mean(X(:,X_flag),2);
                        predict_median=median(X(:,X_flag),2);
                        predict_online=forecast_tensor(h).predict(:,tau,t);
                        predict_nhc=forecast_tensor(h).nhc(:,tau,t);
                        error_mean(ii,tau)=error_mean(ii,tau)+get_distance(Y,predict_mean);
                        error_median(ii,tau)=error_median(ii,tau)+get_distance(Y,predict_median);
                        error_online(ii,tau)=error_online(ii,tau)+get_distance(Y,predict_online);
                        error_nhc(ii,tau)=error_nhc(ii,tau)+get_distance(Y,predict_nhc);
                        counts(ii,tau)=counts(ii,tau)+1;
                    end
                end
            end
        end
        error_mean(ii,:)=error_mean(ii,:)./counts(ii,:)/1.6;
        error_median(ii,:)=error_median(ii,:)./counts(ii,:)/1.6;
        error_online(ii,:)=error_online(ii,:)./counts(ii,:)/1.6;
        error_nhc(ii,:)=error_nhc(ii,:)./counts(ii,:)/1.6;

%         if ii==1
%             fprintf('Training trajectory data\n');
%         elseif ii==2
%             fprintf('Validation trajectory data\n');
%         elseif ii==3
%             fprintf('Training + Validation trajectory data\n');
%         else
%             fprintf('Testing trajectory data\n');
%         end
%         fprintf('$Ens_{mean}$ & ');
%         for k=1:8
%             fprintf('%.2f ',error_mean(k));
%             if k<8
%                 fprintf(' & ');
%             else
%                 fprintf(' \\\\\\hline');
%             end
%         end
%         fprintf('\n');
%         fprintf('$Ens_{median}$ & ');
%         for k=1:8
%             fprintf('%.2f ',error_median(k));
%             if k<8
%                 fprintf(' & ');
%             else
%                 fprintf(' \\\\\\hline');
%             end
%         end
%         fprintf('\n');
%         fprintf('$NHC$ & ');
%         for k=1:8
%             fprintf('%.2f ',error_nhc(k));
%             if k<8
%                 fprintf(' & ');
%             else
%                 fprintf(' \\\\\\hline');
%             end
%         end
%         fprintf('\n');
%         fprintf('$OMuLT$ & ');
%         for k=1:8
%             fprintf('%.2f ',error_online(k));
%             if k<8
%                 fprintf(' & ');
%             else
%                 fprintf(' \\\\\\hline');
%             end
%         end
%         fprintf('\n');
% 
%         error(ii) = sum(error_online([2 4 6 8]));
    
    end 
    
    fprintf('\n');
    fprintf('$Ens_{mean}$ & ');
    tau=8;
    for k=1:7
        fprintf('%.2f ',error_mean(k,tau));
        if k<7
            fprintf(' & ');
        else
            fprintf(' \\\\\\hline');
        end
    end
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
    fprintf('$OMuLeT$ & ');
    for k=1:7
        fprintf('%.2f ',error_online(k,tau));
        if k<7
            fprintf(' & ');
        else
            fprintf(' \\\\\\hline');
        end
    end
    fprintf('\n');
%     return;
    
    figure;
    hold on;
    tau=8
    h1=plot(2012:2018,error_mean(:,tau),'k-');
%     plot(error_median(:,tau*2),'g-');
    h2=plot(2012:2018,error_nhc(:,tau),'b-');
    h3=plot(2012:2018,error_online(:,tau),'r-');
    lg=legend([h3,h2,h1],{'OMuLeT' 'NHC' 'Ensemble Mean'},'FontSize',12);
    xticks(2012:2018);
    xlabel('Year');
    ylabel('Forecast Error (mi)');
    title('48 hours Forecast Error')
%     lg=legend([h3,h2,h1],{'OMuLT' 'Ensenble Mean', 'NHC'},'FontSize',8,'Location','NorthEastOutside');
    hold off;
    
end

