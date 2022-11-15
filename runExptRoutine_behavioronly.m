% runExptRoutine_behavioronly.m
%
% Top level function for running 1 or more trials of a pre-determined
% behavior experiments
%
% Sets up folder structure for organizing data (date/fly),
%  prompts whether this is new fly or additional trial(s) for fly. For
%  new fly, prompts for experimental condition, and runs through
%  experimental trials until no more new trials. For same fly (in case
%  previous run of runEphysExpt stopped unexpectedly), can run additional
%  trials.
%
% Original: 01/30/2021 - HY
% Updated:  12/20/2021 - MC
%           01/10/2022 - MC added new battery


function runExptRoutine_behavioronly()
% clean up
close all

% initialize persistent variables for this function
%persistent flyDirPath trialNum;
% reset values of persistent variables
flyDirPath = [];
trialNum = [];

% load constant settings
[dataDir, ~, settings] = ephysSettings();

% set up folder structure by date for organizing data
dateDirPath = fullfile(dataDir, datestr(now,'yyyy_mm_dd'));
% get just name of directory
[~, dateDirName, ~] = fileparts(dateDirPath);
% make date folder if it doesn't already exist
if ~exist(dateDirPath, 'dir')
    mkdir(dateDirPath)
end
cd(dateDirPath);

% figure out which fly we're on in the date directory
dateDirContents = dir(dateDirPath);
currFlyDirs = dateDirContents(contains({dateDirContents.name},'fly') & ~contains({dateDirContents.name},'processed'));
if isempty(currFlyDirs) %if first fly
    flyNum = 1;
else % otherwise, pull previous and +1
    flyNum = length(currFlyDirs) + 1;
end
flyDirName = sprintf('fly%02d',flyNum); % fly folder name

% creates fly folder in date directory
mkdir(flyDirName); % make fly folder

% go to fly directory
cd(flyDirName);
flyDirPath = pwd;

alphabet = 'abcdefghijklmnopqrstuvwxyz';

%% FLY INFO

% request fly metadata
flyData = getFlyMetadata(dateDirName, flyDirName);

% generate basic experimental info struct
exptInfo.dateDir = dateDirName;
exptInfo.flyDir = flyDirName;
exptInfo.exptDate = datestr(now, 'yymmdd');
exptInfo.exptStartTime = datestr(now, 'HH:MM:SS');
cd(flyDirPath)

% if fictrac, remind user to configure and start FicTrac
startFicTrac(flyDirPath)

% if using display, remind user to check if panels are working
disp('Connecting to G4 display...');
userSettings %load g4 settings and paths
connectHost; %required, start g4 connection

Panel_com('all_on');
g4check = input('[I] Check display is working...');
Panel_com('all_off');

delete([exp_path '\Log Files\*']) %clear log folder
g4log_dir = fullfile(flyDirPath,'g4logs');
if ~exist(g4log_dir, 'dir') %make g4 log dir if needed
    mkdir(g4log_dir)
end



%% select g4 display parameters

% select pattern battery
selection = 4.5;
switch selection
    case 0 %bar, box, small box battery
        change = 'pattern';
        pattSelect = [13, 14, 15, 16, 17, 18]; %bar, box, small box
        funcSelect = [05, 05, 07, 07, 06, 06]; %75deg sweeps
    case 1 %small box, vary height battery
        change = 'pattern';
        pattSelect = [19, 20, 21, 22, 15]; %small box x4, box
        funcSelect = [06, 06, 06, 06, 07]; %75deg sweeps
    case 2.1 %box, vary sweep size
        change = 'function';
        pattSelect = [15, 15];
        funcSelect = [07, 11]; %75, 120
    case 2.2 %bar, vary sweep size
        change = 'function';
        pattSelect = [13, 13];
        funcSelect = [05, 09]; %75, 120
    case 2.3 %bar, vary sweep size
        change = 'function';
        pattSelect = [13, 13];
        funcSelect = [05, 13]; %75, 180
    case 3 %box, vary sweep velocity;
        change = 'function';
        pattSelect = [13, 13, 13];
        funcSelect = [22, 23, 24]; %50 75 100
        durrSelect = [0.5, 1, 0.5];
    case 4.1 %bar +/- grating or +/- starfield
        change = 'pattern';
        pattSelect = [30, 31, 32];
        funcSelect = [05, 05, 05]; %75
        durrSelect = [1, 0.25, 0.25];
    case 4.2 %bar +/- grating or +/- starfield
        change = 'pattern';
        pattSelect = [33, 34, 35];
        funcSelect = [05, 05, 05]; %75
        durrSelect = [01, 01, 01];
    case 4.3 %bar +/- grating or +/- starfield, 3gs 25% density
        change = 'pattern';
        pattSelect = [36, 37, 38];
        funcSelect = [05, 05, 05]; %75
        durrSelect = [01, .5, .5];
    case 4.4 %bar +/- grating or +/- starfield, 3gs 15% density
        change = 'pattern';
        pattSelect = [39, 40, 41];
        funcSelect = [05, 05, 05]; %75
        durrSelect = [01, 01, 01];
    case 4.5 %bar +/- grating or +/- starfield, 4gs 30% density, 7gs background
        change = 'pattern';
        pattSelect = [42, 43, 44];
        funcSelect = [05, 05, 05]; %75
        durrSelect = [01, 01, 01];
