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

filesPath       = '/mnt/disk1/andrea/German_Study/Data/Raw/MFF/Sleep/OdorD_Night/';

%----For Cue Night:
load('/mnt/disk1/andrea/German_Study/Classification/SO_Classification/SODetection/Channel_Cue_night_FastSSPeak_Scales1_2.5_SO0.5-4_PhCpl0.5-2SlowOsc/13-Nov-2020_21-14-15_AllData.mat')
filesDavidPath  = '/home/andrea/Desktop/disk1/andrea/German_Study/Data/Filtered-David/CueNight/';

%----For placebo Night
% load('/gpfs01/born/group/Andrea/ReactivatedConnectivity/SOClassification/SODetection/Channel_Placebo_night_FastSSPeak_Scales1_2.5_SO0.5-4_PhCpl0.5-2SlowOsc/16-Nov-2020_07-40-16_AllData.mat')
% filesDavidPath  = '/gpfs01/born/group/Andrea/ReactivatedConnectivity/Filtered-David/PlaceboNight/';


files           = dir(strcat(filesPath,'.mff'));

addpath(genpath('/home/andrea/Documents/Ray2015'))

files_DA_Cue = {...
    'RC_051_sleep','RC_091_sleep','RC_121_sleep','RC_131_sleep',...
    'RC_141_sleep','RC_161_sleep','RC_171_sleep','RC_201_sleep',...
    'RC_241_sleep','RC_251_sleep','RC_261_sleep','RC_281_sleep',...
    'RC_291_sleep','RC_301_sleep',...
    'RC_392_sleep','RC_412_sleep','RC_442_sleep','RC_452_sleep',...
    'RC_462_sleep','RC_472_sleep','RC_482_sleep','RC_492_sleep',...
    'RC_512_sleep'};


files_PA_Cue = {...
    'RC_052_sleep','RC_092_sleep','RC_122_sleep','RC_132_sleep',...
    'RC_142_sleep','RC_162_sleep','RC_172_sleep','RC_202_sleep',...
    'RC_242_sleep','RC_252_sleep','RC_262_sleep','RC_282_sleep',...
    'RC_292_sleep','RC_302_sleep',...    
    'RC_391_sleep','RC_411_sleep','RC_441_sleep','RC_451_sleep',...
    'RC_461_sleep','RC_471_sleep','RC_481_sleep','RC_491_sleep',...
    'RC_511_sleep'};

chanOfInterest      = 'E36';
stimulation_seq     = 'switchedOFF_switchedON';
trials2rejFile      = '';
trials2rejVar       = 'comps2reject';

NewSR = 200;
OldSR = 1000;

SR_Ratio = OldSR/NewSR;

%bands       = [1 4;4 8; 8 12; 12 16;16 30];
bands       =1:1:30; 
crossval    = 15;
intervals   = 0;%:1000:30000;

x_Odor_On = [];
x_Odor_Off = [];

x_Vehicle_On = [];
x_Vehicle_Off = [];

%% Separate events, before checking SO

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For Cue Night
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Nsubj = 0;
SUBJ = [];

