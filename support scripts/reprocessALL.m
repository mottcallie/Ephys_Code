% one script to re-process them all

% initialize
clear
close all

% pull file names
cd('D:\')
expt_tracker = readtable('Battery_Tracker.xlsx','Sheet',1); %load all expts
% for each included expt, pull the full file path
for et = 1:height(expt_tracker)
    day = expt_tracker.Date(et);
    fly = sprintf('fly%02d',expt_tracker.Fly(et));

    % load in main data set
    cell = sprintf('cell%02d',expt_tracker.Cell(et));
    exptFolders{et,1} = fullfile('D:',day,fly,cell);
end

% re-process each file
for e = 1:length(exptFolders)
    thisFolder = exptFolders{e};
    reprocessExpt(thisFolder{1})
    
    disp(['Experiment ' num2str(e) ' re-processed and re-analyzed'])
end

close all