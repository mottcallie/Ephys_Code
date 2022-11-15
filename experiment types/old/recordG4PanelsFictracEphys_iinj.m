% recordG4PanelsFictracEphys_iinj.m
%
% Trial Type Function
% Display pattern/function on G4 panels
% Record G4 panels, FicTrac channels, and ephys channels AND inject current
%
% INPUTS:
%   settings - struct of ephys setup settings, from ephysSettings()
%   stepAmp - current amplitude, pA
%   nSteps - number of current pulses to deliver, duration set accordingly
%
% OUTPUTS:
%   rawData - raw data measured by DAQ, matrix where each column is data
%       from a different channel
%   inputParams - parameters for this experiment type
%   rawOutput - raw output sent by DAQ, matrix where each column is
%       different channel
%
% Created: 11/01/2021 - MC
%

function [rawData, inputParams, rawOutput] = recordG4PanelsFictracEphys_iinj(settings,stepAmp, nSteps)

%% INITIALIZE DAQ
inputParams.exptCond = 'G4PanelsFictracEphys_iinj'; % name of trial type

% which input and output data streams used in this experiment
inputParams.aInCh = {'ampI', 'amp10Vm', 'ampScaledOut', ...
    'ampMode', 'ampGain', 'ampFreq', ...
    'ficTracHeading', 'ficTracIntX', 'ficTracIntY'};
inputParams.aOutCh = {'ampExtCmdIn'};
inputParams.dInCh = {};
inputParams.dOutCh = {};

% initialize DAQ, including channels
[userDAQ, ~, ~, ~, ~] = initUserDAQ(settings, inputParams.aInCh, inputParams.aOutCh,...
    inputParams.dInCh, inputParams.dOutCh);


%% SET CURRENT INJECT PARAMETERS

disp('Initializing output...');

% set parameters
spaceAmp = 0; %interstep amplitude, pA

stepDur = 0.5; %current step duration, sec
spaceDur = 9.5; %interstep duration, sec

% convert sec to output sampling rate
stepDur_sr = stepDur*settings.bob.sampRate;
spaceDur_sr = spaceDur*settings.bob.sampRate;

% convert current amplitude into output voltage
% note: compensate for non-zero output from DAQ at rest
stepAmpV = (stepAmp - settings.VOut.zeroI) * settings.VOut.IConvFactor;
spaceAmpV = (spaceAmp - settings.VOut.zeroI) * settings.VOut.IConvFactor;

% each stimulus as a column, starts with space, ends with step
spaceMatrix = ones(spaceDur_sr, 1) * spaceAmpV;
stepMatrix = ones(stepDur_sr, 1) .* stepAmpV;

% combine to set output matrix
repeatMatrix = repmat([spaceMatrix ; stepMatrix],nSteps,1);
rawOutput = [repeatMatrix ; spaceMatrix]; %add space at end

% set experiment duration
duration = length(rawOutput)/settings.bob.sampRate;

% store output parameters
inputParams.stepName = [num2str(stepDur *100) 'msec' '_' num2str(stepAmp) 'pA' '_iinj'];
inputParams.stepAmp = stepAmp;
inputParams.stepDur = stepDur *100; %msec

%% SET PANEL PARAMETERS

disp('Initializing G4 panels...');

% set parameters
pattN = 1; %blank background
funcN = 2; %hold midline
mode = 1; %pos func

% pull settings and connect
userSettings %load settings
Panel_com('change_root_directory', exp_path);
load([exp_path '\currentExp'])
expt_t = duration; %sec

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

% load panel parameters
Panel_com('set_control_mode', mode);
Panel_com('set_pattern_id', pattN);
Panel_com('set_pattern_func_id', funcN);


%% ACQUIRE
disp(['Starting current injection w/ G4 display: ' patlookup.name])
inputParams.trialDuration = expt_t;

% queue current injection output
userDAQ.queueOutputData(rawOutput);

% start experiment
Panel_com('start_log'); %start listening log, waits for "start" cmd
pause(0.1) %slight delay

inputParams.startTimeStamp = datestr(now, 'HH:MM:SS');
Panel_com('start_display', expt_t); %sec
rawData = userDAQ.startForeground(); % acquire data (in foreground)

% stop experiment
pause(0.2)
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