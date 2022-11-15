% recordG4PanelsFictrac_set.m
%
% Trial Type Function
% Display pattern/function on G4 panels
% Record G4 panels, FicTrac channels
%
% INPUTS:
%   settings - struct of ephys setup settings, from ephysSettings()
%   pattN - g4 pattern number
%   funcN - g4 function number
%   ypos - set pattern y position
%   mode - 0=streaming, 1=position function, 2=constant rate, 3=position change, 4=Closed-loop (CL), 5=CL+bias, 6=CL+OL
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
%

function [rawData, inputParams, rawOutput] = recordG4PanelsFictrac_set(settings,pattN,funcN,mode,duration)

%% INITIALIZE DAQ
inputParams.exptCond = 'G4PanelsFictrac'; % name of trial type

% which input and output data streams used in this experiment
inputParams.aInCh = {'ficTracHeading', 'ficTracIntX', 'ficTracIntY'};
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

% pull settings and connect
userSettings %load settings
Panel_com('change_root_directory', exp_path);
load([exp_path '\currentExp'])
expt_t = duration * 60;

%store pattern parameters
load(['patt_lookup_' sprintf('%04d', pattN)])
inputParams.pattern_name = patlookup.fullname;
inputParams.objectSize = patlookup.size;
inputParams.objectGS = patlookup.objgs;
inputParams.backgroundGS = patlookup.bckgs;
%store function parameters
load(['func_lookup_' sprintf('%04d', funcN)])
inputParams.function_name = funlookup.name;
inputParams.sweepRange = funlookup.sweepRange;
inputParams.sweepRate = funlookup.sweepRange;
inputParams.sweepDur = (funlookup.sweepRange/funlookup.sweepRate)*2;

inputParams.expt_name = [patlookup.fullname '_' funlookup.name];

% load panel parameters
Panel_com('set_control_mode', mode);
Panel_com('set_pattern_id', pattN);
Panel_com('set_pattern_func_id', funcN);


%% ACQUIRE
disp(['Starting G4 display: ' patlookup.fullname ' w/ ' funlookup.name])
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
if length(g4_xpos)<length(rawData(:,1))
    g4_length = length(g4_xpos);
    g4_xpos(g4_length+1:length(rawData(:,1))) = NaN;
end
if length(g4_xpos)>length(rawData(:,1))
    g4_xpos = g4_xpos(1:length(rawData(:,1)));
end

% save g5 display data into rawData
inputParams.aInCh{end+1} = 'g4display_xpos'; %add channel marker
rawData(:,end+1) = g4_xpos;
Panel_com('stop_display')
disp('Finished G4 display');
end