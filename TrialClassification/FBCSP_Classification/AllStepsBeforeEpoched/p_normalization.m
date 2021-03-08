Data =  EEG.data;

s_mean = mean(Data(:));
s_std = std(Data(:));

Data = (Data-s_mean)/s_std;

EEG.data = Data;
