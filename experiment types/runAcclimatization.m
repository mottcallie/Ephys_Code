% runAcclimatization.m
%
% Trial Type Function
% Display and hold blank G4 pattern/function
% Record G4 panels, FicTrac channels
%
% INPUTS:
%   settings - struct of ephys setup settings, from ephysSettings()
%   duration - sec
%   loop - open (0) or closed (2)
%
% OUTPUTS:
%
% CREATED: 03/22/2022 - MC
% Updated: 09/14/2022 - MC g4 panels now through DAC instead of log
%

function [rawData, inputParams, rawOutput] = runAcclimatization(settings,duration,loop)

%% INITIALIZE DAQ
inputParams.exptCond = 'G4PanelsFictrac'; % name of trial type

% which input and output data streams used in this experiment
inputParams.aInCh = {'ficTracHeading', 'ficTracIntX', 'ficTracIntY', 'g4panelXPosition'};
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
switch loop
    case 0
        pattN = 1; %blank background
        funcN = 1; %hold
        mode = 1; %pos change func

        % pull settings and connect
        userSettings %load settings
        Panel_com('change_root_directory', exp_path);
        load([exp_path '\currentExp'])
        expt_t = duration;

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

        % load panel parameters
        Panel_com('set_control_mode', mode);
        Panel_com('set_pattern_id', pattN);
        Panel_com('set_pattern_func_id', funcN);

    case 1
        % panel settings
        pattN = 2; %6px dark bar only

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
    case 2
        % panel settings
        pattN = 2; %6px dark bar only
        %pattN = 6; %6px bright bar only

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
end





%% ACQUIRE
disp(['[' datestr(now,'HH:MM') '] Beginning acclimation period: ' patlookup.name ' w/ ' 'closed-loop'])
inputParams.trialDuration = expt_t;
userDAQ.DurationInSeconds = expt_t;

% start experiment
pause(0.1) %slight delay
inputParams.startTimeStamp = datestr(now, 'HH:MM:SS');
Panel_com('start_display', expt_t); %sec
rawData = userDAQ.startForeground(); % acquire data (in foreground)
% stop experiment
pause(0.1)

disp('Finished acclimatization block.');
end