for file_DA = files_DA_Cue
    
    Nsubj = Nsubj+1;
    
    disp(strcat('Sujeto: ',file_DA))
    
    addpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1/'))
    %addpath('/gpfs01/born/group/Andrea/eeglab2019_1/plugins/mffmatlabio-master/')
    
    dataType    = '.mff';
    [EEGRaw] = f_load_data(...
        strcat(char(file_DA),dataType), filesPath, dataType);
   
    dataType    = '.set';
    [EEGDavidCue] = f_load_data(...
        strcat(char(file_DA),'_TRIALS_switchedOFF_switchedON_Odor',...
        dataType), filesDavidPath, dataType);    
    
    [EEGDavidVehicle] = f_load_data(...
        strcat(char(file_DA),'_TRIALS_switchedOFF_switchedON_Sham',...
        dataType), filesDavidPath, dataType); 
    
    rmpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1/'))

    [~,~,Trig_OI_Cue]= intersect(...
        {EEGDavidCue.event.mffkey_gidx},{EEGRaw.event.mffkey_gidx});
    
     [~,~,Trig_OI_Vehicle]= intersect(...
        {EEGDavidVehicle.event.mffkey_gidx},{EEGRaw.event.mffkey_gidx});
    
    Trig_OI_Cue     = sort(Trig_OI_Cue);
    Trig_OI_Vehicle = sort(Trig_OI_Vehicle);
    
    
    %-----Find latency of triggers in the original file
    Latency_OI_Cue = [EEGRaw.event(Trig_OI_Cue).latency]; %latencies in ms or samples (since 1000 as SR)
    Latency_OI_Vehicle = [EEGRaw.event(Trig_OI_Vehicle).latency]; %latencies in ms or samples (since 1000 as SR)
    
    Latency_OI_Cue_Off = Latency_OI_Cue - 15*OldSR; %latencies in ms or samples (since 1000 as SR)
    Latency_OI_Vehicle_Off = Latency_OI_Vehicle - 15*OldSR;%latencies in ms or samples (since 1000 as SR)
    
    %% Cue Odor
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    % OFF
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    SO_OdorOff = OverallSlowOsc.(chanOfInterest).OdorOff(:,Nsubj);
    
    OriginalStartTime = [];
    OriginalMidTime = [];
    OriginalendTime = [];
    for trial = 1:length(SO_OdorOff)
        for SO = 1:size(SO_OdorOff{trial},1)
            
            if ~isempty(SO_OdorOff{trial})
                if~isnan(SO_OdorOff{trial}(1))
                    % Time of SO occurence in the trial (in samples)
                    StartTime = SO_OdorOff{trial}(SO,2);
                    MidTime = SO_OdorOff{trial}(SO,3);
                    endTime = SO_OdorOff{trial}(SO,4);
                    
                    % Time of SO occurence accorging to trigger in the whole
                    % recording (in miliseconds)
                    TrialStartTime = StartTime/NewSR*1000;
                    TrialMidTime = MidTime/NewSR*1000;
                    TrialendTime = endTime/NewSR*1000;
                    
                    % Time of SO occurence in the whole recording
                    OriginalStartTime = cat(1,OriginalStartTime,...
                        Latency_OI_Cue_Off(trial)+TrialStartTime);
                    OriginalMidTime = cat(1,OriginalMidTime,...
                        Latency_OI_Cue_Off(trial)+TrialMidTime);
                    OriginalendTime = cat(1,OriginalendTime,...
                        Latency_OI_Cue_Off(trial)+TrialendTime);
                end
            end
            
        end
    end

    Last_event = numel(EEGRaw.event);
    
    for SO = 1:numel(OriginalStartTime)
        % Add triggers to the original EEG
        EEGRaw.event(SO+Last_event).type = '35';
        EEGRaw.event(SO+Last_event).latency = OriginalStartTime(SO);
        EEGRaw.event(SO+Last_event).duration = 0;
        EEGRaw.event(SO+Last_event).label = 'SO_start';
    end

    Last_event = numel(EEGRaw.event);
    
    for SO = 1:numel(OriginalMidTime)
        % Add triggers to the original EEG
        EEGRaw.event(SO+Last_event).type = '36';
        EEGRaw.event(SO+Last_event).latency = OriginalMidTime(SO);
        EEGRaw.event(SO+Last_event).duration = 0;
        EEGRaw.event(SO+Last_event).label = 'SO_Mid';
    end
    
    Last_event = numel(EEGRaw.event);
    
    for SO = 1:numel(OriginalendTime)
        % Add triggers to the original EEG
        EEGRaw.event(SO+Last_event).type = '37';
        EEGRaw.event(SO+Last_event).latency = OriginalendTime(SO);
        EEGRaw.event(SO+Last_event).duration = 0;
        EEGRaw.event(SO+Last_event).label = 'SO_End';
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    % ON
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    SO_OdorOn = OverallSlowOsc.(chanOfInterest).OdorOn(:,Nsubj);
    
    OriginalStartTime = [];
    OriginalMidTime = [];
    OriginalendTime = [];
    for trial = 1:length(SO_OdorOn)
        for SO = 1:size(SO_OdorOn{trial},1)
            
            if ~isempty(SO_OdorOn{trial})
                if~isnan(SO_OdorOn{trial}(1))
                    % Time of SO occurence in the trial
                    StartTime = SO_OdorOn{trial}(SO,2);
                    MidTime = SO_OdorOn{trial}(SO,3);
                    endTime = SO_OdorOn{trial}(SO,4);
                    
                    % Time of SO occurence accorging to trigger in the whole
                    % recording
                    TrialStartTime = StartTime/NewSR*1000;
                    TrialMidTime = MidTime/NewSR*1000;
                    TrialendTime = endTime/NewSR*1000;
                    
                    % Time of SO occurence in the whole recording
                    OriginalStartTime = cat(1,OriginalStartTime,...
                        Latency_OI_Cue(trial)+TrialStartTime);
                    OriginalMidTime = cat(1,OriginalMidTime,...
                        Latency_OI_Cue(trial)+TrialMidTime);
                    OriginalendTime = cat(1,OriginalendTime,...
                        Latency_OI_Cue(trial)+TrialendTime);
                end
            end
            
        end
    end

    Last_event = numel(EEGRaw.event);
    
    for SO = 1:numel(OriginalStartTime)
        % Add triggers to the original EEG
        EEGRaw.event(SO+Last_event).type = '45';
        EEGRaw.event(SO+Last_event).latency = OriginalStartTime(SO);
        EEGRaw.event(SO+Last_event).duration = 0;
        EEGRaw.event(SO+Last_event).label = 'SO_start';
    end

    Last_event = numel(EEGRaw.event);
    
    for SO = 1:numel(OriginalMidTime)
        % Add triggers to the original EEG
        EEGRaw.event(SO+Last_event).type = '46';
        EEGRaw.event(SO+Last_event).latency = OriginalMidTime(SO);
        EEGRaw.event(SO+Last_event).duration = 0;
        EEGRaw.event(SO+Last_event).label = 'SO_Mid';
    end
    
    Last_event = numel(EEGRaw.event);
    
    for SO = 1:numel(OriginalendTime)
        % Add triggers to the original EEG
        EEGRaw.event(SO+Last_event).type = '47';
        EEGRaw.event(SO+Last_event).latency = OriginalendTime(SO);
        EEGRaw.event(SO+Last_event).duration = 0;
        EEGRaw.event(SO+Last_event).label = 'SO_End';
    end


