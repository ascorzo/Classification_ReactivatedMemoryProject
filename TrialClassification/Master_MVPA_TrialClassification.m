
filesPath       = '/mnt/disk1/andrea/German_Study/Data/Raw/SET/Sleep/';
files           = dir(strcat(filesPath,'.set'));

addpath('/home/andrea/Documents/MatlabFunctions/fieldtrip-20200828')
ft_defaults

addpath('/mnt/disk1/andrea/German_Study/')
p_filesPerNight
p_clustersOfInterest

trials2rejFile      = '';
trials2rejVar       = 'comps2reject';

addpath('/home/andrea/Documents/MatlabFunctions/MVPA-Light/startup/')
startup_MVPA_Light


filesPath = '/mnt/disk1/andrea/German_Study/Data/PreProcessed/MastoidRef-Interp/';

ChansOfInterest = Clust.central; %'all';
AllSubjData.trial = [];
AllSubjData.clabels = [];

for subj  = 1:numel(files_DA_Cue)
    
    disp(strcat('Sujeto: ',files_DA_Cue(subj)))
    file_DA = files_DA_Cue(subj);

    %% Odor D Night
    addpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1'))
    dataType    = '.set';
    file = dir(strcat(filesPath,'*',file_DA{1,1},'*.set'));

    [EEGOdorD] = pop_loadset('filename', file.name,'filepath', filesPath);
    
    rmpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1'))

    All_DIN1  = find(strcmp({EEGOdorD.event.label}, 'DIN1')); 
    All_DIN2  = find(strcmp({EEGOdorD.event.label}, 'DIN2'));

    cidx_all                                = {EEGOdorD.event.mffkey_cidx};
    cidx_all(cellfun('isempty',cidx_all))   = [];
    cidx_all                                = cellfun(@str2double,cidx_all);
    cidx_unique                             = sort(unique(cidx_all));
    
    for cidx = numel(cidx_unique):-1:1
        
        idx = find(strcmp({EEGOdorD.event.mffkey_cidx}, num2str(cidx_unique(cidx)))); % where in the event structure are we
        
        % For each event, check whether it occurs exactly twice (start/end)
        if sum(cidx_all == cidx_unique(cidx)) ~= 2
            cidx_unique(cidx) = [];
            warning('Deleting a stimulation because it doesnt have a start and end.')
            
            % ...whether first is a start and second an end trigger
        elseif ~strcmp(EEGOdorD.event(idx(1)).label, 'DIN1') || ~strcmp(EEGOdorD.event(idx(2)).label, 'DIN2')
            cidx_unique(cidx) = [];
            warning('Deleting a stimulation because it doesnt have the right start and end.')
            
            % ...whether it is about 15 s long
        elseif EEGOdorD.event(idx(2)).latency - EEGOdorD.event(idx(1)).latency < 15 * EEGOdorD.srate || EEGOdorD.event(idx(2)).latency - EEGOdorD.event(idx(1)).latency > 15.1 * EEGOdorD.srate
            cidx_unique(cidx) = [];
            warning('Deleting a stimulation because its too short or too long.')   
        end
    end
    
    
    % Now all EEG.event are valid, all odd ones are odor, all even ones are vehicle
    cidx_odor           = cidx_unique(mod(cidx_unique,2) ~= 0);
    cidx_vehicle        = cidx_unique(mod(cidx_unique,2) == 0);
    
    [~,Odor_Epochs] = intersect(str2double({EEGOdorD.event.mffkey_cidx}), cidx_odor);
    [~,Vehicle_Epochs] = intersect(str2double({EEGOdorD.event.mffkey_cidx}), cidx_vehicle);
    
    [OdorDOn] = intersect(All_DIN1,Odor_Epochs);
    [VehicleDOn] = intersect(All_DIN1,Vehicle_Epochs);
    
    addpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1'))
    
    EEGVehicleD  = pop_epoch(EEGOdorD,[],[-15 15],'eventindices',VehicleDOn);
    EEGOdorD     = pop_epoch(EEGOdorD,[],[-15 15],'eventindices',OdorDOn);
    
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
    X = squeeze(mean(dat.trial(:,:,ival_idx),3));
    
    %% Cross-validation
    
    % Configuration struct for cross-validation. As classifier, we
    % use LDA. The value of the regularisation parameter lambda is determined
    % automatically. As performance measure, use area under the ROC curve
    % ('auc').
    %
    % To get a realistic estimate of classification performance, we perform
    % 5-fold (cfg.k = 5) cross-validation with 10 repetitions (cfg.repeat = 10).
    
    cfg_LDA = [];
    cfg_LDA.classifier      = 'lda';
    cfg_LDA.metric          = 'accuracy';
    cfg_LDA.cv              = 'kfold';  % 'kfold' 'leaveout' 'holdout'
    cfg_LDA.k               = 5;
    cfg_LDA.repeat          = 15;
    
    % the hyperparameter substruct contains the hyperparameters for the classifier.
    % Here, we only set lambda = 'auto'. This is the default, so in general
    % setting hyperparameter is not required unless one wants to change the default
    % settings.
    cfg_LDA.hyperparameter          = [];
    cfg_LDA.hyperparameter.lambda   = 'auto';
    
    [acc_LDA, result_LDA] = mv_crossvalidate(cfg_LDA, X, clabel);
    
    % Run analysis also for Logistic Regression (LR), using the same
    % cross-validation settings.
    cfg_LR = cfg_LDA;
    cfg_LR.classifier       = 'logreg';
    
    [acc_LR, result_LR] = mv_crossvalidate(cfg_LR, X, clabel);
    
    fprintf('\nClassification accuracy (LDA): %2.2f%%\n', 100*acc_LDA)
    fprintf('Classification accuracy (Logreg): %2.2f%%\n', 100*acc_LR)
    
    % Produce plot of results
    %h = mv_plot_result({result_LDA, result_LR});
    
    Accuracy_LDA(subj) = acc_LDA;
    Accuracy_LR(subj) = acc_LR;
    
    %% Comparing cross-validation to training and testing on the same data
    cfg_LDA.metric = 'accuracy';
    
    % Select only the first samples
    nReduced = 29;
    label_reduced = clabel(1:nReduced);
    X_reduced = X(1:nReduced,:);
    
    % Cross-validation (proper way)
    cfg_LDA.cv = 'kfold';
    acc_LDA = mv_crossvalidate(cfg_LDA, X_reduced, label_reduced);
    
    % No cross-validation (test on training data)
    cfg_LDA.cv     = 'none';
    acc_reduced = mv_crossvalidate(cfg_LDA, X_reduced, label_reduced);
    
    fprintf('Using %d samples with cross-validation (proper way): %2.2f%%\n', nReduced, 100*acc_LDA)
    fprintf('Using %d samples without cross-validation (test on training data): %2.2f%%\n', nReduced, 100*acc_reduced)

    AllSubjData.trial = cat(1,AllSubjData.trial,New_Trial);
    AllSubjData.clabels = cat(2,AllSubjData.clabels,attended_deviant);
    AllSubjData.time = dat.time;
