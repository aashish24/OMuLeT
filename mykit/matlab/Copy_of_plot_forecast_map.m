function plot_forecast_map(opts)
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
    load(sprintf('%s/model.mat',filename_all.data_dir));
    
    num = numel(forecast_tensor);
    num_model = length(opts.models);
    
    top=zeros(num_model,8,8);
    top_all=zeros(num_model,8,8);
    
    h_id=opts.hurricane;
    fc=forecast_tensor(h_id);
    num_model = length(fc.models);
    
    [~,idx]=ismember(fc.models, opts.models);
    flag=false(1,size(fc.X,4));
    figure('Position',[0 0 600 600]);
%     geoshow('landareas.shp','FaceColor',[0.9294    0.7412    0.3961]);
%     geoshow('usastatehi.shp');
%     states = shaperead('usastatehi');
%     for k = 1:numel(states)
%         text(states(k).LabelLat,states(k).LabelLon, states(k).Name,'HorizontalAlignment','center');
%     end
    num_model=numel(fc.models);
%     load coastlines;
%     for t=1:size(fc.X,4)
    for t=45:1:60
        P=fc.predict(:,:,t);
        P_mean=squeeze(mean(fc.X(:,:,:,t),1));
        P_nhc=fc.nhc(:,:,t);
        idx=~(sum(P==-1000)>0);
        if sum(idx)==0
            continue;
        end
        idx=idx(1:8);
        flag(t)=true;
        figure(1);
%         geoshow('usastatehi.shp');
        latlim = [20 40];  
        lonlim = [-90 -75];
        [Z,refvec] = gtopo30('data/gt30w100n40_dem/W100N40',1,latlim,lonlim);
        Z(isnan(Z(:))) = -1;
        geoshow(Z,refvec,'DisplayType','texturemap');
        demcmap(Z);
        nhc_idx=find(fc.models==1);
        h={};
%         idx
        for m=1:num_model
            X=squeeze(fc.X(:,m,:,t));
            h{m}=geoshow(X(1,idx),X(2,idx),'displaytype','line','color',[50,205,50]/255);
%             [48,128,20]/255
        end
        h{m+1}=geoshow(P_mean(1,idx),P_mean(2,idx),'displaytype','line','LineStyle',':','color','k','LineWidth',3);
        h{m+2}=geoshow(P_nhc(1,idx),P_nhc(2,idx),'displaytype','line','LineStyle','-.','color',[255 97 0]/255,'LineWidth',3);
        h{m+3}=geoshow(P(1,idx),P(2,idx),'displaytype','line','LineStyle','--','color','b','LineWidth',3);
        Y=fc.Y(:,t:t+8);
        h{m+4}=geoshow(Y(1,[true,idx]),Y(2,[true,idx]),'displaytype','line','color','r','LineWidth',3);
%         for ii=1:size(Y,2)
%             textm(Y(2,ii),Y(1,ii),'starting point')
%         end
        h{m+5}=geoshow(Y(1,1),Y(2,1),'displaytype','point','color','r','LineWidth',2,'Marker','diamond');
%         xc=floor(mean(ax.XLim));
%         yc=floor(mean(ax.YLim));
        text(Y(1,1),Y(2,1),'Current Location')
        xc=floor(mean(Y(2,:)));
        yc=floor(mean(Y(1,:)));
        yc_delta=floor(max(Y(1,:))-min(Y(1,:)));
        xlim([xc-6 xc+6]);
        ylim([yc-6 yc+6]);
        xlabel('Longitude');
        ylabel('Latitude');
        formatOut = 'yyyy/mm/dd HH:MM';
        title(sprintf('Forecasts generated at %s UTC',datestr(fc.time(t),formatOut)),'FontSize',14);
%         legend([h{m+4} h{m+2}],{'Best Track', 'NHC', },'FontSize',12);
%         legend([ h{m+4} h{m+2} h{m+1} h{1}],{'Best Track', 'NHC', 'Ensemble Mean', 'Ensemble Members'},'FontSize',12);
        legend([ h{m+4}  h{m+3} h{m+2} h{m+1} h{1}],{'Best Track', 'OMuLeT', 'NHC', 'Ensemble Mean', 'Ensemble Members'},'FontSize',12);
%         legend([h{m+4} h{m+1} h{1}],{'Best Track', 'Ensemble Mean', 'Ensemble Members'},'FontSize',12);
        makedir(sprintf('plots/hurricane_%d',h_id));
        saveas(gcf,sprintf('plots/hurricane_%d/%d.png',h_id,t),'png')
        F(t) = getframe(gcf);
%         for m=1:num_model+4
%             delete (h{m});
%         end
        clf(gcf)
    end
    
    % create the video writer with 1 fps
    writerObj = VideoWriter('myVideo.avi');
    writerObj.FrameRate = 1;
    % set the seconds per image
    % open the video writer
    open(writerObj);
    % write the frames to the video
    for i=1:length(F)
        % convert the image to a frame
        if flag(i)
            frame = F(i);    
            writeVideo(writerObj, frame);
        end
    end
    % close the writer object
    close(writerObj);
    
%     xlim([-180 180]);
%     ylim([-180 180]);
%     title(['P(rank \leq ', num2str(opts.k), ',\tau_2 | rank \leq ', num2str(opts.k), ',\tau_1) for model forecasts AP 01 to 20']);
% 	title(['P(rank \leq ', num2str(opts.k), ',\tau_2 | rank \leq ', num2str(opts.k), ',\tau_1) for 5 model forecasts']);
%     xlabel('Lead time \tau_1');
%     ylabel('Lead time \tau_2')
    
    fprintf('---------- %s / End ----------\n', process);

end

