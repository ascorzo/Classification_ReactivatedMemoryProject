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

filesPath       = 'D:\GermanData\DATA\RawData\';
files           = dir(strcat(filesPath,'.mff'));



%----For Cue Night:

files_DA_Cue = {...
    'RC_051_sleep','RC_091_sleep','RC_121_sleep','RC_131_sleep',...
    'RC_141_sleep','RC_161_sleep','RC_171_sleep','RC_201_sleep',...
    'RC_241_sleep','RC_251_sleep','RC_261_sleep','RC_281_sleep',...
    'RC_291_sleep','RC_301_sleep',...
    'RC_392_sleep','RC_412_sleep','RC_442_sleep','RC_452_sleep',...
    'RC_462_sleep','RC_472_sleep','RC_482_sleep','RC_492_sleep',...
    'RC_512_sleep'};


files_MA_Cue = {...
    'RC_052_sleep','RC_092_sleep','RC_122_sleep','RC_132_sleep',...
    'RC_142_sleep','RC_162_sleep','RC_172_sleep','RC_202_sleep',...
    'RC_242_sleep','RC_252_sleep','RC_262_sleep','RC_282_sleep',...
    'RC_292_sleep','RC_302_sleep',...    
    'RC_391_sleep','RC_411_sleep','RC_441_sleep','RC_451_sleep',...
    'RC_461_sleep','RC_471_sleep','RC_481_sleep','RC_491_sleep',...
    'RC_511_sleep'};

trials2rejFile      = '';
trials2rejVar       = 'comps2reject';


ChansOfInterest = {'E22','E9','E11','E33','E122','E24','E124','E36'...
    'E104','E45','E108','E52','E92','E58','E96','E70','E83','E75'};

%% Separate events, before checking SO

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For Cue Night
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Nsubj = 0;
SUBJ = [];


for file_DA = files_MA_Cue
    
    Nsubj = Nsubj+1;
    
    addpath(genpath('C:\Users\lanan\Documents\MATLAB\eeglab2019_1'))
    dataType    = '.mff';
    [EEG] = f_load_data(...
        strcat(char(file_DA),dataType), filesPath, dataType);
    
    rmpath(genpath('C:\Users\lanan\Documents\MATLAB\eeglab2019_1'))


    All_DIN1  = find(strcmp({EEG.event.label}, 'DIN1')); 
    All_DIN2  = find(strcmp({EEG.event.label}, 'DIN2'));

    cidx_all                                = {EEG.event.mffkey_cidx};
    cidx_all(cellfun('isempty',cidx_all))   = [];
    cidx_all                                = cellfun(@str2double,cidx_all);
    cidx_unique                             = sort(unique(cidx_all));
    
    for cidx = numel(cidx_unique):-1:1
        
        idx = find(strcmp({EEG.event.mffkey_cidx}, num2str(cidx_unique(cidx)))); % where in the event structure are we
        
        % For each event, check whether it occurs exactly twice (start/end)
        if sum(cidx_all == cidx_unique(cidx)) ~= 2
            cidx_unique(cidx) = [];
            warning('Deleting a stimulation because it doesnt have a start and end.')
            
            % ...whether first is a start and second an end trigger
        elseif ~strcmp(EEG.event(idx(1)).label, 'DIN1') || ~strcmp(EEG.event(idx(2)).label, 'DIN2')
            cidx_unique(cidx) = [];
            warning('Deleting a stimulation because it doesnt have the right start and end.')
            
            % ...whether it is about 15 s long
        elseif EEG.event(idx(2)).latency - EEG.event(idx(1)).latency < 15 * EEG.srate || EEG.event(idx(2)).latency - EEG.event(idx(1)).latency > 15.1 * EEG.srate
            cidx_unique(cidx) = [];
            warning('Deleting a stimulation because its too short or too long.')   
        end
    end
    
    
    % Now all EEG.event are valid, all odd ones are odor, all even ones are vehicle
    cidx_odor           = cidx_unique(mod(cidx_unique,2) ~= 0);
    cidx_vehicle        = cidx_unique(mod(cidx_unique,2) == 0);
    
    [~,Odor_Epochs] = intersect(str2double({EEG.event.mffkey_cidx}), cidx_odor);
    [~,Vehicle_Epochs] = intersect(str2double({EEG.event.mffkey_cidx}), cidx_vehicle);
    
    [OdorOn] = intersect(All_DIN1,Odor_Epochs);
    [VehicleOn] = intersect(All_DIN1,Vehicle_Epochs);
    
    addpath(genpath('C:\Users\lanan\Documents\MATLAB\eeglab2019_1'))
    
    EEGOdor     = pop_epoch(EEG,[],[-15 15],'eventindices',OdorOn);
    EEGVehicle  = pop_epoch(EEG,[],[-15 15],'eventindices',VehicleOn);
    
    
    %%

    %-----Epoch the data for Odor-------------
    ft_EEG_Odor = eeglab2fieldtrip(EEGOdor,'raw');
    cfg = []; cfg.channel = ChansOfInterest;%ft_EEG_Odor.label(1:end-1);
    ft_EEG_Odor = ft_selectdata(cfg, ft_EEG_Odor);
    
    %-----Epoch the data for Vehicle-------------
    ft_EEG_Vehicle = eeglab2fieldtrip(EEGVehicle,'raw');
    cfg = []; cfg.channel = ChansOfInterest;%ft_EEG_Vehicle.label(1:end-1);
    ft_EEG_Vehicle = ft_selectdata(cfg, ft_EEG_Vehicle);
    
    rmpath(genpath('C:\Users\lanan\Documents\MATLAB\eeglab2019_1'))
    
    %% Organize data structure
    
    
    cfg = [];
    layout = ft_prepare_layout(cfg, ft_EEG_Odor);
    
    % Odor vs Vehicle
    mintrials = min(size(ft_EEG_Odor.trial,2),...
        size(ft_EEG_Vehicle.trial,2));
    CatTrials = cat(2,ft_EEG_Odor.trial(1:mintrials),...
        ft_EEG_Vehicle.trial(1:mintrials));
    
    NewTrial =[];
    for trial = 1:length(CatTrials)
        NewTrial(trial,:,:) = CatTrials{trial};
    end
    
    NewTime = cat(2,ft_EEG_Odor.time(1:mintrials),...
        ft_EEG_Vehicle.time(1:mintrials));
    Newlabel = ft_EEG_Odor.label;
    Newcfg = ft_EEG_Odor.cfg;
    
    attended_deviant = logical([ones(1,mintrials),zeros(1,mintrials)]); 
    chans = layout;
    dat.trial = single(NewTrial);
    dat.time = NewTime{1,1};
    dat.label = Newlabel';
    dat.cfg = Newcfg;
    nChan = length(Newlabel);
    nTime = length(NewTime{1,1});
    nTrial = length(CatTrials);
    
    save(strcat(file_DA{1,1},'OdorVsVehicle'),'attended_deviant','chans',...
        'dat','nChan','nTime','nTrial');

end

%%

%addpath('/home/andrea/Documents/MatlabFunctions/MVPA-Light-master/startup/')

AllTrials = [];
All_attended_deviant = [];

for file_DA = files_MA_Cue
    Data = load(strcat(file_DA{1,1},'OdorVsVehicle.mat'));
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
