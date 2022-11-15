% runExptRoutine_battery.m
%
% Top level function for running 1 or more trials of MULTIPLE electrophysiology experiment.
%
% Sets up folder structure for organizing data (date/fly/cell),
%  prompts whether this is new cell or additional trial(s) for cell. For
%  new cell, prompts for experimental condition, asks to run pre-expt
%  routines (pipette resistance, seal test, etc.), and runs through
%  experimental trials until no more new trials. For same cell (in case
%  previous run of runEphysExpt stopped unexpectedly), can run additional
%  trials.
%
% Original: 01/30/2021 - HY
% Updated:  06/09/2021 - MC improved reminders, inputR check
%           07/02/2021 - MC added repeat trial function
%           11/01/2021 - MC updated for G4 display system
%           03/14/2022 - MC general updated
%           05/25/2022 - MC increased resistance checks, added additional
%                           pre-experiment acclimatization blocks


function runExptRoutine_battery()
% clean up
close all

% clear function collectData() because it has persistent variable
% whichInScan that can't be persistent across different trials
clear collectData

% initialize persistent variables for this function
persistent cellDirPath trialNum;

% load constant settings
[dataDir, exptFnDir, settings] = ephysSettings();

% Asks whether this is a new cell
newCell = input('[INPUT] New Cell? (y/n): ', 's');


