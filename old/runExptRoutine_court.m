% runExptRoutine_court.m
%
% Top level function for running 1 or more trials of a pre-determined courtship
% electrophysiology experiment.
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


function runExptRoutine_court()
% clean up
close all

% initialize persistent variables for this function
persistent cellDirPath trialNum;

% load constant settings
[dataDir, ~, settings] = ephysSettings();

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
    currFlyDirs = dateDirContents(contains({dateDirContents.name},'fly')& ~contains({dateDirContents.name},'processed'));
    
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
        metaDatPath = [currCellDirs.folder filesep ...
            currCellDirs.name filesep 'metaDat.mat'];
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
    currCellDirs = flyDirContents(contains({flyDirContents.name}, 'cell') & ~contains({flyDirContents.name}, 'processed'));
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
    
    
    
    %% **ASKS TO RUN PRE-EXPT ROUTINES**
    while 1
        runPERout = input('\n[INPUT] Run pre-experimental routines? (y/n): ', 's');
        if strcmpi(runPERout, 'y')
            preExptData = preExptRoutine(settings);
            
            % save pre-expt data !!
            save('preExptData.mat', 'preExptData', '-v7.3');
            
            % asks about running pre-experimental routine again
            runPERagain = input('\n[INPUT] Run pre-experimental routines again? (y/n): ','s');
            if ~strcmpi(runPERagain, 'y')
                disp('Pre-experimental routine was not run again.');
                break;
            end
            
        else
            disp('Pre-experimental routine was not run.');
            break;
        end
    end
    
    
    
    %% NOT A NEW CELL
