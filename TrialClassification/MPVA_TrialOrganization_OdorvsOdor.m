% Columns in the OverallSlowOsc Matriz
% 1) = To which time bin corresponds that particular event
% 2) = startTime: SO: first up-down zero crossing
% 3) = midTime: SO: down-up zero crossing
% 4) = endTime: spindle: negative zero crossing
% 5) = duration: duration from start to end in seconds (SO: between the two down-to-up crossings)
% 6) = maxTime: time of maximum (SO: of positive half-wave/up-state) in datapoints of original dataset
% 7) = minTime: time of minimum (SO: of negative half-wave/down-state) in datapoints of original dataset
% 8) = minAmp: amplitude of maximum (SO: of positive half-wave/up-state) in �V
% 9) = maxAmp: amplitude of minimum (SO: of negative half-wave/down-state) in �V
% 10)= p2pAmp: peak-to-peak amplitude (SO: down-to-up state)
% 11)= p2pTime: time in seconds from peak-to-peak (SO: down-to-up state)
% 12)= Power
% 13)= Frequency

%% Set Parameters

dbstop if error

filesPath       = '/mnt/disk1/andrea/German_Study/Data/Raw/SET/Sleep/';
files           = dir(strcat(filesPath,'.set'));

addpath('/home/andrea/Documents/MatlabFunctions/fieldtrip-20200828')
ft_defaults

p_filesPerNight

trials2rejFile      = '';
trials2rejVar       = 'comps2reject';


ChansOfInterest = {'E22','E9','E11','E33','E122','E24','E124','E36'...
    'E104','E45','E108','E52','E92','E58','E96','E70','E83','E75'};

%% Separate events, before checking SO

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For Cue Night
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SUBJ = [];


