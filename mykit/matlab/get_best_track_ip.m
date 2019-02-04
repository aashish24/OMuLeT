function opts = get_best_track_ip(opts)
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

    process = 'get interplated best track';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/best_track.mat',filename_all.data_dir));

    for h=1:numel(best_track)
        track=best_track{h};
        time=track(:,1)*4;
        [~,idx]=sort(time);
        track=track(idx,:);
        time=time(idx);
        if floor(time(1))==time(1)
            newtrack=track(1,:);
        else
            newtrack=[];
        end
        for ii=1:numel(time)-1
            for t=floor(time(ii)+1):floor(time(ii+1))
                newtrack=[newtrack;(track(ii,:)*(time(ii+1)-t)+track(ii+1,:)*(t-time(ii)))/(time(ii+1)-time(ii))];
            end
%             if floor(time(ii+1))-floor(time(ii)+1)>1
%                 track
%                 newtrack
%             end
        end
%         if size(best_track{h},1)~=size(newtrack,1)
%             h=h;
%         end
        best_track{h}=newtrack;
    end
    save(sprintf('%s/best_track.mat',filename_all.data_dir),'best_track');
    
%     fid=fopen(sprintf('%s/hurricane.csv',filename_all.data_dir),'w+');
%     for p=1:numel(hurricane) 
%         fprintf(fid,'%s,%s,%s\n',hurricane(p).id,hurricane(p).location,hurricane(p).name);
%     end
%     fclose(fid);

% 
%     process = 'Convert model info';
%     opts.kml_type=2;
%     t1=clock;
%     for p=1:num
% %         fprintf('%d ', p);
%         if mod(p,1000)==0
%             t2=clock;
%             fprintf('%s / Runs:%d/%d / Timeleft:%s\n', process, p, num, get_timeleft(p,num,t1,t2));
%         end
%         opts=convert_kml([listing(p+2).folder '/' listing(p+2).name], opts);
%     end
%     model=opts.model;
%     fid=fopen(sprintf('%s/model.csv',filename_all.data_dir),'w+');
%     for p=1:numel(model) 
%         fprintf(fid,'%s,%s\n',model(p).id,model(p).type);
%     end
%     fclose(fid);
%     save(sprintf('%s/model.mat',filename_all.data_dir),'model');
% 
% %     load(sprintf('%s/hurricane.mat',filename_all.data_dir));
% %     load(sprintf('%s/model.mat',filename_all.data_dir));
%     
%     process = 'Convert forcast info';
%     opts.kml_type=3;
%     opts.hurricane = hurricane;
%     opts.model = model;
%     t1=clock;
%     core=1;
%     p=1;
%     forecast=[];
% %     num=2000;
%     while p<=num
% %         fprintf('%d ', p);
%         if mod(p,100)<core
%             t2=clock;
%             fprintf('%s / Runs:%d/%d / Timeleft:%s\n', process, p, num, get_timeleft(p,num,t1,t2));
%         end
%         opts_t=cell(core,1);
%         for c=1:core
%             if p+c+1<=num
%                 opts_t{c}=convert_kml([listing(p+c+1).folder '/' listing(p+c+1).name], opts);
%             end
%         end
%         for c=1:core
%             if p+c+1<=num && isfield(opts_t{c},'forecast')
%                 forecast=[forecast; opts_t{c}.forecast];
%             end
%         end
%         p=p+core;
%     end
% %     forecast=opts.forecast;
%     save(sprintf('%s/forecast.mat',filename_all.data_dir),'forecast');
%     csvwrite(sprintf('%s/forecast.csv',filename_all.data_dir),forecast);

%     load(sprintf('%s/hurricane.mat',filename_all.data_dir));
%     load(sprintf('%s/forecast.mat',filename_all.data_dir));
%     for p=1:numel(hurricane)
%         idx=forecast(:,1)==p;
%         t=forecast(idx,3);
%         hurricane(p).time_begin=min(t);
%         hurricane(p).time_end=max(t);
%     end
%     fid=fopen(sprintf('%s/hurricane.csv',filename_all.data_dir),'w+');
%     for p=1:numel(hurricane) 
%         fprintf(fid,'%s,%s\n',hurricane(p).id,hurricane(p).name);
%     end
%     fclose(fid);
%     save(sprintf('%s/hurricane.mat',filename_all.data_dir),'hurricane');

    fprintf('---------- %s / End ----------\n', process);
end

