function plot_forecast_leadtime(opts)
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
    
    hurricane(opts.hurricane).name
    fc=forecast_tensor(opts.hurricane);
    num_model=size(fc.X,1);
    for tau=1:size(fc.X,3)
        figure; 
        hold on;
        X=squeeze(fc.X(:,1,tau,:));
        X=[-1000*ones(num_model,tau) X(:,1:end-tau)];
        for m=1:size(X,1)
            idx=X(m,:)~=-1000;
            ft=1:size(fc.X,4);
            h1=plot(ft(idx),X(m,idx),'b-');
        end
        X=fc.Y(1,1:end-8);
        idx=X~=-1000;
        ft=1:size(X,2);
        h2=plot(ft(idx),X(idx),'r-');
        hold off;
        xlabel('Time(6 hours interval)');
        ylabel('Longitude');
        title(sprintf('Forecasts With Lead Time %d', tau));
        legend([h1,h2],{'AP 01-20 Forecasts','Best Track'});
        saveas(gcf,sprintf('plots/Irma_lon_tau_%d.eps',tau),'epsc');
        close(gcf);
        
        figure; 
        hold on;
        X=squeeze(fc.X(:,2,tau,:));
        X=[-1000*ones(num_model,tau) X(:,1:end-tau)];
        for m=1:size(X,1)
            idx=X(m,:)~=-1000;
            ft=1:size(fc.X,4);
            h1=plot(ft(idx),X(m,idx),'b-');
        end
        X=fc.Y(2,1:end-8);
        idx=X~=-1000;
        ft=1:size(X,2);
        h2=plot(ft(idx),X(idx),'r-');
        hold off;
        xlabel('Time(6 hours interval)');
        ylabel('Latitude');
        title(sprintf('Forecasts With Lead Time %d', tau));
        legend([h1,h2],{'AP 01-20 Forecasts','Best Track'});
        saveas(gcf,sprintf('plots/Irma_lat_tau_%d.eps',tau),'epsc');
        close(gcf);
    end
    
    fprintf('---------- %s / End ----------\n', process);

end