%% Vehicle 

    %%%%%%%%%%%%%%%%%%%%%%%%%%
    % OFF
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    SO_VehicleOff = OverallSlowOsc.(chanOfInterest).ShamOff(:,Nsubj);
    
    OriginalStartTime = [];
    OriginalMidTime = [];
    OriginalendTime = [];
    for trial = 1:length(SO_VehicleOff)
        for SO = 1:size(SO_VehicleOff{trial},1)
            
            if ~isempty(SO_VehicleOff{trial})
                if~isnan(SO_VehicleOff{trial}(1))
                    % Time of SO occurence in the trial
                    StartTime = SO_VehicleOff{trial}(SO,2);
                    MidTime = SO_VehicleOff{trial}(SO,3);
                    endTime = SO_VehicleOff{trial}(SO,4);
                    
                    % Time of SO occurence accorging to trigger in the whole
                    % recording
                    TrialStartTime = StartTime/NewSR*1000;
                    TrialMidTime = MidTime/NewSR*1000;
                    TrialendTime = endTime/NewSR*1000;
                    
                    % Time of SO occurence in the whole recording
                    OriginalStartTime = cat(1,OriginalStartTime,...
                        Latency_OI_Vehicle_Off(trial)+TrialStartTime);
                    OriginalMidTime = cat(1,OriginalMidTime,...
                        Latency_OI_Vehicle_Off(trial)+TrialMidTime);
                    OriginalendTime = cat(1,OriginalendTime,...
                        Latency_OI_Vehicle_Off(trial)+TrialendTime);
                end
            end
            
        end
    end

    Last_event = numel(EEGRaw.event);
    
    for SO = 1:numel(OriginalStartTime)
        % Add triggers to the original EEG
        EEGRaw.event(SO+Last_event).type = '55';
        EEGRaw.event(SO+Last_event).latency = OriginalStartTime(SO);
        EEGRaw.event(SO+Last_event).duration = 0;
        EEGRaw.event(SO+Last_event).label = 'SO_start';
    end

    Last_event = numel(EEGRaw.event);
    
    for SO = 1:numel(OriginalMidTime)
        % Add triggers to the original EEG
        EEGRaw.event(SO+Last_event).type = '56';
        EEGRaw.event(SO+Last_event).latency = OriginalMidTime(SO);
        EEGRaw.event(SO+Last_event).duration = 0;
        EEGRaw.event(SO+Last_event).label = 'SO_Mid';
    end
    
    Last_event = numel(EEGRaw.event);
    
    for SO = 1:numel(OriginalendTime)
        % Add triggers to the original EEG
        EEGRaw.event(SO+Last_event).type = '57';
        EEGRaw.event(SO+Last_event).latency = OriginalendTime(SO);
        EEGRaw.event(SO+Last_event).duration = 0;
        EEGRaw.event(SO+Last_event).label = 'SO_End';
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%
    % ON
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    SO_VehicleOn = OverallSlowOsc.(chanOfInterest).ShamOn(:,Nsubj);
    
    OriginalStartTime = [];
    OriginalMidTime = [];
    OriginalendTime = [];
    for trial = 1:length(SO_VehicleOn)
        for SO = 1:size(SO_VehicleOn{trial},1)
            if ~isempty(SO_VehicleOn{trial})
                if~isnan(SO_VehicleOn{trial}(1))
                    % Time of SO occurence in the trial
                    StartTime = SO_VehicleOn{trial}(SO,2);
                    MidTime = SO_VehicleOn{trial}(SO,3);
                    endTime = SO_VehicleOn{trial}(SO,4);
                    
                    % Time of SO occurence accorging to trigger in the whole
                    % recording
                    TrialStartTime = StartTime/NewSR*1000;
                    TrialMidTime = MidTime/NewSR*1000;
                    TrialendTime = endTime/NewSR*1000;
                    
                    % Time of SO occurence in the whole recording in ms
                    OriginalStartTime = cat(1,OriginalStartTime,...
                        Latency_OI_Vehicle(trial)+TrialStartTime);
                    OriginalMidTime = cat(1,OriginalMidTime,...
                        Latency_OI_Vehicle(trial)+TrialMidTime);
                    OriginalendTime = cat(1,OriginalendTime,...
                        Latency_OI_Vehicle(trial)+TrialendTime);
                end
            end
        end
    end

    Last_event = numel(EEGRaw.event);
    
    for SO = 1:numel(OriginalStartTime)
        % Add triggers to the original EEG
        EEGRaw.event(SO+Last_event).type = '65';
        EEGRaw.event(SO+Last_event).latency = OriginalStartTime(SO);
        EEGRaw.event(SO+Last_event).duration = 0;
        EEGRaw.event(SO+Last_event).label = 'SO_start';
    end

    Last_event = numel(EEGRaw.event);
    
    for SO = 1:numel(OriginalMidTime)
        % Add triggers to the original EEG
        EEGRaw.event(SO+Last_event).type = '66';
        EEGRaw.event(SO+Last_event).latency = OriginalMidTime(SO);
        EEGRaw.event(SO+Last_event).duration = 0;
        EEGRaw.event(SO+Last_event).label = 'SO_Mid';
    end
    
    Last_event = numel(EEGRaw.event);
    
    for SO = 1:numel(OriginalendTime)
        % Add triggers to the original EEG
        EEGRaw.event(SO+Last_event).type = '67';
        EEGRaw.event(SO+Last_event).latency = OriginalendTime(SO);
        EEGRaw.event(SO+Last_event).duration = 0;
        EEGRaw.event(SO+Last_event).label = 'SO_End';
    end
    
    %EEG = EEGRaw;
    %addpath('C:\Users\lanan\Documents\MATLAB\eeglab2019_1')
    %eeglab redraw
    
    % Remove external channels
    chan_Mastoids       = {'E57', 'E100'};
    chan_EOG            = {'E8', 'E14', 'E21', 'E25', 'E126', 'E127'};
    chan_EMG            = {'E43', 'E120'};
    chan_VREF           = {'E129'};
    chan_Face           = {'E49', 'E48', 'E17', 'E128', 'E32', 'E1', ...
        'E125', 'E119', 'E113'};
        

    chans2Rej   = [chan_Mastoids, chan_EOG, chan_EMG, chan_Face, chan_VREF];
    
    [~, idx_chan2rej] = intersect({EEGRaw.chanlocs.labels},chans2Rej);
    
    addpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1/'))
    [EEGRaw] = ...
        pop_select( EEGRaw, 'nochannel', idx_chan2rej);
    
    % Epoch Data
    
    %-----Epoch the data for cue On-------------
    OUTEEG_CueSO_On = pop_epoch(EEGRaw,{'46'},[-1 1]);
    
    %-----Epoch the data for cue Off-------------
    OUTEEG_CueSO_Off = pop_epoch(EEGRaw,{'36'},[-1 1]);
    
    %-----Epoch the data for Vehicle On-------------
    OUTEEG_VehicleSO_On = pop_epoch(EEGRaw,{'66'},[-1 1]);
    
    %-----Epoch the data for Vehicle Off-------------
    OUTEEG_VehicleSO_Off = pop_epoch(EEGRaw,{'56'},[-1 1]);
    
    rmpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1/'))
    
    
    % Organize data structure
