% recordG4PanelsFictracEphysOpto_func.m
%
% Trial Type Function
% Display pattern/function on G4 panels
% Record G4 panels and FicTrac channels
% Deliver 3 second light pulse at the start of each trial
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
% Adapted: 10/06/2022 - MC
%

function [rawData, inputParams, rawOutput] = recordG4PanelsFictracOpto_court(settings,duration)

%% INITIALIZE DAQ
inputParams.exptCond = 'G4PanelsFictracOpto'; % name of trial type

% which input and output data streams used in this experiment
inputParams.aInCh = {'ficTracHeading', 'ficTracIntX', 'ficTracIntY', 'g4panelXPosition'};
inputParams.aOutCh = {'optoExtCmd'};
inputParams.dInCh = {};
inputParams.dOutCh = {};

% initialize DAQ, including channels
[userDAQ, ~, ~, ~, ~] = initUserDAQ(settings, inputParams.aInCh, inputParams.aOutCh,...
    inputParams.dInCh, inputParams.dOutCh);

% generate output matrix for opto stimulation
pulse = 0; %1 for brief pulse, 0 for entire trial
if pulse
    stimDur = 3; %sec.
    stimOutput = ones(stimDur*settings.bob.sampRate,1)*5; %generate stim array, 5V output
    restOutput = zeros((duration-stimDur)*settings.bob.sampRate,1); %generate remaining rest array
    rawOutput = [stimOutput ; restOutput]; %combine
else
    rawOutput = ones(duration*settings.bob.sampRate,1)*5; %generate stim array, 5V output
end

% queue opto stimulation output
userDAQ.queueOutputData(rawOutput);


%% SET PANEL PARAMETERS

disp('Initializing G4 panels...');
% panel settings
pattN = 2; %6px dark bar only
%pattN = 4; %16px dark box only

%funcN = 30; %50d/sec sweeps for bar
%funcN = 31; %50d/sec sweeps for bo
funcN = 32; %75d/sec sweeps for bar
%funcN = 33; %75d/sec sweeps for box

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
userDAQ.outputSingleScan(0);

disp('Finished trial.');
end