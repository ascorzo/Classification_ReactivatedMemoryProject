close all
addpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1/');
addpath(genpath('/home/andrea/Documents/Ray2015/'));
eeglab

filepath = '/home/sleep/Documents/DAVID/Datasets/Ori/preProcessing/CustomFiltered/';
files = dir(strcat(filepath,'*.set'));

warning off

conditions = {'Cue Switched ON';...
    'Sham Switched ON';...
    'Cue Switched OFF';...
    'Sham Switched OFF'};

[indx,tf] = listdlg('PromptString',{'Which conditions do you want to compare?'...
    'Please select only two',''},...
    'SelectionMode','multiple','ListString',conditions);

% if sum(find(indx ~= 0))>2
%     
%     return
% end
dbstop if error


for i = 12:numel(files)
    
    bands       = (1:1:30);
    crossval    = 15;
    intervals   = 0;%:1000:30000;
    filename = files(i).name;
    
    EEG = pop_loadset( filename, filepath);
    
    %% Normalizar
    run p_normalization.m
    
    %% Epoch
    %------- Separar por DIN1 y DIN2-----------------------------
    
    All_DIN1 = find(strcmp({EEG.event.code},'DIN1'));
    
    All_DIN2 = find(strcmp({EEG.event.code},'DIN2'));
    
    
    %------- Separar por pares e impares---------------------------
    
    get_cidx= {EEG.event.mffkey_cidx};
    
    Sham_Epochs = find(mod(str2double(get_cidx),2)==0);
    Cue_Epochs = find(mod(str2double(get_cidx),2)~= 0);
    
    [ShamOn] = intersect(All_DIN1,Sham_Epochs);
    [CueOn] = intersect(All_DIN1,Cue_Epochs);
    
    [ShamOff] = intersect(All_DIN2,Sham_Epochs);
    [CueOff] = intersect(All_DIN2,Cue_Epochs);
    
    %EEG = pop_resample( EEG, 200);
    
    subTrialSize = 5000;
    
    %-----Organizar los datos para la clasificación-------------
    x = [];
    y = [];
    
    if find(indx == 1)
        OUTEEG_CueOn = pop_epoch( EEG,[],[0 15],'eventindices',CueOn);
        
        %Dividir los trials en ventanas mas cortas de tiempo
        OUTEEG_CueOn.data = reshape(OUTEEG_CueOn.data,...
            [size(OUTEEG_CueOn.data,1),subTrialSize,...
            size(OUTEEG_CueOn.data,2)/subTrialSize*size(OUTEEG_CueOn.data,3)]);
        
        x = double(cat(3,x,permute(OUTEEG_CueOn.data,[2,1,3])));
        y = cat(2,y,ones(1,size(OUTEEG_CueOn.data,3)));
        c = {OUTEEG_CueOn.chanlocs.labels}; 
        s = OUTEEG_CueOn.srate;
    end
    if find(indx == 2)
        OUTEEG_CueOff = pop_epoch( EEG,[],[0 15],'eventindices',CueOff);
        
        %Dividir los trials en ventanas mas cortas de tiempo
        OUTEEG_CueOff.data = reshape(OUTEEG_CueOff.data,...
            [size(OUTEEG_CueOff.data,1),subTrialSize,...
            size(OUTEEG_CueOff.data,2)/subTrialSize*size(OUTEEG_CueOff.data,3)]);
        
        x = double(cat(3,x,permute(OUTEEG_CueOff.data,[2,1,3])));
        y = cat(2,y,ones(1,size(OUTEEG_CueOff.data,3))*2);
        c = {OUTEEG_CueOff.chanlocs.labels}; 
        s = OUTEEG_CueOff.srate;
    end
    if find(indx == 3)
        OUTEEG_ShamOn = pop_epoch( EEG,[],[0 15],'eventindices',ShamOn);
        
        %Dividir los trials en ventanas mas cortas de tiempo
        OUTEEG_ShamOn.data = reshape(OUTEEG_ShamOn.data,...
            [size(OUTEEG_ShamOn.data,1),subTrialSize,...
            size(OUTEEG_ShamOn.data,2)/subTrialSize*size(OUTEEG_ShamOn.data,3)]);
        
        x = double(cat(3,x,permute(OUTEEG_ShamOn.data,[2,1,3])));
        y = cat(2,y,ones(1,size(OUTEEG_ShamOn.data,3))*3);
        c = {OUTEEG_ShamOn.chanlocs.labels}; 
        s = OUTEEG_ShamOn.srate;
    end
    if find(indx == 4)
        OUTEEG_ShamOff = pop_epoch( EEG,[],[0 15],'eventindices',ShamOff);
        
        %Dividir los trials en ventanas mas cortas de tiempo
        OUTEEG_ShamOff.data = reshape(OUTEEG_ShamOff.data,...
            [size(OUTEEG_ShamOff.data,1),subTrialSize,...
            size(OUTEEG_ShamOff.data,2)/subTrialSize*size(OUTEEG_ShamOff.data,3)]);
        
        
        x = double(cat(3,x,permute(OUTEEG_ShamOff.data,[2,1,3])));
        y = cat(2,y,ones(1,size(OUTEEG_ShamOff.data,3))*4);
        c = {OUTEEG_ShamOff.chanlocs.labels}; 
        s = OUTEEG_ShamOff.srate;
    end
    
    x = x(:,1:128,:);
    c = c(1:128);
    y = y-min(y);y = y/max(y);
    
    name = filename(1:6);
    Subjects.(name).x = x;
    Subjects.(name).y = y;
    Subjects.(name).c = c;
    Subjects.(name).s = s;
    
    
    %-----Clasificar los datos (sujeto por sujeto)--------------
    [Results, Accuracies] = classifyAll(bands,intervals,2,crossval,...
        {name},...
        Subjects.(name));
    
    save(strcat(name,'_cond_',num2str(indx)),'Results','Accuracies');
    
    clearvars -except filepath files indx

    
end
close all
