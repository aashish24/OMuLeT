function [train, test] = get_dataset_LSTM(opts)
%GET_best_track Summary of this function goes here
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

    process = 'Get dataset';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/forecast.mat',filename_all.data_dir));
    load(sprintf('%s/model.mat',filename_all.data_dir));
    load(sprintf('%s/best_track.mat',filename_all.data_dir));
    load(sprintf('%s/forecast_label.mat',filename_all.data_dir));
    load(sprintf('%s/train_test_idx.mat',filename_all.data_dir));
    
    [~,model_ids] = ismember(opts.models, extractfield(model,'id'));
    
    train.A = [];
    train.B = [];
    train.Y = [];
    train.L = [];
    train.l = [];
    num_train = 0;
    for p=1:length(train_idx)
        h=train_idx(p);
        idx = forecast{h}(:,3)<=opts.b*opts.t & forecast{h}(:,3)>0 & mod(forecast{h}(:,2),opts.t/24)==0 & mod(forecast{h}(:,3),opts.t)==0 & ismember(forecast{h}(:,1),model_ids) & forecast_label{h}>0;
        if sum(idx)==0
            continue;
        end
        fc_b = forecast{h}(idx,:);
        ht_b = best_track{h}(forecast_label{h}(idx),:);
        idx = fc_b(:,3)<=opts.a*opts.t;
        fc_a = fc_b(idx,:);
        ht_a = ht_b(idx,:);
        t_min = min(fc_b(:,2));
        t_max = max(fc_b(:,2));
        t_all = t_min:(opts.t/24):t_max;
        t_num = length(t_all);
        flag = true(1,length(t_all));
        
        A_all = [];
        B_all = [];
        Y_all = [];
        L_all = [];
        for t=1:t_num
            idx_b=fc_b(:,2)==t_all(t);
            fc_bu=unique(fc_b(idx_b,3));
            idx_a=(fc_a(:,2)+fc_a(:,3)/24)==t_all(t);
            fc_au=unique(fc_a(idx_a,3));
            A = zeros(opts.a, opts.p, opts.f);
            B = zeros(opts.b, opts.p, opts.f);
            Y = zeros(1, opts.f);
            L = zeros(opts.b, opts.f);
            if length(fc_bu)<opts.b || length(fc_au)<opts.a || (~opts.percentile && (sum(idx_b)<opts.b*opts.p || sum(idx_a)<opts.a*opts.p))
                flag(t)=false;
            else
                fc_at=fc_a(idx_a,:);
                ht_at=ht_a(idx_a,:);
                A=[];
                Y=ht_at(1,[2 3]);
                for ii=1:opts.a
                    idx=fc_at(:,3)==ii*opts.t;
                    fc_att=fc_at(idx,:);
                    if opts.percentile
                        fc_atts=sort(fc_att(:,[4,5]));
                    else
                        fc_atts=fc_att(:,[4,5]);
                    end
                    idx=get_idx(1,size(fc_atts,1),opts.p);
                    A(ii,:,:)=fc_atts(idx,:);
                end
                fc_bt=fc_b(idx_b,:);
                ht_bt=ht_b(idx_b,:);
                B=[];
                L=[];
                for ii=1:opts.b
                    idx=fc_bt(:,3)==ii*opts.t;
                    fc_btt=fc_bt(idx,:);
                    if opts.percentile
                        fc_btts=sort(fc_btt(:,[4,5]));
                    else
                        fc_btts=fc_btt(:,[4,5]);
                    end
                    ht_btt=ht_bt(idx,[2,3]);
                    idx=get_idx(1,size(fc_btts,1),opts.p);
                    B(ii,:,:)=fc_btts(idx,:);
                    L(ii,:)=ht_btt(1,:);
                end
            end
            A_all(t,:,:,:)=A;
            B_all(t,:,:,:)=B;
            Y_all(t,:)=Y;
            L_all(t,:,:)=L;
        end 
        for f=1:length(flag)-opts.s+1
            idx=f:f+opts.s-1;
            if sum(flag(idx))==opts.s
                num_train=num_train+1;
                train.A(num_train,:,:,:,:)=A_all(idx,:,:,:);
                train.B(num_train,:,:,:,:)=B_all(idx,:,:,:);
                train.Y(num_train,:,:)=Y_all(idx,:);
                train.L(num_train,:,:,:)=L_all(idx,:,:);
                train.l(num_train,:,:)=L_all(f+opts.s-1,:,:);
            end
        end
    end
    
    test.A = [];
    test.B = [];
    test.Y = [];
    test.L = [];
    test.l = [];
    num_test = 0;
    for p=1:length(test_idx)
        h=test_idx(p);
        idx = forecast{h}(:,3)<=opts.b*opts.t & forecast{h}(:,3)>0 & mod(forecast{h}(:,2),opts.t/24)==0 & mod(forecast{h}(:,3),opts.t)==0 & ismember(forecast{h}(:,1),model_ids) & forecast_label{h}>0;
        if sum(idx)==0
            continue;
        end
        fc_b = forecast{h}(idx,:);
        ht_b = best_track{h}(forecast_label{h}(idx),:);
        idx = fc_b(:,3)<=opts.a*opts.t;
        fc_a = fc_b(idx,:);
        ht_a = ht_b(idx,:);
        t_min = min(fc_b(:,2));
        t_max = max(fc_b(:,2));
        t_all = t_min:(opts.t/24):t_max;
        t_num = length(t_all);
        flag = true(1,length(t_all));
        
        A_all = [];
        B_all = [];
        Y_all = [];
        L_all = [];
        for t=1:t_num
            idx_b=fc_b(:,2)==t_all(t);
            fc_bu=unique(fc_b(idx_b,3));
            idx_a=(fc_a(:,2)+fc_a(:,3)/24)==t_all(t);
            fc_au=unique(fc_a(idx_a,3));
            A = zeros(opts.a, opts.p, opts.f);
            B = zeros(opts.b, opts.p, opts.f);
            Y = zeros(1, opts.f);
            L = zeros(opts.b, opts.f);
            if length(fc_bu)<opts.b || length(fc_au)<opts.a || (~opts.percentile && (sum(idx_b)<opts.b*opts.p || sum(idx_a)<opts.a*opts.p))
                flag(t)=false;
            else
                fc_at=fc_a(idx_a,:);
                ht_at=ht_a(idx_a,:);
                A=[];
                Y=ht_at(1,[2 3]);
                for ii=1:opts.a
                    idx=fc_at(:,3)==ii*opts.t;
                    fc_att=fc_at(idx,:);
                    if opts.percentile
                        fc_atts=sort(fc_att(:,[4,5]));
                    else
                        fc_atts=fc_att(:,[4,5]);
                    end
                    idx=get_idx(1,size(fc_atts,1),opts.p);
                    A(ii,:,:)=fc_atts(idx,:);
                end
                fc_bt=fc_b(idx_b,:);
                ht_bt=ht_b(idx_b,:);
                B=[];
                L=[];
                for ii=1:opts.b
                    idx=fc_bt(:,3)==ii*opts.t;
                    fc_btt=fc_bt(idx,:);
                    if opts.percentile
                        fc_btts=sort(fc_btt(:,[4,5]));
                    else
                        fc_btts=fc_btt(:,[4,5]);
                    end
                    ht_btt=ht_bt(idx,[2,3]);
                    idx=get_idx(1,size(fc_btts,1),opts.p);
                    B(ii,:,:)=fc_btts(idx,:);
                    L(ii,:)=ht_btt(1,:);
                end
            end
            A_all(t,:,:,:)=A;
            B_all(t,:,:,:)=B;
            Y_all(t,:)=Y;
            L_all(t,:,:)=L;
        end 
        for f=1:length(flag)-opts.s+1
            idx=f:f+opts.s-1;
            if sum(flag(idx))==opts.s
                num_test=num_test+1;
                test.A(num_test,:,:,:,:)=A_all(idx,:,:,:);
                test.B(num_test,:,:,:,:)=B_all(idx,:,:,:);
                test.Y(num_test,:,:)=Y_all(idx,:);
                test.L(num_test,:,:,:)=L_all(idx,:,:);
                test.l(num_test,:,:)=L_all(f+opts.s-1,:,:);
            end
        end
    end
        
        

