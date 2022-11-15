% recordG4PanelsFictracEphys_menotaxis.m
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
% Created: 04/20/2022 - MC
% Updated: 09/14/2022 - MC g4 panels now through DAC instead of log
%

function [rawData, inputParams, rawOutput] = recordG4PanelsFictracEphys_menotaxis(settings,duration)

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
pattN = 3; %6px bright bar only

%mode = 4; %closed loop - frame rate
mode = 7; %closed loop - frame index

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
disp(['[' datestr(now,'HH:MM') '] Beginning: ' patlookup.name ' w/ ' 'closed-loop'])
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