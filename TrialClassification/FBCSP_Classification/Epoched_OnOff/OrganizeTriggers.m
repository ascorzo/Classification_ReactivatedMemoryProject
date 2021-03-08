addpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1');
eeglab
filepath = '/home/sleep/Documents/DAVID/Datasets/Ori/preProcessing/MedianFiltered/';
files = dir(strcat(filepath,'*.set'));

for i = 1:numel(files)
    filename = files(i).name;
    
    EEG = pop_loadset( filename, filepath);
    
    %% Separar por DIN1 y DIN2
    
    All_DIN1 = find(strcmp({EEG.event.code},'DIN1'));
    
    All_DIN2 = find(strcmp({EEG.event.code},'DIN2'));
    
    
    %% Separar por pares e impares
    
    get_cidx= {EEG.event.mffkey_cidx};
    
    Sham_Epochs = find(mod(str2double(get_cidx),2)==0);
    Cue_Epochs = find(mod(str2double(get_cidx),2)~= 0);
    
    [ShamOn] = intersect(All_DIN1,Sham_Epochs);
    [CueOn] = intersect(All_DIN1,Cue_Epochs);
    
    [ShamOff] = intersect(All_DIN2,Sham_Epochs);
    [CueOff] = intersect(All_DIN2,Cue_Epochs);
    
    EEG = pop_resample( EEG, 200);
    
    OUTEEG_Cue = pop_epoch( EEG,[],[0 30],'eventindices',CueOn);
    %OUTEEG_CueOff = pop_epoch( EEG,[],[0 15],'eventindices',CueOff);
    OUTEEG_Sham = pop_epoch( EEG,[],[0 30],'eventindices',ShamOn);
    %OUTEEG_ShamOff = pop_epoch( EEG,[],[0 15],'eventindices',ShamOff);
    
    outputname_Cue = strcat(filename(1:7),'Epochs_Cue');
    %outputname_CueOff = strcat(filename(1:7),'Epochs_CueOff');
    outputname_Sham = strcat(filename(1:7),'Epochs_Sham');
    %outputname_ShamOff = strcat(filename(1:7),'Epochs_ShamOff');
    
    pop_saveset(OUTEEG_Cue,'filename',outputname_Cue);
    %pop_saveset(OUTEEG_CueOff,'filename',outputname_CueOff);
    pop_saveset(OUTEEG_Sham,'filename',outputname_Sham);
    %pop_saveset(OUTEEG_ShamOff,'filename',outputname_ShamOff);
    
end