%CueOnvsVehOn
%     mintrials = min(size(OUTEEG_CueSO_On.data,3),...
%         size(OUTEEG_VehicleSO_On.data,3));
%     x = cat(3,double(permute(OUTEEG_CueSO_On.data(:,:,end-mintrials+1:end),[2,1,3])),...
%         double(permute(OUTEEG_VehicleSO_On.data(:,:,end-mintrials+1:end),[2,1,3])));
%     x = f_zscore_normalization(x);
%     y = [zeros(1,mintrials),...
%         ones(1,mintrials)];
%         
%     SUBJ.(file_DA{1, 1}).CueOnvsVehOn.x = x; 
%     SUBJ.(file_DA{1, 1}).CueOnvsVehOn.y = y;
%     SUBJ.(file_DA{1, 1}).CueOnvsVehOn.c = {OUTEEG_CueSO_On.chanlocs.labels}; 
%     SUBJ.(file_DA{1, 1}).CueOnvsVehOn.s = OUTEEG_CueSO_On.srate; 
    
    
    %CueOnvsCueOff
%     mintrials = min(size(OUTEEG_CueSO_On.data,3),...
%         size(OUTEEG_CueSO_Off.data,3));
%     x = cat(3,double(permute(OUTEEG_CueSO_On.data(:,:,end-mintrials+1:end),[2,1,3])),...
%         double(permute(OUTEEG_CueSO_Off.data(:,:,end-mintrials+1:end),[2,1,3])));
%     x = f_zscore_normalization(x);
%     y = [ones(1,mintrials),...
%         zeros(1,mintrials)];
%         
%     SUBJ.(file_DA{1, 1}).CueOnvsCueOff.x = x; 
%     SUBJ.(file_DA{1, 1}).CueOnvsCueOff.y = y;
%     SUBJ.(file_DA{1, 1}).CueOnvsCueOff.c = {OUTEEG_CueSO_On.chanlocs.labels}; 
%     SUBJ.(file_DA{1, 1}).CueOnvsCueOff.s = OUTEEG_CueSO_On.srate;
    
    %VehOnvsVehOff
