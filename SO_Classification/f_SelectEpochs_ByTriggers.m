   
function [EEGCue,EEGVehicle] = f_SelectEpochs_ByTriggers(EEG)

All_DIN1  = find(strcmp({EEG.event.label}, 'DIN1'));
All_DIN2  = find(strcmp({EEG.event.label}, 'DIN2'));

cidx_all                                = {EEG.event.mffkey_cidx};
cidx_all(cellfun('isempty',cidx_all))   = [];
cidx_all                                = cellfun(@str2double,cidx_all);
cidx_unique                             = sort(unique(cidx_all));

for cidx = numel(cidx_unique):-1:1
    
    idx = find(strcmp({EEG.event.mffkey_cidx}, num2str(cidx_unique(cidx)))); % where in the event structure are we
    
%     For each event, check whether it occurs exactly twice (start/end)
    if sum(cidx_all == cidx_unique(cidx)) ~= 2
        cidx_unique(cidx) = [];
        warning('Deleting a stimulation because it doesnt have a start and end.')
        
        ...whether first is a start and second an end trigger
        elseif ~strcmp(EEG.event(idx(1)).label, 'DIN1') || ~strcmp(EEG.event(idx(2)).label, 'DIN2')
        cidx_unique(cidx) = [];
        warning('Deleting a stimulation because it doesnt have the right start and end.')
        
        ...whether it is about 15 s long
    elseif EEG.event(idx(2)).latency - EEG.event(idx(1)).latency < 15 * EEG.srate || EEG.event(idx(2)).latency - EEG.event(idx(1)).latency > 15.1 * EEG.srate
        cidx_unique(cidx) = [];
        warning('Deleting a stimulation because its too short or too long.')
    end
end


% Now all EEG.event are valid, all odd ones are cue, all even ones are vehicle
cidx_cue           = cidx_unique(mod(cidx_unique,2) ~= 0);
cidx_vehicle        = cidx_unique(mod(cidx_unique,2) == 0);



[~,Cue_Epochs] = intersect(str2double({EEG.event.mffkey_cidx}), cidx_cue);
[~,Vehicle_Epochs] = intersect(str2double({EEG.event.mffkey_cidx}), cidx_vehicle);

[CueOn] = intersect(All_DIN1,Cue_Epochs);
[VehicleOn] = intersect(All_DIN1,Vehicle_Epochs);

EEGCue     = pop_epoch(EEG,[],[-15 30],'eventindices',CueOn);
EEGVehicle  = pop_epoch(EEG,[],[-15 30],'eventindices',VehicleOn);

end