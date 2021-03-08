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

%%

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