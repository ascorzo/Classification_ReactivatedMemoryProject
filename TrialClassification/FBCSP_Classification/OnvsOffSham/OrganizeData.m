%% Recognize all the Sham data

addpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1');
eeglab
filepath = '/home/andrea/Documents/DataGermany/FBCSP_Classification/Epoched/';
files_Sham_On = dir(strcat(filepath,'*_ShamOn*','.set'));
files_Sham_Off = dir(strcat(filepath,'*_ShamOff*','.set'));

for i = 1:numel(files_Sham_On)
    file_On = files_Sham_On(i).name;
    file_Off = files_Sham_Off(i).name;
    EEGOn = pop_loadset( file_On, filepath);
    EEGOff = pop_loadset( file_Off, filepath);
    
    filename = strcat(file_On(1:7),'ShamOn_vs_ShamOff');
    x = double(cat(3,permute(EEGOn.data,[2,1,3]),permute(EEGOff.data,[2,1,3])));
    y = [zeros(1,size(EEGOn.data,3)),ones(1,size(EEGOff.data,3))];
    c = {EEGOn.chanlocs.labels};
    s = EEGOff.srate;
    
    x = x(:,1:128,:);
    c = c(1:128);
    
    save(filename,'x','y','c','s')
    
end