% preExptMotorControls.m
%
% Function that runs pre/post experiment routine for collecting trials in
% darkness and/or during optomotor reflex
%
% INPUT:
%   settings - struct of ephys setup settings, from ephysSettings()
%
%
% Adapted:  09/06/2022 MC
% Updated:  10/04/2022 MC combined stationary/optomotor presentation

function preExptMotorControls(settings)
%% set variables
currentFolder = cd;
preExptFolderName = 'optomotorctrl';

% make preExptTrials folder if it does't already exist
if ~isfolder(preExptFolderName)
    mkdir(preExptFolderName);
end

% go to preExptFolder
cd(preExptFolderName);

% set trial parameters
nTrials = 1;      %number of trials
duration = 30+40; %duration in seconds

%% run optomotor trials
for n = 1:nTrials
    disp(['Starting optomotor trial ' num2str(n)])
    pattN = 5; %8px vgrating
    funcN = 28; %pause, then fast optomotor alternation
    [rawData, inputParams, rawOutput] = recordG4PanelsFictracEphys_inputOL(settings,pattN,funcN, duration);

    % SAVE RAW TRIAL DATA !!
    inputParams.filename = ['optomotorcontrol' num2str(n,'%02.f')];
    save([inputParams.filename '_raw.mat'], 'rawData', 'rawOutput', 'inputParams','-v7.3');

    % PROCESS TRIAL DATA !!
    [daqData, daqOutput, daqTime] = preprocessUserDaq(inputParams, rawData, rawOutput, settings);
    [exptData, exptMeta] = processExptData(daqData, daqOutput, daqTime, inputParams, settings);
    % find spike rate
    [~,spikeRaster,spikeRate] = convolveSpikeRate(settings,exptData,'gaussian');
    exptData.spikeRaster = spikeRaster;
    exptData.spikeRate = spikeRate;
    vc_avgspikerate = nanmean(exptData.spikeRate);
    disp(['Spike Rate: ' num2str(round(vc_avgspikerate)) '/s']);
    % save processed trial data
    save([inputParams.filename '_pro.mat'], 'exptData', 'exptMeta', '-v7.3');
    disp('Processed data saved!');

    % Plot processesed data
    disp('Plotting data...');
    plotExpt(exptData,exptMeta)
    sgtitle(strrep(inputParams.filename,'_',' '))
    % save plot of trial data
    saveas(gcf,[inputParams.filename '_plot.png']);
    disp('Plotted data saved!');
end
disp('Optomotor trials complete.')

%% terminate
disp('All motor control trials have been completed.')
cd(currentFolder) %go back to folder where we started
end


