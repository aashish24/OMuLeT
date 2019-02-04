function hurricane_track = get_hurricane_track(opts)
%GET_HURRICANE_TRACK Summary of this function goes here
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

    process = 'Get hurricane track';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/hurricane.mat',filename_all.data_dir));
    load(sprintf('%s/forecast.mat',filename_all.data_dir));
    
    for h=1:numel(hurricane)
        fc=forecast{h};
        idx =  fc(:,3)==0 & fc(:,6)~=-1000 & fc(:,7)~=-1000;
        ht = fc(idx, [2 4:7]);
        [~, idx] = unique(ht(:,1));
        hurricane_track{h} = ht(idx,:);
    end
    
    save(sprintf('%s/hurricane_track.mat',filename_all.data_dir),'hurricane_track');
%     csvwrite(sprintf('%s/hurricane_track.csv',filename_all.data_dir),hurricane_track);
    fprintf('---------- %s / End ----------\n', process);
end

