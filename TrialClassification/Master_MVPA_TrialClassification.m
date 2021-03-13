
filesPath       = '/mnt/disk1/sleep/Datasets/Ori_PlaceboNight/EEGLABFilt_Mastoids_Off_On_200Hz_Oct_NEW_EEGLAB/';
filesOdor       = dir(strcat(filesPath,'*Odor.set'));
filesVehicle    = dir(strcat(filesPath,'*Sham.set'));

addpath('/home/andrea/Documents/MatlabFunctions/fieldtrip-20200828')
ft_defaults

addpath('/mnt/disk1/andrea/German_Study/')
p_filesPerNight
p_clustersOfInterest

trials2rejFile      = '';
trials2rejVar       = 'comps2reject';

addpath('/home/andrea/Documents/MatlabFunctions/MVPA-Light/startup/')
startup_MVPA_Light



ChansOfInterest = 'all';% Clust.central; %'all';
AllSubjData.trial = [];
AllSubjData.clabels = [];

for subj  = 1:numel(filesOdor)
    
    disp(strcat('Sujeto: ',filesOdor(subj).name))
    file_Odor = filesOdor(subj).name;
    file_Vehicle = filesVehicle(subj).name;

    %% Odor D Night
    addpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1'))

    [EEGOdorD] = pop_loadset('filename', file_Odor,'filepath', filesPath);
    [EEGVehicleD] = pop_loadset('filename', file_Vehicle,'filepath', filesPath);
    
    EEGOdorD = f_zscore_normalization(EEGOdorD); % z score normalization
    EEGVehicleD = f_zscore_normalization(EEGVehicleD); % z score normalization

    %%

    %-----Epoch the data for Odor D -------------
    ft_EEG_OdorD = eeglab2fieldtrip(EEGOdorD,'raw');
    cfg = []; cfg.channel = ChansOfInterest; cfg.avgoverchan = 'no';%ft_EEG_Odor.label(1:end-1);
    ft_EEG_OdorD = ft_selectdata(cfg, ft_EEG_OdorD);
    
    %-----Epoch the data for Vehicle D -------------
    ft_EEG_VehicleD = eeglab2fieldtrip(EEGVehicleD,'raw');
    cfg = []; cfg.channel = ChansOfInterest; cfg.avgoverchan = 'no'; %ft_EEG_Vehicle.label(1:end-1);
    ft_EEG_VehicleD = ft_selectdata(cfg, ft_EEG_VehicleD);
    rmpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1'))


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
    ival_idx = find(dat.time >= 0  & dat.time <= 15);
    
    % Extract the mean activity in the interval as features
    %X = squeeze(mean(dat.trial(:,:,ival_idx),3));
    X = dat.trial(:,:,ival_idx);
    
    %% Cross-validation
    
    cfg                 = [];
    cfg.classifier      = 'svm';
    cfg.metric          = 'accuracy';
    cfg.cv              = 'kfold';  % 'kfold' 'leaveout' 'holdout'
    cfg.k               = 5;
    cfg.repeat          = 10;
    cfg.preprocess      = {'zscore'};
    cfg.sample_dimension        = 1;
    cfg.feature_dimension       = 3;
    
    cfg.hyperparameter          = [];
    cfg.hyperparameter.lambda   = 'auto';
    
    [acc, result] = mv_classify(cfg, X, clabel);
        
    % Produce plot of results
    %h = mv_plot_result({result_LDA, result_LR});
    
    Accuracy(:,subj) = acc;

    AllSubjData.trial = cat(1,AllSubjData.trial,New_Trial);
    AllSubjData.clabels = cat(2,AllSubjData.clabels,attended_deviant);
    AllSubjData.time = dat.time;
end

 % Average interval of interest
 ival_idx = find(AllSubjData.time >= 0  & AllSubjData.time <= 15);
    
 % Extract the mean activity in the interval as features
 X = AllSubjData.trial(:,:,ival_idx);

 cfg                 = [];
 cfg.classifier      = 'svm';
 cfg.metric          = 'accuracy';
 cfg.cv              = 'kfold';  % 'kfold' 'leaveout' 'holdout'
 cfg.k               = 5;
 cfg.repeat          = 10;
 cfg.preprocess      = {'zscore'};
 cfg.sample_dimension        = 1;
 cfg.feature_dimension       = 3;
 
 cfg.hyperparameter          = [];
 cfg.hyperparameter.lambda   = 'auto';
    

cfg.hyperparameter          = [];
cfg.hyperparameter.lambda   = 'auto';
    
[acc_All, result_All] = mv_classify(cfg, X, AllSubjData.clabels);

savepath = '/mnt/disk1/andrea/German_Study/Classification/TrialClassification/';

save(char(strcat(savepath,'svm_Classification_OdorMNight')),'acc_All','Accuracy');

function New_x = f_zscore_normalization(x)
    New_x = x;
      %------Trial by trial normalization------
     for trial = 1:size(x.data,3)
         mean_x = squeeze(mean(x.data(:,:,trial),2));
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