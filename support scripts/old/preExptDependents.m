% preExptDependents
%
% Function that selects necessary prompts and dependencies depending on
% what kind of experiment is being run
%
% exptName - name of exeriment being run
%

function preExptDependents(exptName)

% if ephys, remind user to check ext. command switch on amplifier
if contains(exptName,'ephys','IgnoreCase',true)
    checkCmd = input('[INPUT] Flip EXT CMD switch on...');
end

% if fictrac, remind user to configure and start FicTrac
if contains(exptName,'fictrac','IgnoreCase',true)
    startFicTrac(cellDirPath)
end

% if using display, remind user to check if panels are working
if contains(exptName,'g4','IgnoreCase',true)
    disp('[NOTICE] Connecting to G4 display...');
    userSettings %load g4 settings and paths
    connectHost; %required, start g4 connection
    
    Panel_com('all_on');
    checkDisp = input('[INPUT] Check display is working...');
    Panel_com('all_off');
    
    delete([exp_path '\Log Files\*']) %clear log folder
    g4log_dir = fullfile(cellDirPath,'g4logs');
    if ~exist(g4log_dir, 'dir') %make g4 log dir if needed
        mkdir(g4log_dir)
    end
end

end

