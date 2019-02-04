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

    process = 'Get win rate of models';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/forecast_tensor_%d_%d.mat',filename_all.data_dir,opts.t,opts.beta));
    load(sprintf('%s/hurricane.mat',filename_all.data_dir));
    load(sprintf('%s/model.mat',filename_all.data_dir));
    
    num = numel(forecast_tensor);
    num_model = length(opts.models);
    
    top=zeros(num_model,8,8);
    top_all=zeros(num_model,8,8);
    
    h=opts.hurricane;
    fc=forecast_tensor(h);
    num_model = length(fc.models);

    fc=forecast_tensor(h);
    [~,idx]=ismember(fc.models, opts.models);
    flag=false(1,size(fc.X,4));
    figure('Position',[0 0 800 800]);
    geoshow('landareas.shp','FaceColor',[0.9294    0.7412    0.3961]);
    num_model=numel(fc.models);
%     load coastlines;
    for t=20:size(fc.X,4)
        idx=fc.label(:,t)>0;
        idx(1)=1;
        if sum(idx)<=2
            continue;
        end
        flag(t)=true;
        figure(1);
%         geoshow('landareas.shp','FaceColor',[0.9294    0.7412    0.3961]);
        h={};
%         for m=1:num_model
%             X=squeeze(fc.X(:,m,:,t));
%             h{m}=geoshow(X(2,idx),X(1,idx),'displaytype','line','color',[0.7 0.7 0.7]);
%         end
m=num_model;
        X=fc.X(:,:,:,t);
        X=squeeze(median(X,1));
        h{num_model+1}=geoshow(X(2,idx),X(1,idx),'displaytype','point','MarkerEdgeColor','r');
        h{num_model+2}=geoshow(X(2,idx),X(1,idx),'displaytype','line','color','r');
        Y=fc.Y(:,t:t+8);
        h{num_model+3}=geoshow(Y(2,:),Y(1,:),'displaytype','point','MarkerEdgeColor','g');
        h{num_model+4}=geoshow(Y(2,:),Y(1,:),'displaytype','line','color','g');
%         xc=floor(mean(ax.XLim));
%         yc=floor(mean(ax.YLim));
        xc=floor(mean(Y(1,:)));
        yc=floor(mean(Y(2,:)));
        xlim([xc-6 xc+6]);
        ylim([yc-6 yc+6]);
        xlabel('Longitude');
        ylabel('Latitude');
        legend([h{m+4} h{m+2}],{'Best track', 'NHC'})
        F(t) = getframe(gcf);
        for m=1:num_model+4
            delete (h{m});
        end
    end
    
    % create the video writer with 1 fps
    writerObj = VideoWriter('myVideo.avi');
    writerObj.FrameRate = 2;
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

