path = '/mnt/disk1/andrea/German_Study/Classification/RSClassification/';

files = dir(strcat(path,'*RS1vsRS2.mat'));

All_Accuracies_RS1vsRS2 = [];
for subj = 1:numel(files)
    load(strcat(path,files(subj).name))  
    All_Accuracies_RS1vsRS2(subj,:) = Accuracies.subjects{1,1}.cv;
end


files = dir(strcat(path,'*RS1vsRS3.mat'));

All_Accuracies_RS1vsRS3 = [];
for subj = 1:numel(files)
    load(strcat(path,files(subj).name))  
    All_Accuracies_RS1vsRS3(subj,:) = Accuracies.subjects{1,1}.cv;
end

files = dir(strcat(path,'*RS2vsRS3.mat'));

All_Accuracies_RS2vsRS3 = [];
for subj = 1:numel(files)
    load(strcat(path,files(subj).name))  
    All_Accuracies_RS2vsRS3(subj,:) = Accuracies.subjects{1,1}.cv;
end

%% Combine all results

path = 'Y:\Andrea\ReactivatedConnectivity\SOClassification\MotorNight\Interval2Sec\';

files = dir(strcat(path,'*CueOnvsVehOn.mat'));

All_Accuracies_CueOnvsVehOn = [];
for subj = 1:numel(files)
    load(strcat(path,files(subj).name))  
    All_Results{subj} = Results{1,1};
    All_Accuracies_CueOnvsVehOn(subj) = Accuracies.subjects{1,1}.mean;
    All_Accuracies.subjects{subj} = Accuracies.subjects{1,1};
end
All_Accuracies.mean = mean(All_Accuracies_CueOnvsVehOn);

%% Measures of sensitivity and specificity 
All_Sensitivity = [];
All_Specificity = [];

for subj = 1:numel(All_Results)
    for run = 1:numel(All_Results{1,subj})
        RealLabels = All_Results{1,subj}{1,run}.classlabels;
        EstimatedLabels = All_Results{1,subj}{1,run}.estimatedLbls';
        
        GoodPredictions = RealLabels == EstimatedLabels;
        
        % positives are zeros (Odor), Negatives are ones (Vehicle)
        sensitivity = sum(EstimatedLabels(GoodPredictions)==0)/...
            (sum(EstimatedLabels == 0));
        
        specificity = sum(EstimatedLabels(GoodPredictions)==1)/...
            (sum(EstimatedLabels == 1));
        
        All_Sensitivity(subj,run) = sensitivity;
        All_Specificity(subj,run) = specificity;
        
        All_OdorEventsRatio(subj,run) = sum(RealLabels==0)/numel(RealLabels);
        
    end
end