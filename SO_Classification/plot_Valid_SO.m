figure;

RecordingValues = DataE36;
fsample = 1000;
low_pass = 0.5;
high_pass = 4;

FilteredEEG = f_filter_deltaband(RecordingValues, 2, fsample, ...
    low_pass, high_pass);

subplot(3, 1, [1, 2])
plot((1:numel(RecordingValues)) ./fsample, ...
    RecordingValues, ...
    'Color', [0 0 0], 'LineWidth', .5);
negVal = abs(nanmin(RecordingValues));
posVal = nanmax(RecordingValues);
limVal = max([negVal, posVal]) + 0.25 * max([negVal, posVal]);
ylim([-limVal, limVal])
ylabel('Amplitude (uV)')

subplot(3, 1, 3)
plot((1:numel(FilteredEEG)) ./fsample, ...
    FilteredEEG, 'Color','k', 'LineWidth', .5);
negVal = abs(min(FilteredEEG));
posVal = max(FilteredEEG);
limVal = max([negVal, posVal]) + 0.25 * max([negVal, posVal]);
ylim([-limVal, limVal])
hold on;
for iSO = 1:size(ValidSO,2)
    pts_detected = [ValidSO(1,iSO):1:ValidSO(2,iSO)];
    line([pts_detected(1)/fsample pts_detected(end)/fsample], ...
        [0 0], ...
        'Color','green',...
        'LineWidth', 1.5) % All
end
ylabel('Amplitude (uV)')
xlabel('Time (s)')
hold off
set(gcf,'WindowState','maximized')

function FiltereData = f_filter_deltaband(v_data, s_order, fsample, ...
    low_pass, high_pass)

[d, e]          = butter(s_order, 2 * low_pass / fsample, 'low');
FiltereData     = filtfilt(d, e, v_data); %Filter Signal
[d, e]          = butter(s_order, 2 * high_pass / fsample, 'high');
FiltereData     = filtfilt(d, e, FiltereData);

end