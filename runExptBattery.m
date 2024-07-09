% runExptBattery.m
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
% Updated:  01/02/2023 - MC converted from single to battery


function runExptBattery()
% clean up
close all

% clear function collectData() because it has persistent variable
clear collectData

% initialize persistent variables for this function
persistent cellDirPath trialNum;

% load constant settings
[dataDir, exptFnDir, settings] = ephysSettings();

% Asks whether this is a new cell
newCell = input('[INPUT] New Cell? (y/n): ', 's');


%% NEW CELL
if (~strcmpi(newCell, 'n'))
    %% set up new cell
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
    acclimateDur = input('[INPUT] Add acclimatization period? (min): ');
    acclimateN = 1; %counter
    acclimateFTMode = 2; % (0) OL with background, (1) CL with dark bar, (3) CL with bright bar
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
                close all
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
        if ~strcmpi(runPERout, 'n')
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
    cd(cellDirPath) % make sure we're in the cell directory

    %% prompt user to select an experiment

    disp('[INPUT] Select an experiment');
    exptSelected = 0;
    while ~exptSelected
        exptTypeFileName = uigetfile('*.m', 'Select an experiment', exptFnDir);
        % if user cancels or selects valid file
        if (exptTypeFileName == 0)
            disp('Selection cancelled');
            exptSelected = 1; % end loop
        elseif (contains(exptTypeFileName, '.m'))
            disp(['Experiment: ' exptTypeFileName]);
            exptSelected = 1; % end loop
        else
            disp('Select an experimental .m file or cancel');
            exptSelected = 0;
        end
    end

    % get name without .m
    exptTypeName = extractBefore(exptTypeFileName, '.');
    % convert selected experiment file into function handle
    exptFn = str2func(exptTypeName);

    inUseEphys = contains(exptTypeName,'ephys','IgnoreCase',true); %determine if ephys used
    inUseFictrac = contains(exptTypeName,'fictrac','IgnoreCase',true); %determine if fictrac used
    inUsePanels = contains(exptTypeName,'g4','IgnoreCase',true); %determine if panels used
    inUseStim = contains(exptTypeName,'stim','IgnoreCase',true); %determine if opto pulse used


    %% select a battery

    % select which battery to be run ahead of time
    fprintf(['\nBATTERY OPTIONS\n',...
        '(01) Vary sweep speed w/ dark bar \n',...
        '(02) Background only, alternating current and opto stimulation \n',...
        '(03) Motion pulse varying speed \n'...
        '(04) Motion pulse varying speed w/o stim \n' ...
        '(05) Stationary pulse \n'...
        '(06) Stationary pulse w/o stim \n'...
        '(07) Background only on/off \n'...
        '(08) Menotaxis\n' ...
        '(09) Background only, alternating opto stimulation\n'...
        '(10) Simple closed-loop\n'...
        '(11) Simple current injection\n'...
        '(12) Motion pulse extended range\n'...
        '(13) Motion pulse extended range w/o stim\n']);
    batterySelect = input('[INPUT] Select experimental battery: ');
    % then pull matching patterns and functions
    switch batterySelect
        case 1 %speed battery
            pattSelect = [2 2 2 2 2 2]; %same bar
            funcSelect = [6 5 105 6 7 8]; %same arc, VARY SPEED
            stimSelect = [0 1 1 1 1 1]; %1 break trial, stim rest
            trialDuration = 60; %sec, time of trial
            trialBreak = 10; %sec, break between trial
        case 2 %current injection
            pattSelect = [01 01 01 01]; %background
            funcSelect = [01 01 01 01]; %hold
            stimSelect = [00 00 01 01; 00 01 00 01]; %1 break trial, 1 stim trial
            trialDuration = 60; %sec, time of trial
            trialBreak = 0; %sec, break between trial
        case 3 % motion pulse w/stim
            pattSelect = ones(1,10)*2; %dark bar
            funcSelect = (108:117);
            stimSelect = ones(1,10); %stim for all trials
            trialDuration = 60; %sec, time of trial
            trialBreak = 5; %sec, break between trials
        case 4 % motion pulse w/o stim
            pattSelect = ones(1,10)*2; %dark bar
            funcSelect = (108:117);
            stimSelect = zeros(1,10); %stim for all trials
            trialDuration = 60; %sec, time of trial
            trialBreak = 5; %sec, break between trials
        case 5 % stationary pulse w/stim
            pattSelect = ones(1,10)*2; %dark bar
            funcSelect = (118:127);
            stimSelect = ones(1,10); %stim for all trials
            trialDuration = 38; %sec, time of trial
            trialBreak = 3; %sec, break between trials
        case 6 % stationary pulse w/o stim
            pattSelect = ones(1,10)*2; %dark bar
            funcSelect = (118:127);
            stimSelect = zeros(1,10); %stim for all trials
            trialDuration = 38; %sec, time of trial
            trialBreak = 3; %sec, break between trials
        case 7 %alternating background on/off
            pattSelect = 017; %background on/off
            funcSelect = 128; %alternate on/off
            stimSelect = 00; %no stim
            trialDuration = 10*60; %sec, time of trial
            trialBreak = 0; %sec, break between trials
        case 8 %menotaxis
            pattSelect = 06; %bright bar
            funcSelect = 00; %none
            stimSelect = 00; %no stim
            trialDuration = 12.5*60; %sec, time of trial
            trialBreak = 0; %sec, break between trials
        case 9 %background
            pattSelect = [01 01]; %background
            funcSelect = [01 01]; %hold
            stimSelect = [00 01]; %1 break trial, 1 stim trial
            trialDuration = 60; %sec, time of trial
            trialBreak = 0; %sec, break between trial
        case 10 %menotaxis
            pattSelect = 06; %bright bar
            funcSelect = 00; %none
            stimSelect = 00; %no stim
            trialDuration = 5*60; %sec, time of trial
            trialBreak = 0; %sec, break between trials
        case 11 %current injection
            pattSelect = 01; %background
            funcSelect = 01; %hold
            stimSelect = 00; %no stim
            trialDuration = 60; %sec, time of trial
            trialBreak = 0; %sec, break between trial
        case 12 % motion pulse extended range w/stim
            pattSelect = ones(1,10)*2; %dark bar
            funcSelect = (129:138);
            stimSelect = ones(1,10); %stim for all trials
            trialDuration = 87; %sec, time of trial
            trialBreak = 5; %sec, break between trials
        case 13 % motion pulse extended range w/o stim
            pattSelect = ones(1,10)*2; %dark bar
            funcSelect = (129:138);
            stimSelect = zeros(1,10); %stim for all trials
            trialDuration = 87; %sec, time of trial
            trialBreak = 5; %sec, break between trials
    end

    %% check relevant external dependencies
    cd(cellDirPath)

    % if fictrac, configure and start based on exeriment type (open/closed)
    if inUseFictrac
        %determine if open or closed loop experiment
        if contains(exptTypeName,'cl','IgnoreCase',true)
            ftMode = 2; %set closed-loop
        elseif contains(exptTypeName,'jumps','IgnoreCase',true)
            ftMode = 3; %set closed-loop WITH bar jumps
        else %default
            ftMode = 0; %set open-loop
        end
        startFicTrac(cellDirPath,ftMode)
    end

    % if g4, connect to display and check panels are working
    if inUsePanels
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
    if inUseEphys
        extCheck = input('[INPUT] Flip EXT CMD switch on...');
    end

    % if opto stim, reminder user to check ND filters
    if inUseStim
        if sum(stimSelect) > 0
            ndCheck = input('[INPUT] Check ND filters in place...');
        end
    end


    %% run experiment
    cd(cellDirPath)

    % general settings:
    batteryN = length(pattSelect);
    trialPerExpt = input('\n[INPUT] How many trials? (#) ');
    trialPerExpt = ceil(trialPerExpt/batteryN); %divide total trials by N battery variants
    %trialDuration = input('\n[INPUT] Duration of each trial? (sec) ');
    alpha = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'; %for denoting each battery variant

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

    % begin experiment trials
    while 1 %repeat expt until user breaks
        for te = 1:trialPerExpt

            % update trial number with each itteration
            if isempty(trialNum)
                trialNum = 1;
            else
                trialNum = trialNum + 1;
            end

            % RUN EXPERIMENT !!
            % randomize battery order for each trial
            subt = 1; %keeping track of sub trials
            for rp = randperm(length(pattSelect))
                pattN = pattSelect(rp); %pull this pattern
                funcN = funcSelect(rp); %pull this function
                stim = stimSelect(:,rp); %pull this stim
                varN = alpha(rp); %pull this variant letter
                disp(['Starting trial ' num2str(trialNum,'%02.f') ' subset ' num2str(subt) '/' num2str(batteryN) ' ' varN '...'])
                [rawData, inputParams, rawOutput] = exptFn(settings,trialDuration,pattN,funcN,stim);

                % SAVE RAW TRIAL DATA !!
                inputParams.filename = [baseFilename num2str(trialNum,'%02.f') varN];
                save([inputParams.filename '_raw.mat'], 'rawData', 'rawOutput', 'inputParams','-v7.3');
                fprintf('Raw data for trial %02d saved! \n', trialNum);

                % RUN POST TRIAL ROUTINE !!
                [exptData] = postExptRoutine(inputParams, rawData, rawOutput, settings);

                % if ephys, check and plot input resistance at the end of each trial
                if inUseEphys
                    InputR = measureInputResistance(settings); %measure
                    disp(['Input Resistance: ' num2str(round(InputR)) 'MOhms']);

                    checkInputR(subt,trialNum) = InputR; %store input resistance
                    if isfield(exptData,'scaledVoltage')
                        checkVm(subt,trialNum) = mean(exptData.scaledVoltage); %store resting vm
                    else
                        checkVm = 0;
                    end
                    checkSR(subt,trialNum) = mean(exptData.spikeRate); %store spike rate

                    plotPatchCheck(checkInputR,checkVm,checkSR)
                end
                subt=subt+1; %update counter
                pause(trialBreak) %break between trial
            end
         end

        % prompt user to select
        addTrial = input('\n[INPUT] Run another trial batch? (y/n): ','s');
        if strcmpi(addTrial, 'n')
            disp('Experiment ended by user.');
            close all
            break;
        end

    end

    %terminate external programs
    if inUsePanels
        Panel_com('stop_display');
        Panel_com('all_off');
        disconnectHost;
    end
    if inUseFictrac
        system('Taskkill/IM cmd.exe');
        disp('Fictrac terminated.')
    end



    %% INVALID INPUT, DON'T DO ANYTHING
else
    disp('[ERROR] Invalid input. Ending routine.');
    return;
end

end
