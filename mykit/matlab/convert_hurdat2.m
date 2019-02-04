function opts = convert_hurdat2(opts)
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

    process = 'Convert Hurdat2 best track';
    fprintf('---------- %s / Begin ----------\n', process);
    
%     load(sprintf('%s/raw/hurricane.mat',filename_all.data_dir));
%     hurricane_all = extractfield(hurricane,'id');

    listing = dir(sprintf('%s/NHC/hurdat2',filename_all.base_dir));
    num = numel(listing)-2;
    
    hurricane=[];
    best_track=[];
    t1=clock;
    for p=1:num
        fid=fopen([listing(p+2).folder,'/',listing(p+2).name]);
        tline=fgets(fid);
        while ~feof(fid)
            str=strsplit(tline,',');
            id=lower(str{1});
            name=strrep(str{2}, ' ', '');
%             name=strrep(str{2}, 'UNNAMED', '');
            num_track=str2num(str{3});
%             hurricane_id = find(ismember(hurricane, id));
            hurricane_id=numel(hurricane)+1;
            hurricane(hurricane_id).id=id;
            hurricane(hurricane_id).name=name;
            if id(1)=='a'
                hurricane(hurricane_id).location=1;
            elseif id(1)=='e'
                hurricane(hurricane_id).location=2;
            elseif id(1)=='c'
                hurricane(hurricane_id).location=3;
            else
                hurricane(hurricane_id).location=0;
            end
            track=[];
            for ii=1:num_track
                tline=fgets(fid);
                str=strsplit(tline,',');
                time=datenum(strrep([str{1} str{2}],' ',''),'yyyymmddHHMM');
                lat=str{5};
                if lat(end)=='N'
                    lat=str2num(lat(1:end-1));
                elseif lat(end)=='S'
                    lat=-str2num(lat(1:end-1));
                else
                    error('unknow latitude');
                end
                lon=str{6};
                if lon(end)=='E'
                    lon=str2num(lon(1:end-1));
                elseif lon(end)=='W'
                    lon=-str2num(lon(1:end-1));
                else
                    error('unknow longitude');
                end
                wind=str2num(str{7});
                pressure=str2num(str{8});
                track=[track; time lat lon wind pressure];
            end
            best_track{hurricane_id}=track;
            hurricane(hurricane_id).start_time=track(1,1);
            hurricane(hurricane_id).end_time=track(end,1);
            tline=fgets(fid);
        end
    end
    save(sprintf('%s/raw/hurricane.mat',filename_all.data_dir),'hurricane');
    save(sprintf('%s/raw/best_track.mat',filename_all.data_dir),'best_track');
    
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

