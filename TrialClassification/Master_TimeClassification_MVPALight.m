
addpath('/gpfs01/born/group/Andrea/fieldtrip-20200828')
ft_defaults


addpath('/gpfs01/born/group/Andrea/Github/MVPA-Light/startup/')
startup_MVPA_Light


filesPath = '/gpfs01/born/group/Andrea/ReactivatedConnectivity/RawSleepData/preProcessing/Epoched_90Sec_ONOFF/OdorD_Night/';

files = dir(strcat(filesPath,'*.set'));


AllSubjData.trial = [];
AllSubjData.clabels = [];

for subj  = 1:numel(files)
    
    disp(strcat('Sujeto: ',files(subj).name))
    
    %----------------------------------------------------------------------
    % Import and convert to fieldtrip
    %----------------------------------------------------------------------
    addpath(genpath('/gpfs01/born/group/Andrea/eeglab2019_1/'))
    EEG = pop_loadset(strcat(filesPath,files(subj).name));
    ft_EEG = eeglab2fieldtrip(EEG,'raw');
    rmpath(genpath('/gpfs01/born/group/Andrea/eeglab2019_1/'))
    
    clear EEG
    
    %----------------------------------------------------------------------
    % Separate conditions
    %----------------------------------------------------------------------
    cfg = [];
    cfg.latency = [-5 30];
    ft_EEG_OdorD = ft_selectdata(cfg, ft_EEG);
    
    cfg = [];
    cfg.latency = [25 60];
    ft_EEG_VehicleD = ft_selectdata(cfg, ft_EEG);
    ft_EEG_VehicleD.time = ft_EEG_OdorD.time;


%%
    % OdorD vs Vehicle
    mintrials = min(size(ft_EEG_OdorD.trial,2),...
        size(ft_EEG_VehicleD.trial,2));

    CatTrials = cat(2,ft_EEG_OdorD.trial(1:mintrials),...
        ft_EEG_VehicleD.trial{1:mintrials});

    CatTime = cat(2,ft_EEG_OdorD.time(1:mintrials),...
        ft_EEG_VehicleD.time(1:mintrials));
        
    CatTrialInfo = cat(1,ft_EEG_OdorD.trialinfo,ft_EEG_VehicleD.trialinfo);
    
    attended_deviant = logical([ones(1,mintrials),zeros(1,mintrials)]); 

    % shuffle data
    v_trials = randperm(mintrials*2);
    dat = ft_EEG_OdorD;
    CatTrials = CatTrials(v_trials);
    dat.time = ft_EEG_OdorD.time{1};
    dat.trialinfo = CatTrialInfo(v_trials,:);
    attended_deviant = attended_deviant(v_trials);

    New_Trial = [];
    for trial = 1:length(CatTrials)
        New_Trial(trial,:,:) = CatTrials{trial};
    end

    dat.trial = New_Trial;
    clabel = attended_deviant;

     %% Train and test classifier
    
    % Average interval of interest
    %ival_idx = find(dat.time >= 0  & dat.time <= 15);
    
    % Extract the mean activity in the interval as features
    %X = squeeze(mean(dat.trial(:,:,ival_idx),3));
    X = dat.trial;
    
    %% Cross-validation

    
    cfg_LDA = [];
    cfg_LDA.classifier      = 'lda';
    cfg_LDA.metric          = 'accuracy';
    cfg_LDA.cv              = 'kfold';  % 'kfold' 'leaveout' 'holdout'
    cfg_LDA.k               = 5;
    cfg_LDA.repeat          = 10;
    cfg_LDA.preprocess      = {'zscore'};
    cfg_LDA.sample_dimension        = 1;
    cfg_LDA.feature_dimension       = 3;
    
    % the hyperparameter substruct contains the hyperparameters for the classifier.
    % Here, we only set lambda = 'auto'. This is the default, so in general
    % setting hyperparameter is not required unless one wants to change the default
    % settings.
    cfg_LDA.hyperparameter          = [];
    cfg_LDA.hyperparameter.lambda   = 'auto';
    
    
    Time_Intervals = [-4 0; -2 2; 0 4; 2 6; 4 8; 6 10; 8 12; 10 14;...
        12 16; 14 18; 16 20;18 22; 20 24; 22 26; 24 28; 26 30];
    
    for time_interval = 1:size(Time_Intervals)
        ival_idx = find(dat.time >= Time_Intervals(time_interval,1)  & ...
            dat.time <= Time_Intervals(time_interval,2));
        X = dat.trial(:,:,ival_idx);
        
        [acc_LDA(subj,time_interval,:), result_LDA] =  mv_classify(cfg_LDA, X, clabel);
    end
    
 
    AllSubjData.trial = cat(1,AllSubjData.trial,New_Trial);
    AllSubjData.clabels = cat(2,AllSubjData.clabels,attended_deviant);
    AllSubjData.time = dat.time;
