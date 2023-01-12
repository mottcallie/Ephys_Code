% batteryG4PanelsFictracEphys.m
%
% Battery Type Function
% Display pattern/function on G4 panels
% Record G4 panels, FicTrac channels, and ephys channels
%
% INPUTS:
%   settings - struct of ephys setup settings, from ephysSettings()
%   pattN - pattern number selection
%   funcN - function number selection
%   duration - sec
%
% OUTPUTS:
%   rawData - raw data measured by DAQ, matrix where each column is data
%       from a different channel
%   inputParams - parameters for this experiment type
%   rawOutput - raw output sent by DAQ, matrix where each column is
%       different channel
%
% Created: 06/01/2022 - MC
%

function [rawData, inputParams, rawOutput] = batteryG4PanelsFictracEphys(settings,pattN,funcN,duration)

%% INITIALIZE DAQ
inputParams.exptCond = 'G4PanelsFictracEphys'; % name of trial type

% which input and output data streams used in this experiment
inputParams.aInCh = {'ampI', 'amp10Vm', 'ampScaledOut', ...
    'ampMode', 'ampGain', 'ampFreq', ...
    'ficTracHeading', 'ficTracIntX', 'ficTracIntY'};
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
disp(['Starting G4 display: ' patlookup.name ' using ' funlookup.name])
inputParams.trialDuration = expt_t;
userDAQ.DurationInSeconds = expt_t;

% start experiment
Panel_com('start_log'); %start listening log, waits for "start" cmd
pause(0.1) %slight delay

inputParams.startTimeStamp = datestr(now, 'HH:MM:SS');
Panel_com('start_display', expt_t); %sec
rawData = userDAQ.startForeground(); % acquire data (in foreground)

% stop experiment
pause(0.1)
Panel_com('stop_log');

% pull g4 display data
pause(1)
latestLog = getlatestfile([exp_path '\Log Files']); %locate most recent log
Log = G4_TDMS_folder2struct_mc([exp_path '\Log Files\' latestLog]); %convert log .tdms to .mat format
srConvert = settings.bob.sampRate/500; %daq vs panel sample rate
g4_xpos = repelem(Log.Frames.Position,srConvert);

% save g5 display data into rawData
inputParams.aInCh{end+1} = 'g4display_xpos'; %add channel marker
rawData(:,end+1) = g4_xpos;

disp('Finished G4 display');
end