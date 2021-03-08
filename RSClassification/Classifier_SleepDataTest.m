
%% Set Parameters

dbstop if error

filesPath       = '/mnt/disk1/andrea/German_Study/Data/Raw/SET/Sleep/OdorD_Night/';

files           = dir(strcat(filesPath,'.set'));

addpath(genpath('/home/andrea/Documents/Ray2015'))

files_DA_Cue = {...
    'RC_051_sleep','RC_091_sleep','RC_121_sleep','RC_131_sleep',...
    'RC_141_sleep','RC_161_sleep','RC_171_sleep','RC_201_sleep',...
    'RC_241_sleep','RC_251_sleep','RC_261_sleep','RC_281_sleep',...
    'RC_291_sleep','RC_301_sleep',...
    'RC_392_sleep','RC_412_sleep','RC_442_sleep','RC_452_sleep',...
    'RC_462_sleep','RC_472_sleep','RC_482_sleep','RC_492_sleep',...
    'RC_512_sleep'};


%bands       = [1 4;4 8; 8 12; 12 16;16 30];
bands       = 1:1:30; 
crossval    = 15;
intervals   = 0;%:1000:30000;

warning off


%% Separate events, before checking SO

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For Cue Night
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Nsubj = 0;
SUBJ = [];
estimatedLblsOdor = {};
estimatedLblsVehicle = {};

ResultsRS_path = '/mnt/disk1/andrea/German_Study/Classification/RSClassification/OdorDNight/';

for file_DA = files_DA_Cue
    
    disp(strcat('Sujeto: ',file_DA))

    Nsubj = Nsubj+1;
    
    RS_Results = load(strcat(ResultsRS_path,'S',num2str(Nsubj),'RS2vsRS3'));
    
    addpath(genpath('/home/andrea/Documents/MatlabFunctions/eeglab2019_1/'))
    %addpath('/gpfs01/born/group/Andrea/eeglab2019_1/plugins/mffmatlabio-master/')
    
    dataType    = '.set';
    [EEGRaw] = f_load_data(...
        strcat(char(file_DA),'_Import',dataType), filesPath, dataType);
    

    % Remove external channels
    chan_Mastoids       = {'E57', 'E100'};
    chan_EOG            = {'E8', 'E14', 'E21', 'E25', 'E126', 'E127'};
    chan_EMG            = {'E43', 'E120'};
    chan_VREF           = {'E129'};
    chan_Face           = {'E49', 'E48', 'E17', 'E128', 'E32', 'E1', ...
        'E125', 'E119', 'E113'};
        