end



cfg_LDA = [];
cfg_LDA.classifier      = 'lda';
cfg_LDA.metric          = 'accuracy';
cfg_LDA.cv              = 'kfold';  % 'kfold' 'leaveout' 'holdout'
cfg_LDA.k               = 5;
cfg_LDA.repeat          = 10;
cfg_LDA.preprocess      = {'zscore'};
cfg_LDA.sample_dimension        = 1;
cfg_LDA.feature_dimension       = 3;


cfg_LDA.hyperparameter          = [];
cfg_LDA.hyperparameter.lambda   = 'auto';

Time_Intervals = [-4 0; -2 2; 0 4; 2 6; 4 8; 6 10; 8 12; 10 14;...
    12 16; 14 18; 16 20;18 22; 20 24; 22 26; 24 28; 26 30];

clabel = AllSubjData.clabels;

for time_interval = 1:size(Time_Intervals)
    ival_idx = find(AllSubjData.time >= Time_Intervals(time_interval,1)  & ...
        AllSubjData.time <= Time_Intervals(time_interval,2));
    X = AllSubjData.trial(:,:,ival_idx);
    
    [acc_LDA_All(time_interval,:), result_LDA] =  mv_classify(cfg_LDA, X, clabel);
end


plot(squeeze(mean(acc_LDA,3))')

plot(squeeze(mean(acc_LDA_All,2)))

addpath(genpath('/gpfs01/born/group/Andrea/eeglab2019_1/'))

for time_interval = [3,4,5,6,12,13,14,15,16]%1:size(Time_Intervals) 
    figure
    topoplot(acc_LDA_All(time_interval,:), reducedchanlocs,'maplimits',[0.45 0.55]);colorbar; 
    
    title(num2str(Time_Intervals(time_interval,:)))
end
   
%%
for subj = 1:size(acc_LDA,1)
    %plot subject by subject
    for time_interval = 1:size(Time_Intervals)
        figure
        topoplot(acc_LDA(subj,time_interval,:).*(acc_LDA(subj,time_interval,:)>0.6),...
            reducedchanlocs,'maplimits',[0 0.8],'conv','on');colorbar;
        
        title(strcat('SUBJ',num2str(subj),' Interval',num2str(Time_Intervals(time_interval,:))))
    end
end


for time_interval = 1:size(Time_Intervals)
        figure
        topoplot(squeeze(mean(acc_LDA(:,time_interval,:),1)),...
            reducedchanlocs,'maplimits',[0.4 0.6],'conv','on');colorbar;
        
        title(strcat('Interval',num2str(Time_Intervals(time_interval,:))))
end


%%
function New_x = f_zscore_normalization(x)
    New_x = x;
      %------Trial by trial normalization------
     for trial = 1:size(x.data,3)
         mean_x= squeeze(mean(x.data(:,:,trial),2));
         std_x = squeeze(std(double(x.data(:,:,trial)),[],2));
         
         mean_x = repmat(mean_x,1,size(x.data,2),1);
         std_x = repmat(std_x,1,size(x.data,2),1);
         
         New_x.trial(:,:,trial) = (squeeze(x.data(:,:,trial))-mean_x)./std_x;
     end
    
    %------Normalization across trials----
%    mean_x= mean(x.data(:));
%    std_x= std(x.data(:));
      
%    mean_x = repmat(mean_x,size(x.data,1),size(x.data,2),size(x.data,3));
%    std_x = repmat(std_x,size(x.data,1),size(x.data,2),size(x.data,3));
      
      
%    New_x.trial = x.data-mean_x./std_x;
end