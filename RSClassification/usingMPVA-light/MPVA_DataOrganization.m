% Columns in the OverallSlowOsc Matrix
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

addpath('/home/andrea/Documents/MatlabFunctions/fieldtrip-20200828/')
ft_defaults

filesPath       = '/mnt/disk1/andrea/German_Study/Data/Clean/RestingState/';
files           = dir(strcat(filesPath,'.set'));

warning off
ft_warning off

sleepfilesPath  = '/mnt/disk1/andrea/German_Study/Data/Raw/SET/Sleep/';

%----For Cue Night:

files_DA_RS = {...
    's5_n1','s9_n1','s12_n1','s13_n1',...
    's14_n1','s16_n1','s17_n1','s20_n1',...
    's24_n1','s25_n1','s26_n1','s28_n1',...
    's29_n1','s30_n1',...
    's39_n2','s41_n2','s44_n2','s45_n2',...
    's46_n2','s47_n2','s48_n2','s49_n2',...
    's51_n2'};


files_MA_RS = {...
    's5_n2','s9_n2','s12_n2','s13_n2',...
    's14_n2','s16_n2','s17_n2','s20_n2',...
    's24_n2','s25_n2','s26_n2','s28_n2',...
    's29_n2','s30_n2',...    
    's39_n1','s41_n1','s44_n1','s45_n1',...
    's46_n1','s47_n1','s48_n1','s49_n1',...
    's51_n1'};

files_DA_Sleep = {...
    'RC_051_sleep','RC_091_sleep','RC_121_sleep','RC_131_sleep',...
    'RC_141_sleep','RC_161_sleep','RC_171_sleep','RC_201_sleep',...
    'RC_241_sleep','RC_251_sleep','RC_261_sleep','RC_281_sleep',...
    'RC_291_sleep','RC_301_sleep',...
    'RC_392_sleep','RC_412_sleep','RC_442_sleep','RC_452_sleep',...
    'RC_462_sleep','RC_472_sleep','RC_482_sleep','RC_492_sleep',...
    'RC_512_sleep'};