elseif (strcmpi(newCell, 'n'))
    
    cd(cellDirPath)
    
    %% remind user to check relevant external dependencies
    % if ephys, remind user to check ext. command switch on amplifier
    check1 = input('[INPUT] Flip EXT CMD switch on...');
    
    % if fictrac, remind user to configure and start FicTrac
    startFicTrac(cellDirPath)
    
    % if using display, remind user to check if panels are working
    disp('[NOTICE] Connecting to G4 display...');
    userSettings %load g4 settings and paths
    connectHost; %required, start g4 connection
    
    Panel_com('all_on');
    check2 = input('[INPUT] Check display is working...');
    Panel_com('all_off');
    
    delete([exp_path '\Log Files\*']) %clear log folder
    g4log_dir = fullfile(cellDirPath,'g4logs');
    if ~exist(g4log_dir, 'dir') %make g4 log dir if needed
        mkdir(g4log_dir)
    end
        
    
        
    %% run experiment
    cd(cellDirPath)
    
    duration = 1;
    stepAmp = 100; %current step (100pA max), pA
    nSteps = 6; %number of current steps to deliver per trial
    
    % prompt user to select trial type
    fprintf('0-end \n1-75  high \n2-75  low \n3-180 high \n4-180 low \n5-360 high \n6-360 low \n')
    trialtype = input('[INPUT] Which experiment would you like to run: ');
    switch trialtype
        case 0
            disp('No experiment selected, ending experiment...')
        case 1 %75 high
            pattSelect = [4, 5, 7, 9, 11];
            funcSelect = 8;
        case 2 %75 low
            pattSelect = [4, 6, 8, 10, 12];
            funcSelect = 8;
        case 3 %180 high
            pattSelect = [4, 5, 7, 9, 11];
            funcSelect = 12;
        case 4 %180 low
            pattSelect = [4, 6, 8, 10, 12];
            funcSelect = 12;        
        case 5 %360 high
            pattSelect = [4, 5, 7, 9, 11];
            funcSelect = 20;
        case 6 %360 low
            pattSelect = [4, 6, 8, 10, 12];
            funcSelect = 20;
    end

    while trialtype > 0 %repeat expt until user breaks      
        
        % load remaining g4 parameters
        mode = 1; %pos change func
        pattTot = length(pattSelect); %total n
    
        % update trial number with each itteration
        if isempty(trialNum)
            trialNum = 1;
        else
            trialNum = trialNum + 1;
        end
        
        %check input resistance at the start of every trials
        inputResistance = measureInputResistance(settings);
        disp(['[NOTICE] Initial input Resistance is ' num2str(round(inputResistance)) ' MOhms']);
        
        
        for p = randperm(pattTot) %randomize order
            % run experiment !!
            pattCurrent = pattSelect(p);
            [rawData, inputParams, rawOutput] = recordG4PanelsFictracEphys_set(settings,pattCurrent,funcSelect,mode,duration);
            
            % set filename
            fileBase = erase(cellDirPath,dataDir);
            fileBase = [fileBase '\trial' num2str(trialNum,'%02.f') '\' inputParams.pattern_name];
            inputParams.filename = strrep(fileBase,'\','_');
            
            % save raw trial data !!
            inputParams.inputResistance = inputResistance; % store
            save([inputParams.filename '_raw.mat'], 'rawData', 'rawOutput', 'inputParams','-v7.3');
            % move g4 log to data folder, if exists
            g4log_raw = dir([exp_path '\Log Files\G4_TDMS_Logs*']); %check for log
            if ~isempty(g4log_raw) %if exists, move log
                movefile(fullfile(g4log_raw.folder, g4log_raw.name), g4log_dir,'f');
            end
            fprintf('[NOTICE] Raw data for trial %02d saved! \n', trialNum);
            
            % run, save, and plot processed trial data !!
            postExptRoutine(inputParams, rawData, rawOutput, settings);
            
        end
        
        % run current inject experiment !!
        [rawData, inputParams, rawOutput] = recordG4PanelsFictracEphys_iinj(settings, stepAmp, nSteps);
        % set filename
        fileBase = erase(cellDirPath,dataDir);
        fileBase = [fileBase '\trial' num2str(trialNum,'%02.f') '\' inputParams.stepName];
        inputParams.filename = strrep(fileBase,'\','_');
        
        % save raw trial data !!
        inputParams.inputResistance = inputResistance; % store
        save([inputParams.filename '_raw.mat'], 'rawData', 'rawOutput', 'inputParams','-v7.3');
        % move g4 log to data folder, if exists
        g4log_raw = dir([exp_path '\Log Files\G4_TDMS_Logs*']); %check for log
        if ~isempty(g4log_raw) %if exists, move log
            movefile(fullfile(g4log_raw.folder, g4log_raw.name), g4log_dir,'f');
        end
        fprintf('[NOTICE] Raw data for trial %02d saved! \n', trialNum);
        
        % run, save, and plot processed trial data !!
        postExptRoutine(inputParams, rawData, rawOutput, settings);
        
        
        
        % run again?
        fprintf('0-end \n1-75  high \n2-75  low \n3-180 high \n4-180 low \n5-360 high \n6-360 low \n')
        trialtype = input('[INPUT] Run another trial? Which experiment: ');
        switch trialtype
            case 0
                disp('No experiment selected, ending experiment...')
                break
            case 1 %75 high
                pattSelect = [4, 5, 7, 9, 11];
                funcSelect = 4;
            case 2 %75 low
                pattSelect = [4, 6, 8, 10, 12];
                funcSelect = 4;
            case 3 %180 high
                pattSelect = [4, 5, 7, 9, 11];
                funcSelect = 8;
            case 4 %180 low
                pattSelect = [4, 6, 8, 10, 12];
                funcSelect = 8;
            case 5 %360 high
                pattSelect = [4, 5, 7, 9, 11];
                funcSelect = 10;
            case 6 %360 low
                pattSelect = [4, 6, 8, 10, 12];
                funcSelect = 10;
        end
        
    end
    
    %kill displays
    Panel_com('stop_display')
    Panel_com('all_off')
    
    %kill remaining command prompts
    system('Taskkill/IM cmd.exe');
    disp('Fictrac terminated')
    
    
    
    %% INVALID INPUT, DON'T DO ANYTHING
else
    disp('[ERROR] Invalid input. Ending runEphysExpt()');
    return;
end

end
