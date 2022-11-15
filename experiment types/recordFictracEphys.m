% recordFictracEphys.m
%
% Trial Type Function 
% Records both FicTrac channels and ephys channels, WITHOUT current injection
%
% INPUTS:
%   settings - struct of ephys setup settings, from ephysSettings()
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
% Original: 01/30/2021 - HY
% Updated: 04/01/2021 - MC
%

function [rawData, inputParams, rawOutput] = recordFictracEphys(settings, ...
    duration)

    % EXPERIMENT-SPECIFIC PARAMETERS
    inputParams.exptCond = 'fictracEphys'; % name of trial type
    
    % which input and output data streams used in this experiment
    inputParams.aInCh = {'ampI', 'amp10Vm', 'ampScaledOut', ...
        'ampMode', 'ampGain', 'ampFreq', 'ficTracHeading', ...
        'ficTracIntX', 'ficTracIntY'};
    inputParams.aOutCh = {};
    inputParams.dInCh = {'ficTracCamFrames'};
    inputParams.dOutCh = {};
    
    % output matrix - empty for this trial type (there are no output
    %  channels initialized for DAQ; no current injection, triggers, etc)
    % placeholder for different trial types
    rawOutput = [];
    
    % save trial duration here into inputParams
    inputParams.trialDuration = duration; 

    % initialize DAQ, including channels
    [userDAQ, ~, ~, ~, ~] = initUserDAQ(settings, ...
        inputParams.aInCh, inputParams.aOutCh, inputParams.dInCh, ...
        inputParams.dOutCh);
    
    % set duration of acquisition
    userDAQ.DurationInSeconds = duration;
    
    % get time stamp of approximate experiment start
    inputParams.startTimeStamp = datestr(now, 'HH:MM:SS');
    
    disp(['[' datestr(now,'HH:MM') '] Beginning: ephys and behavior trial'])
    % acquire data (in foreground)
    rawData = userDAQ.startForeground();

    disp('Finished ephys and behavior trial.');
end