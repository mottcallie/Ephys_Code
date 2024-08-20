% batteryStimG4PanelsFictracEphys_IDepol.m
%
% Trial Type Function for battery and stimulating
% Display pattern/function on G4 panels
% Record G4 panels, FicTrac channels, and ephys channels
% Deliver light and optional depolarizing current hold
%
% INPUTS:
%   settings - struct of ephys setup settings, from ephysSettings()
%   duration - min
%   pattN - select pattern
%   funcN - select function
%   stim - 1 for opto output, 0 for no opto output
%
% OUTPUTS:
%   rawData - raw data measured by DAQ, matrix where each column is data
%       from a different channel
%   inputParams - parameters for this experiment type
%   rawOutput - raw output sent by DAQ, matrix where each column is
%       different channel
%
% Adapted: 01/23/2023 - MC
%

function [rawData, inputParams, rawOutput] = batteryStimG4PanelsFictracEphys_IDepol(settings,duration,pattN,funcN,stim)

%% INITIALIZE DAQ
inputParams.exptCond = 'StimG4PanelsFictracEphysIInj'; % name of trial type

% which input and output data streams used in this experiment
inputParams.aInCh = {'ampI', 'amp10Vm', 'ampScaledOut', ...
    'ampMode', 'ampGain', 'ampFreq', ...
    'ficTracHeading', 'ficTracIntX', 'ficTracIntY', 'g4panelXPosition'};
inputParams.aOutCh = {'ampExtCmdIn','optoExtCmd'};
inputParams.dInCh = {};
inputParams.dOutCh = {};

% initialize DAQ, including channels
[userDAQ, ~, ~, ~, ~] = initUserDAQ(settings, inputParams.aInCh, inputParams.aOutCh,...
    inputParams.dInCh, inputParams.dOutCh);

% first, generate output for iinj (output 1)
% depending on input
if stim
    holdAmp = +100; %pA
else
    holdAmp = 0; %pA
end
[iInjOutput, iInjParams] = holdIInj2(settings, holdAmp, duration);
duration_adj = length(iInjOutput)/settings.bob.sampRate; %adjust duration to matrch output
% save meta data
inputParams.iInjProtocol = 'holdIInj';
inputParams.iInjParams = iInjParams; % current injection parameters

% second, generate output for opto (output 2)
optoOutput = ones(duration_adj*settings.bob.sampRate,1)*5; %generate stim array, 5V output

% queue opto stimulation output
rawOutput = [iInjOutput optoOutput]; %combine
userDAQ.queueOutputData(rawOutput); %queue


%% SET PANEL PARAMETERS

disp('Initializing G4 panels...');
% panel settings
mode = 1; %pos change func

% pull settings and connect
userSettings %load settings
Panel_com('change_root_directory', exp_path);
load([exp_path '\currentExp'])
expt_t = duration;

%store pattern parameters
load(['patt_lookup_' sprintf('%04d', pattN)])
inputParams.pattern_name = patlookup.name;
inputParams.objectSize = patlookup.size;
inputParams.objectGS = patlookup.objgs;
inputParams.backgroundGS = patlookup.bckgs;
%store function parameters
load(['func_lookup_' sprintf('%04d', funcN)])
inputParams.function_name = funlookup.name;
inputParams.sweepRange = funlookup.sweepRange;
inputParams.sweepRate = funlookup.sweepRange;
%inputParams.sweepDur = (funlookup.sweepRange/funlookup.sweepRate)*2;

% load panel parameters
Panel_com('set_control_mode', mode);
Panel_com('set_pattern_id', pattN);
Panel_com('set_pattern_func_id', funcN);


%% ACQUIRE
disp(['[' datestr(now,'HH:MM') '] Beginning: ' patlookup.name ' w/ ' funlookup.name])
inputParams.trialDuration = expt_t;

% start experiment
pause(0.1) %slight delay
inputParams.startTimeStamp = datestr(now, 'HH:MM:SS');
Panel_com('start_display', expt_t); %sec
rawData = userDAQ.startForeground(); % acquire data (in foreground)
% stop experiment
pause(0.1)
userDAQ.outputSingleScan([0 0]);

disp('Finished trial.');
end