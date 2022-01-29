%% rcsplotter for in-clinic testing


rc = rcsPlotter();

% RCS01

rc.addFolder('/Users/anashaughnessy/Desktop/Session1643170132041/DeviceNPC700491H')

rc.loadData()

pain_scores = readtable('/Users/anashaughnessy/Desktop/RCS05 Matlab Pain Scores3.csv');

% create figure
hfig = figure('Color','w');
hsb = gobjects();
nplots = 6; %update

for i = 1:nplots
       hsb(i,1) = subplot(nplots,1,i); 
end
rc.plotTdChannel(1,hsb(1,1)); title('TD Channel')
rc.plotTdChannelSpectral(1,hsb(2,1)); title('Spectrogram')
%rc.plotActigraphyChannel('X',hsb(3,1)); title('Accelerometry')
%rc.plotAdaptiveLd(1, hsb(4,1)); title('LD0'); ylim([0 1000])
rc.plotAdaptiveCurrent(0, hsb(3,1)); title('Current Delivered (mA)')
rc.plotAdaptiveState(hsb(4,1)); title('Adaptive State');

ax2 = subplot(2,1,2)
plot(pain_scores.rcs05_pain_vasnrs_rcs05_timestamp,pain_scores.intensity_vas_v2_v2_v2)
ylim([0 100])
linkaxes([hfig,ax2],'x')
title('VAS Pain Scores')

