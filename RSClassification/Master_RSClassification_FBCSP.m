% Columns in the OverallSlowOsc Matriz
% 1) = To which time bin corresponds that particular event
% 2) = startTime: SO: first up-down zero crossing
% 3) = midTime: SO: down-up zero crossing
% 4) = endTime: spindle: negative zero crossing
% 5) = duration: duration from start to end in seconds (SO: between the two down-to-up crossings)
% 6) = maxTime: time of maximum (SO: of positive half-wave/up-state) in datapoints of original dataset
% 7) = minTime: time of minimum (SO: of negative half-wave/down-state) in datapoints of original dataset
% 8) = minAmp: amplitude of maximum (SO: of positive half-wave/up-state) in �V
% 9) = maxAmp: amplitude of minimum (SO: of negative half-wave/down-state) in �V
% 10)= p2pAmp: peak-to-peak amplitude (SO: down-to-up state)
% 11)= p2pTime: time in seconds from peak-to-peak (SO: down-to-up state)
% 12)= Power
% 13)= Frequency

%% Set Parameters

dbstop if error
addpath('/home/andrea/Documents/MatlabFunctions/fieldtrip-20200828/')

ft_defaults

filesPath  = '/mnt/disk1/andrea/German_Study/Data/Clean/RestingState/';

files           = dir(strcat(filesPath,'*.mat'));

addpath(genpath('/home/andrea/Documents/Ray2015'))

files_DA_Cue = {...
    '5_n1','9_n1','12_n1','13_n1',...
    '14_n1','16_n1','17_n1','20_n1',...
    '24_n1','25_n1','26_n1','28_n1',...
    '29_n1','30_n1',...
    '39_n2','41_n2','44_n2','45_n2',...
    '46_n2','47_n2','48_n2','49_n2',...    
    '51_n2'};

files_MA_Cue = {...
    '5_n2','9_n2','12_n2','13_n2',...
    '14_n2','16_n2','17_n2','20_n2',...
    '24_n2','25_n2','26_n2','28_n2',...
    '29_n2','30_n2',...
    '39_n1','41_n1','44_n1','45_n1',...
    '46_n1','47_n1','48_n1','49_n1',...    
    '51_n1'};


%bands       = [1 4;4 8; 8 12; 12 16;16 30];
bands       =1:1:30; 
crossval    = 10;
intervals   = 0;%:1000:30000;

warning off
%% Separate events, before checking SO

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For Cue Night
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Nsubj = 0;
SUBJ = [];

%addpath('/gpfs01/born/group/Andrea/fieldtrip-20200828/')
%ft_defaults

x_RS1_All = [];
x_RS2_All = [];
x_RS3_All = [];

for file_DA = files_DA_Cue
    
    Nsubj = Nsubj+1;
    
    % LOAD DATA
    
    RS1_file = dir(strcat(filesPath,'*s',char(file_DA),'_rs1*.mat'));
    RS1_Data = load(strcat(filesPath,RS1_file.name));
    RS1_Data = RS1_Data.data;
    
    RS2_file = dir(strcat(filesPath,'*s',char(file_DA),'_rs2*.mat'));
    RS2_Data = load(strcat(filesPath,RS2_file.name));
    RS2_Data = RS2_Data.data;
    
    RS3_file = dir(strcat(filesPath,'*s',char(file_DA),'_rs3*.mat'));
    RS3_Data = load(strcat(filesPath,RS3_file.name));
    RS3_Data = RS3_Data.data;
    
    
    % EPOCH DATA
        
    cfg = [];
    cfg.length               = 3; % epochs of 3 seconds
    
    RS1_Epoched      = ft_redefinetrial(cfg, RS1_Data);
    RS2_Epoched      = ft_redefinetrial(cfg, RS2_Data);
    RS3_Epoched      = ft_redefinetrial(cfg, RS3_Data);
    
        % zscore Normalization
    RS1_Epoched = f_zscore_normalization(RS1_Epoched);
    RS2_Epoched = f_zscore_normalization(RS2_Epoched);
    RS3_Epoched = f_zscore_normalization(RS3_Epoched);
    
      
    % Organize data structure
    
    %RS1 vs RS2
    minepochs = min(length(RS1_Epoched.trial),length(RS2_Epoched.trial));
    x_RS1 = [];
    x_RS2 = [];
    for trial = 1:minepochs
        x_RS1 = cat(3,x_RS1,RS1_Epoched.trial{1,trial});
        x_RS2 = cat(3,x_RS2,RS2_Epoched.trial{1,trial});
    end
    
        
    x = cat(3,x_RS1,x_RS2);
    y = [zeros(1,minepochs),...
        ones(1,minepochs)];
    
    name = ['S',num2str(Nsubj)];
        
    SUBJ.(name).RS1vsRS2.x = permute(x,[2,1,3]); 
    SUBJ.(name).RS1vsRS2.y = y;
    SUBJ.(name).RS1vsRS2.c = RS1_Epoched.label'; 
    SUBJ.(name).RS1vsRS2.s = RS1_Epoched.fsample; 
    
    
    %RS1 vs RS3
    minepochs = min(length(RS1_Epoched.trial),length(RS3_Epoched.trial));
    x_RS1 = [];
    x_RS3 = [];
    for trial = 1:minepochs
        x_RS1 = cat(3,x_RS1,RS1_Epoched.trial{1,trial});
        x_RS3 = cat(3,x_RS3,RS3_Epoched.trial{1,trial});
    end
    
        
    x = cat(3,x_RS1,x_RS3);
    y = [zeros(1,minepochs),...
        ones(1,minepochs)];
        
    SUBJ.(name).RS1vsRS3.x = permute(x,[2,1,3]); 
    SUBJ.(name).RS1vsRS3.y = y;
    SUBJ.(name).RS1vsRS3.c = RS1_Epoched.label'; 
    SUBJ.(name).RS1vsRS3.s = RS1_Epoched.fsample; 
    
        
    %RS2 vs RS3
    minepochs = min(length(RS2_Epoched.trial),length(RS3_Epoched.trial));
    x_RS2 = [];
    x_RS3 = [];
    for trial = 1:minepochs
        x_RS2 = cat(3,x_RS2,RS2_Epoched.trial{1,trial});
        x_RS3 = cat(3,x_RS3,RS3_Epoched.trial{1,trial});
    end
    
        
    x = cat(3,x_RS2,x_RS3);
    y = [zeros(1,minepochs),...
        ones(1,minepochs)];
        
    SUBJ.(name).RS2vsRS3.x = permute(x,[2,1,3]);  
    SUBJ.(name).RS2vsRS3.y = y;
    SUBJ.(name).RS2vsRS3.c = RS2_Epoched.label'; 
    SUBJ.(name).RS2vsRS3.s = RS2_Epoched.fsample; 
    
        
    % Organize data structure All Subjects
    
    
    x_RS1_All = cat(3,x_RS1_All,x_RS1(:,:,end-50:end));
    x_RS2_All = cat(3,x_RS2_All,x_RS2(:,:,end-50:end));
    x_RS3_All = cat(3,x_RS3_All,x_RS3(:,:,end-50:end));
    
    
    % Classification
    
    [Results, Accuracies] = classifyAll(bands,intervals,2,crossval,...
        {name},...
        SUBJ.(name).RS1vsRS2);
    
    save(strcat(name,'RS1vsRS2'),'Results','Accuracies')
    
    [Results, Accuracies] = classifyAll(bands,intervals,2,crossval,...
        {name},...
        SUBJ.(name).RS1vsRS3);
    
    save(strcat(name,'RS1vsRS3'),'Results','Accuracies')
    
    [Results, Accuracies] = classifyAll(bands,intervals,2,crossval,...
        {name},...
        SUBJ.(name).RS2vsRS3);
    
    save(strcat(name,'RS2vsRS3'),'Results','Accuracies')

    clear SUBJ

