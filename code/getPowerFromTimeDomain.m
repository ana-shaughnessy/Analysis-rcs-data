function  [powerFromTimeDomain] = getPowerFromTimeDomain(combinedDataTable,settings)
% creates a table with power computed signals from time domain signal using
% an equivalent process to the internal power computation in the device
% power is computed using
% - hann windowing of latest fft interval (new and old points, depending on overlapping)
% - fft is applied
% - power calculated as sum of power of all bins in the frequency band
% 
% Input = 
% (1) combinedDataTable
% (2) settings: cell with following structures {fftSettings, powerSettings, metaData}
%       1 = fftSettings (type = output from DEMO_Process)
%       2 = powerSettings (type = output from DEMO_Process)
%       3 = metaData (type = output from DEMO_Process)
%
% output
%     powerFromTimeDomain = table(harmoinized times, derived times, PB1,PB2,PB3,...,PB8)
%
% Assumptions:
% - hann window 100%
% - no change in fft and power settings in data set
%

% Parse input variables
fftSettings = settings{1}; % fftSettings
powerSettings = settings{2}; % powerSettings
metaData = settings{3}; % metaData
ampGains = metaData.ampGains; % actual amplifier gains per channel

% initialize output power 
powerFromTimeDomain = table();
powerFromTimeDomain.localTime= combinedDataTable.localTime;
powerFromTimeDomain.DerivedTimes = combinedDataTable.DerivedTime;
for inumBands = 1:8 % initialize bands
    powerFromTimeDomain.(['PowerCh',num2str(inumBands)]) = nan(1,size(combinedDataTable,1))';
end

% loop for each time domain channel
for c=1:4
    % extract input parameters
    tch = combinedDataTable.DerivedTime;
    t = seconds(tch-tch(1))/1000;
    [interval,binStart,binEnd,fftSize] = readFFTsettings(powerSettings,c);
    sr = fftSettings.TDsampleRates;
    switch fftSize % actual fft size of device for 64, 250, 1024 fftpoints
        case 64, fftSizeActual = 62;
        case 256, fftSizeActual = 250;
        case 1024, fftSizeActual = 1000;
    end
    keych = combinedDataTable.(['TD_key',num2str(c-1)]); % next channel
    td_rcs = transformTDtoRCS(keych,ampGains.(['Amp',num2str(c)])); % transform TD signal to rcs internal values
    overlap = 1-(sr*interval/1e3/fftSizeActual); % time window parameters
    L = fftSize; % timeWin is now named L, number of time window points
    hann_win = 0.5*(1-cos(2*pi*(0:L-1)/(L-1))); % create hann taper function, equivalent to the Hann 100% 
    stime = 1; % sample 1 of data set where window starts
    totalTimeWindows = ceil(length(td_rcs)/L/(1-overlap)); 
    counter = 1; % initialize counter
    while counter <= totalTimeWindows % loop through time singal
        if stime+L <= length(t) % check at least one time window available before reach end signal
            X = fft(td_rcs(stime:stime+L-1)'.*hann_win,fftSize); % fft of the next window
            SSB = X(1:L/2); % from double to single sided FFT
            SSB(2:end) = 2*SSB(2:end); % scaling step 1, multiply by 2 bins 2 to end (all except DC)
            YFFT = abs(SSB/(L/2)); % scaling step 2, dividing by fft buffer size (L/2) (to be hoest i think this should be L)
            fftPower = 2*(YFFT.^2); % this factor 2 is necessary to match power values from RCS
            binStartBand1 = binStart(2*c-1);
            binEndBand1 = binEnd(2*c-1);
            binStartBand2 = binStart(2*c);
            binEndBand2 = binEnd(2*c);
            powerFromTimeDomain.(['PowerCh',num2str(2*c-1)])(stime+L-1) = sum(fftPower(binStartBand1:binEndBand1));
            powerFromTimeDomain.(['PowerCh',num2str(2*c)])(stime+L-1) = sum(fftPower(binStartBand2:binEndBand2));
        end
        counter = counter + 1;
        stime = stime + (L - ceil(L*overlap));
    end   
end
end

function [interval,binStart,binEnd,fftSize] = readFFTsettings(powerSettings,c)
    % at the moment assuming the only active Power Band is Band 0
    interval = powerSettings.fftConfig.interval; % is given in ms
    for iBand = 1:size(powerSettings.powerBands.indices_BandStart_BandStop,1)
        binStart(iBand) = powerSettings.powerBands.indices_BandStart_BandStop(iBand,1);
        binEnd(iBand) = powerSettings.powerBands.indices_BandStart_BandStop(iBand,2);
    end
    fftSize = powerSettings.fftConfig.size;
end

function td_rcs = transformTDtoRCS(keych,AmpGain)
    FP_READ_UNITS_VALUE = 48644.8683623726;    % predefined value from hardware 
    lfp_mv = nan(1,length(keych))';
    lfp_mv(~isnan(keych)) = keych(~isnan(keych))-mean(keych(~isnan(keych))); % remove mean
    config_trim_ch = AmpGain; % read from device settins (see above) 
    lfpGain_ch = 250*(config_trim_ch/255);  % actual gain amplifier ch
    lfp_rcs = lfp_mv * (lfpGain_ch*FP_READ_UNITS_VALUE) / (1000*1.2); % transform to rcs units
    td_rcs = lfp_rcs;
end

function AmpGains = createAmplifierGainsTable(folderPath)
% gets the gain of the amplifier (Amp channel: 1,2,3,4)

% Load in DeviceSettings.json file
DeviceSettings = jsondecode(fixMalformedJson(fileread([folderPath filesep 'DeviceSettings.json']),'DeviceSettings'));

%%
% Fix format - Sometimes device settings is a struct or cell array
if isstruct(DeviceSettings)
    DeviceSettings = {DeviceSettings};
end
%%
recordCounter = 1; % Initalize counter for records in DeviceSetting
while recordCounter <= length(DeviceSettings)
    currentSettings = DeviceSettings{recordCounter};
    % Check until Factory Settings are found
    if isfield(currentSettings,'FactorySettings')
         if isfield(currentSettings.FactorySettings,'name')
            for ii=1:size(currentSettings.FactorySettings,1)
                nextName = currentSettings.FactorySettings(ii).name; 
                if strcmp(nextName,'cfg_config_data.dev.HT_sns_amp1_gain250_trim')
                    AmpGains.Amp1 = currentSettings.FactorySettings(ii).actualValue;
                elseif strcmp(nextName,'cfg_config_data.dev.HT_sns_amp2_gain250_trim')
                    AmpGains.Amp2 = currentSettings.FactorySettings(ii).actualValue;
                elseif strcmp(nextName,'cfg_config_data.dev.HT_sns_amp3_gain250_trim')
                    AmpGains.Amp3 = currentSettings.FactorySettings(ii).actualValue;
                elseif strcmp(nextName,'cfg_config_data.dev.HT_sns_amp4_gain250_trim')
                    AmpGains.Amp4 = currentSettings.FactorySettings(ii).actualValue;
                end
            end    
         end
    end
    recordCounter = recordCounter+1;
end

end