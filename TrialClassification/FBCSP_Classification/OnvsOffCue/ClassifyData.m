addpath(genpath('/home/andrea/Documents/Ray2015/'));

RC_051 = load('RC_051_CueOn_vs_CueOff.mat');
RC_091 = load('RC_091_CueOn_vs_CueOff.mat');
RC_121 = load('RC_121_CueOn_vs_CueOff.mat');
RC_131 = load('RC_131_CueOn_vs_CueOff.mat');
RC_141 = load('RC_141_CueOn_vs_CueOff.mat');
RC_161 = load('RC_161_CueOn_vs_CueOff.mat');
RC_171 = load('RC_171_CueOn_vs_CueOff.mat');
RC_201 = load('RC_201_CueOn_vs_CueOff.mat');
RC_241 = load('RC_241_CueOn_vs_CueOff.mat');
RC_251 = load('RC_251_CueOn_vs_CueOff.mat');
RC_261 = load('RC_261_CueOn_vs_CueOff.mat');
RC_281 = load('RC_281_CueOn_vs_CueOff.mat');
RC_291 = load('RC_291_CueOn_vs_CueOff.mat');
RC_301 = load('RC_301_CueOn_vs_CueOff.mat');

RC_392 = load('RC_392_CueOn_vs_CueOff.mat');
RC_412 = load('RC_412_CueOn_vs_CueOff.mat');
RC_442 = load('RC_442_CueOn_vs_CueOff.mat');
RC_452 = load('RC_452_CueOn_vs_CueOff.mat');
RC_462 = load('RC_462_CueOn_vs_CueOff.mat');
RC_472 = load('RC_472_CueOn_vs_CueOff.mat');
RC_482 = load('RC_482_CueOn_vs_CueOff.mat');
RC_492 = load('RC_492_CueOn_vs_CueOff.mat');
RC_512 = load('RC_512_CueOn_vs_CueOff.mat');


%%
bands       = (1:6:30);
crossval    = 10;
[Results, Accuracies] = classifyAll(bands,0,2,crossval,...
    {'RC_051','RC_091','RC_121','RC_131','RC_141','RC_161','RC_171',...
    'RC_201','RC_241','RC_251','RC_261','RC_281','RC_291','RC_301',...
    'RC_392','RC_412','RC_442','RC_452','RC_462','RC_472','RC_482',...
    'RC_492','RC_512'},...
    RC_051,RC_091,RC_121,RC_131,RC_141,RC_161,RC_171,...
    RC_201,RC_241,RC_251,RC_261,RC_281,RC_291,RC_301,...
    RC_392,RC_412,RC_442,RC_452,RC_462,RC_472,RC_482,...
    RC_492,RC_512);


% [Results, Accuracies] = classifyAll(bands,0,2,crossval,...
%     {'RC_051','RC_091'},...
%     RC_051,RC_091);
% 
% [Results, Accuracies] = classifyAll(bands,0,2,crossval,...
%     {'RC_051','RC_091','RC_121','RC_131','RC_141'},...
%     RC_051,RC_091,RC_121,RC_131,RC_141);

% [Results, Accuracies] = classifyAll(bands,0,2,crossval,...
%     {'RC_051','RC_091','RC_121','RC_131','RC_141','RC_161','RC_171',...
%     'RC_201','RC_241','RC_251','RC_261','RC_281','RC_291','RC_301'},...
%     RC_051,RC_091,RC_121,RC_131,RC_141,RC_161,RC_171,...
%     RC_201,RC_241,RC_251,RC_261,RC_281,RC_291,RC_301);
