%Plot Accuracies

path = 'Y:\Andrea\ReactivatedConnectivity\SOClassification\';

files = dir(strcat(path,'*CueOnvsVehOn.mat'));

All_Accuracies_CueOnvsVehOn = [];
for subj = 1:numel(files)
    load(strcat(path,files(subj).name))  
    All_Accuracies_CueOnvsVehOn(subj,:) = Accuracies.subjects{1,1}.cv;
end

files = dir(strcat(path,'*CueOnvsCueOff.mat'));

All_Accuracies_CueOnvsCueOff = [];
for subj = 1:numel(files)
    load(strcat(path,files(subj).name))  
    All_Accuracies_CueOnvsCueOff(subj,:) = Accuracies.subjects{1,1}.cv;
end

files = dir(strcat(path,'*VehOnvsVehOff.mat'));

All_Accuracies_VehOnvsVehOff = [];
for subj = 1:numel(files)
    load(strcat(path,files(subj).name))  
    All_Accuracies_VehOnvsVehOff(subj,:) = Accuracies.subjects{1,1}.cv;
end

%%
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

%%
load('Y:\Andrea\ReactivatedConnectivity\SOClassification\EMapAll')
load('Y:\Andrea\ReactivatedConnectivity\Time-Frequency_FT\clusterChans.mat')
[~,ind] = intersect(EMapAll(1,:),frontal_channels);

X=cell2mat(EMapAll(2,:));
Y=cell2mat(EMapAll(3,:));

X=X/max(abs(X));
Y=Y/max(abs(Y));

XNew = -Y;
YNew = X;

Xfrontal = XNew(ind);
Yfrontal = YNew(ind);

EMapAll(2,:) = num2cell(XNew);
EMapAll(3,:) = num2cell(YNew);

%%

for subj = 1:numel(All_Results)
    subs = subj;
    runs = find(All_Accuracies.subjects{1,subj}.cv > 75);
    sel_chan_depression = EMapAll(1,:,:);
    csptitle = {'Odor D','Vehicle'};
    if ~isempty(runs)
        plotCSPcv(All_Results,All_Accuracies,EMapAll,sel_chan_depression,subs,runs,csptitle);
    end
    %suptitle(strcat('Subj ',num2str(subj)))
end

 %getBandsAll(res,subs);
%%


[~,ind] = intersect(EMapAll(1,:),frontal_channels);

X=cell2mat(EMapAll(2,:));
Y=cell2mat(EMapAll(3,:));

X=X/max(abs(X));
Y=Y/max(abs(Y));

XNew = -Y;
YNew = X;

Xfrontal = XNew(ind);
Yfrontal = YNew(ind);

EMapAll(2,:) = num2cell(XNew);
EMapAll(3,:) = num2cell(YNew);

Wmat = All_Results{1,1}{1,1}.CSP.avgW;
plotCSPW(EMapAll,sel_chan_depression,Wmat,csptitle,Xfrontal,Yfrontal);

%%

figHandles = findall(0,'Type','figure'); 

 % Create filename 
 fn = strcat('C:\Users\lanan\Desktop\',num2str(1));  %in this example, we'll save to a temp directory.
 
 % Save first figure
 export_fig(fn, '-png', figHandles(1))
 
 % Loop through figures 2:end
 for i = 1:numel(figHandles)
     fn = strcat('C:\Users\lanan\Desktop\',num2str(i));
     export_fig(fn, '-png', figHandles(i), '-append')
 end
