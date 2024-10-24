% recordG4PanelsFictracEphys_IInj.m
%
% Trial Type Function for displaying patterns on G4 panels and recording 
% data from FicTrac channels and electrophysiological (ephys) channels. 
% This function outputs current pulses while conducting the experiment.
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
% - rawOutput  : Matrix of raw output sent by the DAQ, where each column 
%                corresponds to a different channel.
%
% CREATED: 06/01/2022 by MC
% UPDATED: 09/14/2022 by MC, G4 panels now controlled through DAC instead of log.
%
function [rawData, inputParams, rawOutput] = recordG4PanelsFictracEphys_IInj(settings,duration)

%% INITIALIZE DAQ
inputParams.exptCond = 'FictracEphysIInj'; % name of trial type

% which input and output data streams used in this experiment
inputParams.aInCh = {'ampI', 'amp10Vm', 'ampScaledOut', ...
    'ampMode', 'ampGain', 'ampFreq', 'ficTracHeading', ...
    'ficTracIntX', 'ficTracIntY', 'g4panelXPosition'};
inputParams.aOutCh = {'ampExtCmdIn'};
inputParams.dInCh = {};
inputParams.dOutCh = {};

% initialize DAQ, including channels
[userDAQ, ~, ~, ~, ~] = initUserDAQ(settings, inputParams.aInCh, inputParams.aOutCh,...
    inputParams.dInCh, inputParams.dOutCh);

%% SET CURRENT INJECTION PARAMETERS

    % get multi-step output vector 
    [iInjOut, iInjParams] = multiStepIInj(settings, duration); 
    
    % save info into returned variables
    rawOutput = iInjOut; % output commanded into rawOutput
    % save meta data
    inputParams.iInjProtocol = 'multiStepIInj'; 
    inputParams.iInjParams = iInjParams; % current injection parameters

    % queue current injection output
    userDAQ.queueOutputData(iInjOut);


    %% SET PANEL PARAMETERS

    disp('Initializing G4 panels...');
    % panel settings
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

%% ACQUIRE
disp(['[' datestr(now,'HH:MM') '] Beginning: ' patlookup.name ' w/ ' funlookup.name])
inputParams.trialDuration = expt_t;

% start experiment
pause(0.1) %slight delay
inputParams.startTimeStamp = datestr(now, 'HH:MM:SS');
Panel_com('start_display', expt_t); %sec
disp('Delivering multi-step current injections');
rawData = userDAQ.startForeground(); % acquire data (in foreground)
% stop experiment
pause(0.1)
userDAQ.outputSingleScan(0);

disp('Finished trial.');
end