%     mintrials = min(size(OUTEEG_VehicleSO_On.data,3),...
%         size(OUTEEG_VehicleSO_Off.data,3));
%     x = cat(3,double(permute(OUTEEG_VehicleSO_On.data(:,:,end-mintrials+1:end),[2,1,3])),...
%         double(permute(OUTEEG_VehicleSO_Off.data(:,:,end-mintrials+1:end),[2,1,3])));
%     x = f_zscore_normalization(x);
%     y = [ones(1,mintrials),...
%         zeros(1,mintrials)];
%         
%     SUBJ.(file_DA{1, 1}).VehOnvsVehOff.x = x; 
%     SUBJ.(file_DA{1, 1}).VehOnvsVehOff.y = y;
%     SUBJ.(file_DA{1, 1}).VehOnvsVehOff.c = {OUTEEG_VehicleSO_On.chanlocs.labels}; 
%     SUBJ.(file_DA{1, 1}).VehOnvsVehOff.s = OUTEEG_VehicleSO_On.srate;
    
    
        
    % Organize data structure All Subjects
    
    mintrialsAll = min([size(OUTEEG_CueSO_On.data,3),...
        size(OUTEEG_CueSO_Off.data,3),...
        size(OUTEEG_VehicleSO_On.data,3),...
        size(OUTEEG_VehicleSO_Off.data,3)]);
    
    x_Odor_On = cat(3,x_Odor_On,double(permute(OUTEEG_CueSO_On.data(:,:,end-mintrialsAll+1:end),[2,1,3])));
    x_Vehicle_On = cat(3,x_Vehicle_On,double(permute(OUTEEG_VehicleSO_On.data(:,:,end-mintrialsAll+1:end),[2,1,3])));
    x_Odor_Off = cat(3,x_Odor_Off,double(permute(OUTEEG_CueSO_Off.data(:,:,end-mintrialsAll+1:end),[2,1,3])));
    x_Vehicle_Off = cat(3,x_Vehicle_Off,double(permute(OUTEEG_VehicleSO_Off.data(:,:,end-mintrialsAll+1:end),[2,1,3])));
 
    
    x_Odor_On = f_zscore_normalization(x_Odor_On);
    x_Vehicle_On = f_zscore_normalization(x_Vehicle_On);
    x_Odor_Off = f_zscore_normalization(x_Odor_Off);
    x_Vehicle_Off = f_zscore_normalization(x_Vehicle_Off);
    
