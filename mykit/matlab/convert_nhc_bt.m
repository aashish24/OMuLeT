function opts = convert_nhc_bt(opts)
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

    process = 'Convert NHC best track data';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/raw/hurricane.mat',filename_all.data_dir));
    load(sprintf('%s/raw/best_track.mat',filename_all.data_dir));

    listing = dir(sprintf('%s/NHC/best_track',filename_all.base_dir));
    num = numel(listing)-2;
    t1=clock;
    for p=1:num
        if mod(p,100)==0
            t2=clock;
            fprintf('%s / Runs:%d/%d / Timeleft:%s\n', process, p, num, get_timeleft(p,num,t1,t2));
        end
        [filepath,id,ext] = fileparts(listing(p+2).name);
        hurricane_all = extractfield(hurricane,'id');
        hurricane_id = find(ismember(hurricane_all, id));
        if isempty(hurricane_id)
            hurricane_id=numel(hurricane)+1;
            hurricane(hurricane_id).id=id;
            if id(1)=='a'
                hurricane(hurricane_id).location=1;
            elseif id(1)=='e'
                hurricane(hurricane_id).location=2;
            elseif id(1)=='c'
                hurricane(hurricane_id).location=3;
            else
                hurricane(hurricane_id).location=0;
            end
            best_track{hurricane_id}=[];
%             opts=convert_kml([listing(p+2).folder '/' listing(p+2).name], opts);

            filename =[listing(p+2).folder '/' listing(p+2).name];
            [fid msg] = fopen(filename,'rt');
            if fid<0
                error(msg)
            end
            txt = fread(fid,'uint8=>char')';
            fclose(fid);

            [filepath,name,ext] = fileparts(filename);
            name=lower(name);
            names = regexp(name,'_','split');
    
            hurricane_all = extractfield(hurricane,'id');
    %         model_all = extractfield(model,'id');
            hurricane_id = find(ismember(hurricane_all, names{1}));
            expr = '<Placemark(?<placemark>.+?)</Placemark>';
            obj = regexp(txt,expr,'names');
            exprs{1} = '<lat>(?<lat>.+?)</lat>\s*<lon>(?<lon>.+?)</lon>.+?<stormName>(?<storm_name>.*)</stormName>.+?<intensity>(?<intensity>\d*)</intensity>.+?<minSeaLevelPres>(?<pressure>\d*)</minSeaLevelPres>\s*<atcfdtg>(?<time>\d*)</atcfdtg>';
            exprs{2} = '<td>STORMNAME</td>\s*<td>(?<storm_name>.*)</td>.+?<td>DTG</td>\s*<td>(?<time>.+?)</td>.+?<td>MSLP</td>\s*<td>(?<pressure>\d*)</td>.+?<td>INTENSITY</td>\s*<td>(?<intensity>.+?)</td>.+?<td>LAT</td>\s*<td>(?<lat>.+?)</td>.+?<td>LON</td>\s*<td>(?<lon>.+?)</td>';
            exprs{3} = '<name>(?<time>.+?)</name>.+?<td>LAT</td>\s*<td>(?<lat>.+?)</td>.+?<td>LON</td>\s*<td>(?<lon>.+?)</td>.+?<td>MSLP_mb</td>\s*<td>(?<pressure>\d*)\s*mb</td>.+?<td>INTENSITY_kt</td>\s*<td>(?<intensity>\d*)\s*kt</td>';
            bt=[];
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
                    if isempty(hurricane(hurricane_id).name)
                        hurricane(hurricane_id).name=data.storm_name;
                    end
                    if n==1
                        data.ntime=datenum(data.time,'yyyymmddHH');
                    elseif n==2
                        data.ntime=datenum(data.time,'yyyymmddHH');
                    elseif n==3
                        str=strsplit(data.time);
                        data.ntime=datenum(sprintf('%s-%s-%2d-%s',name(end-3:end),str{4},str2num(str{3}),str{1}),'yyyy-m-dd-HHMM');
                    end
                    bt=[bt;data.ntime,str2num(data.lat),str2num(data.lon),str2num(data.intensity),str2num(data.pressure)];
                end
                o=o+1;
            end
            if kml_flag
                error('Unknow kml type!');
            end
            best_track{hurricane_id}=bt;
            hurricane(hurricane_id).start_time=bt(1,1);
            hurricane(hurricane_id).end_time=bt(end,1);
        end
    end
    save(sprintf('%s/raw/hurricane.mat',filename_all.data_dir),'hurricane');
    save(sprintf('%s/raw/best_track.mat',filename_all.data_dir),'best_track');
    
    fprintf('---------- %s / End ----------\n', process);
end

