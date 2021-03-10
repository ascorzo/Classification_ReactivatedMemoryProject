addpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1/'));
addpath(genpath('/home/andrea/Documents/Ray2015/'));
%eeglab

filepath = '/mnt/disk1/sleep/Datasets/Ori/EEGLABFilt_Mastoids_Off_On_200Hz_Oct/';
filesOdor = dir(strcat(filepath,'*Odor.mat'));
filesVehicle = dir(strcat(filepath,'*Sham.mat'));

savepath = '/mnt/disk1/andrea/German_Study/Classification/TrialClassification/FBCSP/';

warning off

conditions = {'Odor Switched ON';...
    'Vehicle Switched ON';...
    'Odor Switched OFF';...
    'Vehicle Switched OFF'};

addpath('/mnt/disk1/andrea/German_Study/')
run p_clustersOfInterest.m

% [indx,tf] = listdlg('PromptString',{'Which conditions do you want to compare?'...
%     'Please select only two',''},...
%     'SelectionMode','multiple','ListString',conditions);

indx = [1,2];

if sum(indx ~= 0)>2
    return
end
%dbstop if error
cluster = Clust.parietal;

for i = 1:numel(filesOdor)
    
    bands       = (1:1:30);
    crossval    = 15;
    intervals   = 0;%:1000:30000;
    filenameOdor = filesOdor(i).name;
    filenameVehicle = filesVehicle(i).name;
    
    EEG = load(strcat(filepath,filenameOdor));
    run p_normalization.m
    EEGOdor = EEG;
    % [channels, chanIdx] = intersect({EEGOdor.hdr.orig.chanlocs.labels},cluster);
    [channels, chanIdx] = intersect({EEGOdor.hdr.orig.chanlocs.labels},...
    {EEGOdor.hdr.orig.chanlocs.labels});

    EEG = load(strcat(filepath,filenameVehicle));
    run p_normalization.m
    EEGVehicle = EEG;    
    %-----Organizar los datos para la clasificación-------------
    x = [];
    y = [];
    
    if find(indx == 1)
        OUTEEG_CueOn = EEGOdor.data(chanIdx,5001:6000,:);

        x = double(cat(3,x,permute(OUTEEG_CueOn,[2,1,3])));
        y = cat(2,y,ones(1,size(OUTEEG_CueOn,3)));
        c = channels; 
        s = EEGOdor.hdr.orig.srate;
    end
    if find(indx == 2)
        OUTEEG_VehOn = EEGVehicle.data(chanIdx,5001:6000,:);
        
        x = double(cat(3,x,permute(OUTEEG_VehOn,[2,1,3])));
        y = cat(2,y,ones(1,size(OUTEEG_VehOn,3))*2);
        c = channels; 
        s = EEGVehicle.hdr.orig.srate;
    end
    if find(indx == 3)
        OUTEEG_CueOff = EEGVehicle.data(chanIdx,1:3000,:);
        
        x = double(cat(3,x,permute(OUTEEG_CueOff,[2,1,3])));
        y = cat(2,y,ones(1,size(OUTEEG_CueOff,3))*3);
        c = channels; 
        s = EEGVehicle.hdr.orig.srate;
    end
    if find(indx == 4)
        OUTEEG_VehOff = EEGOdor.data(chanIdx,1:3000,:);
        
        x = double(cat(3,x,permute(OUTEEG_VehOff,[2,1,3])));
        y = cat(2,y,ones(1,size(OUTEEG_VehOff,3))*4);
        c = channels; 
        s = EEGOdor.hdr.orig.srate;
    end
    
    % x = x(:,1:128,:);
    % c = c(1:128);
    y = y-min(y);y = y/max(y);
    
    name = filenameOdor(1:6);
    Subjects.(name).x = x;
    Subjects.(name).y = y;
    Subjects.(name).c = c;
    Subjects.(name).s = s;
    
    
    %-----Clasificar los datos (sujeto por sujeto)--------------
    [Results, Accuracies] = classifyAll(bands,intervals,2,crossval,...
        {name},...
        Subjects.(name));
    
    save(char(strcat(savepath,name,'_',conditions(indx(1)),'_vs_',conditions(indx(2)),'Allchans_10sec')),'Results','Accuracies');
    
    clear Subjects
 
end
close all