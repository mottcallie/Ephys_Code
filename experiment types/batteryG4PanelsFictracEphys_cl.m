% batteryStimG4PanelsFictracEphysOpto.m
%
% Trial Type Function for battery and stimulating
% Display pattern/function on G4 panels
% Record G4 panels, FicTrac channels, and ephys channels
% Deliver light
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
% Adapted: 03/26/2024 - MC
%

function [rawData, inputParams, rawOutput] = batteryG4PanelsFictracEphys_cl(settings,duration,pattN,funcN,stim)
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
panel_gain = 80;

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
Panel_com('set_gain_bias', [panel_gain 0]);
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