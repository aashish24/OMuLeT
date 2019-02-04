function plot_wind_speed(opts)
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

    process = 'plot wind speed';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/raw/best_track.mat',filename_all.data_dir));
    load(sprintf('%s/raw/hurricane.mat',filename_all.data_dir));
    data=[];
    M=zeros(7,20);
    num_lat=80;
    num_lon=200;
    wind_mean=zeros(num_lat,num_lon);
    wind_count=zeros(num_lat,num_lon);
    flag_al=[];
    flag_land=[];
    
    for h=1:numel(best_track)
%         if hurricane(h).location==1
%             continue;
%         end
        bt=best_track{h};
        for ii=2:size(bt,1)-1
            intensity=bt(ii,4);
            bt2=bt(ii-1:ii+1,1:3);
            if isempty(find(bt2==-1000)) && intensity>0
                dis=get_distance(bt2(1,2:3),bt2(2,2:3))+get_distance(bt2(2,2:3),bt2(3,2:3));
                speed=dis/1.6/(bt2(3,1)-bt2(1,1))/24;
                if intensity>100
                    intensity=intensity;
                end
                data=[data; bt(ii,2:3) intensity speed];
                flag_al=[flag_al; hurricane(h).location==1];
                m1=floor(speed/10)+1;
                m2=floor(intensity/10)+1;
%                 M(m1,m2)=M(m1,m2)+1;
                lat_t=bt(ii,2);
                lon_t=bt(ii,3);
                lat_t=floor(lat_t)+1;
                lon_t=floor(lon_t)+201;
                if(lat_t>0 && lat_t<num_lat && lon_t>0 && lon_t<num_lon)
                    wind_mean(lat_t,lon_t)=wind_mean(lat_t,lon_t)+speed;
                    wind_count(lat_t,lon_t)=wind_count(lat_t,lon_t)+1;
                end
            end
        end
    end
    
    lat = data(:,1);
    lon = data(:,2);
    flag_land = landmask(lat,lon);
    
%     figure;
%     geoshow('usastatehi.shp');
%     h_land=geoshow(lat(island),lon(island),'displaytype','point','Marker','.','MarkerEdgeColor','r')
% %     'displaytype','point','color','r','LineWidth',2,'Marker','diamond');
%     h_ocean=geoshow(lat(~island),lon(~island),'displaytype','point','Marker','.','MarkerEdgeColor','b')
%     xlim([-200 0]);

%     usa = shaperead('usastatehi.shp'); 
%     c = load('coast');
%     
%     idx=find(wind_count>0);
%     wind_mean(idx)=wind_mean(idx)./wind_count(idx);
%     h=imagesc([-200 -1],[1 80],wind_mean);
%     axis('xy');
%     colorbar
%     xlabel('Longitude');
%     ylabel('Latitude');
%     hold on;
%     latlim = [0 80];
%     lonlim = [-200 0];
%     plot([1 1],[-100 10],'r');
%     for ii=1:numel(usa)
%         plot(usa(ii).X,usa(ii).Y,'color',[237,189,101]/255);
%     end
%     hold off;

    num=size(data,1);
    dis=zeros(num,1);
    dist_method = 'fast';   %'fast' or 'great_circle'
    dist_maxthresh = 200000*1000;
    [dists_min,lats_closest,lons_closest] = dist_from_coast(data(~flag_land,1),data(~flag_land,2),dist_method,dist_maxthresh);
    
    dis(~flag_land)=dists_min;
    
    c=dis/max(dis);

    idx=true(num,1);
    figure;
    scatter(data(idx,3),data(idx,4),1,[c,1-c,zeros(num,1)]);
    xlabel('Intensity (kt)');
    ylabel('Moving speed (miles/hr)');
    xlim([0 200]);
    ylim([0 70])
    corrcoef(data(idx,3),data(idx,4))
    
   
%     idx=flag_al & flag_land;
% %     idx(:)=1;
%     figure;
%     plot(data(idx,3),data(idx,4),'.');
%     xlabel('Intensity (kt)');
%     ylabel('Moving speed (miles/hr)');
%     xlim([0 200]);
%     ylim([0 70])
%     corrcoef(data(idx,3),data(idx,4))
%     
%     idx=flag_al & ~flag_land;
% %     idx(:)=1;
%     figure;
%     plot(data(idx,3),data(idx,4),'.');
%     xlabel('Intensity (kt)');
%     ylabel('Moving speed (miles/hr)');
%     xlim([0 200]);
%     ylim([0 70])
%     corrcoef(data(idx,3),data(idx,4))
% 
%     
%     idx=~flag_al & flag_land;
% %     idx(:)=1;
%     figure;
%     plot(data(idx,3),data(idx,4),'.');
%     xlabel('Intensity (kt)');
%     ylabel('Moving speed (miles/hr)');
%     xlim([0 200]);
%     ylim([0 70])
%     corrcoef(data(idx,3),data(idx,4))
% 
%     
%     idx=~flag_al & ~flag_land;
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

