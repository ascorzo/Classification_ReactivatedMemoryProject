%% Recognize all the Cue data
addpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1');
eeglab
filepath = '/home/andrea/Documents/DataGermany/FBCSP_Classification/Epoched/';
files_Cue_On = dir(strcat(filepath,'*_CueOn*','.set'));
files_Cue_Off = dir(strcat(filepath,'*_CueOff*','.set'));

for i = numel(files_Cue_On)
    file_On = files_Cue_On(i).name;
    file_Off = files_Cue_Off(i).name;
    EEGOn = pop_loadset( file_On, filepath);
    EEGOff = pop_loadset( file_Off, filepath);
    
    filename = strcat(file_On(1:7),'CueOn_vs_CueOff');
    x = double(cat(3,permute(EEGOn.data,[2,1,3]),permute(EEGOff.data,[2,1,3])));
    y = [zeros(1,size(EEGOn.data,3)),ones(1,size(EEGOff.data,3))];
    c = {EEGOn.chanlocs.labels};
    s = EEGOff.srate;
    
    x = x(:,1:128,:);
    c = c(1:128);
    
    save(filename,'x','y','c','s')
    
end