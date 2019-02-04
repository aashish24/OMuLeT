function plot_forecast_corrcoef(opts)
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

    process = 'Get plot for forecast with different lead time';
    fprintf('---------- %s / Begin ----------\n', process);
    
    load(sprintf('%s/forecast_tensor_6_8.mat',filename_all.data_dir));
    load(sprintf('%s/hurricane.mat',filename_all.data_dir));
    load(sprintf('%s/model.mat',filename_all.data_dir));
    
    same=zeros(8,8,2);
    diff=zeros(8,8,2);
    same2=cell(8,8,2);
    diff2=cell(8,8,2);
    
    dt_max=2;
    tau_max=8;
    num=numel(forecast_tensor);
    
    t1=clock;
    for h=1:num
        if mod(h,20)==0
            t2=clock;
            fprintf('%s / Runs:%d/%d / Timeleft:%s\n', process, h, num, get_timeleft(h,num,t1,t2));
        end
        same3=cell(8,8,2);
        diff3=cell(8,8,2);
        fc=forecast_tensor(h);
        for j=1:2
            for dt=1:dt_max
                for tau=1:size(fc.X,3)
                    num_model=size(fc.X,1);
                    for t=1:size(fc.X,4)
                        if t+dt<=size(fc.X,4)
                            X1=fc.X(:,j,tau,t);
                            X2=fc.X(:,j,tau,t+dt);
                            L1=fc.label(tau,t);
                            L2=fc.label(tau,t+dt);
                            if L1<=0 || L2<=0
                                continue;
                            end
                            Z1=X1-fc.Y(j,L1);
                            Z2=X2-fc.Y(j,L2);
                            idx1=find(X1~=-1000);
                            idx2=find(X2~=-1000);
                            l1=length(idx1);
                            l2=length(idx2);
                            [idx3,idx4]=ind2sub([l1,l2],1:l1*l2);
                            idx1=idx1(idx3);
                            idx2=idx2(idx4);
                            idx=idx1==idx2;
                            same3{tau,dt,j}=[same3{tau,dt,j};Z1(idx1(idx)),Z2(idx2(idx))];
                            diff3{tau,dt,j}=[diff3{tau,dt,j};Z1(idx1(~idx)),Z2(idx2(~idx))];
                        end
                    end
                end
            end
        end
        for j=1:2
            for dt=1:dt_max
                for tau=1:size(fc.X,3)
                    same2{tau,dt,j}=[same2{tau,dt,j}; same3{tau,dt,j}];
                    diff2{tau,dt,j}=[diff2{tau,dt,j}; diff3{tau,dt,j}];
                end
            end
        end
    end
    for j=1:2
        for dt=1:dt_max
            for tau=1:8
                coef=corrcoef(same2{tau,dt,j}(:,1),same2{tau,dt,j}(:,2));
                same(tau,dt,j)=coef(1,2);
                coef=corrcoef(diff2{tau,dt,j}(:,1),diff2{tau,dt,j}(:,2));
                diff(tau,dt,j)=coef(1,2);
            end
        end
    end
    %plot
    for j=1:2
        for dt=1:dt_max
            for tau=1:8
                fprintf('%1.2f,%1.2f', same(tau,dt,j),diff(tau,dt,j));
                if tau<8
                    fprintf(' & ');
                end
            end
            fprintf('\\\\ \\hline \n');
        end
        fprintf('\n');
    end
    
    same=zeros(8,8,2);
    diff=zeros(8,8,2);
    same2=cell(8,8,2);
    diff2=cell(8,8,2);
    
    t1=clock;
    for h=1:num
        if mod(h,20)==0
            t2=clock;
            fprintf('%s / Runs:%d/%d / Timeleft:%s\n', process, h, num, get_timeleft(h,num,t1,t2));
        end
        same3=cell(8,8,2);
        diff3=cell(8,8,2);
        fc=forecast_tensor(h);
        for j=1:2
            for tau1=1:tau_max
                for tau2=1:tau_max
                    num_model=size(fc.X,1);
                    for t=1:size(fc.X,4)
                        X1=fc.X(:,j,tau1,t);
                        X2=fc.X(:,j,tau2,t);
                        L1=fc.label(tau1,t);
                        L2=fc.label(tau2,t);
                        if L1<=0 || L2<=0
                            continue;
                        end
                        Z1=X1-fc.Y(j,L1);
                        Z2=X2-fc.Y(j,L2);
                        idx1=find(X1~=-1000);
                        idx2=find(X2~=-1000);
                        l1=length(idx1);
                        l2=length(idx2);
                        [idx3,idx4]=ind2sub([l1,l2],1:l1*l2);
                        idx1=idx1(idx3);
                        idx2=idx2(idx4);
                        idx=idx1==idx2;
                        same3{tau2,tau1,j}=[same3{tau2,tau1,j};Z1(idx1(idx)),Z2(idx2(idx))];
                        diff3{tau2,tau1,j}=[diff3{tau2,tau1,j};Z1(idx1(~idx)),Z2(idx2(~idx))];
                    end
                end
            end
        end
        for j=1:2
            for tau1=1:tau_max
                for tau2=1:tau_max
                    same2{tau2,tau1,j}=[same2{tau2,tau1,j}; same3{tau2,tau1,j}];
                    diff2{tau2,tau1,j}=[diff2{tau2,tau1,j}; diff3{tau2,tau1,j}];
                end
            end
        end
    end
    for j=1:2
        for tau1=1:tau_max
            for tau2=1:tau_max
                coef=corrcoef(same2{tau2,tau1,j}(:,1),same2{tau2,tau1,j}(:,2));
                same(tau2,tau1,j)=coef(1,2);
                coef=corrcoef(diff2{tau2,tau1,j}(:,1),diff2{tau2,tau1,j}(:,2));
                diff(tau2,tau1,j)=coef(1,2);
            end
        end
    end
    %plot
    for j=1:2
        for tau1=1:tau_max
            for tau2=1:tau_max
                fprintf('%1.2f,%1.2f', same(tau2,tau1,j),diff(tau2,tau1,j));
                if tau2<8
                    fprintf(' & ');
                end
            end
            fprintf('\\\\ \\hline \n');
        end
        fprintf('\n');
    end
    
    
    fprintf('---------- %s / End ----------\n', process);

end