end

 % Average interval of interest
 ival_idx = find(AllSubjData.time >= 0  & AllSubjData.time <= 15);
    
 % Extract the mean activity in the interval as features
 X = squeeze(mean(AllSubjData.trial(:,:,ival_idx),3));

cfg_LDA = [];
cfg_LDA.classifier      = 'lda';
cfg_LDA.metric          = 'accuracy';
cfg_LDA.cv              = 'kfold';  % 'kfold' 'leaveout' 'holdout'
cfg_LDA.k               = 5;
cfg_LDA.repeat          = 15;
    
    % the hyperparameter substruct contains the hyperparameters for the classifier.
    % Here, we only set lambda = 'auto'. This is the default, so in general
    % setting hyperparameter is not required unless one wants to change the default
    % settings.
cfg_LDA.hyperparameter          = [];
cfg_LDA.hyperparameter.lambda   = 'auto';
    
[acc_LDA_All, result_LDA_All] = mv_crossvalidate(cfg_LDA, X, AllSubjData.clabels);
    
    % Run analysis also for Logistic Regression (LR), using the same
    % cross-validation settings.
cfg_LR = cfg_LDA;
cfg_LR.classifier       = 'logreg';
    
[acc_LR_All, result_LR_All] = mv_crossvalidate(cfg_LR, X, AllSubjData.clabels);


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