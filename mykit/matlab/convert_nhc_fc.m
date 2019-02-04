function opts = convert_nhc_fc(opts)
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

    process = 'Convert NHC forecast data';
    fprintf('---------- %s / Begin ----------\n', process);

    load(sprintf('%s/raw/hurricane.mat',filename_all.data_dir));
    hurricane_all = extractfield(hurricane,'id');
    
    model=[];
    model_id=1;
    model(model_id).id='NHC';
    model(model_id).type=3;

    listing = dir(sprintf('%s/NHC/adv_track',filename_all.base_dir));
    num = numel(listing)-2;

    forecast=cell(1,numel(hurricane));
    t1=clock;
    for p=1:num
        if mod(p,1000)==0
            t2=clock;
            fprintf('%s / Runs:%d/%d / Timeleft:%s\n', process, p, num, get_timeleft(p,num,t1,t2));
        end
        [filepath,name,ext] = fileparts(listing(p+2).name);
        name=lower(name);
        names = split(name,'_');
        hurricane_id = find(ismember(hurricane_all, names{1}));
        if ~isempty(hurricane_id)
            %opts=convert_kml([listing(p+2).folder '/' listing(p+2).name], opts);
            filename =[listing(p+2).folder '/' listing(p+2).name];
            [fid msg] = fopen(filename,'rt');
            if fid<0
                error(msg)
            end
            txt = fread(fid,'uint8=>char')';
            fclose(fid);

            [filepath,name,ext] = fileparts(filename);
            name=lower(name);
            names = split(name,'_');
    
            expr = '<Placemark(?<placemark>.+?)</Placemark>';
            obj = regexp(txt,expr,'names');
            
            o=1;
            fc=[];
            kml_flag=true;
            while o<=numel(obj)
                data_t=[];
                % file type 1
                exprs{1}= '<Data name="fulldateLbl">\s*<value>(?<data>.+?)</value>';
                exprs{2}= '<Data name="tau">\s*<value>(?<data>.+?)</value>';
                exprs{3}= '<Data name="lat">\s*<value>(?<data>.+?)</value>';
                exprs{4}= '<Data name="lon">\s*<value>(?<data>.+?)</value>';
                exprs{5}= '<Data name="mslp">\s*<value>(?<data>.+?)</value>';
                exprs{6}= '<Data name="maxWnd">\s*<value>(?<data>.+?)</value>';
                for n=1:numel(exprs)
                    data_t{n} = regexp(obj(o).placemark,exprs{n},'names');
                end
                if numel(data_t{1})>0 && numel(data_t{2})>0 && numel(data_t{3})>0 && numel(data_t{4})>0
                    kml_flag=false;
                    t = strsplit(data_t{1}.data,{' ',',',':'});
                    data.ntime=datenum([t{1} '-' t{2} '-' t{3} '-' t{6} '-' t{7} '-' t{8}],'HH-MM-PM-mmm-dd-yyyy');
                    data.forecast_time=str2num(data_t{2}.data);
                    if strcmp(t{4}, 'EDT') || strcmp(t{4}, 'EST')
                        data.ntime=data.ntime+(4-data.forecast_time)/24;
                    elseif strcmp(t{4}, 'CDT') || strcmp(t{4}, 'CST')
                        data.ntime=data.ntime+(5-data.forecast_time)/24;
                    elseif strcmp(t{4}, 'MDT') || strcmp(t{4}, 'MST')
                        data.ntime=data.ntime+(6-data.forecast_time)/24;
                    elseif strcmp(t{4}, 'PDT') || strcmp(t{4}, 'PST')
                        data.ntime=data.ntime+(7-data.forecast_time)/24;
                    else
                        fprintf(1, "Error time zone: %s",t{4});
                    end
                    data.lat=str2num(data_t{3}.data);
                    data.lon=str2num(data_t{4}.data);
                    if numel(data_t{5})>0
                        data.pressure=str2num(data_t{5}.data);
                        if data.pressure==9999
                            data.pressure=-1000;
                        end
                    else
                        data.pressure=-1000;
                    end
                    if numel(data_t{6})>0
                        w = strsplit(data_t{6}.data,{' '});
                        data.wind=str2num(w{1});
                    else
                        data.wind=-1000;
                    end
                    fc=[fc;model_id,data.ntime,data.forecast_time,data.lat,data.lon,data.wind,data.pressure];
                    o=o+1;
                    continue;
                end
                exprs{1}= 'Valid at:\s*(?<data>.+?)\s*<';
                exprs{2}= '>\s*(?<data>\d*)\s*hr Forecast<';
                exprs{3}= 'Location:\s*(?<data>.+?),';
                exprs{4}= 'Location:.+?,\s*(?<data>.+?)\s*<';
                exprs{5}= 'Minimum Pressure:\s*(?<data>\d*)\s*';
                exprs{6}= 'Maximum Wind:\s*(?<data>\d*)\s*';
                for n=1:numel(exprs)
                    data_t{n} = regexp(obj(o).placemark,exprs{n},'names');
                end
                if numel(data_t{1})>0 && numel(data_t{2})>0 && numel(data_t{3})>0 && numel(data_t{4})>0
                    kml_flag=false;
                    t = strsplit(data_t{1}.data,{' ',',',':'});
                    data.ntime=datenum([t{1} '-' t{2} '-' t{3} '-' t{5} '-' t{6} '-' t{7}],'HH-MM-PM-mmm-dd-yyyy');
                    data.forecast_time=str2num(data_t{2}.data);
                    if strcmp(t{4}, 'EDT') || strcmp(t{4}, 'EST') || strcmp(t{4}, 'AST')
                        data.ntime=data.ntime+(4-data.forecast_time)/24;
                    elseif strcmp(t{4}, 'CDT') || strcmp(t{4}, 'CST')
                        data.ntime=data.ntime+(5-data.forecast_time)/24;
                    elseif strcmp(t{4}, 'MDT') || strcmp(t{4}, 'MST')
                        data.ntime=data.ntime+(6-data.forecast_time)/24;
                    elseif strcmp(t{4}, 'PDT') || strcmp(t{4}, 'PST')
                        data.ntime=data.ntime+(7-data.forecast_time)/24;
                    else
                        fprintf(1, "Error time zone: %s",t{4});
                    end
                    data.lat=str2num(data_t{3}.data);
                    lat = strsplit(data_t{3}.data,' ');
                    if lat{2}=='N'
                        data.lat=str2num(lat{1});
                    else
                        data.lat=str2num(lat{1})-180;
                    end
                    lon = strsplit(data_t{4}.data,' ');
                    if lon{2}=='W'
                        data.lon=str2num(lon{1});
                    else
                        data.lon=str2num(lon{1})-360;
                    end
                    if numel(data_t{5})>0
                        data.pressure=str2num(data_t{5}.data);
                    else
                        data.pressure=-1000;
                    end
                    if numel(data_t{6})>0
                        w = strsplit(data_t{6}.data,{' '});
                        data.wind=str2num(w{1});
                    else
                        data.wind=-1000;
                    end
                    fc=[fc;model_id,data.ntime,data.forecast_time,data.lat,data.lon,data.wind,data.pressure];          
                    o=o+1;
                    continue;
                end
                o=o+1;
            end
            if kml_flag && numel(obj)>3
                fprintf('Unknow kml type!');
            end                
            forecast{hurricane_id}=[forecast{hurricane_id}; fc];
        end
    end

    save(sprintf('%s/raw/model.mat',filename_all.data_dir),'model');
    save(sprintf('%s/raw/forecast_nhc.mat',filename_all.data_dir),'forecast');
    
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

