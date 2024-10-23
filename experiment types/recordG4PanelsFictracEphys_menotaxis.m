% recordG4PanelsFictracEphys_menotaxis.m
%
% Trial Type Function for displaying patterns on G4 panels and recording 
% data from FicTrac channels and electrophysiological (ephys) channels. 
% This function is specifically designed for menotaxis trials, where a 
% bright bar pattern is displayed.
%
% INPUTS:
% - settings  : Struct containing electrophysiological setup settings, 
%               typically obtained from the ephysSettings() function.
% - duration  : Duration of the trial (in seconds).
%
% OUTPUTS:
% - rawData   : Matrix of raw data measured by the DAQ, where each column 
%               corresponds to data from a different channel.
% - inputParams : Struct containing parameters specific to this experiment 
%                 type, including experimental conditions and channel settings.
% - rawOutput  : Empty matrix for this trial type as there is no output data.
%
% CREATED: 04/20/2022 by MC
% UPDATED: 09/14/2022 by MC, G4 panels now controlled through DAC instead of log.
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
pattN = 6; %06px bright bar

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