

for i = 1:length(Accuracies.subjects)
    for j = 1:length(Accuracies.subjects{i,1}.timesegs)
        m_Accuracies(i,j) = Accuracies.subjects{i,1}.timesegs{j,1}.mean;
    end
end

plot(mean(m_Accuracies,1));