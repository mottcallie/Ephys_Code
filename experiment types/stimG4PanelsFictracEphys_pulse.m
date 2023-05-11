% stimG4PanelsFictracEphys_pulse.m
%
% Trial Type Function for stimulating
% Display pattern/function on G4 panels
% Record G4 panels, FicTrac channels, and ephys channels
% Deliver alternating light pulses throughout trial
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
% Adapted: 01/30/2023 - MC
%

function [rawData, inputParams, rawOutput] = stimG4PanelsFictracEphys_pulse(settings,duration)

%% INITIALIZE DAQ
inputParams.exptCond = 'StimG4PanelsFictracEphys'; % name of trial type

% which input and output data streams used in this experiment
inputParams.aInCh = {'ampI', 'amp10Vm', 'ampScaledOut', ...
    'ampMode', 'ampGain', 'ampFreq', ...
    'ficTracHeading', 'ficTracIntX', 'ficTracIntY', ...
    'g4panelXPosition'};
inputParams.aOutCh = {'optoExtCmd'};
inputParams.dInCh = {};
inputParams.dOutCh = {};

% initialize DAQ, including channels
[userDAQ, ~, ~, ~, ~] = initUserDAQ(settings, inputParams.aInCh, inputParams.aOutCh,...
    inputParams.dInCh, inputParams.dOutCh);

% generate output matrix for opto stimulation
pulseDur = 15; %pulse duration, sec.
stimOutput = ones(pulseDur*settings.bob.sampRate,1)*5; %generate stim array, 5V output
restOutput = zeros(pulseDur*settings.bob.sampRate,1); %generate rest array, 0V output
nPulse = ceil(duration/(pulseDur*2)); %number of pulses given duration
rawOutput_pre = repmat([restOutput ; stimOutput],nPulse,1); %combine and repeat

% cut off according to trial duration (e.g., leaves slack if desired)
rawOutput = rawOutput_pre(1:duration*settings.bob.sampRate);

% queue opto stimulation output
userDAQ.queueOutputData(rawOutput);


%% SET PANEL PARAMETERS

disp('Initializing G4 panels...');
% panel settings
pattN = 1; %background
funcN = 1; %hold
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
userDAQ.outputSingleScan(0);
pause(0.1)

disp('Finished trial.');
end