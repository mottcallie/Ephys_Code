% one script to re-process them all

% initialize
clear
close all

% pull file names
cd('D:\')
expt_tracker = readtable('Battery_Tracker.xlsx','Sheet',4); %load all expts
e = 1;
% for each included expt, pull the full file path
for et = 1:height(expt_tracker)
    day = expt_tracker.Date(et);
    fly = sprintf('fly%02d',expt_tracker.Fly(et));
    cell = sprintf('cell%02d',expt_tracker.Cell(et));
    include = expt_tracker.Include(et);

    % load in path
    if include
        exptFolders{e,1} = fullfile('D:',day,fly,cell);
        e = e+1; %update counter
    end
end

% re-process each file
for e = 1:length(exptFolders)
    thisFolder = exptFolders{e};
    reprocessExpt(thisFolder{1})
    
    disp(['Experiment ' num2str(e) ' re-processed and re-analyzed'])
end

close all