%     [Results, Accuracies] = classifyAll(bands,intervals,2,crossval,...
%             {file_DA{1,1}},...
%             SUBJ.(file_DA{1, 1}).CueOnvsVehOn);
%         
%     save(strcat(file_DA{1,1},'CueOnvsVehOn'),'Results','Accuracies')

%     [Results, Accuracies] = classifyAll(bands,intervals,2,crossval,...
%             {file_DA{1,1}},...
%             SUBJ.(file_DA{1, 1}).CueOnvsCueOff);
%         
%     save(strcat(file_DA{1,1},'CueOnvsCueOff'),'Results','Accuracies')
%     
%     [Results, Accuracies] = classifyAll(bands,intervals,2,crossval,...
%         {file_DA{1,1}},...
%         SUBJ.(file_DA{1, 1}).VehOnvsVehOff);
%     
%     save(strcat(file_DA{1,1},'VehOnvsVehOff'),'Results','Accuracies')


end

    %CueOnvsVehOn
    AllSubj.CueOnvsVehOn.x = cat(3,x_Odor_On, x_Vehicle_On);
    AllSubj.CueOnvsVehOn.y = [ones(1,size(x_Odor_On,3)),...
        zeros(1,size(x_Vehicle_On,3))];
    AllSubj.CueOnvsVehOn.c = {OUTEEG_CueSO_On.chanlocs.labels}; 
    AllSubj.CueOnvsVehOn.s = OUTEEG_CueSO_On.srate; 
    
    
    %CueOnvsCueOff
    AllSubj.CueOnvsCueOff.x = cat(3,x_Odor_On, x_Odor_Off);
    AllSubj.CueOnvsCueOff.y = [ones(1,size(x_Odor_On,3)),...
        zeros(1,size(x_Odor_Off,3))];
    AllSubj.CueOnvsCueOff.c = {OUTEEG_CueSO_On.chanlocs.labels}; 
    AllSubj.CueOnvsCueOff.s = OUTEEG_CueSO_On.srate; 
    
    %VehOnvsVehOff
    AllSubj.VehOnvsVehOff.x = cat(3,x_Vehicle_On, x_Vehicle_Off);
    AllSubj.VehOnvsVehOff.y = [ones(1,size(x_Vehicle_On,3)),...
        zeros(1,size(x_Vehicle_Off,3))];

    AllSubj.VehOnvsVehOff.c = {OUTEEG_CueSO_On.chanlocs.labels}; 
    AllSubj.VehOnvsVehOff.s = OUTEEG_CueSO_On.srate; 


    [Results, Accuracies] = classifyAll(bands,intervals,2,crossval,...
            {'All_Subj'},...
            AllSubj.CueOnvsVehOn);
        
    save(strcat('AllSubj_CueOnvsVehOn_Norm_Hz'),'Results','Accuracies')

    [Results, Accuracies] = classifyAll(bands,intervals,2,crossval,...
            {file_DA{1,1}},...
            SUBJ.(file_DA{1, 1}).CueOnvsCueOff);
        
    save(strcat(file_DA{1,1},'CueOnvsCueOff_Norm'),'Results','Accuracies')
    
    [Results, Accuracies] = classifyAll(bands,intervals,2,crossval,...
        {file_DA{1,1}},...
        SUBJ.(file_DA{1, 1}).VehOnvsVehOff);
    
    save(strcat(file_DA{1,1},'VehOnvsVehOff_Norm'),'Results','Accuracies')

%%

function New_x = f_zscore_normalization(x)
New_x = x;
for trial = 1:size(x,3)
    mean_x= squeeze(mean(x(:,:,trial),1));
    std_x= squeeze(std(x(:,:,trial),[],1));
    
    mean_x = repmat(mean_x,size(x,1),1,1) ;
    std_x = repmat(std_x,size(x,1),1,1) ;
    
    New_x(:,:,trial) = ((squeeze(x(:,:,trial)))-mean_x)./std_x;   
end
end