%     chans2Rej   = [chan_Mastoids, chan_EOG, chan_EMG, chan_Face, chan_VREF];
    chans2Rej   = [chan_VREF];
    
    [~, idx_chan2rej] = intersect({EEGRaw.chanlocs.labels},chans2Rej);
    
    [EEGRaw] = ...
        pop_select( EEGRaw, 'nochannel', idx_chan2rej);
    
    All_DIN1  = find(strcmp({EEGRaw.event.label}, 'DIN1')); 
    All_DIN2  = find(strcmp({EEGRaw.event.label}, 'DIN2'));

    cidx_all                                = {EEGRaw.event.mffkey_cidx};
    cidx_all(cellfun('isempty',cidx_all))   = [];
    cidx_all                                = cellfun(@str2double,cidx_all);
    cidx_unique                             = sort(unique(cidx_all));
    
    for cidx = numel(cidx_unique):-1:1
        
        idx = find(strcmp({EEGRaw.event.mffkey_cidx}, num2str(cidx_unique(cidx)))); % where in the event structure are we
        
        % For each event, check whether it occurs exactly twice (start/end)
        if sum(cidx_all == cidx_unique(cidx)) ~= 2
            cidx_unique(cidx) = [];
            warning('Deleting a stimulation because it doesnt have a start and end.')
            
            % ...whether first is a start and second an end trigger
        elseif ~strcmp(EEGRaw.event(idx(1)).label, 'DIN1') || ~strcmp(EEGRaw.event(idx(2)).label, 'DIN2')
            cidx_unique(cidx) = [];
            warning('Deleting a stimulation because it doesnt have the right start and end.')
            
            % ...whether it is about 15 s long
        elseif EEGRaw.event(idx(2)).latency - EEGRaw.event(idx(1)).latency < 15 * EEGRaw.srate || EEGRaw.event(idx(2)).latency - EEGRaw.event(idx(1)).latency > 15.1 * EEGRaw.srate
            cidx_unique(cidx) = [];
            warning('Deleting a stimulation because its too short or too long.')   
        end
    end
    
    
    % Now all EEG.event are valid, all odd ones are odor, all even ones are vehicle
    cidx_odor           = cidx_unique(mod(cidx_unique,2) ~= 0);
    cidx_vehicle        = cidx_unique(mod(cidx_unique,2) == 0);
    
    [~,Cue_Epochs] = intersect(str2double({EEGRaw.event.mffkey_cidx}), cidx_odor);
    [~,Sham_Epochs] = intersect(str2double({EEGRaw.event.mffkey_cidx}), cidx_vehicle);
    
    [CueOn] = intersect(All_DIN1,Cue_Epochs);
    [ShamOn] = intersect(All_DIN1,Sham_Epochs);
    
    %% Epoch Data and catenate trials
    
    x_Odor = [];
    x_Vehicle = [];
 
    TimePoint = 0;
    
    for v_time = -15:3:15
         
        TimePoint = TimePoint+1;
        EEGOdor     = pop_epoch(EEGRaw,[],[v_time-3 v_time+3],'eventindices',CueOn);
        EEGVehicle  = pop_epoch(EEGRaw,[],[v_time-3 v_time+3],'eventindices',ShamOn);
 
        
        % zscore Normalization
        EEGOdor = f_zscore_normalization(EEGOdor); % z score normalization
        EEGVehicle = f_zscore_normalization(EEGVehicle); % z score normalization
        
        x_Odor = double(permute(EEGOdor.data,[2,1,3]));
        x_Vehicle = double(permute(EEGVehicle.data,[2,1,3]));
        
        % For Odor
        DataOdor.x = x_Odor;
        DataOdor.c = {EEGOdor.chanlocs.labels};
        DataOdor.s = EEGOdor.srate;
        
        % For Vehicle
        DataVehicle.x = x_Vehicle;
        DataVehicle.c = {EEGVehicle.chanlocs.labels};
        DataVehicle.s = EEGVehicle.srate;
        
    
        filtData = justFilter(DataOdor,bands);
        nBands = size(filtData,2);
        [~, bestcv] = max(RS_Results.Accuracies.subjects{1, 1}.cv);
        estimatedLblsOdor{Nsubj,TimePoint} = ...
            {double(classifyTest(filtData,RS_Results.Results{1,1}{1,bestcv},nBands))};
       
        
        filtData = justFilter(DataVehicle,bands);
        nBands = size(filtData,2);
        estimatedLblsVehicle{Nsubj,TimePoint} = ...
            {double(classifyTest(filtData,RS_Results.Results{1,1}{1,bestcv},nBands))};
          
    end
    
end



%% plots

predOdor = [];
predVehicle = [];

predOdor_Norm = [];
predVehicle_Norm = [];

for subj = 1:size(estimatedLblsVehicle,1)
    for timepoint = 1:size(estimatedLblsVehicle,2)
        predOdor(subj,timepoint) = mean(estimatedLblsOdor{subj,timepoint}{1,1});
        predVehicle(subj,timepoint) = mean(estimatedLblsVehicle{subj,timepoint}{1,1});
    end
    
    meanOdor = mean(predOdor(subj,:));
    stdOdor = std(predOdor(subj,:));
    predOdor_Norm(subj,:) = (predOdor(subj,:)-meanOdor)/stdOdor;
    
    
    meanVehicle = mean(predVehicle(subj,:));
    stdVehicle = std(predVehicle(subj,:));
    predVehicle_Norm(subj,:) = (predVehicle(subj,:)-meanVehicle)/stdVehicle;
end

save('Predictions','predOdor','predVehicle')
v_time = -15:3:15;
subplot(2,1,1)
plot(v_time,nanmean(predOdor_Norm,1))

subplot(2,1,2)
plot(v_time,nanmean(predVehicle_Norm,1))

%%
function New_x = f_zscore_normalization(x)
New_x = x;
for trial = 1:size(x.data,3)
    mean_x= squeeze(mean(x.data(:,:,trial),2));
    std_x = squeeze(std(double(x.data(:,:,trial)),[],2));
    
    mean_x = repmat(mean_x,1,size(x.data,2),1);
    std_x = repmat(std_x,1,size(x.data,2),1);
    
    
    New_x.trial(:,:,trial) = (squeeze(x.data(:,:,trial))-mean_x)./std_x;
end
end


