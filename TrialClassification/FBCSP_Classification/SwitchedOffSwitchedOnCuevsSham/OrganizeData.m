%% Recognize all the Off-Period data
addpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1');
eeglab
filepath = '/home/andrea/Documents/DataGermany/Epoched/';
files_Cue_Off = dir(strcat(filepath,'*_CueOff*','.set'));
files_Sham_Off = dir(strcat(filepath,'*_ShamOff*','.set'));

files_Cue_On = dir(strcat(filepath,'*_CueOn*','.set'));
files_Sham_On = dir(strcat(filepath,'*_ShamOn*','.set'));

for i = 1:numel(files_Cue_Off)
    
    file_Cue_On = files_Cue_On(i).name;
    file_Sham_On = files_Sham_On(i).name;
    file_Cue_Off = files_Cue_Off(i).name;
    file_Sham_Off = files_Sham_Off(i).name;
    
    
    EEGCueOn = pop_loadset( file_Cue_On, filepath);
    EEGShamOn = pop_loadset( file_Sham_On, filepath);
    EEGCueOff = pop_loadset( file_Cue_Off, filepath);
    EEGShamOff = pop_loadset( file_Sham_Off, filepath);
    
    filename = strcat(file_Cue_On(1:7),'OffOn_CuevsSham');
    
    EEGCue = cat(3,EEGCueOn.data,EEGShamOff.data);
    EEGSham = cat(3,EEGShamOn.data,EEGCueOff.data);
    
    x = double(cat(3,permute(EEGCue,[2,1,3]),permute(EEGSham,[2,1,3])));
    y = [zeros(1,size(EEGCue,3)),ones(1,size(EEGSham,3))];
    c = {EEGCueOn.chanlocs.labels};
    s = EEGShamOn.srate;
    
    save(filename,'x','y','c','s')
    
end