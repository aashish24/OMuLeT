function error = plot_forecast(opts)
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

    process = 'Get plot for forecast models';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/forecast.mat',filename_all.data_dir));
    load(sprintf('%s/hurricane.mat',filename_all.data_dir));
    load(sprintf('%s/model.mat',filename_all.data_dir));
    load(sprintf('%s/hurricane_track.mat',filename_all.data_dir));
    load(sprintf('%s/forecast_label.mat',filename_all.data_dir));
    
    [~,model_ids] = ismember(opts.models, extractfield(model,'id'));
    idx = forecast(:,1)==opts.hurricane & forecast(:,4)==opts.forecast_time & ismember(forecast(:,2),model_ids) & forecast_label>0;
    forecast = forecast(idx,:);
%     hurricane_track = hurricane_track(forecast_label(idx),:);
    time_min=min(forecast(:,3));
    forecast(:,3)=(forecast(:,3)-time_min)*24+forecast(:,4);
    
    xl={'Time(hours)','Time(hours)','Longitude'};
    yl={'Longitude','Latitude','Latitude'};
    x1=[2 2 3];
    y1=[3 4 4]; 
    x2=[3 3 5];
    y2=[5 6 6]; 
    for p=1:3
        figure;
        hold on;
        for m=1:length(model_ids)
            idx=forecast(:,2)==model_ids(m);
            fc=forecast(idx,:);
            [~,idx]=sort(fc(:,3));
            fc=fc(idx,:);
            plot(fc(:,x2(p)),fc(:,y2(p)),'-');
        end
        idx=hurricane_track(:,1)==opts.hurricane;
        ht=hurricane_track(idx,:);
        ht(:,2)=(ht(:,2)-time_min)*24;
        [~,idx]=sort(ht(:,2));
        ht=ht(idx,:);
        plot(ht(:,x1(p)),ht(:,y1(p)),'-','LineWidth',2);
        hold off;
        title(sprintf('%s forecast %d hours',hurricane(opts.hurricane).id,opts.forecast_time));
        xlabel(xl{p});
        ylabel(yl{p});
        legend([opts.models, 'Hurricane Track'],'FontSize',6,'Location','best');
    end
    
    fprintf('---------- %s / End ----------\n', process);

end