for subj  = 1:numel(files_DA_Cue)
    
    disp(strcat('Sujeto: ',files_DA_Cue(subj)))
    
    file_DA = files_DA_Cue(subj);
    %% Odor D Night
    addpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1'))
    dataType    = '.set';
    [EEGOdorD] = f_load_data(...
        strcat(char(file_DA),'_Import',dataType), strcat(filesPath,'OdorD_Night/'), dataType);
    
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
    
    %% Odor M Night
    
    file_MA = files_MA_Cue(subj);
    
    dataType    = '.set';
    [EEGOdorM] = f_load_data(...
        strcat(char(file_MA),'_Import',dataType), strcat(filesPath,'OdorM_Night/'), dataType);
    
    rmpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1'))


    All_DIN1  = find(strcmp({EEGOdorM.event.label}, 'DIN1')); 
    All_DIN2  = find(strcmp({EEGOdorM.event.label}, 'DIN2'));

    cidx_all                                = {EEGOdorM.event.mffkey_cidx};
    cidx_all(cellfun('isempty',cidx_all))   = [];
    cidx_all                                = cellfun(@str2double,cidx_all);
    cidx_unique                             = sort(unique(cidx_all));
    
    for cidx = numel(cidx_unique):-1:1
        
        idx = find(strcmp({EEGOdorM.event.mffkey_cidx}, num2str(cidx_unique(cidx)))); % where in the event structure are we
        
        % For each event, check whether it occurs exactly twice (start/end)
        if sum(cidx_all == cidx_unique(cidx)) ~= 2
            cidx_unique(cidx) = [];
            warning('Deleting a stimulation because it doesnt have a start and end.')
            
            % ...whether first is a start and second an end trigger
        elseif ~strcmp(EEGOdorM.event(idx(1)).label, 'DIN1') || ~strcmp(EEGOdorM.event(idx(2)).label, 'DIN2')
            cidx_unique(cidx) = [];
            warning('Deleting a stimulation because it doesnt have the right start and end.')
            
            % ...whether it is about 15 s long
        elseif EEGOdorM.event(idx(2)).latency - EEGOdorM.event(idx(1)).latency < 15 * EEGOdorM.srate || EEGOdorM.event(idx(2)).latency - EEGOdorM.event(idx(1)).latency > 15.1 * EEGOdorM.srate
            cidx_unique(cidx) = [];
            warning('Deleting a stimulation because its too short or too long.')   
        end
    end
    
    
    % Now all EEG.event are valid, all odd ones are odor, all even ones are vehicle
    cidx_odor           = cidx_unique(mod(cidx_unique,2) ~= 0);
    cidx_vehicle        = cidx_unique(mod(cidx_unique,2) == 0);
    
    [~,Odor_Epochs] = intersect(str2double({EEGOdorM.event.mffkey_cidx}), cidx_odor);
    [~,Vehicle_Epochs] = intersect(str2double({EEGOdorM.event.mffkey_cidx}), cidx_vehicle);
    
    [OdorMOn] = intersect(All_DIN1,Odor_Epochs);
    [VehicleMOn] = intersect(All_DIN1,Vehicle_Epochs);
    
    addpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1'))
    
    EEGVehicleM  = pop_epoch(EEGOdorM,[],[-15 15],'eventindices',VehicleMOn);
    EEGOdorM     = pop_epoch(EEGOdorM,[],[-15 15],'eventindices',OdorMOn);
    
    
    EEGOdorM = f_zscore_normalization(EEGOdorM); % z score normalization
    EEGVehicleM = f_zscore_normalization(EEGVehicleM); % z score normalization
    
    %%

    %-----Epoch the data for Odor D -------------
    ft_EEG_OdorD = eeglab2fieldtrip(EEGOdorD,'raw');
    cfg = []; cfg.channel = ChansOfInterest;%ft_EEG_Odor.label(1:end-1);
    ft_EEG_OdorD = ft_selectdata(cfg, ft_EEG_OdorD);
    
    %-----Epoch the data for Vehicle D -------------
    ft_EEG_VehicleD = eeglab2fieldtrip(EEGVehicleD,'raw');
    cfg = []; cfg.channel = ChansOfInterest;%ft_EEG_Vehicle.label(1:end-1);
    ft_EEG_VehicleD = ft_selectdata(cfg, ft_EEG_VehicleD);
    
    %-----Epoch the data for Odor M -------------
    ft_EEG_OdorM = eeglab2fieldtrip(EEGOdorM,'raw');
    cfg = []; cfg.channel = ChansOfInterest;%ft_EEG_Odor.label(1:end-1);
    ft_EEG_OdorM = ft_selectdata(cfg, ft_EEG_OdorM);
    
    %-----Epoch the data for Vehicle M -------------
    ft_EEG_VehicleM = eeglab2fieldtrip(EEGVehicleM,'raw');
    cfg = []; cfg.channel = ChansOfInterest;%ft_EEG_Vehicle.label(1:end-1);
    ft_EEG_VehicleM = ft_selectdata(cfg, ft_EEG_VehicleM);
    
    rmpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1'))
    
    %% Organize data structure

    cfg = [];
    layout = ft_prepare_layout(cfg, ft_EEG_OdorD);
    
    % OdorD vs Vehicle
    mintrials = min(size(ft_EEG_OdorD.trial,2),...
        size(ft_EEG_VehicleD.trial,2));
    CatTrials = cat(2,ft_EEG_OdorD.trial(1:mintrials),...
        ft_EEG_VehicleD.trial(1:mintrials));
    
    NewTrial =[];
    for trial = 1:length(CatTrials)
        NewTrial(trial,:,:) = CatTrials{trial};
    end
    
    NewTime = cat(2,ft_EEG_OdorD.time(1:mintrials),...
        ft_EEG_VehicleD.time(1:mintrials));
    Newlabel = ft_EEG_OdorD.label;
    Newcfg = ft_EEG_OdorD.cfg;
    
    attended_deviant = logical([ones(1,mintrials),zeros(1,mintrials)]); 
    chans = layout;
    dat.trial = single(NewTrial);
    dat.time = NewTime{1,1};
    dat.label = Newlabel';
    dat.cfg = Newcfg;
    nChan = length(Newlabel);
    nTime = length(NewTime{1,1});
    nTrial = length(CatTrials);
    
    % shuffle data
    v_trials = randperm(mintrials*2);
    dat.trial = dat.trial(v_trials,:,:);
    attended_deviant = attended_deviant(v_trials);
    
    
    save(strcat(file_DA{1,1},'OdorDVsVehicle'),'attended_deviant','chans',...
        'dat','nChan','nTime','nTrial');
    
    % OdorM vs Vehicle
    mintrials = min(size(ft_EEG_OdorM.trial,2),...
        size(ft_EEG_VehicleM.trial,2));
    CatTrials = cat(2,ft_EEG_OdorM.trial(1:mintrials),...
        ft_EEG_VehicleM.trial(1:mintrials));
    
    NewTrial =[];
    for trial = 1:length(CatTrials)
        NewTrial(trial,:,:) = CatTrials{trial};
    end
    
    NewTime = cat(2,ft_EEG_OdorM.time(1:mintrials),...
        ft_EEG_VehicleM.time(1:mintrials));
    Newlabel = ft_EEG_OdorM.label;
    Newcfg = ft_EEG_OdorM.cfg;
    
    attended_deviant = logical([ones(1,mintrials),zeros(1,mintrials)]); 
    chans = layout;
    dat.trial = single(NewTrial);
    dat.time = NewTime{1,1};
    dat.label = Newlabel';
    dat.cfg = Newcfg;
    nChan = length(Newlabel);
    nTime = length(NewTime{1,1});
    nTrial = length(CatTrials);
    
     % shuffle data
    v_trials = randperm(mintrials*2);
    dat.trial = dat.trial(v_trials,:,:);
    attended_deviant = attended_deviant(v_trials);
    
    save(strcat(file_DA{1,1},'OdorMVsVehicle'),'attended_deviant','chans',...
        'dat','nChan','nTime','nTrial');
    
    % OdorD vs OdorM
    mintrials = min(size(ft_EEG_OdorD.trial,2),...
        size(ft_EEG_OdorM.trial,2));
    CatTrials = cat(2,ft_EEG_OdorD.trial(1:mintrials),...
        ft_EEG_OdorM.trial(1:mintrials));
    
    NewTrial =[];
    for trial = 1:length(CatTrials)
        NewTrial(trial,:,:) = CatTrials{trial};
    end
    
    NewTime = cat(2,ft_EEG_OdorD.time(1:mintrials),...
        ft_EEG_OdorM.time(1:mintrials));
    Newlabel = ft_EEG_OdorD.label;
    Newcfg = ft_EEG_OdorD.cfg;
    
    attended_deviant = logical([ones(1,mintrials),zeros(1,mintrials)]); 
    chans = layout;
    dat.trial = single(NewTrial);
    dat.time = NewTime{1,1};
    dat.label = Newlabel';
    dat.cfg = Newcfg;
    nChan = length(Newlabel);
    nTime = length(NewTime{1,1});
    nTrial = length(CatTrials);
    
     % shuffle data
    v_trials = randperm(mintrials*2);
    dat.trial = dat.trial(v_trials,:,:);
    attended_deviant = attended_deviant(v_trials);
    
    save(strcat(file_DA{1,1},'OdorDvsOdorM'),'attended_deviant','chans',...
        'dat','nChan','nTime','nTrial');
    
        % Vehicle D vs Vehicle M
    mintrials = min(size(ft_EEG_VehicleD.trial,2),...
        size(ft_EEG_VehicleM.trial,2));
    CatTrials = cat(2,ft_EEG_VehicleD.trial(1:mintrials),...
        ft_EEG_VehicleM.trial(1:mintrials));
    
    NewTrial =[];
    for trial = 1:length(CatTrials)
        NewTrial(trial,:,:) = CatTrials{trial};
    end
    
    NewTime = cat(2,ft_EEG_VehicleD.time(1:mintrials),...
        ft_EEG_VehicleM.time(1:mintrials));
    Newlabel = ft_EEG_VehicleD.label;
    Newcfg = ft_EEG_VehicleD.cfg;
    
    attended_deviant = logical([ones(1,mintrials),zeros(1,mintrials)]); 
    chans = layout;
    dat.trial = single(NewTrial);
    dat.time = NewTime{1,1};
    dat.label = Newlabel';
    dat.cfg = Newcfg;
    nChan = length(Newlabel);
    nTime = length(NewTime{1,1});
    nTrial = length(CatTrials);
    
    
    % shuffle data
    v_trials = randperm(mintrials*2);
    dat.trial = dat.trial(v_trials,:,:);
    attended_deviant = attended_deviant(v_trials);
    
    save(strcat(file_DA{1,1},'VehDvsVehM'),'attended_deviant','chans',...
        'dat','nChan','nTime','nTrial');
    
    

