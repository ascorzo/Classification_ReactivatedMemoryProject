addpath('/home/andrea/Documents/MatlabFunctions/MVPA-Light-master/startup/')

startup_MVPA_Light

files_DA_RS = {...
    's5_n1','s9_n1','s12_n1','s13_n1',...
    's14_n1','s16_n1','s17_n1','s20_n1',...
    's24_n1','s25_n1','s26_n1','s28_n1',...
    's29_n1','s30_n1',...
    's39_n2','s41_n2','s44_n2','s45_n2',...
    's46_n2','s47_n2','s48_n2','s49_n2',...
    's51_n2'};


files_MA_RS = {...
    's5_n2','s9_n2','s12_n2','s13_n2',...
    's14_n2','s16_n2','s17_n2','s20_n2',...
    's24_n2','s25_n2','s26_n2','s28_n2',...
    's29_n2','s30_n2',...    
    's39_n1','s41_n1','s44_n1','s45_n1',...
    's46_n1','s47_n1','s48_n1','s49_n1',...
    's51_n1'};

Nsubj = 0;
Accuracy = [];
Accuracy_LDA = [];
Accuracy_LR = [];


cond ='RS1vsRS2';

for file_DA = files_DA_RS(7:end)
    % Load data
    filename = strcat(file_DA{1,1},cond,'.mat');
    [dat, clabel] = load_example_data(filename);
    Nsubj = Nsubj +1;
    
    %% Let's have a look at the data first: Calculate and plot ERP for attended and unattended deviants
    
%     % ERP for each condition
%     CueOn_Data = squeeze(mean(dat.trial(clabel == 1,:,:)));
%     VehOn_Data = squeeze(mean(dat.trial(clabel == 2,:,:)));
%     
%     % Plot ERP: attended deviants in red, unattended deviants in green. Each
%     % line is one EEG channel.
%     close
%     h1= plot(dat.time, CueOn_Data, 'r'); hold on
%     h2 =plot(dat.time, VehOn_Data, 'b');
%     grid on
%     xlabel('Time [s]'),ylabel('EEG amplitude')
%     title('SO Data')
%     legend([h1(1),h2(1)],{'Odor', 'Vehicle'})
    
    %% Train and test classifier
    
    % Looking at the ERP the classes seem to be well-separated between in the
    % interval 0.6-0.8 seconds. We will apply a classifier to this interval. First,
    % find the sample corresponding to this interval, and then average the
    % activity across time within this interval. Then use the averaged activity
    % for classification.
    ival_idx = find(dat.time >= 0 & dat.time <= 2.5);
    
    % Extract the mean activity in the interval as features
    X = squeeze(mean(dat.trial(:,:,ival_idx),3));
    
    % Get default hyperparameters for the LDA classifier
    param = mv_get_hyperparameter('lda');
    
    % We also want to calculate class probabilities (prob variable) for each
    % sample (do not use unless explicitly required since it slows down
    % calculations a bit)
    param.prob  = 1;
    
    % Train an LDA classifier
    cf = train_lda(param, X, clabel);
    
    % Test classifier on the same data: the function gives the predicted
    % labels (predlabel), the decision values (dval) which represent the
    % distance to the hyperplane, and the class probability for the sample
    % belonging to class 1 (prob)
    [predlabel, dval, prob] = test_lda(cf, X);
    
    % To calculate classification accuracy, compare the predicted labels to
    % the true labels and take the mean
    fprintf('Classification accuracy: %2.2f\n', mean(predlabel==clabel))
    
    Accuracy(Nsubj) = mean(predlabel==clabel);
    
    %% Cross-validation
    
    % Configuration struct for cross-validation. As classifier, we
    % use LDA. The value of the regularisation parameter lambda is determined
    % automatically. As performance measure, use area under the ROC curve
    % ('auc').
    %
    % To get a realistic estimate of classification performance, we perform
    % 5-fold (cfg.k = 5) cross-validation with 10 repetitions (cfg.repeat = 10).
    
    cfg_LDA = [];
    cfg_LDA.classifier      = 'lda';
    cfg_LDA.metric          = 'accuracy';
    cfg_LDA.cv              = 'kfold';  % 'kfold' 'leaveout' 'holdout'
    cfg_LDA.k               = 5;
    cfg_LDA.repeat          = 15;
    
    % the hyperparameter substruct contains the hyperparameters for the classifier.
    % Here, we only set lambda = 'auto'. This is the default, so in general
    % setting hyperparameter is not required unless one wants to change the default
    % settings.
    cfg_LDA.hyperparameter          = [];
    cfg_LDA.hyperparameter.lambda   = 'auto';
    
    [acc_LDA, result_LDA] = mv_crossvalidate(cfg_LDA, X, clabel);
    
    % Run analysis also for Logistic Regression (LR), using the same
    % cross-validation settings.
    cfg_LR = cfg_LDA;
    cfg_LR.classifier       = 'logreg';
    
    [acc_LR, result_LR] = mv_crossvalidate(cfg_LR, X, clabel);
    
    fprintf('\nClassification accuracy (LDA): %2.2f%%\n', 100*acc_LDA)
    fprintf('Classification accuracy (Logreg): %2.2f%%\n', 100*acc_LR)
    
    % Produce plot of results
    %h = mv_plot_result({result_LDA, result_LR});
    
    Accuracy_LDA(Nsubj) = acc_LDA;
    Accuracy_LR(Nsubj) = acc_LR;
    
