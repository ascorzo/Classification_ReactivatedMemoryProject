%% Recognize all the On-Period data
addpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1'));

addpath('/home/andrea/Documents/MatlabFunctions/fieldtrip-20200828')
ft_defaults


addpath('/home/andrea/Documents/MatlabFunctions/MVPA-Light/startup/')
startup_MVPA_Light


filepath_RAW    = '/mnt/disk1/andrea/German_Study/Data/PreProcessed/MastoidRef-Interp/';
filepath_Colab  = '/mnt/disk1/sleep/Datasets/Ori/EEGLABFilt_Mastoids_Off_On_200Hz_Oct/';

files_Cue_On = dir(strcat(filepath_Colab,'*_Odor*','.mat'));
files_Sham_On = dir(strcat(filepath_Colab,'*_Sham*','.mat'));



chanOfInterest      = 'E15'; % frontal because of the general behavior of SO

AllSubjData.trial = [];
AllSubjData.clabels = [];


OscillationEvents = ...
    load('/mnt/disk1/andrea/German_Study/Classification/SO_Classification/SODetection/12-Jun-2021_AllData_CueD.mat');

for subj = 1:numel(files_Cue_On)
    
    file_Cue = files_Cue_On(subj).name;
    file_Sham = files_Sham_On(subj).name;
    
    EEGOdor = load(strcat(filepath_Colab,file_Cue));
    EEGVehicle = load(strcat(filepath_Colab,file_Sham));
    
    file_whole = dir(strcat(filepath_RAW,'*',file_Cue(1:6),'*.set'));
    
    EEGWhole = pop_loadset('filename', file_whole.name, ...
        'filepath', filepath_RAW);
    
    % Remove external channels
    chan_Mastoids       = {'E57', 'E100'};
    chan_EOG            = {'E8', 'E14', 'E21', 'E25', 'E126', 'E127'};
    chan_EMG            = {'E43', 'E120'};
    chan_VREF           = {'E129'};
    chan_Face           = {'E49', 'E48', 'E17', 'E128', 'E32', 'E1', ...
        'E125', 'E119', 'E113'};
    chan_Undesired  = {'E56','E63','E68','E73','E81','E88','E94','E99','E57'};
    
    chans2Rej   = [chan_Undesired];
    
    [~, idx_chan2rej] = intersect({EEGWhole.chanlocs.labels},chans2Rej);
        
        
    [EEGWhole] = ...
        pop_select( EEGWhole, 'nochannel', idx_chan2rej);
    
    [~,~,Trig_OI_Cue]= intersect(...
        {EEGOdor.hdr.orig.event.mffkey_gidx},{EEGWhole.event.mffkey_gidx});
    
    [~,~,Trig_OI_Vehicle]= intersect(...
        {EEGVehicle.hdr.orig.event.mffkey_gidx},{EEGWhole.event.mffkey_gidx});
    
    Trig_OI_Cue     = sort(Trig_OI_Cue);
    Trig_OI_Vehicle = sort(Trig_OI_Vehicle);
    
    Latency_OI_Odor = [EEGWhole.event(Trig_OI_Cue).latency];
    Latency_OI_Vehicle= [EEGWhole.event(Trig_OI_Vehicle).latency];
    
    %% For odor On
    condition               = 'OdorOn';
    eventsOfInterest = OscillationEvents.OverallSlowOsc.(chanOfInterest).(condition)(:,subj);
    
    
    OriginalStartTime = [];
    OriginalMidTime = [];
    OriginalendTime = [];
    
    for trial = 1:length(eventsOfInterest)
        
        for SO = 1:size(eventsOfInterest{trial},1)
            
            if ~isempty(eventsOfInterest{trial})
                if~isnan(eventsOfInterest{trial}(1))
                    % Time of SO occurence in the trial (in samples)
                    StartTime = eventsOfInterest{trial}(SO,2);
                    MidTime = eventsOfInterest{trial}(SO,3);
                    endTime = eventsOfInterest{trial}(SO,4);
                    
                    
                    % Time of SO occurence in the whole recording
                    OriginalStartTime = cat(1,OriginalStartTime,...
                        Latency_OI_Odor(trial)+StartTime);
                    OriginalMidTime = cat(1,OriginalMidTime,...
                        Latency_OI_Odor(trial)+MidTime);
                    OriginalendTime = cat(1,OriginalendTime,...
                        Latency_OI_Odor(trial)+endTime);
                end
            end
            
        end
    end
    
    Last_event = numel(EEGWhole.event);
    
    for SO = 1:numel(OriginalStartTime)
        % Add triggers to the original EEG
        EEGWhole.event(SO+Last_event).type = '35';
        EEGWhole.event(SO+Last_event).latency = OriginalStartTime(SO);
        EEGWhole.event(SO+Last_event).duration = 0;
        EEGWhole.event(SO+Last_event).label = 'SO_start';
    end

    Last_event = numel(EEGWhole.event);
    
    for SO = 1:numel(OriginalMidTime)
        % Add triggers to the original EEG
        EEGWhole.event(SO+Last_event).type = '36';
        EEGWhole.event(SO+Last_event).latency = OriginalMidTime(SO);
        EEGWhole.event(SO+Last_event).duration = 0;
        EEGWhole.event(SO+Last_event).label = 'SO_Mid';
    end
    
    Last_event = numel(EEGWhole.event);
    
    for SO = 1:numel(OriginalendTime)
        % Add triggers to the original EEG
        EEGWhole.event(SO+Last_event).type = '37';
        EEGWhole.event(SO+Last_event).latency = OriginalendTime(SO);
        EEGWhole.event(SO+Last_event).duration = 0;
        EEGWhole.event(SO+Last_event).label = 'SO_End';
    end
    
    %% for vehicle on 
    condition               = 'ShamOn';
    eventsOfInterest = OscillationEvents.OverallSlowOsc.(chanOfInterest).(condition)(:,subj);
    
    OriginalStartTime = [];
    OriginalMidTime = [];
    OriginalendTime = [];
    
    for trial = 1:length(eventsOfInterest)
        
        for SO = 1:size(eventsOfInterest{trial},1)
            
            if ~isempty(eventsOfInterest{trial})
                if~isnan(eventsOfInterest{trial}(1))
                    % Time of SO occurence in the trial (in samples)
                    StartTime = eventsOfInterest{trial}(SO,2);
                    MidTime = eventsOfInterest{trial}(SO,3);
                    endTime = eventsOfInterest{trial}(SO,4);
                    
                    
                    % Time of SO occurence in the whole recording
                    OriginalStartTime = cat(1,OriginalStartTime,...
                        Latency_OI_Vehicle(trial)+StartTime);
                    OriginalMidTime = cat(1,OriginalMidTime,...
                        Latency_OI_Vehicle(trial)+MidTime);
                    OriginalendTime = cat(1,OriginalendTime,...
                        Latency_OI_Vehicle(trial)+endTime);
                end
            end
            
        end
    end
    
    Last_event = numel(EEGWhole.event);
    
    for SO = 1:numel(OriginalStartTime)
        % Add triggers to the original EEG
        EEGWhole.event(SO+Last_event).type = '45';
        EEGWhole.event(SO+Last_event).latency = OriginalStartTime(SO);
        EEGWhole.event(SO+Last_event).duration = 0;
        EEGWhole.event(SO+Last_event).label = 'SO_start';
    end

    Last_event = numel(EEGWhole.event);
    
    for SO = 1:numel(OriginalMidTime)
        % Add triggers to the original EEG
        EEGWhole.event(SO+Last_event).type = '46';
        EEGWhole.event(SO+Last_event).latency = OriginalMidTime(SO);
        EEGWhole.event(SO+Last_event).duration = 0;
        EEGWhole.event(SO+Last_event).label = 'SO_Mid';
    end
    
    Last_event = numel(EEGWhole.event);
    
    for SO = 1:numel(OriginalendTime)
        % Add triggers to the original EEG
        EEGWhole.event(SO+Last_event).type = '47';
        EEGWhole.event(SO+Last_event).latency = OriginalendTime(SO);
        EEGWhole.event(SO+Last_event).duration = 0;
        EEGWhole.event(SO+Last_event).label = 'SO_End';
    end
    
    
        %-----Epoch the data for cue On-------------
    OUTEEG_CueSO_On = pop_epoch(EEGWhole,{'36'},[-2 2]);

    %-----Epoch the data for Vehicle On-------------
    OUTEEG_VehicleSO_On = pop_epoch(EEGWhole,{'46'},[-2 2]);
    
    % Organize data structure
    
    %convert to fieldtrip
    ft_EEG_OdorD = eeglab2fieldtrip(OUTEEG_CueSO_On,'raw');
    ft_EEG_VehicleD = eeglab2fieldtrip(OUTEEG_VehicleSO_On,'raw');
    
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

    savepath = '/mnt/disk1/andrea/German_Study/Classification/SO_Classification/';

    save(char(strcat(savepath,'MVPA_SOClassification[-2_2]_OdorD_ValidEpochs')),'acc_All','acc','result_All','result');