files_MA_Sleep = {...
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


addpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1'))
dataType    = '.set';
[EEG] = f_load_data(...
    strcat(char(files_DA_Sleep(1)),'_Import',dataType), strcat(sleepfilesPath,'OdorD_Night/'), dataType);

ft_EEG = eeglab2fieldtrip(EEG,'raw');
cfg = []; cfg.channel = ChansOfInterest;%ft_EEG_Odor.label(1:end-1);
ft_EEG = ft_selectdata(cfg, ft_EEG);

rmpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1'))


mintrials = 100;

%RS1 vs RS2
cfg = [];
layout = ft_prepare_layout(cfg, ft_EEG);
%% Separate events, before checking SO

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For Cue Night
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SUBJ = [];


for subj  = 1:numel(files_DA_RS)
    
    disp(strcat('Sujeto: ',files_DA_RS(subj)))
    
    file_DA = files_DA_RS(subj);
    
    %% Odor D Night
    
     % LOAD DATA
    
    RS1_file = dir(strcat(filesPath,char(file_DA),'_rs1','*.mat'));
    RS1_Data = load(strcat(filesPath,RS1_file.name));
    RS1_Data = RS1_Data.data;
    
    RS2_file = dir(strcat(filesPath,char(file_DA),'_rs2','*.mat'));
    RS2_Data = load(strcat(filesPath,RS2_file.name));
    RS2_Data = RS2_Data.data;
    
    RS3_file = dir(strcat(filesPath,char(file_DA),'_rs3','*.mat'));
    RS3_Data = load(strcat(filesPath,RS3_file.name));
    RS3_Data = RS3_Data.data;
    
    
    cfg = []; cfg.channel = ChansOfInterest;%ft_EEG_Odor.label(1:end-1);
    RS1_Data = ft_selectdata(cfg, RS1_Data);
    RS2_Data = ft_selectdata(cfg, RS2_Data);
    RS3_Data = ft_selectdata(cfg, RS3_Data);
    
    
    % EPOCH DATA
        
    cfg = [];
    cfg.length    = 3; % epochs of 3 seconds
    
    RS1_Data      = ft_redefinetrial(cfg, RS1_Data);
    RS2_Data      = ft_redefinetrial(cfg, RS2_Data);
    RS3_Data      = ft_redefinetrial(cfg, RS3_Data);
    
    
    % zscore Normalization
    RS1_Data = f_zscore_normalization(RS1_Data);
    RS2_Data = f_zscore_normalization(RS2_Data);
    RS3_Data = f_zscore_normalization(RS3_Data);
    
    
    %% Organize data structure


     %RS1 vs RS2

    mintrials = min(size(RS1_Data.trial,2),...
        size(RS2_Data.trial,2));
    CatTrials = cat(2,RS1_Data.trial(1:mintrials),...
        RS2_Data.trial(1:mintrials));
    
    NewTrial =[];
    for trial = 1:length(CatTrials)
        NewTrial(trial,:,:) = CatTrials{trial};
    end
    
    NewTime = cat(2,RS1_Data.time(1:mintrials),...
        RS2_Data.time(1:mintrials));
    Newlabel = RS1_Data.label;
    Newcfg = RS1_Data.cfg;
    
    attended_deviant = logical([zeros(1,mintrials),ones(1,mintrials)]); 
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
    
    save(strcat(file_DA{1,1},'RS1vsRS2'),'attended_deviant','chans',...
        'dat','nChan','nTime','nTrial');
    
    %RS1 vs RS3

    mintrials = min(size(RS1_Data.trial,2),...
        size(RS3_Data.trial,2));
    CatTrials = cat(2,RS1_Data.trial(1:mintrials),...
        RS3_Data.trial(1:mintrials));
    
    NewTrial =[];
    for trial = 1:length(CatTrials)
        NewTrial(trial,:,:) = CatTrials{trial};
    end
    
    NewTime = cat(2,RS1_Data.time(1:mintrials),...
        RS3_Data.time(1:mintrials));
    Newlabel = RS1_Data.label;
    Newcfg = RS1_Data.cfg;
    
    attended_deviant = logical([zeros(1,mintrials),ones(1,mintrials)]); 
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
    
    save(strcat(file_DA{1,1},'RS1vsRS3'),'attended_deviant','chans',...
        'dat','nChan','nTime','nTrial');
    
    %RS2 vs RS3
    mintrials = min(size(RS2_Data.trial,2),...
        size(RS3_Data.trial,2));
    CatTrials = cat(2,RS2_Data.trial(1:mintrials),...
        RS3_Data.trial(1:mintrials));
    
    NewTrial =[];
    for trial = 1:length(CatTrials)
        NewTrial(trial,:,:) = CatTrials{trial};
    end
    
    NewTime = cat(2,RS2_Data.time(1:mintrials),...
        RS3_Data.time(1:mintrials));
    Newlabel = RS2_Data.label;
    Newcfg = RS2_Data.cfg;
    
    attended_deviant = logical([zeros(1,mintrials),ones(1,mintrials)]); 
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
    
    
    save(strcat(file_DA{1,1},'RS2vsRS3'),'attended_deviant','chans',...
        'dat','nChan','nTime','nTrial');
    
      
end

%%

%addpath('/home/andrea/Documents/MatlabFunctions/MVPA-Light-master/startup/')


% RS1 vs RS2
AllTrials = [];
All_attended_deviant = [];

for file_DA = files_DA_RS
    Data = load(strcat(file_DA{1,1},'RS1vsRS2.mat'));
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


save('AllSubj_RS1vsRS2.mat','dat','attended_deviant','chans',...
        'nChan','nTime','nTrial','-v7.3');

  
 % RS1 vs RS3
AllTrials = [];
All_attended_deviant = [];

for file_DA = files_DA_RS
    Data = load(strcat(file_DA{1,1},'RS1vsRS3.mat'));
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


save('AllSubj_RS1vsRS3.mat','dat','attended_deviant','chans',...
        'nChan','nTime','nTrial','-v7.3');
    
% RS2 vs RS3
AllTrials = [];
All_attended_deviant = [];

for file_DA = files_DA_RS
    Data = load(strcat(file_DA{1,1},'RS2vsRS3.mat'));
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


save('AllSubj_RS2vsRS3.mat','dat','attended_deviant','chans',...
    'nChan','nTime','nTrial','-v7.3');



function New_x = f_zscore_normalization(x)
New_x = x;
for trial = 1:length(x.trial)
    mean_x= squeeze(mean(x.trial{trial},2));
    std_x = squeeze(std(x.trial{trial},[],2));
    
    mean_x = repmat(mean_x,1,size(x.trial{trial},2));
    std_x = repmat(std_x,1,size(x.trial{trial},2));
    
    
    New_x.trial{trial} = (squeeze(x.trial{trial})-mean_x)./std_x;
end
end