end

%%

%addpath('/home/andrea/Documents/MatlabFunctions/MVPA-Light-master/startup/')


% Odor D vs Vehicle 
AllTrials = [];
All_attended_deviant = [];

for file_DA = files_DA_Cue
    Data = load(strcat(file_DA{1,1},'OdorDVsVehicle.mat'));
    AllTrials = cat(1,AllTrials,Data.dat.trial);
    All_attended_deviant = cat(2,All_attended_deviant,Data.attended_deviant);
end

perms = randperm(length(All_attended_deviant));

attended_deviant = logical(All_attended_deviant(perms));
chans = Data.chans;
dat.trial = AllTrials(perms,:,:);
dat.time = Data.dat.time;
dat.label = Data.dat.label;
dat.cfg = Data.dat.cfg;
nChan = Data.nChan;
nTime = Data.nChan;
nTrial = length(All_attended_deviant);


save('AllSubj_OdorDVsVehicle.mat','dat','attended_deviant','chans',...
        'nChan','nTime','nTrial','-v7.3');

  
 % Odor M vs Vehicle 
AllTrials = [];
All_attended_deviant = [];

for file_DA = files_DA_Cue
    Data = load(strcat(file_DA{1,1},'OdorMVsVehicle.mat'));
    AllTrials = cat(1,AllTrials,Data.dat.trial);
    All_attended_deviant = cat(2,All_attended_deviant,Data.attended_deviant);
