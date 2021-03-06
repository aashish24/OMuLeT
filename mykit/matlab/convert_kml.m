function opts = convert_kml(filename, opts)
%READKML Summary of this function goes here
%   Detailed explanation goes here
    if nargin<2
        fprintf('Not enough input arguments!\n');
        return;
    end

    [fid msg] = fopen(filename,'rt');
    if fid<0
        error(msg)
    end
    txt = fread(fid,'uint8=>char')';
    fclose(fid);
    
    [filepath,name,ext] = fileparts(filename);
    name=lower(name);
    names = regexp(name,'_','split');

    if opts.kml_type==1
        if ~isfield(opts,'hurricane')
            hurricane_all = {};
        else
            hurricane_all = extractfield(opts.hurricane,'id');
        end
        hurricane_id = find(ismember(hurricane_all, names{1}));
        if isempty(hurricane_id)
            expr = '<Document>\s*<name>\s*(?<name>.+?)\s*</name>';
            obj = regexp(txt,expr,'names');
            if ~isempty(obj)
                hurricane_id=numel(hurricane_all)+1;
                opts.hurricane(hurricane_id).id = names{1};
                if opts.hurricane(hurricane_id).id(1)=='a'
                    opts.hurricane(hurricane_id).location = 1;
                else
                    opts.hurricane(hurricane_id).location = 2;
                end
                opts.hurricane(hurricane_id).name = obj(1).name;
                hurricane_all{hurricane_id} = names{1};
            end
        end
    elseif opts.kml_type == 2
        % model type: early 1 late 2 ens 3
        model_type = 1;
        if numel(names) == 3
            if strcmp(names{3},'late')
                model_type = 2;
            elseif strcmp(names{3},'ens')
                model_type = 3;
            end
        end
        if ~isfield(opts,'model')
            model_all = {};
        else
            model_all = extractfield(opts.model,'id');
        end
        expr = '<name>\s*Model:\s*(?<name>.+?)\s*</name>';
        obj = regexp(txt,expr,'names');
        for o = 1:numel(obj)
            model_id = find(ismember(model_all, obj(o).name));
            if isempty(model_id)
                model_id = numel(model_all)+1;
                opts.model(model_id).id = obj(o).name;
                opts.model(model_id).type = model_type;
                model_all{model_id} = obj(o).name;
            end
        end
    elseif opts.kml_type==3
        hurricane_all = extractfield(opts.hurricane,'id');
        model_all = extractfield(opts.model,'id');
        hurricane_id = find(ismember(hurricane_all, names{1}));
        if isempty(hurricane_id)
%             fprintf('unknown hurricane: %s\n',names{1});
            return;
        end
        expr = '<Placemark(?<placemark>.+?)</Placemark>';
        obj = regexp(txt,expr,'names');
        exprs{1} = ['<name>\s*(?<forecast_model>\w+?)\s*Forecast Hour\s*(?<forecast_time>\d+?)\s*</name>' ...
            '\s*<description>.+?(?<hurricane_hour>\d*) UTC (?<hurricane_day>\d*) (?<hurricane_month>\w*) (?<hurricane_year>\d*).+?Maximum Sustained Wind:\s*(?<forecast_wind>.+?)\s*kt.+?Minimum Sea Level Pressure:\s*(?<forecast_pressure>.+?)\s*hPa</description>' ...
            '.+?<coordinates>\s*(?<forecast_coord>.+?)\s*</coordinates>'];
        n=1;
        o=1;
        forecast=[];
        while o<=numel(obj) && n<=numel(exprs)
            data = regexp(obj(o).placemark,exprs{n},'names');
            if isempty(data)
                if o==1
                    n=n+1;
                    continue;
                end
            else
                model_id = find(ismember(model_all, data.forecast_model));
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
                forecast = [forecast; model_id hurricane_time forecast_time forecast_lat forecast_lon forecast_wind forecast_pressure];
            end
            o=o+1;
        end
        if n>numel(exprs)
            error('Unknow kml type!');
        end
        opts.forecast{hurricane_id}=[opts.forecast{hurricane_id}; forecast];
    elseif opts.kml_type==4
        hurricane_all = extractfield(opts.hurricane,'id');