%     num=0;
%     for p=1:length(test_idx)
%         h=test_idx(p);
%         idx = forecast{h}(:,3)<=opts.forecast_time & mod(forecast{h}(:,3),6)==0 & ismember(forecast{h}(:,1),model_ids) & forecast_label{h}>0;
%         if sum(idx)==0
%             continue;
%         end
%         fc = forecast{h}(idx,:);
%         ht = best_track{h}(forecast_label{h}(idx),:);
%         [C,ia,ic] = unique(fc(:,[2 3]),'rows');
%         fc2 = [];
%         ht2 = [];
%         for ii = 1:length(C)
%             idx = find(ic==ii);
%             fc2 = [fc2; fc(idx(1),[2 3]) median(fc(idx,4:end),1)];
%             ht2 = [ht2; ht(idx(1),:)];
%         end
%         time=unique(fc2(:,1));
%         s=opts.forecast_time/6+1;
%         for t=1:numel(time)
%             idx=fc2(:,1)==time(t);
%             if sum(idx)==s
%                 num=num+1;
%                 test.X=[test.X; reshape(fc2(idx,[3:4]),1,s*2)];
%                 test.y=[test.y; reshape(ht2(idx,[2:3]),1,s*2)];
%                 test_csv.X=[test_csv.X; reshape(fc2(idx,[3:4])',1,s*2)];
%                 test_csv.y=[test_csv.y; reshape(ht2(idx,[2:3])',1,s*2)];
%             end
%         end
%     end
    
    folder=sprintf('dataset_LSTM_%d_%d_%d_%d',opts.s,opts.a,opts.b,opts.p);
    makedir(sprintf('%s/%s',filename_all.data_dir,folder));
    save(sprintf('%s/%s/dataset_LSTM.mat',filename_all.data_dir,folder),'train','test');
    
    size_A = opts.s*opts.a*opts.p*opts.f;
    size_B = opts.s*opts.b*opts.p*opts.f;
    size_Y = opts.s*opts.f;
    size_L = opts.s*opts.b*opts.f;
    size_l = opts.b*opts.f;
    train_A = reshape(train.A, num_train, size_A);
    train_B = reshape(train.B, num_train, size_B);
    train_Y = reshape(train.Y, num_train, size_Y);
    train_L = reshape(train.L, num_train, size_L);
    train_l = reshape(train.l, num_train, size_l);
    test_A = reshape(test.A, num_test, size_A);
    test_B = reshape(test.B, num_test, size_B);
    test_Y = reshape(test.Y, num_test, size_Y);
    test_L = reshape(test.L, num_test, size_L);
    test_l = reshape(test.l, num_test, size_l);
    
    csvwrite(sprintf('%s/%s/train_A.csv',filename_all.data_dir,folder),train_A);
    csvwrite(sprintf('%s/%s/train_B.csv',filename_all.data_dir,folder),train_B);
    csvwrite(sprintf('%s/%s/train_Y.csv',filename_all.data_dir,folder),train_Y);
    csvwrite(sprintf('%s/%s/train_L.csv',filename_all.data_dir,folder),train_L);
    csvwrite(sprintf('%s/%s/train_l.csv',filename_all.data_dir,folder),train_l);    
    csvwrite(sprintf('%s/%s/test_A.csv',filename_all.data_dir,folder),test_A);
    csvwrite(sprintf('%s/%s/test_B.csv',filename_all.data_dir,folder),test_B);
    csvwrite(sprintf('%s/%s/test_Y.csv',filename_all.data_dir,folder),test_Y);
    csvwrite(sprintf('%s/%s/test_L.csv',filename_all.data_dir,folder),test_L);
    csvwrite(sprintf('%s/%s/test_l.csv',filename_all.data_dir,folder),test_l);       
    
    fprintf('---------- %s / End ----------\n', process);
end

