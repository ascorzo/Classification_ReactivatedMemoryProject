addpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1/');
eeglab
filepath = '/home/sleep/Documents/DAVID/Datasets/Ori/preProcessing/CustomFiltered/';
files = dir(strcat(filepath,'*.set'));

for i = 1:numel(files)
    filename = files(i).name;
    
    EEG = pop_loadset( filename, filepath);
    
    %% Normalizar
    
    run p_normalization.m
    
    outputname = strcat(filename,'_Normalized');
    
    pop_saveset(EEG,'filename',outputname);
    
end