%% NEW CELL
if (strcmpi(newCell, 'y'))
    % clear functions and persistent and global variables for new cell
    clear collectData % has persistent variable whichInScan

    % reset values of persistent variables
    cellDirPath = [];
    trialNum = [];

    % asks for description of the cell
    cellUserTxt = input('\n[INPUT] Which cell is this? ', 's');

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
    currFlyDirs = dateDirContents(...
        contains({dateDirContents.name},'fly'));

    % asks whether this is a new fly
    newFly = input('\n[INPUT] New Fly? (y/n): ', 's');
    if (strcmpi(newFly, 'n')) % NOT A NEW FLY
        flyNum = length(currFlyDirs);

        if (flyNum == 0)
            flyNum = 1;
            flyDirName = sprintf('fly%02d',flyNum); % fly folder name
            mkdir(flyDirName);
        else
            flyDirName = sprintf('fly%02d',flyNum); % fly folder name
        end

        % go to fly directory
        cd(flyDirName);
        flyDirPath = pwd;

        % load fly metadata from previous cell
        flyDirContents = dir(flyDirPath);
        currCellDirs = flyDirContents(...
            contains({flyDirContents.name}, 'cell'));
        % path to metadata file of last cell for this fly
        metaDatPath = [currCellDirs(end).name filesep 'metaDat.mat'];
        % load fly metadata
        load(metaDatPath, 'flyData');
    else % NEW FLY (this is default)
        flyNum = length(currFlyDirs) + 1;
        flyDirName = sprintf('fly%02d',flyNum); % fly folder name

        % creates fly folder in date directory
        mkdir(flyDirName); % make fly folder

        % go to fly directory
        cd(flyDirName);
        flyDirPath = pwd;

        % request fly metadata
        flyData = getFlyMetadata(dateDirName, flyDirName);
    end

    % create new cell folder
    % existing cells for this fly
    flyDirContents = dir(flyDirPath);
    currCellDirs = flyDirContents(contains({flyDirContents.name}, 'cell'));
    currCellDirs(contains({currCellDirs.name}, 'processed'))=[];
    cellNum = length(currCellDirs) + 1;
    cellDirName = sprintf('cell%02d', cellNum); % cell folder name
    % create cell folder
    mkdir(cellDirName);

    % go to cell directory
    cd(cellDirName);
    cellDirPath = pwd;

    % generate basic experimental info struct
    exptInfo.cellInfo = cellUserTxt;
    exptInfo.dateDir = dateDirName;
    exptInfo.flyDir = flyDirName;
    exptInfo.cellDir = cellDirName;
    exptInfo.exptDate = datestr(now, 'yymmdd');
    exptInfo.exptStartTime = datestr(now, 'HH:MM:SS');

    % save settings, fly metadata, experimental info to file
    save('metaDat.mat', 'flyData', 'settings', 'exptInfo', '-v7.3');


    %% **ASKS TO RUN PRE-PRE-EXPT ACCLIMITIZATION PERIOD**
    % if using display, remind user to check if panels are working


    % Asks whether to include acclimatization block, then runs until user declines
    acclimateDur = input('[INPUT] Add acclimatization period? (0/Xmin): ');
    acclimateN = 1; %counter
    acclimateFTMode = 2; %open(0) or closed(2) loop
    while 1
        if ~isempty(acclimateDur) && acclimateDur>0
            % connect display during first run
            if acclimateN==1
                disp('[NOTICE] Connecting to G4 display...');
                connectHost; %required
                Panel_com('all_on'); %turn on
                checkPanels = input('[INPUT] Check display is working...');
                Panel_com('all_off'); %turn off

                %make g4 log dir if needed
                g4log_dir = fullfile(cellDirPath,'g4logs');
                if ~exist(g4log_dir, 'dir')
                    mkdir(g4log_dir)
                end
            end
            % configure/start fictrac
            startFicTrac(cellDirPath,acclimateFTMode)

            % begin acclimatization block
            [rawData, inputParams, rawOutput] = runAcclimatization(settings,acclimateDur*60,acclimateFTMode);
            % save and process pre-pre-expt data !!
            inputParams.filename = ['prepreExptAcclimate_' num2str(acclimateN)];
            save([inputParams.filename '_raw.mat'], 'rawData', 'inputParams','-v7.3');
            [~] = postExptRoutine(inputParams, rawData, rawOutput, settings);

             % asks about running another acclimatization block
            runAcclimateAgain = input('\n[INPUT] Run another acclimatization? (y/n): ','s');
            acclimateN = acclimateN+1; %update counter
            if ~strcmpi(runAcclimateAgain, 'y')
                disp('Acclimatization was not run again.');
                % close fictrac prior to main expt
                system('Taskkill/IM cmd.exe');
                disp('Fictrac terminated.')
                Panel_com('all_off');
                disconnectHost
                break;
            end
            
        else
            disp('Acclimatization was not run.');
            break;
        end
    end


    %% **ASKS TO RUN PRE-EXPT PATCHING ROUTINE**
    runPERout = input('\n[INPUT] Run pre-experimental patching routine? (y/n): ', 's');
    while 1
        if strcmpi(runPERout, 'y')
            preExptData = preExptRoutine(settings);

            % save pre-expt data !!
            save('preExptData.mat', 'preExptData', '-v7.3');

            % asks about running pre-experimental routine again
            runPERagain = input('\n[INPUT] Run pre-experimental patching routine again? (y/n): ','s');
            if ~strcmpi(runPERagain, 'y')
                disp('Pre-experimental patching routine was not run again.');
                break;
            end

        else
            disp('Pre-experimental patching routine was not run.');
            break;
        end
    end


    %% NOT A NEW CELL