%     %% Comparing cross-validation to training and testing on the same data
%     cfg_LDA.metric = 'accuracy';
%     
%     % Select only the first samples
%     nReduced = 29;
%     label_reduced = clabel(1:nReduced);
%     X_reduced = X(1:nReduced,:);
%     
%     % Cross-validation (proper way)
%     cfg_LDA.cv = 'kfold';
%     acc_LDA = mv_crossvalidate(cfg_LDA, X_reduced, label_reduced);
%     
%     % No cross-validation (test on training data)
%     cfg_LDA.cv     = 'none';
%     acc_reduced = mv_crossvalidate(cfg_LDA, X_reduced, label_reduced);
%     
%     fprintf('Using %d samples with cross-validation (proper way): %2.2f%%\n', nReduced, 100*acc_LDA)
%     fprintf('Using %d samples without cross-validation (test on training data): %2.2f%%\n', nReduced, 100*acc_reduced)
%     
end

% Load data
    filename = strcat('AllSubj_',cond,'.mat');
    [dat, clabel] = load_example_data(filename);
    Nsubj = Nsubj +1;
    
    %% Let's have a look at the data first: Calculate and plot ERP for attended and unattended deviants
    
%     % ERP for each condition
%     CueOn_Data = squeeze(mean(dat.trial(clabel == 1,:,:)));
%     VehOn_Data = squeeze(mean(dat.trial(clabel == 2,:,:)));
%     
%     % Plot ERP: attended deviants in red, unattended deviants in green. Each
%     % line is one EEG channel.
%     close
%     h1= plot(dat.time, CueOn_Data, 'r'); hold on
%     h2 =plot(dat.time, VehOn_Data, 'b');
%     grid on
%     xlabel('Time [s]'),ylabel('EEG amplitude')
%     title('SO Data')
%     legend([h1(1),h2(1)],{'Odor', 'Vehicle'})
    
    %% Train and test classifier
    
    % Looking at the ERP the classes seem to be well-separated between in the
    % interval 0.6-0.8 seconds. We will apply a classifier to this interval. First,
    % find the sample corresponding to this interval, and then average the
    % activity across time within this interval. Then use the averaged activity
    % for classification.
    ival_idx = find(dat.time >= 0 & dat.time <= 2.5);
    
    % Extract the mean activity in the interval as features
    X = squeeze(mean(dat.trial(:,:,ival_idx),3));
    
    % Get default hyperparameters for the LDA classifier
    param = mv_get_hyperparameter('lda');
    
    % We also want to calculate class probabilities (prob variable) for each
    % sample (do not use unless explicitly required since it slows down
    % calculations a bit)
    param.prob  = 1;
    
    % Train an LDA classifier
    cf = train_lda(param, X, clabel);
    
    % Test classifier on the same data: the function gives the predicted
    % labels (predlabel), the decision values (dval) which represent the
    % distance to the hyperplane, and the class probability for the sample
    % belonging to class 1 (prob)
    [predlabel, dval, prob] = test_lda(cf, X);
    
    % To calculate classification accuracy, compare the predicted labels to
    % the true labels and take the mean
    fprintf('Classification accuracy: %2.2f\n', mean(predlabel==clabel))
    
    Accuracy(Nsubj) = mean(predlabel==clabel);
    
    %% Cross-validation
    
    % Configuration struct for cross-validation. As classifier, we
    % use LDA. The value of the regularisation parameter lambda is determined
    % automatically. As performance measure, use area under the ROC curve
    % ('auc').
    %
    % To get a realistic estimate of classification performance, we perform
    % 5-fold (cfg.k = 5) cross-validation with 10 repetitions (cfg.repeat = 10).
    
    cfg_LDA = [];
    cfg_LDA.classifier      = 'lda';
    cfg_LDA.metric          = 'accuracy';
    cfg_LDA.cv              = 'kfold';  % 'kfold' 'leaveout' 'holdout'
    cfg_LDA.k               = 5;
    cfg_LDA.repeat          = 15;
    
    % the hyperparameter substruct contains the hyperparameters for the classifier.
    % Here, we only set lambda = 'auto'. This is the default, so in general
    % setting hyperparameter is not required unless one wants to change the default
    % settings.
    cfg_LDA.hyperparameter          = [];
    cfg_LDA.hyperparameter.lambda   = 'auto';
    
    [acc_LDA, result_LDA] = mv_crossvalidate(cfg_LDA, X, clabel);
    
    % Run analysis also for Logistic Regression (LR), using the same
    % cross-validation settings.
    cfg_LR = cfg_LDA;
    cfg_LR.classifier       = 'logreg';
    
    [acc_LR, result_LR] = mv_crossvalidate(cfg_LR, X, clabel);
    
    fprintf('\nClassification accuracy (LDA): %2.2f%%\n', 100*acc_LDA)
    fprintf('Classification accuracy (Logreg): %2.2f%%\n', 100*acc_LR)
    
    % Produce plot of results
    %h = mv_plot_result({result_LDA, result_LR});
    
    Accuracy_LDA(Nsubj) = acc_LDA;
    Accuracy_LR(Nsubj) = acc_LR;
    
    %% Comparing cross-validation to training and testing on the same data
    cfg_LDA.metric = 'accuracy';
    
    % Select only the first samples
    nReduced = 29;
    label_reduced = clabel(1:nReduced);
    X_reduced = X(1:nReduced,:);
    
    % Cross-validation (proper way)
    cfg_LDA.cv = 'kfold';
    acc_LDA = mv_crossvalidate(cfg_LDA, X_reduced, label_reduced);
    
    % No cross-validation (test on training data)
    cfg_LDA.cv     = 'none';
    acc_reduced = mv_crossvalidate(cfg_LDA, X_reduced, label_reduced);
    
    fprintf('Using %d samples with cross-validation (proper way): %2.2f%%\n', nReduced, 100*acc_LDA)
    fprintf('Using %d samples without cross-validation (test on training data): %2.2f%%\n', nReduced, 100*acc_reduced)

    %% plots
    
    X = categorical({...
    '05','09','12','13',...
    '14','16','17 ','20',...
    '24','25','26 ','28',...
    '29','30',...
    '39','41','44','45',...
    '46','47','48','49',...
    '51','AllSubj'});

    X = reordercats(X,{...
    '05','09','12','13',...
    '14','16','17 ','20',...
    '24','25','26 ','28',...
    '29','30',...
    '39','41','44','45',...
    '46','47','48','49',...
    '51','AllSubj'});

    subplot(1,2,1)
    bar(X,Accuracy)
    title(strcat('Accuracy LDA',' Test on Training Data'))
    ylim([0 1])
    xticklabels(labelticks)
   
    
    
    subplot(1,2,2)
    bar(X,Accuracy_LDA)
    ylim([0 1])
    title(strcat('Accuracy LDA',' Including 10 CV'))
    
    set(gcf,'position',[76,220,1723,666])
  
    saveas(gcf,strcat(cond,'.png'))