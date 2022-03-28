%% rcsplotter for in-clinic testing


rc = rcsPlotter();

% RCS01


rc.addFolder('/Users/anashaughnessy/Desktop/RCS05R (8)/Session1647495798147/DeviceNPC700491H')

rc.loadData()

% create figure
hfig = figure('Color','w');
hsb = gobjects();
nplots = 4; %update
for i = 1:nplots
       hsb(i,1) = subplot(nplots,1,i); 
end
rc.plotTdChannel(1,hsb(1,1)); title('TD Channel')
rc.plotTdChannelSpectral(1,hsb(2,1)); title('Spectrogram')
rc.plotActigraphyChannel('X',hsb(3,1)); title('Accelerometry')
rc.plotAdaptiveLd(1, hsb(4,1)); title('LD0'); ylim([0 1000])
rc.plotAdaptiveCurrent(0, hsb(4,1)); title('Current Delivered (mA)')
rc.plotAdaptiveState(hsb(5,1)); title('Adaptive State');

%%
figure
plot(AdaptiveData.Ld0_output); hold on;
plot(mean(AdaptiveData.Ld0_output)); hold on;
plot(AdaptiveData.Ld0_highThreshold, 'LineWidth', 2);
plot(AdaptiveData.Ld0_lowThreshold, 'LineWidth', 2);
title('LD0')
ylim([0 50])

% link axes since time domain and acc have differnt
% sample rates: 
%linkaxes(hsb,'x');

rc.reportPowerBands %prints