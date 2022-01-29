%% rcsplotter for in-clinic testing


rc = rcsPlotter();

% RCS05

rc.addFolder('/Users/anashaughnessy/Desktop/Session1642038606117/DeviceNPC700491H')
rc.loadData()

output= rc.Data.combinedDataTable.Adaptive_CurrentAdaptiveState;
state= categorical(output);
summary(state)
%h= histogram(state)
%title('LD0 Adaptive Current State')
%xlabel('State')
%ylabel('Count')