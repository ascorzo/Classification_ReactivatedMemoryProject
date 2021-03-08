%% Recognize all the Off-Period data

addpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1');
eeglab
filepath = '/home/andrea/Documents/DataGermany/FBCSP_Classification/Epoched/';
files_Cue_Off = dir(strcat(filepath,'*_CueOff*','.set'));
files_Sham_Off = dir(strcat(filepath,'*_ShamOff*','.set'));

for i = 1:numel(files_Cue_Off)
    file_Cue = files_Cue_Off(i).name;
    file_Sham = files_Sham_Off(i).name;
    EEGCue = pop_loadset( file_Cue, filepath);
    EEGSham = pop_loadset( file_Sham, filepath);
    
    filename = strcat(file_Cue(1:7),'CueOff_vs_ShamOff');
    x = double(cat(3,permute(EEGCue.data,[2,1,3]),permute(EEGSham.data,[2,1,3])));
    y = [zeros(1,size(EEGCue.data,3)),ones(1,size(EEGSham.data,3))];
    c = {EEGCue.chanlocs.labels};
    s = EEGSham.srate;
    
    x = x(:,1:128,:);
    c = c(1:128);
    
    save(filename,'x','y','c','s')
    
end