%         model_all = extractfield(opts.model,'id');
        hurricane_id = find(ismember(hurricane_all, names{1}));
        expr = '<Placemark(?<placemark>.+?)</Placemark>';
        obj = regexp(txt,expr,'names');
        exprs{1} = '<lat>(?<lat>.+?)</lat>\s*<lon>(?<lon>.+?)</lon>.+?<stormName>(?<storm_name>.*)</stormName>.+?<intensity>(?<intensity>\d*)</intensity>.+?<minSeaLevelPres>(?<pressure>\d*)</minSeaLevelPres>\s*<atcfdtg>(?<time>\d*)</atcfdtg>';
        exprs{2} = '<td>STORMNAME</td>\s*<td>(?<storm_name>.*)</td>.+?<td>DTG</td>\s*<td>(?<time>.+?)</td>.+?<td>MSLP</td>\s*<td>(?<pressure>\d*)</td>.+?<td>INTENSITY</td>\s*<td>(?<intensity>.+?)</td>.+?<td>LAT</td>\s*<td>(?<lat>.+?)</td>.+?<td>LON</td>\s*<td>(?<lon>.+?)</td>';
        exprs{3} = '<name>(?<time>.+?)</name>.+?<td>LAT</td>\s*<td>(?<lat>.+?)</td>.+?<td>LON</td>\s*<td>(?<lon>.+?)</td>.+?<td>MSLP_mb</td>\s*<td>(?<pressure>\d*)\s*mb</td>.+?<td>INTENSITY_kt</td>\s*<td>(?<intensity>\d*)\s*kt</td>';
        n=1;
        o=1;
        best_track=[];
        while o<=numel(obj) && n<=numel(exprs)
            data = regexp(obj(o).placemark,exprs{n},'names');
            if isempty(data)
                if o==1
                    n=n+1;
                    continue;
                end
            else
                if isempty(opts.hurricane(hurricane_id).name)
                    opts.hurricane(hurricane_id).name=data.storm_name;
                end
                if n==1
                    data.ntime=datenum(data.time,'yyyymmddHH');
                elseif n==2
                    data.ntime=datenum(data.time,'yyyymmddHH');
                elseif n==3
                    str=strsplit(data.time);
                    data.ntime=datenum(sprintf('%s-%s-%2d-%s',name(end-3:end),str{4},str2num(str{3}),str{1}),'yyyy-m-dd-HHMM');
                end
                best_track=[best_track;data.ntime,str2num(data.lat),str2num(data.lon),str2num(data.intensity),str2num(data.pressure)];
            end
            o=o+1;
        end
        if n>numel(exprs)
            error('Unknow kml type!');
        end
        opts.best_track{hurricane_id}=best_track;
    elseif opts.kml_type==5
        if ~isfield(opts,'hurricane')
            hurricane_all = {};
        else
            hurricane_all = extractfield(opts.hurricane,'id');
        end
        hurricane_id = find(ismember(hurricane_all, names{1}));
        if isempty(hurricane_id)
            error('unknown hurricane');
            return;
        end
        if strcmp(names{3},'track')==0
            return;
        end
        expr = '<Placemark(?<placemark>.+?)</Placemark>';
        obj = regexp(txt,expr,'names');
        o=1;
        forecast=[];
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
            if numel(data_t{1})>0
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
                else
                    data.pressure=-1000;
                end
                if numel(data_t{6})>0
                    w = strsplit(data_t{6}.data,{' '});
                    data.wind=str2num(w{1});
                else
                    data.wind=-1000;
                end
                forecast=[forecast;opts.model_id,data.ntime,data.forecast_time,data.lat,data.lon,data.wind,data.pressure];
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
            if numel(data_t{2})>0
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
                forecast=[forecast;opts.model_id,data.ntime,data.forecast_time,data.lat,data.lon,data.wind,data.pressure];
%                 if size(forecast,2)<7
%                     o=o;
%                 end           
                o=o+1;
                continue;
            end
            o=o+1;
        end
        opts.forecast{hurricane_id}=[opts.forecast{hurricane_id}; forecast];
    end
end
    
%     forecast_all = xml.kml.Document.Folder;
%     for m=1:numel(forecast_all)
%         if numel(forecast_all)==1
%             model_name = xml.kml.Document.Folder.name.Text;
%             Placemark = xml.kml.Document.Folder.Placemark;
%         else
%             model_name = xml.kml.Document.Folder{m}.name.Text;
%             Placemark = xml.kml.Document.Folder{m}.Placemark;
%         end
%         model_name = regexprep(model_name,'Model:\s*','');
%         if ~isfield(opts,'model')
%             model_id=1;
%             opts.model(1).id = model_name;
%             opts.model(1).type = model_type;
%         else
%             model_all = extractfield(opts.model,'id');
%             model_id = find(ismember(model_all, model_name));
%             if isempty(model_id)
%                 model_id=numel(model_all)+1;
%                 opts.model(model_id).id = model_name;
%                 opts.model(model_id).type = model_type;
%             end
%         end
%         for p=1:numel(Placemark)
%             forecast_time = Placemark{p}.name.Text;
%             forecast_time = regexprep(forecast_time,'.*Forecast Hour\s*','');
%             forecast_time = str2num(forecast_time);
%             if isempty(forecast_time)
%                 continue;
%             end
%          
%             forecast_coordinates = Placemark{p}.Point.coordinates.Text;
%             forecast_coordinates = regexprep(forecast_coordinates,'<coordinates.*?>(\s+)*','');
%             forecast_coordinates = regexprep(forecast_coordinates,'(\s+)*</coordinates>','');
%             forecast_coordinates = str2double(regexp(forecast_coordinates,'[,\s]+','split'));
%             forecast_lon = forecast_coordinates(1);
%             forecast_lat = forecast_coordinates(2);
%             
%             description = Placemark{p}.description.Text;
%             description = regexprep(description,'.*Wind:\s*','');
%             description = regexprep(description,'\s*kt.*','');
%             forecast_wind = str2double(description);
%             if isnan(forecast_wind)
%                 forecast_wind = -1;
%             end
%             
%             description = Placemark{p}.description.Text;
%             description = regexprep(description,'.*Minimum Sea Level Pressure:\s*','');
%             description = regexprep(description,'\s*hPa.*','');
%             forecast_pressure = str2double(description);
%             if isnan(forecast_pressure)
%                 forecast_pressure = -1;
%             end
%             
%             if ~isfield(opts,'forecast')
%                 opts.forecast = [hurricane_id model_id hurricane_time forecast_time forecast_lon forecast_lat forecast_wind forecast_pressure];
%             else
%                 opts.forecast = [opts.forecast; hurricane_id model_id hurricane_time forecast_time forecast_lon forecast_lat forecast_wind forecast_pressure];
%             end
%         end
%     end
    

