
filesPath       = '/mnt/disk1/sleep/Datasets/Ori/EEGLABFilt_Mastoids_Off_On_200Hz_Oct_NEW_EEGLAB/';
filesOdor       = dir(strcat(filesPath,'*Odor.set'));
filesVehicle    = dir(strcat(filesPath,'*Sham.set'));

addpath('/home/andrea/Documents/MatlabFunctions/fieldtrip-20200828')
ft_defaults

addpath('/mnt/disk1/andrea/German_Study/')
p_clustersOfInterest

trials2rejFile      = '';
trials2rejVar       = 'comps2reject';

addpath('/home/andrea/Documents/MatlabFunctions/MVPA-Light/startup/')
startup_MVPA_Light



ChansOfInterest = 'all';% Clust.central; %'all';
AllSubjData.trial   = [];
AllSubjData.clabels = [];
CatTrials           = [];
CatTime             = [];
CatTrialInfo        =[];

conditions = {'Odor Switched ON';...
    'Vehicle Switched ON';...
    'Odor Switched OFF';...
    'Vehicle Switched OFF'};
indx = [2,4];

if sum(indx ~= 0)>2
    return
end

for subj  = 1:numel(filesOdor)
    
    disp(strcat('Sujeto: ',filesOdor(subj).name))
    file_Odor = filesOdor(subj).name;
    file_Vehicle = filesVehicle(subj).name;

    %% Odor D Night
    addpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1'))

    [EEGOdorD] = pop_loadset('filename', file_Odor,'filepath', filesPath);
    [EEGVehicleD] = pop_loadset('filename', file_Vehicle,'filepath', filesPath);
    
    % EEGOdorD = f_zscore_normalization(EEGOdorD); % z score normalization
    % EEGVehicleD = f_zscore_normalization(EEGVehicleD); % z score normalization

    %%

    %-----Select data for Odor D -------------
    ft_EEG_OdorD = eeglab2fieldtrip(EEGOdorD,'raw');
    cfg = []; cfg.channel = ChansOfInterest; cfg.avgoverchan = 'no';%ft_EEG_Odor.label(1:end-1);
    ft_EEG_OdorD = ft_selectdata(cfg, ft_EEG_OdorD);

    cfg = []; cfg.latency = [0 15];
    ft_EEG_OdorD_SwitchedOn = ft_selectdata(cfg, ft_EEG_OdorD);

    cfg = []; cfg.latency = [-15 -0.0050];
    ft_EEG_Vehicle_SwitchedOff = ft_selectdata(cfg, ft_EEG_OdorD);
    
    %-----Select data for Vehicle D -------------
    ft_EEG_VehicleD = eeglab2fieldtrip(EEGVehicleD,'raw');
    cfg = []; cfg.channel = ChansOfInterest; cfg.avgoverchan = 'no'; %ft_EEG_Vehicle.label(1:end-1);
    ft_EEG_VehicleD = ft_selectdata(cfg, ft_EEG_VehicleD);

    cfg = []; cfg.latency = [0 15];
    ft_EEG_VehicleD_SwitchedOn = ft_selectdata(cfg, ft_EEG_VehicleD);

    cfg = []; cfg.latency = [-15 -0.0050];
    ft_EEG_OdorD_SwitchedOff = ft_selectdata(cfg, ft_EEG_VehicleD);

    rmpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1'))


    % OdorD vs Vehicle
    mintrials = min(size(ft_EEG_OdorD.trial,2),...
        size(ft_EEG_VehicleD.trial,2));


    if find(indx == 1)
        CatTrials = cat(2,CatTrials,...
        ft_EEG_OdorD_SwitchedOn.trial(1:mintrials));

        CatTime = cat(2,CatTime,...
        ft_EEG_OdorD_SwitchedOn.time(1:mintrials));
        
        CatTrialInfo = cat(1,CatTrialInfo,ft_EEG_OdorD_SwitchedOn.trialinfo);

        dat = ft_EEG_OdorD_SwitchedOn;
        dat.time = ft_EEG_OdorD_SwitchedOn.time{1};
    end

    if find(indx == 2)
        CatTrials = cat(2,CatTrials,...
        ft_EEG_VehicleD_SwitchedOn.trial(1:mintrials));

        CatTime = cat(2,CatTime,...
        ft_EEG_VehicleD_SwitchedOn.time(1:mintrials));
        
        CatTrialInfo = cat(1,CatTrialInfo,ft_EEG_VehicleD_SwitchedOn.trialinfo);

        dat = ft_EEG_VehicleD_SwitchedOn;
        dat.time = ft_EEG_VehicleD_SwitchedOn.time{1};
    end

    if find(indx == 3)
        CatTrials = cat(2,CatTrials,...
        ft_EEG_OdorD_SwitchedOff.trial(1:mintrials));

        CatTime = cat(2,CatTime,...
        ft_EEG_OdorD_SwitchedOff.time(1:mintrials));
        
        CatTrialInfo = cat(1,CatTrialInfo,ft_EEG_OdorD_SwitchedOff.trialinfo);

        dat = ft_EEG_OdorD_SwitchedOff;
        dat.time = ft_EEG_OdorD_SwitchedOff.time{1};
    end

    if find(indx == 4)
        CatTrials = cat(2,CatTrials,...
        ft_EEG_Vehicle_SwitchedOff.trial(1:mintrials));

        CatTime = cat(2,CatTime,...
        ft_EEG_Vehicle_SwitchedOff.time(1:mintrials));
        
        CatTrialInfo = cat(1,CatTrialInfo,ft_EEG_Vehicle_SwitchedOff.trialinfo);

        dat = ft_EEG_Vehicle_SwitchedOff;
        dat.time = ft_EEG_Vehicle_SwitchedOff.time{1};
    end
    
     
    attended_deviant = [zeros(1,mintrials),ones(1,mintrials)]+1;
    % shuffle data
    v_trials = randperm(mintrials*2);
    CatTrials = CatTrials(v_trials);
    dat.trialinfo = CatTrialInfo(v_trials,:);
    attended_deviant = attended_deviant(v_trials);

    New_Trial = [];
    for trial = 1:length(CatTrials)
        New_Trial(trial,:,:) = CatTrials{trial};
    end

    dat.trial = New_Trial;
    clabel = attended_deviant;

     %% Train and test classifier
    X = dat.trial;
    
    %% Cross-validation
    
    cfg                 = [];
    cfg.classifier      = 'svm';
    cfg.metric          = 'auc';
    cfg.cv              = 'kfold';  % 'kfold' 'leaveout' 'holdout'
    cfg.k               = 5;
    cfg.repeat          = 10;
    cfg.preprocess      = {'zscore'};
    cfg.sample_dimension        = 1;
    cfg.feature_dimension       = [2,3];
    
    cfg.hyperparameter          = [];
    cfg.hyperparameter.lambda   = 'auto';
    
    [acc, result] = mv_classify(cfg, X, clabel);
        
    % Produce plot of results
    %h = mv_plot_result({result_LDA, result_LR});
    
    Accuracy(subj) = acc;

    AllSubjData.trial = cat(1,AllSubjData.trial,New_Trial);
    AllSubjData.clabels = cat(2,AllSubjData.clabels,attended_deviant);
    AllSubjData.time = dat.time;
end

 X = AllSubjData.trial;

 cfg                 = [];
 cfg.classifier      = 'svm';
 cfg.metric          = 'auc';
 cfg.cv              = 'kfold';  % 'kfold' 'leaveout' 'holdout'
 cfg.k               = 5;
 cfg.repeat          = 10;
 cfg.preprocess      = {'zscore'};
 cfg.sample_dimension        = 1;
 cfg.feature_dimension       = [2,3];
 
 cfg.hyperparameter          = [];
 cfg.hyperparameter.lambda   = 'auto';
    

cfg.hyperparameter          = [];
cfg.hyperparameter.lambda   = 'auto';
    
[acc_All, result_All] = mv_classify(cfg, X, AllSubjData.clabels);

savepath = '/mnt/disk1/andrea/German_Study/Classification/TrialClassification/';

save(char(strcat(savepath,'svm_Classification_OdorDNight_AllFeatures_VehicleOnvsPost')),'acc_All','Accuracy');

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