%% rcsplotter for in-clinic testing


rc = rcsPlotter();

% RCS05

rc.addFolder('/Users/anashaughnessy/Desktop/Session1643179404646/DeviceNPC700491H')
%rc.addFolder('/Users/anashaughnessy/Desktop/Session1639105669168/DeviceNPC700492H')
rc.loadData()
%output = [];
%for k1 = 1:2
    %output = [output; rc.Data(k1).combinedDataTable.Adaptive_Ld0_output ];
%end

output= rc.Data.combinedDataTable.Adaptive_Ld0_output
h= histogram(output)
title('LD0 Histogram Right Side Adaptive')
xlabel('LD0')
ylabel('Count')