end

%set display parameters
mode = 1; %pos change func
%trialDuration = 1; %min
%anotherOne = 'y'; %breaks when n
trials = 20;

% for each selection
for n = 1:length(pattSelect)
    %pull pattern name and file
    load(['patt_lookup_' sprintf('%04d', pattSelect(n))])
    dispInfo.pattNames{n} = patlookup.fullname;
    pat = load([sprintf('%04d', pattSelect(n)) '_' patlookup.name '.mat']);
    dispInfo.pattFiles{n} = pat.pattern.Pats;
    
    %pull function name and file
    load(['func_lookup_' sprintf('%04d', funcSelect(n))])
    dispInfo.funcNames{n} = funlookup.name;
    load([sprintf('%04d', funcSelect(n)) '_' funlookup.name '.mat'])
    dispInfo.funcFiles{n} = pfnparam.func;
    
    %pull full trial name
    dispInfo.fullNames{n} = [patlookup.fullname '_' funlookup.name];
end
dispInfo.change = change;

% save settings, fly metadata, experimental info to file
save('metaDat.mat', 'flyData', 'settings', 'exptInfo', 'dispInfo', '-v7.3');

%% run experiment
cd(flyDirPath)

%while ~(strcmpi(anotherOne, 'n')) %repeat expt until user breaks
for t = 1:trials
    disp(['START OF TRIAL ' num2str(t)])
    % update trial number with each itteration
    if isempty(trialNum)
        trialNum = 1;
    else
        trialNum = trialNum + 1;
    end
    
    
    % run experiment !!
    pTot = length(pattSelect);
    for p = randperm(pTot) %randomize order
        % select matching pat/func
        pattCurrent = pattSelect(p);
        funcCurrent = funcSelect(p);
        durrCurrent = durrSelect(p);
        % run
        [rawData, inputParams, rawOutput] = recordG4PanelsFictrac_set(settings,pattCurrent,funcCurrent,mode,durrCurrent);
        
        % set filename
        fileBase = erase(flyDirPath,dataDir);
        fileBase = [fileBase '\trial' num2str(trialNum,'%02.f') alphabet(p) '\' inputParams.expt_name];
        inputParams.filename = strrep(fileBase,'\','_');
        
        % save raw trial data !!
        save([inputParams.filename '_raw.mat'], 'rawData', 'rawOutput', 'inputParams','-v7.3');
        % move g4 log to data folder, if exists
        g4log_raw = dir([exp_path '\Log Files\G4_TDMS_Logs*']); %check for log
        if ~isempty(g4log_raw) %if exists, move log
            movefile(fullfile(g4log_raw.folder, g4log_raw.name), g4log_dir,'f');
        end
        disp(['Raw data for ' inputParams.pattern_name ' saved!']);
        
        % run, save, and plot processed trial data !!
        postExptRoutine(inputParams, rawData, rawOutput, settings);
        
    end
    
    % move g4 log to data folder, if exists
    g4log_raw = dir([exp_path '\Log Files\G4_TDMS_Logs*']); %check for log
    if ~isempty(g4log_raw) %if exists, move log
        movefile(fullfile(g4log_raw.folder, g4log_raw.name), g4log_dir,'f');
    end
    disp(['END OF TRIAL ' num2str(t)])
    
    
    
    % run again?
    %anotherOne = input('[INPUT] Run another trial (y/n) ', 's');
    
end


%kill displays
Panel_com('stop_display')
Panel_com('all_off')

%kill remaining command prompts
system('Taskkill/IM cmd.exe');
disp('Fictrac terminated')

end
