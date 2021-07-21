addpath('/home/andrea/Documents/MatlabFunctions/MVPA-Light-master/startup/')

startup_MVPA_Light

files_DA_Cue = {...
    'RC_051_sleep','RC_091_sleep','RC_121_sleep','RC_131_sleep',...
    'RC_141_sleep','RC_161_sleep','RC_171_sleep','RC_201_sleep',...
    'RC_241_sleep','RC_251_sleep','RC_261_sleep','RC_281_sleep',...
    'RC_291_sleep','RC_301_sleep',...
    'RC_392_sleep','RC_412_sleep','RC_442_sleep','RC_452_sleep',...
    'RC_462_sleep','RC_472_sleep','RC_482_sleep','RC_492_sleep',...
    'RC_512_sleep'};


files_MA_Cue = {...
    'RC_052_sleep','RC_092_sleep','RC_122_sleep','RC_132_sleep',...
    'RC_142_sleep','RC_162_sleep','RC_172_sleep','RC_202_sleep',...
    'RC_242_sleep','RC_252_sleep','RC_262_sleep','RC_282_sleep',...
    'RC_292_sleep','RC_302_sleep',...    
    'RC_391_sleep','RC_411_sleep','RC_441_sleep','RC_451_sleep',...
    'RC_461_sleep','RC_471_sleep','RC_481_sleep','RC_491_sleep',...
    'RC_511_sleep'};

Nsubj = 0;
Accuracy = [];
Accuracy_LDA = [];
Accuracy_LR = [];
Nsubj = 0;

cond ='OdorDVsVehicle';

for file_DA = files_DA_Cue
    % Load data
    filename = strcat(file_DA{1,1},cond,'.mat');
    [dat, clabel] = load_example_data(filename);
    Nsubj = Nsubj +1;
    
    %% Train and test classifier
    
    % Average interval of interest
    ival_idx = find(dat.time >= 11 & dat.time <= 15);
    
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
    
end

% Load data
    filename = strcat('AllSubj_',cond,'.mat');
    [dat, clabel] = load_example_data(filename);
    Nsubj = Nsubj +1;
    
    
    %% Train and test classifier
    
    % Looking at the ERP the classes seem to be well-separated between in the
    % interval 0.6-0.8 seconds. We will apply a classifier to this interval. First,
    % find the sample corresponding to this interval, and then average the
    % activity across time within this interval. Then use the averaged activity
    % for classification.
    ival_idx = find(dat.time >= 11 & dat.time <= 15);
    
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
   
    
    
    subplot(1,2,2)
    bar(X,Accuracy_LDA)
    ylim([0 1])
    title(strcat('Accuracy LDA',' Including 10 CV'))
    
    set(gcf,'position',[76,220,1723,666])
  
    saveas(gcf,strcat(cond,'.png'))