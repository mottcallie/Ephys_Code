% batteryStimG4PanelsFictracEphys_IInj.m
%
% Trial Type Function for displaying patterns on G4 panels and recording 
% data from FicTrac channels and electrophysiological (ephys) channels. 
% This function delivers light and current pulses during the trial.
%
% INPUTS:
% - settings  : Struct containing electrophysiological setup settings, 
%               typically obtained from the ephysSettings() function.
% - duration  : Duration of the trial (in minutes).
% - pattN     : Identifier for the pattern to be displayed on the G4 panels.
% - funcN     : Identifier for the function to be applied during the trial.
% - optostim   : Binary flag (1 for opto output, 0 for no opto output).
%
% OUTPUTS:
% - rawData   : Matrix of raw data measured by the DAQ, where each column 
%               corresponds to data from a different channel.
% - inputParams : Struct containing parameters specific to this experiment 
%                 type, including experimental conditions and channel settings.
% - rawOutput  : Matrix of raw output sent by the DAQ, where each column 
%                corresponds to a different channel.
%
% ADAPTED: 02/16/2023 by MC
%
function [rawData, inputParams, rawOutput] = batteryStimG4PanelsFictracEphys_IInj(settings,duration,pattN,funcN,optostim)

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
% get multi-step output vector
[iInjOutput, iInjParams] = alterStepIInj(settings, duration);
duration_adj = length(iInjOutput)/settings.bob.sampRate; %adjust duration to matrch output

% save meta data
inputParams.iInjProtocol = 'alternatingStepIInj';
inputParams.iInjParams = iInjParams; % current injection parameters

% second, generate output for opto (output 2)
% depending on input
if optostim
    optoOutput = ones(duration_adj*settings.bob.sampRate,1)*5; %generate stim array, 5V output
else
    optoOutput = zeros(duration_adj*settings.bob.sampRate,1); %generate empty stim array, 0V output
end

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
inputParams.sweepDur = (funlookup.sweepRange/funlookup.sweepRate)*2;

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