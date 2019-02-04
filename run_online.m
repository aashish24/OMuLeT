addpath('mykit/matlab');

opts.config_filename='uwm.config';

opts.time_train=datenum('201401010000','yyyymmddHHMM');
opts.time_vali=datenum('201501010000','yyyymmddHHMM');
opts.time_year(1)=datenum('201301010000','yyyymmddHHMM');
opts.time_year(2)=datenum('201401010000','yyyymmddHHMM');
opts.time_year(3)=datenum('201501010000','yyyymmddHHMM');
opts.time_year(4)=datenum('201601010000','yyyymmddHHMM');
opts.time_year(5)=datenum('201701010000','yyyymmddHHMM');
opts.time_year(6)=datenum('201801010000','yyyymmddHHMM');
% 0 for all, 1 for al, 2 for ep
opts.location=0;
get_hurricane_split(opts);

% opts.models = {'AP01' 'AP02' 'AP03' 'AP04' 'AP05' 'AP06' 'AP07' 'AP08' 'AP09' 'AP10' 'AP11' 'AP12' 'AP13' 'AP14' 'AP15' 'AP16' 'AP17' 'AP18' 'AP19' 'AP20'};
% opts.models = {'NVGM' 'NVGI' 'AVNO' 'AVNI' 'GFSO' 'GFSI' 'EMX' 'EMXI' 'EMX2' 'EGRR' 'EGRI' 'EGR2' 'CMC' 'CMCI' 'HWRF' 'HWFI' 'CTCX' 'CTCI' 'HMON' 'HMNI' 'AEMN' ...
% 'AEMI' 'UEMN' 'UEMI' 'EEMN' 'EMN2' 'FSSE' 'HCCA' 'GFEX' 'TVCN' 'TVCA' 'TVCN' 'TVCE' 'TVCX' 'RVCN' 'IVCN' 'CLP5' 'OCD5' 'SHF5' 'DSF5' 'OCD5' 'TCLP' 'DRCL' 'SHIP' 'DSHP' 'LGEM' };
% [~,model_ids] = ismember(opts.models, extractfield(model,'id'))
% 30 out of 46
% NVGM NVGI AVNO AVNI EGRI EGR2 CMC CMCI HWRF HWFI CTCX CTCI HMON HMNI AEMN AEMI TVCN TVCA TVCN TVCE TVCX RVCN CLP5 OCD5 OCD5 TCLP DRCL SHIP DSHP LGEM
opts.models = [2 3 8 9 10 11 15 17 22 23 25 26 26 47 50 52 59 67 71 72 72 76 77 80 106 107 108 109 111 117];
% opts.models = 2:157;
opts.models_min=1;
opts.models_percent=0;

% opts.percentile = false;

opts.t=6;  % time interval
opts.s=2;  % window size
opts.alpha=8;  % forcasted
opts.beta=8;  % forcast
opts.f=2;  % feature number

% para=[0.3    0.8    6  150.0000    3    0.5];
% para=[0.55    0.8    1.6  450    2    0.3];
% para=[0.55    0.8    0.3  400    1.5    0.3];
para=[0.5    0.8    0.1  450    1.6    0.3];
% 1.0349    0.8000    1.4400  555.5556    1.6200    0.2187
opts.rho=para(1);
opts.gamma=para(2);
opts.omega=para(3);
opts.mu=para(4);
opts.nu=para(5);
opts.eta=para(6);

get_forecast_tensor(opts);
get_forecast_error(opts);
get_forecast_online(opts);
get_forecast_online_error(opts);

% get_forecast_online_error_years(opts)
% myplot

return;

% sensitivity(1).x=0:0.02:1;
% sensitivity(2).x=0.1:0.05:2;
% sensitivity(3).x=0:0.05:2;
% sensitivity(4).x=0:50:1000;
% sensitivity(5).x=0:0.1:5;
% sensitivity(6).x=0:0.05:2;
% 
% for i=1:6
%     sensitivity(i).y=[];
%     para=[0.55    0.8    1.6  450    2    0.3];
%     for p=sensitivity(i).x
%         para(i)=p;
%         opts_t=opts;
%         opts_t.rho=para(1);
%         opts_t.gamma=para(2);
%         opts_t.omega=para(3);
%         opts_t.mu=para(4);
%         opts_t.nu=para(5);
%         opts_t.eta=para(6);
%         get_forecast_online(opts_t);
%         error=get_forecast_online_error(opts_t);
%         sensitivity(i).y=[sensitivity(i).y error];
%         sensitivity(i)
%     end
% end
yl={'\rho','\gamma','\omega','\mu','\nu','\eta'};
for i=1:6
    subplot(3,2,i)
    plot(sensitivity(i).x,sensitivity(i).y(4,:))
    ylabel('ME','FontSize',10);
    xlabel(yl(i),'FontSize',12);
end

return

% tune parameters

ratio=0.9;
% para=[0.3    0.8    6  150.0000    3    0.5]
para=[0.55    0.8    0.3  400    1.5    0.3];
opts.rho=para(1);
opts.gamma=para(2);
opts.omega=para(3);
opts.mu=para(4);
opts.nu=para(5);
opts.eta=para(6);
get_forecast_online(opts);
error=get_forecast_online_error(opts);
error_pre=error;

% return;

for p=1:1000
    for j=1:length(para)
        bak=para(j);
        para(j)=bak*0.9;
        opts.rho=para(1);
        opts.gamma=para(2);
        opts.omega=para(3);
        opts.mu=para(4);
        opts.nu=para(5);
        opts.eta=para(6);
        get_forecast_online(opts);
        error1=get_forecast_online_error(opts);
        para
%         myplot
        para(j)=bak/0.9;
        opts.rho=para(1);
        opts.gamma=para(2);
        opts.omega=para(3);
        opts.mu=para(4);
        opts.nu=para(5);
        opts.eta=para(6);
        get_forecast_online(opts);
        error2=get_forecast_online_error(opts);
        para
%         myplot
        [~,idx]=min([error(4),error1(4),error2(4)]);
        if idx==1
            para(j)=bak;
            error=error;
        elseif idx==2
            para(j)=bak*0.9;
            error=error1;
        else
            para(j)=bak/0.9;
            error=error2;
        end
        error
        para
    end
    if error(4)>=error_pre(4)
        break;
    end
    error_pre=error;
end