end

perms = randperm(length(All_attended_deviant));

attended_deviant = logical(All_attended_deviant(perms));
chans = Data.chans;
dat.trial = AllTrials(perms,:,:);
dat.time = Data.dat.time;
dat.label = Data.dat.label;
dat.cfg = Data.dat.cfg;
nChan = Data.nChan;
nTime = Data.nChan;
nTrial = length(All_attended_deviant);


save('AllSubj_OdorMVsVehicle.mat','dat','attended_deviant','chans',...
        'nChan','nTime','nTrial','-v7.3');
    
% OdorD vs OdorM
AllTrials = [];
All_attended_deviant = [];

for file_DA = files_DA_Cue
    Data = load(strcat(file_DA{1,1},'OdorDvsOdorM.mat'));
    AllTrials = cat(1,AllTrials,Data.dat.trial);
    All_attended_deviant = cat(2,All_attended_deviant,Data.attended_deviant);
end

perms = randperm(length(All_attended_deviant));

attended_deviant = logical(All_attended_deviant(perms));
chans = Data.chans;
dat.trial = AllTrials(perms,:,:);
dat.time = Data.dat.time;
dat.label = Data.dat.label;
dat.cfg = Data.dat.cfg;
nChan = Data.nChan;
nTime = Data.nChan;
nTrial = length(All_attended_deviant);


save('AllSubj_OdorDvsOdorM.mat','dat','attended_deviant','chans',...
        'nChan','nTime','nTrial','-v7.3');
    
 % Vehicle D vs Vehicle M
AllTrials = [];
All_attended_deviant = [];

for file_DA = files_DA_Cue
    Data = load(strcat(file_DA{1,1},'VehDvsVehM.mat'));
    AllTrials = cat(1,AllTrials,Data.dat.trial);
    All_attended_deviant = cat(2,All_attended_deviant,Data.attended_deviant);
end

perms = randperm(length(All_attended_deviant));

attended_deviant = logical(All_attended_deviant(perms));
chans = Data.chans;
dat.trial = AllTrials(perms,:,:);
dat.time = Data.dat.time;
dat.label = Data.dat.label;
dat.cfg = Data.dat.cfg;
nChan = Data.nChan;
nTime = Data.nChan;
nTrial = length(All_attended_deviant);


save('AllSubj_VehDvsVehM.mat','dat','attended_deviant','chans',...
        'nChan','nTime','nTrial','-v7.3');
    
    function New_x = f_zscore_normalization(x)
    New_x = x;
    
    %------Trial by trial normalization------
%     for trial = 1:size(x.data,3)
%         mean_x= squeeze(mean(x.data(:,:,trial),2));
%         std_x = squeeze(std(double(x.data(:,:,trial)),[],2));
%         
%         mean_x = repmat(mean_x,1,size(x.data,2),1);
%         std_x = repmat(std_x,1,size(x.data,2),1);
% 
%         
%         New_x.trial(:,:,trial) = (squeeze(x.data(:,:,trial))-mean_x)./std_x;
%     end
    
    %------Normalization across trials----
      mean_x= mean(x.data(:));
      std_x= std(x.data(:));
      
      mean_x = repmat(mean_x,size(x.data,1),size(x.data,2),size(x.data,3));
      std_x = repmat(std_x,size(x.data,1),size(x.data,2),size(x.data,3));
      
      
      New_x.trial = x.data-mean_x./std_x;
    
    end