function opts = convert_uwm(opts)
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

    process = 'Convert UWM files';
    fprintf('---------- %s / Begin ----------\n', process);

    if exist(filename_all.hurricane, 'file') == 2
        load(filename_all.hurricane);
        opts.hurricane=hurricane;
    end
    
    if exist(filename_all.model, 'file') == 2
        load(filename_all.model);
        opts.model=model;
    end

    listing = dir(sprintf('%s/UWM',filename_all.base_dir));
    num = numel(listing)-2;
    
%     process = 'Convert hurricane info';
%     opts.kml_type=1;
%     t1=clock;
%     for p=1:num
%         if mod(p,1000)==0
%             t2=clock;
%             fprintf('%s / Runs:%d/%d / Timeleft:%s\n', process, p, num, get_timeleft(p,num,t1,t2));
%         end
%         opts=convert_kml([listing(p+2).folder '/' listing(p+2).name], opts);
%     end
%     hurricane=opts.hurricane;
% %     fid=fopen(sprintf('%s/hurricane.csv',filename_all.data_dir),'w+');
% %     for p=1:numel(hurricane) 
% %         fprintf(fid,'%s,%s\n',hurricane(p).id,hurricane(p).name);
% %     end
% %     fclose(fid);
%     save(sprintf('%s/hurricane.mat',filename_all.data_dir),'hurricane');
% 
    load(sprintf('%s/raw/hurricane.mat',filename_all.data_dir));
    load(sprintf('%s/raw/model.mat',filename_all.data_dir));
    hurricane_all = extractfield(hurricane,'id');
    model_all = extractfield(model,'id');
    
%     process = 'Convert UWM model';
%     opts.model = model;
%     opts.kml_type=2;
%     t1=clock;
%     for p=1:num
%         if mod(p,1000)==0
%             t2=clock;
%             fprintf('%s / Runs:%d/%d / Timeleft:%s\n', process, p, num, get_timeleft(p,num,t1,t2));
%         end
%         opts=convert_kml([listing(p+2).folder '/' listing(p+2).name], opts);
%     end
%     model=opts.model;
% %     fid=fopen(sprintf('%s/model.csv',filename_all.data_dir),'w+');
% %     for p=1:numel(model) 
% %         fprintf(fid,'%s,%s\n',model(p).id,model(p).type);
% %     end
% %     fclose(fid);
%     save(sprintf('%s/raw/model.mat',filename_all.data_dir),'model');

    
    process = 'Convert UWM forcasts';
    forecast=cell(1,numel(hurricane));
    t1=clock;
%     num=1000;
    for p=1:num
        if mod(p,100)==0
            t2=clock;
            fprintf('%s / Runs:%d/%d / Timeleft:%s\n', process, p, num, get_timeleft(p,num,t1,t2));
        end
%         opts=convert_kml([listing(p+2).folder '/' listing(p+2).name], opts);
        filename=[listing(p+2).folder '/' listing(p+2).name];
        
        [fid msg] = fopen(filename,'rt');
        if fid<0
            error(msg)
        end
        txt = fread(fid,'uint8=>char')';
        fclose(fid);

        [filepath,name,ext] = fileparts(filename);
        name=lower(name);
        names = regexp(name,'_','split');
            
        hurricane_id = find(ismember(hurricane_all, names{1}));
        if isempty(hurricane_id)
            fprintf('unknown hurricane: %s\n',names{1});
            continue;
        end
        expr = '<Placemark(?<placemark>.+?)</Placemark>';
        obj = regexp(txt,expr,'names');
        exprs{1} = ['<name>\s*(?<forecast_model>\w+?)\s*Forecast Hour\s*(?<forecast_time>\d+?)\s*</name>' ...
            '\s*<description>.+?(?<hurricane_hour>\d*) UTC (?<hurricane_day>\d*) (?<hurricane_month>\w*) (?<hurricane_year>\d*).+?Maximum Sustained Wind:\s*(?<forecast_wind>.+?)\s*kt.+?Minimum Sea Level Pressure:\s*(?<forecast_pressure>.+?)\s*hPa</description>' ...
            '.+?<coordinates>\s*(?<forecast_coord>.+?)\s*</coordinates>'];
        fc=[];
        o=1;
        kml_flag=true;
        while o<=numel(obj)
            n=1;
            while n<=numel(exprs)
                data = regexp(obj(o).placemark,exprs{n},'names');
                if isempty(data)
                    n=n+1;
                    continue;
                else
                    break;
                end
            end
            if n<=numel(exprs)
                kml_flag=false;
                model_id = find(ismember(model_all, data.forecast_model));
                if isempty(model_id)
                    model_type = 1;
                    if numel(names) == 3
                        if strcmp(names{3},'late')
                            model_type = 2;
                        elseif strcmp(names{3},'ens')
                            model_type = 3;
                        end
                    end
                    model_id=numel(model)+1;
                    model(model_id).id=data.forecast_model;
                    model(model_id).type=model_type;
                    model_all{model_id}=data.forecast_model;
                end
                hurricane_time = datenum(sprintf('%s-%s-%s-%s',data.hurricane_year,data.hurricane_month,data.hurricane_day,data.hurricane_hour),'yyyy-m-dd-HHMM');
    %             hurricane_time2 = datenum(name{2},'yyyymmddhh');
    %             fprintf('%s %s %d\n',name{2}, sprintf('%s-%s-%s-%s',data.hurricane_year,data.hurricane_month,data.hurricane_day,data.hurricane_hour), hurricane_time-hurricane_time2);
                if isempty(model_id)
                    error('unknown model');
                end
                forecast_time = str2num(data.forecast_time);
                forecast_coord = str2double(regexp(data.forecast_coord,'[,\s]+','split'));
                forecast_lon = forecast_coord(1);
                forecast_lat = forecast_coord(2);
                forecast_wind = str2double(data.forecast_wind);
                if isnan(forecast_wind)
                    forecast_wind = -1000;
                end
                forecast_pressure = str2double(data.forecast_pressure);
                if isnan(forecast_pressure)
                    forecast_pressure = -1000;
                end
                fc = [fc; model_id hurricane_time forecast_time forecast_lat forecast_lon forecast_wind forecast_pressure];
            end
            o=o+1;
        end
        if kml_flag && numel(obj)>3
            fprintf('Unknow kml type!');
        end
        forecast{hurricane_id}=[forecast{hurricane_id}; fc];    
    end
    
    save(sprintf('%s/raw/forecast_uwm.mat',filename_all.data_dir),'forecast');
    save(sprintf('%s/raw/model.mat',filename_all.data_dir),'model');
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