elseif (strcmpi(newCell, 'n'))
    %% select an experiment
    % experiment name
    exptTypeName = 'batteryG4PanelsFictracEphys';

    batterySelect = 2;
    switch batterySelect
        case 1 %bar battery
            change = 'pattern';
            pattSelect = [09 10 11 12 13 14 15 16 02 03];
            funcSelect = [17 18 20 22 17 18 20 22 09 09];
        case 2 %box battery
            change = 'pattern';
            pattSelect = [17 18 19 20 21 22 23 24 25 26 27 28];
            funcSelect = [19 20 21 19 20 21 19 20 21 19 20 21];
    end

    % pull display meta data for each selection
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

    % save display meta data
    save('panelDat.mat', 'dispInfo', '-v7.3');


    %% check relevant external dependencies
    cd(cellDirPath)

    % if fictrac, configure and start based on exeriment type (open/closed)
    if contains(exptTypeName,'fictrac','IgnoreCase',true)
        ftMode = 0; %set open-loop
        startFicTrac(cellDirPath,ftMode)
    end

    % if g4, connect to display and check panels are working
    if contains(exptTypeName,'g4','IgnoreCase',true)
        disp('[NOTICE] Connecting to G4 display...');
        connectHost; %required
        Panel_com('all_on'); %turn on
        checkPanels = input('[INPUT] Check display is working...');
        Panel_com('all_off'); %turn off

        %make g4 log dir if needed
        g4log_dir = fullfile(cellDirPath,'g4logs');
        if ~exist(g4log_dir, 'dir')
            mkdir(g4log_dir)
        end
    end    
    
    % if ephys, remind user to check ext. command switch on amplifier
    if contains(exptTypeName,'ephys','IgnoreCase',true)
        extCheck = input('[INPUT] Flip EXT CMD switch on...');
    end


    %% run experiment
    cd(cellDirPath)

    % general settings:
    trialDuration = 0.5; %min
    trialPerExpt = 20; %total
    alpha = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    % set necessary filepaths
    baseFilename = strrep([erase(cellDirPath,dataDir) '\trial'],'\','_'); %set filename
    pc_file = fullfile(cellDirPath,'patchcheck.mat');
    if exist(pc_file,'file')
        load('patchcheck.mat','checkVm','checkInputR','checkSR')
    else
        checkInputR=[];
        checkVm=[];
        checkSR=[];
    end

    while 1 %repeat expt until user breaks
        for tb = 1:trialPerExpt

            % update trial number with each itteration
            if isempty(trialNum)
                trialNum = 1;
            else
                trialNum = trialNum + 1;
            end

            % randomize pattern order
            for rp = randperm(length(pattSelect))
                pattCurrent = pattSelect(rp);
                funcCurrent = funcSelect(rp);

                % RUN EXPERIMENT !!
                disp(['[NOTICE] Starting ' exptTypeName ' experiment...'])
                [rawData, inputParams, rawOutput] = batteryG4PanelsFictracEphys(settings,pattCurrent,funcCurrent,trialDuration*60);

                % SAVE RAW TRIAL DATA !!
                inputParams.filename = [baseFilename num2str(trialNum,'%02.f') alpha(rp) '_' dispInfo.pattNames{rp}];
                save([inputParams.filename '_raw.mat'], 'rawData', 'rawOutput', 'inputParams','-v7.3');
                fprintf('[NOTICE] Raw data for trial %02d saved! \n', trialNum);

                % RUN POST TRIAL ROUTINE !!
                [exptData] = postExptRoutine(inputParams, rawData, rawOutput, settings);

            end

            % if ephys, check and plot input resistance at the end of each trial block
            if contains(exptTypeName,'ephys','IgnoreCase',true)
                InputR = measureInputResistance(settings); %measure
                disp(['Input Resistance: ' num2str(round(InputR)) 'MOhms']);

                checkInputR(trialNum) = InputR; %store input resistance
                if isfield(exptData,'scaledVoltage')
                    checkVm(trialNum) = mean(exptData.scaledVoltage); %store resting vm
                else
                    checkVm = 0;
                end
                checkSR(trialNum) = mean(exptData.spikeRate); %store spike rate
                
                plotPatchCheck(checkInputR,checkVm,checkSR)

            end

        end

        % prompt user to select
        addTrial = input('\n[INPUT] Run another trial batch? (y/n): ','s');
        if strcmpi(addTrial, 'n')
            disp('Experiment ended by user.');
            break;
        end

    end
    
    %terminate external programs
    if contains(exptTypeName,'g4','IgnoreCase',true) %g4 display
        Panel_com('stop_display');
        Panel_com('all_off');
        disconnectHost;
    end
    if contains(exptTypeName,'fictrac','IgnoreCase',true) %fictrac
        system('Taskkill/IM cmd.exe');
        disp('Fictrac terminated.')
    end



    %% INVALID INPUT, DON'T DO ANYTHING
else
    disp('[ERROR] Invalid input. Ending routine.');
    return;
end

end
