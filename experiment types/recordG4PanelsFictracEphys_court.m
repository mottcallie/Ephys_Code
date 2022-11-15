% recordG4PanelsFictracEphys_func.m
%
% Trial Type Function
% Display pattern/function on G4 panels
% Record G4 panels, FicTrac channels, and ephys channels
%
% INPUTS:
%   settings - struct of ephys setup settings, from ephysSettings()
%   duration - min
%
% OUTPUTS:
%   rawData - raw data measured by DAQ, matrix where each column is data
%       from a different channel
%   inputParams - parameters for this experiment type
%   rawOutput - raw output sent by DAQ, matrix where each column is
%       different channel
%
% Created: 11/01/2021 - MC
% Updated: 09/14/2022 - MC g4 panels now through DAC instead of log
%

function [rawData, inputParams, rawOutput] = recordG4PanelsFictracEphys_court(settings,duration)

%% INITIALIZE DAQ
inputParams.exptCond = 'G4PanelsFictracEphys'; % name of trial type

% which input and output data streams used in this experiment
inputParams.aInCh = {'ampI', 'amp10Vm', 'ampScaledOut', ...
    'ampMode', 'ampGain', 'ampFreq', ...
    'ficTracHeading', 'ficTracIntX', 'ficTracIntY', 'g4panelXPosition'};
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
pattN = 2; %6px dark bar only
%pattN = 4; %16px dark box only

funcN = 5; %50d/sec sweeps for bar
%funcN = 6; %50d/sec sweeps for box
%funcN = 7; %75d/sec sweeps for bar
%funcN = 8; %75d/sec sweeps for box

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