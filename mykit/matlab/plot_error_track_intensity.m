function plot_error_track_intensity(opts)
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

    process = 'plot for one hurricane';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/forecast_tensor_%d_%d.mat',filename_all.data_dir,opts.t,opts.beta));
    load(sprintf('%s/hurricane.mat',filename_all.data_dir));
    data=cell(12,1);
    flag_al=[];
    flag_land=[];
    error_track=zeros(12,1);
    error_intensity=zeros(12,1);
    count=zeros(12,1);
    
    for h=1:numel(forecast_tensor)
        X=forecast_tensor(h).X;
        Y=forecast_tensor(h).Y;
        for t=1:size(X,4)
            for tau=1:size(X,3)
                for m=1:size(X,1)
                    fc=X(m,1:3,tau,t);
                    bt=Y(1:3,t+tau)';
                    if fc(3)>0 && bt(3)>0
                        dis=get_distance(fc(1:2),bt(1:2));
                        error_track(tau)=error_track(tau)+dis;
                        error_intensity(tau)=error_intensity(tau)+abs(fc(3)-bt(3));
                        count(tau)=count(tau)+1;
                        data{tau}=[data{tau};dis abs(fc(3)-bt(3))];
                    end
                end
            end
        end
    end
    error_track=error_track./count;
    error_intensity=error_intensity./count;
    
    lat = data(:,1);
    lon = data(:,2);
    flag_land = landmask(lat,lon);
    
%     figure;
%     geoshow('usastatehi.shp');
%     h_land=geoshow(lat(island),lon(island),'displaytype','point','Marker','.','MarkerEdgeColor','r')
% %     'displaytype','point','color','r','LineWidth',2,'Marker','diamond');
%     h_ocean=geoshow(lat(~island),lon(~island),'displaytype','point','Marker','.','MarkerEdgeColor','b')
%     xlim([-200 0]);

    usa = shaperead('usastatehi.shp'); 
    c = load('coast');
    
    idx=find(wind_count>0);
    wind_mean(idx)=wind_mean(idx)./wind_count(idx);
    h=imagesc([-200 -1],[1 80],wind_mean);
    axis('xy');
    colorbar
    xlabel('Longitude');
    ylabel('Latitude');
    hold on;
    latlim = [0 80];
    lonlim = [-200 0];
    plot([1 1],[-100 10],'r');
    for ii=1:numel(usa)
        plot(usa(ii).X,usa(ii).Y,'color',[237,189,101]/255);
    end
    hold off;
    
   
%     idx=~flag_al & flag_land;
% %     idx(:)=1;
%     figure;
%     plot(data(idx,3),data(idx,4),'.');
%     xlabel('Intensity (kt)');
%     ylabel('Moving speed (miles/hr)');
%     xlim([0 200]);
%     ylim([0 70])
%     corrcoef(data(idx,3),data(idx,4))

%     figure;
%     imagesc(flipud(M));
%     xlabel('Intensity(kt)');
%     ylabel('Moving speed (miles/hr)');
    
%     corrcoef(data(flag_land,3),data(flag_land,4))
%     corrcoef(data(~flag_land,3),data(~flag_land,4))
%        moving speed is calculated by the current position and previous position
%     Correlation coefficients: 0.07316
%     xlim([-180 180]);
%     ylim([-180 180]);
%     title(['P(rank \leq ', num2str(opts.k), ',\tau_2 | rank \leq ', num2str(opts.k), ',\tau_1) for model forecasts AP 01 to 20']);
% 	title(['P(rank \leq ', num2str(opts.k), ',\tau_2 | rank \leq ', num2str(opts.k), ',\tau_1) for 5 model forecasts']);
%     xlabel('Lead time \tau_1');
%     ylabel('Lead time \tau_2')
    
    fprintf('---------- %s / End ----------\n', process);

end

