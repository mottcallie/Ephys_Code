% batteryG4PanelsFictracEphys_jumps.m
%
% Trial Type Function for displaying patterns on G4 panels and recording 
% data from FicTrac channels and electrophysiological (ephys) channels. 
% This function is designed to deliver light stimuli while capturing jump 
% data during the trial.
%
% INPUTS:
% - settings  : Struct containing electrophysiological setup settings, 
%               typically obtained from the ephysSettings() function.
% - duration  : Duration of the trial (in minutes).
% - pattN     : Identifier for the pattern to be displayed on the G4 panels.
% - funcN     : Identifier for the function to be applied during the trial.
% - stim      : Binary flag (1 for opto output, 0 for no opto output).
%
% OUTPUTS:
% - rawData   : Matrix of raw data measured by the DAQ, where each column 
%               corresponds to data from a different channel.
% - inputParams : Struct containing parameters specific to this experiment 
%                 type, including experimental conditions and channel settings.
% - rawOutput  : Empty matrix for this trial type, included to maintain 
%                consistency with the trial type function format.
%
% ADAPTED: 11/07/2023 by MC
%          11/14/2023 by MC, added Python trigger for capturing jumps,
%          removed empty stim output delivery.
%
function [rawData, inputParams, rawOutput] = batteryG4PanelsFictracEphys_jumps(settings,duration,pattN,funcN,stim)
%% RESTART FICTRAC
startFicTrac(cd,3)


%% INITIALIZE DAQ
inputParams.exptCond = 'G4PanelsFictracEphys_jumps'; % name of trial type

% which input and output data streams used in this experiment
inputParams.aInCh = {'ampI', 'amp10Vm', 'ampScaledOut', ...
    'ampMode', 'ampGain', 'ampFreq', ...
    'ficTracHeading', 'ficTracIntX', 'ficTracIntY',...
    'g4panelXPosition','pythonJumpTrig'};
inputParams.aOutCh = {};
inputParams.dInCh = {};
inputParams.dOutCh = {};

% output matrix - empty for this trial type (there are no output)
rawOutput = [];

% initialize DAQ, including channels
[userDAQ, ~, ~, ~, ~] = initUserDAQ(settings, inputParams.aInCh, inputParams.aOutCh,...
    inputParams.dInCh, inputParams.dOutCh);


%% SET PANEL PARAMETERS

disp('Initializing G4 panels...');
% panel settings
mode = 7; %cl

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

% load panel parameters
Panel_com('set_control_mode', mode);
Panel_com('set_pattern_id', pattN);


%% ACQUIRE
disp(['[' datestr(now,'HH:MM') '] Beginning: ' patlookup.name ' w/ ' 'closed-loop bar jumps'])
inputParams.trialDuration = expt_t;
userDAQ.DurationInSeconds = expt_t;

% start experiment
pause(0.1) %slight delay
inputParams.startTimeStamp = datestr(now, 'HH:MM:SS');
Panel_com('start_display', expt_t); %sec
rawData = userDAQ.startForeground(); % acquire data (in foreground)
% stop experiment
pause(0.1)

disp('Finished trial.');
end