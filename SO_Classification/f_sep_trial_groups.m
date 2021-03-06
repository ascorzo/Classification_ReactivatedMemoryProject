function [EEG_Odor, EEG_Sham, set_sequence] = f_sep_trial_groups(...
    EEG, set_sequence, noiseTrialFile, def_variable)

% recordings --> trigger1 on, trigger1 off, trigger2 on, trigger2 off, ...     
% set_sequence    = cell string of sequence of odor stimulation and
%                   olfactometer control
% {'switchedON_switchedOFF', 'switchedOFF_switchedON'}
% "on_off" = [ongoing stimulation type 1, post-stimulation type 1] and
% "off_on" = [pre-stimulation type 1, ongoing stimulation type 1], where
% "pre-stimulation type 1" is actually post-stimulation type 2!
% On and Off therefore refers to the current state of the stimulation
% ("switched on" or "switched off").

% noiseTrialFile    = string of path to the .mat file that contains
% information about trials/epochs to be rejected. The file should be
% organized in 3 columns:
% Col 1 = cell strings of subjects where the string is equal to "str_base"
% Col 2 = array of independent components to reject. Not needed for this
%         function
% Col 3 = array of epochs to reject
% The matrix should be contained in a variable whose name is defined by
% "def_variable"
% Leave both EMPTY if you don't want to reject epochs based on this method

global str_base

% At this stage, the rejecteddata field (containing time series of rejected
% channels) is probably not of any need ny more and increases the file size
% unnecessarily.
%EEG = rmfield(EEG, 'rejecteddata');


[EEG] = pop_epoch( EEG, ...
    { }, ...
    [-15 15], ...
    'newname', 'temp_set', ...
    'epochinfo', 'yes');

%% Retain only trials with selected midtrial trigger type
if strcmp(set_sequence, 'switchedON_switchedOFF')
    triggerOI   = 'DIN2';
    trialEdges  = 'DIN1';
elseif strcmp(set_sequence, 'switchedOFF_switchedON')
    triggerOI   = 'DIN1';
    trialEdges  = 'DIN2';
end

% This here is needed because EEG.epoch structure holds either cells or
% chars for EEG.epoch.eventlabel (and others) based on whether at least one
% trial contains overlapping triggers or not
for i_trans = 1 : numel(EEG.epoch)
    if numel(EEG.epoch(i_trans).event) == 1
        EEG.epoch(i_trans).eventlabel = char(EEG.epoch(i_trans).eventlabel);
        EEG.epoch(i_trans).eventtype = char(EEG.epoch(i_trans).eventtype);
%         eventduration
%         eventrelativebegintime
%         eventsourcedevice
%         eventlatency
    end
end

% -------------------------------------------------------------------------
% Identify trials that only contain one trigger (that is they are not
% overlapping with other trials) and only the trigger of interest
% (triggerOI) as midpoint of epoch
idx_triggerOI           = find(strcmp({EEG.epoch.eventlabel}, triggerOI));
idx_unique_triggers     = [];
for i = 1:size(EEG.epoch,2)
    if numel(EEG.epoch(i).event) == 1
        idx_unique_triggers = [idx_unique_triggers i];
    end
end

idx_trialsOI = intersect(idx_triggerOI, idx_unique_triggers);

% -------------------------------------------------------------------------
% Slice the dataset again in only epochs of interest
% [EEG] = pop_epoch( EEG, ...
%     { EEG.epoch(idx_trialsOI).eventtype }, ...
%     [-15 20], ...
%     'newname', 'temp_set', ...
%     'epochinfo', 'yes');

[EEG] = pop_select(EEG,'trial',idx_trialsOI);


%% Reject trials that have been labeled for rejection in a separate file

if ~isempty(noiseTrialFile) && ~isempty(def_variable)
    % ---------------------------------------------------------------------
    % Extract the vectors of the noisy periods that are given by the
    % sideloaded file
    noisyTrials = load(noiseTrialFile);
    
    subj_row = find(strcmp(noisyTrials.(def_variable)(:,1), ...
        str_base));
    
    rej_trials = noisyTrials.(def_variable){subj_row,3};
    
    % ---------------------------------------------------------------------
    % Simply reject the epochs
    if ~isempty(rej_trials)
        [EEG, EEG.lst_changes{end+1,1}] = ...
            pop_rejepoch( EEG, rej_trials ,0);
    end

end


%% Determine groups of trials and separate them
get_cidx= {EEG.event.mffkey_cidx};

% Based on odds vs even @Jens' mail, INDEPENDANTLY OF ON OR OFF
idx_trigger_sham        = find( mod(str2double(get_cidx), 2) == 0);
idx_trigger_odor        = find( mod(str2double(get_cidx), 2) ~= 0);

% Here we reject the last trial if it is not complete (which means,
% recording stopped before trial fully finished). The partial trial will
% be removed from EEG.data and EEG.epoch but will still be shown in 
% EEG.event, which is what we use to identify trials.
if size(EEG.data, 3) ~= length(EEG.epoch)
    error('Incompatible epoch handling')
end
s_rej = 0;
if idx_trigger_sham(end) > size(EEG.data, 3)
    idx_trigger_sham = idx_trigger_sham(1:end-1);
    s_rej = s_rej + 1;
end
if idx_trigger_odor(end) > size(EEG.data, 3)
    idx_trigger_odor = idx_trigger_odor(1:end-1);
    s_rej = s_rej + 1;
end
if s_rej > 1
    error('More than one incomplete trials. This does not make sense')
end
    
% -------------------------------------------------------------------------
% Isolating trial of interest into separate structures

EEG_Sham    = EEG;
EEG_Odor    = EEG;

[EEG_Sham]    = ...
    pop_select( EEG_Sham, 'trial', idx_trigger_sham );
[EEG_Odor]     = ...
    pop_select( EEG_Odor, 'trial', idx_trigger_odor );


end

