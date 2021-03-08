%% Recognize all the On-Period data
addpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1');
eeglab
filepath = '/home/andrea/Documents/DataGermany/FBCSP_Classification/Epoched_OffOn/';
files_Cue_On = dir(strcat(filepath,'*_Cue*','.set'));
files_Sham_On = dir(strcat(filepath,'*_Sham*','.set'));

for i = 1:numel(files_Cue_On)
    file_Cue = files_Cue_On(i).name;
    file_Sham = files_Sham_On(i).name;
    EEGCue = pop_loadset( file_Cue, filepath);
    EEGSham = pop_loadset( file_Sham, filepath);
    
    filename = strcat(file_Cue(1:7),'Cue_vs_Sham');
    x = double(cat(3,permute(EEGCue.data,[2,1,3]),permute(EEGSham.data,[2,1,3])));
    y = [zeros(1,size(EEGCue.data,3)),ones(1,size(EEGSham.data,3))];
    c = {EEGCue.chanlocs.labels}; 
    s = EEGSham.srate;
    
    x = x(:,1:128,:);
    c = c(1:128);
    
    save(filename,'x','y','c','s','-v7.3')
    
end