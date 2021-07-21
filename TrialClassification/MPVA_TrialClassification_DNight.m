addpath('/home/andrea/Documents/MatlabFunctions/fieldtrip-20200828')
ft_defaults


addpath('/home/andrea/Documents/MatlabFunctions/MVPA-Light/startup/')
startup_MVPA_Light

addpath('/mnt/disk1/andrea/German_Study/')
p_clustersOfInterest


% filesPath = '/gpfs01/born/group/Andrea/ReactivatedConnectivity/RawSleepData/preProcessing/Epoched_90Sec_ONOFF/OdorD_Night/';
% files = dir(strcat(filesPath,'*.set'));

filesPath       = '/mnt/disk1/sleep/Datasets/Ori/EEGLABFilt_Mastoids_Off_On_200Hz_Oct_NEW_EEGLAB/';
filesOdor       = dir(strcat(filesPath,'*Odor.set'));
filesVehicle    = dir(strcat(filesPath,'*Sham.set'));



% clusters =  {'left_frontal';'right_frontal';'frontal';'left_central';'left_temporal';'left_parietal';...
% 'left_occipital';'right_occipital';'occipital'};

%for cluster = 1:numel(clusters)

    AllSubjData.trial = [];
    AllSubjData.clabels = [];

    ChansOfInterest = 'all';%Clust.(clusters{cluster}); %'all';

    chan_Undesired = {'E56','E63','E68','E73','E81','E88','E94','E99','E57'};

    chans2Rej = [chan_Undesired];


    for subj = 1:numel(filesOdor)
        
        disp(strcat('Sujeto: ',filesOdor(subj).name(1:6)))
        
        %----------------------------------------------------------------------
        % Import and convert to fieldtrip
        %----------------------------------------------------------------------


        addpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1/'))
        EEG = pop_loadset(strcat(filesPath,filesOdor(subj).name));
        [~,idx_chan2rej] = intersect({EEG.chanlocs.labels},chans2Rej);
        EEG = pop_select(EEG,'nochannel',idx_chan2rej);

        ft_EEG_OdorD = eeglab2fieldtrip(EEG,'raw');

        EEG = pop_loadset(strcat(filesPath,filesVehicle(subj).name));
        [~,idx_chan2rej] = intersect({EEG.chanlocs.labels},chans2Rej);
        EEG = pop_select(EEG,'nochannel',idx_chan2rej);
        ft_EEG_VehicleD = eeglab2fieldtrip(EEG,'raw');
        rmpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1/'))

        % %-----Select channels -------------
        % cfg = []; cfg.channel = ChansOfInterest; cfg.avgoverchan = 'no'; %ft_EEG_Vehicle.label(1:end-1);
        % ft_EEG_OdorD = ft_selectdata(cfg, ft_EEG_OdorD);
        % ft_EEG_VehicleD = ft_selectdata(cfg, ft_EEG_VehicleD);
        
        %-----Select time -------------
        cfg = []; cfg.latency = [0 15];
        ft_EEG_OdorD = ft_selectdata(cfg, ft_EEG_OdorD);
        ft_EEG_VehicleD = ft_selectdata(cfg, ft_EEG_VehicleD);
        
        clear EEG


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
        v_trials            = randperm(mintrials*2);
        dat                 = ft_EEG_OdorD;
        CatTrials           = CatTrials(v_trials);
        dat.time            = ft_EEG_OdorD.time{1};
        dat.trialinfo       = CatTrialInfo(v_trials,:);
        attended_deviant    = attended_deviant(v_trials);

        New_Trial = [];
        for trial = 1:length(CatTrials)
            New_Trial(trial,:,:) = CatTrials{trial};
        end

        dat.trial = New_Trial;
        clabel = attended_deviant;

        %% Train and test classifier
        
        X = dat.trial;
        
        %% Cross-validation

        
        cfg                     = [];
        cfg.classifier          = 'svm';
        cfg.metric              = 'accuracy';
        cfg.cv                  = 'kfold';  % 'kfold' 'leaveout' 'holdout'
        cfg.k                   = 5;
        cfg.repeat              = 10;
        cfg.preprocess          = {'zscore'};
        cfg.sample_dimension    = 1;
        cfg.feature_dimension   = [2,3];
        cfg.dimension_names     = {'samples','channels','time points'};

        
        % the hyperparameter substruct contains the hyperparameters for the classifier.
        % Here, we only set lambda = 'auto'. This is the default, so in general
        % setting hyperparameter is not required unless one wants to change the default
        % settings.
        cfg.hyperparameter          = [];
        cfg.hyperparameter.lambda   = 'auto';
        
            
        [acc(subj), result{subj}] =  mv_classify(cfg, X, clabel);
        
    
        AllSubjData.trial = cat(1,AllSubjData.trial,New_Trial);
        AllSubjData.clabels = cat(2,AllSubjData.clabels,attended_deviant);
        AllSubjData.time = dat.time;
    end


    X = AllSubjData.trial;

    cfg                     = [];
    cfg.classifier          = 'svm';
    cfg.metric              = 'accuracy';
    cfg.cv                  = 'kfold';  % 'kfold' 'leaveout' 'holdout'
    cfg.k                   = 5;
    cfg.repeat              = 10;
    cfg.preprocess          = {'zscore'};
    cfg.sample_dimension    = 1;
    cfg.feature_dimension   = [2,3]; %channels, Time


    cfg.hyperparameter          = [];
    cfg.hyperparameter.lambda   = 'auto';


    clabel = AllSubjData.clabels;

        
    [acc_All, result_All] =  mv_classify(cfg, X, clabel);


    savepath = '/mnt/disk1/andrea/German_Study/Classification/TrialClassification/';

    save(char(strcat(savepath,'MVPA_TrialClassification_OdorD_ValidEpochs')),'acc_All','acc','result_All','result');
