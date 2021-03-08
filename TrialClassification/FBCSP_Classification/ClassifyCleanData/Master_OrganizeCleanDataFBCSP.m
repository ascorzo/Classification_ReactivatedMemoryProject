close all
addpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1/');
addpath(genpath('/home/andrea/Documents/Ray2015/'));


filepath = '/home/sleep/Documents/DAVID/Datasets/Ori/preProcessing/DataChan_CustomKaiserwin/';
filesCue = dir(strcat(filepath,'*Cue*.mat'));
filesSham = dir(strcat(filepath,'*Sham*.mat'));


Classification = {'Subject Dependant';...
    'Subject Independant'};

[indx,tf] = listdlg('PromptString',{'Type of classification to apply'},...
    'SelectionMode','single','ListString',Classification);

dbstop if error
bands       = (1:1:30);
crossval    = 15;
intervals   = 0:1000:30000;

warning off

AllSubjects.x = [];
AllSubjects.y = [];

for i = 1:numel(filesCue)
    filenameCue = filesCue(i).name;
    filenameSham = filesSham(i).name;
    
    C1 = load(strcat(filepath,filenameCue));
    C2 = load(strcat(filepath,filenameSham));
    
    %% Normalizar
    
    Data1 =  double(C1.Channel.Data);
    s_mean = mean(Data1(:));
    s_std = std(Data1(:));
    Data1 = (Data1-s_mean)/s_std;
    
    Data2 =  double(C2.Channel.Data);
    s_mean = mean(Data2(:));
    s_std = std(Data2(:));
    Data2 = (Data2-s_mean)/s_std;
    
    %% Organize Data
    
    
    x = double(cat(3,permute(Data1,[2,1,3]),permute(Data2,[2,1,3])));
    y = cat(2,zeros(1,size(Data1,3)),ones(1,size(Data2,3)));
    c = C1.Channel.Labels;
    s = C1.Channel.Srate;
    
    name = filenameCue(1:6);
    
    Subjects.(name).x = x;
    Subjects.(name).y = y;
    Subjects.(name).c = c';
    Subjects.(name).s = s;
    
    if indx == 1
        [Results, Accuracies] = classifyAll(bands,intervals,2,crossval,...
            {name},...
            Subjects.(name));
        
        save(name,'Results','Accuracies');   
    end
    
    if indx == 2
        AllSubjects.x = cat(3,AllSubjects.x,Subjects.(name).x);
        AllSubjects.y = cat(2,AllSubjects.y,Subjects.(name).y);
        AllSubjects.c = Subjects.(name).c;
        AllSubjects.s = Subjects.(name).s;
    end
    
clear Subjects
        
end

if indx == 2
    [Results, Accuracies] = classifyAll(bands,intervals,2,crossval,...
        {'AllSubjects'},...
        AllSubjects);
    
    save('AllSubjects','Results','Accuracies'); 
    
end

close all



% [Results, Accuracies] = classifyAll(bands,intervals,2,crossval,...
%     {'RC_051';'RC_091';'RC_121';'RC_131';'RC_141';'RC_161';'RC_171';...
%     'RC_201';'RC_241';'RC_251';'RC_261';'RC_281';'RC_291';'RC_301';...
%     'RC_392';'RC_412';'RC_442';'RC_452';'RC_462';'RC_472';'RC_482';...
%     'RC_492';'RC_512'},...
%     Subjects.RC_051,Subjects.RC_091,Subjects.RC_121,Subjects.RC_131,...
%     Subjects.RC_141,Subjects.RC_161,Subjects.RC_171,Subjects.RC_201,...
%     Subjects.RC_241,Subjects.RC_251,Subjects.RC_261,Subjects.RC_281,...
%     Subjects.RC_291,Subjects.RC_301,Subjects.RC_392,Subjects.RC_412,...
%     Subjects.RC_442,Subjects.RC_452,Subjects.RC_462,Subjects.RC_472,...
%     Subjects.RC_482,Subjects.RC_492,Subjects.RC_512);