end


    %RS1vsRS2
    AllSubj.RS1vsRS2.x = permute(cat(3,x_RS1_All, x_RS2_All),[2,1,3]);
    AllSubj.RS1vsRS2.y = [ones(1,size(x_RS1_All,3)),...
        zeros(1,size(x_RS2_All,3))];
    AllSubj.RS1vsRS2.c = RS1_Epoched.label'; 
    AllSubj.RS1vsRS2.s = RS1_Epoched.fsample; 
    
    
    %RS1vsRS3
    AllSubj.RS1vsRS3.x = permute(cat(3,x_RS1_All, x_RS3_All),[2,1,3]);
    AllSubj.RS1vsRS3.y = [ones(1,size(x_RS1_All,3)),...
        zeros(1,size(x_RS3_All,3))];
    AllSubj.RS1vsRS3.c = RS1_Epoched.label'; 
    AllSubj.RS1vsRS3.s = RS1_Epoched.fsample; 
    
    %RS2vsRS3
    AllSubj.RS2vsRS3.x = permute(cat(3,x_RS2_All, x_RS3_All),[2,1,3]);
    AllSubj.RS2vsRS3.y = [ones(1,size(x_RS2_All,3)),...
        zeros(1,size(x_RS3_All,3))];
    AllSubj.RS2vsRS3.c = RS2_Epoched.label'; 
    AllSubj.RS2vsRS3.s = RS2_Epoched.fsample;


    [Results, Accuracies] = classifyAll(bands,intervals,2,crossval,...
        {'All_Subj'},...
        AllSubj.RS1vsRS2);
    
    save(strcat('AllSubj_RS1vsRS2'),'Results','Accuracies')
    
    [Results, Accuracies] = classifyAll(bands,intervals,2,crossval,...
        {'All_Subj'},...
        AllSubj.RS1vsRS3);
    
    save(strcat('AllSubj_RS1vsRS3'),'Results','Accuracies')
    
    
    [Results, Accuracies] = classifyAll(bands,intervals,2,crossval,...
        {'All_Subj'},...
        AllSubj.RS2vsRS3);
    
    save(strcat('AllSubj_RS2vsRS3'),'Results','Accuracies')

%%
function New_x = f_zscore_normalization(x)
New_x = x;
for trial = 1:length(x.trial)
    mean_x= squeeze(mean(x.trial{trial},2));
    std_x = squeeze(std(x.trial{trial},[],2));
    
    mean_x = repmat(mean_x,1,size(x.trial{trial},2));
    std_x = repmat(std_x,1,size(x.trial{trial},2));
    
    
    New_x.trial{trial} = (squeeze(x.trial{trial})-mean_x)./std_x;
end
end
