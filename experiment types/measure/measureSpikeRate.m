% measureSpikeRate.m
%
% Function to record a brief 10s trace and report back with the spike rate.
% Helpful to run at the start of experiments to ensure the proper amount of
% current is being injected.
%
% INPUTS:
%   duration - duration of trial, in seconds
%
% OUTPUTS:
%   rawData - raw data measured by DAQ, matrix where each column is data
%       from a different channel
%   inputParams - parameters for this experiment type
%   rawOutput - raw output sent by DAQ, matrix where each column is
%       different channel (this is here because trial type functions follow
%       this format, but there is no rawOutput for this type)
%
% Original: 12/08/2021 - MC
%

function measureSpikeRate(duration)

    % load settings
    [~, ~ , settings] = ephysSettings();
    
    % which input and output data streams used in this experiment
    inputParams.exptCond = 'ephys'; % name of trial type
    inputParams.aInCh = {'ampI', 'amp10Vm', 'ampScaledOut','ampMode', 'ampGain', 'ampFreq'};
    inputParams.aOutCh = {};
    inputParams.dInCh = {};
    inputParams.dOutCh = {};
    rawOutput = [];
    inputParams.trialDuration = duration; 

    % initialize DAQ, including channels
    [userDAQ, ~, ~, ~, ~] = initUserDAQ(settings, inputParams.aInCh, inputParams.aOutCh, inputParams.dInCh, inputParams.dOutCh);
    
    % set duration of acquisition
    userDAQ.DurationInSeconds = duration;
    % get time stamp of approximate experiment start
    inputParams.startTimeStamp = datestr(now, 'HH:MM:SS');
    
    
    disp('Acquiring spike rate recording.');
    % acquire data (in foreground)
    rawData = userDAQ.startForeground();
    disp('Spike rate recording acquired.');
    
    % process
    [daqData, daqOutput, daqTime] = preprocessUserDaq(inputParams, rawData, rawOutput, settings);
    [exptData, ~] = processExptData(daqData, daqOutput, daqTime, inputParams, settings);
    
    % find spike rate
    [~,~,spikeRate] = findSpikeRate(settings,exptData,7,0);
    vc_avgspikerate = nanmean(spikeRate);
    disp(['Spike rate = ' num2str(round(vc_avgspikerate)) '/s']);


end