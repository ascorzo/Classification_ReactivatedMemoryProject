
addpath(genpath('/home/andrea/Documents/Ray2015/'));
addpath('/home/andrea/Documents/MatlabFunctions/');


files = dir('*RC*.mat');


for i = 1:numel(files)
    
    load(files(i).name)
    
    timesegs = Accuracies.subjects{1,1}.timesegs;
    for j = 1:numel(timesegs)
        AccInt(i,j) = timesegs{j,1}.mean;
    end
    figure
    plot(AccInt(i,:))
    
end
figure
stdshade(AccInt)