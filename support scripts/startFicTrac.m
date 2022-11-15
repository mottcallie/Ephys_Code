% startFicTrac
%
% function for starting fictrac configuration, if not already configured,
% and launching fictrac/python, if not already running
%
% INPUTS
% cellDirPath - load in cell path to export config image
% ftMode - set to open (0) or closed (1) loop mode in fictrac
%
% Created: 11/05/2021 MC
% Updated: 04/20/2022 MC added open/closed loop alternatives

function startFicTrac(cellDirPath,ftMode)
%% configure fictrac
% only if it has not yet been configured for this experiment,
% as indicated by a moved configImg in the expt directory
if ~exist([cellDirPath '\fictrac-configImg.png'],'file')
    % start fictrac config
    fictracCfg = 'cd/ & cd /d C:\dev\fictrac\sample & ..\bin\Release\configGui.exe config_live.txt &';
    
    [~,~] = system(fictracCfg);
    check = input('[INPUT] Configure fictrac...');
    
    % move fictrac config image to data directory
    copyfile('C:\dev\fictrac\sample\fictrac-configImg.png', cellDirPath,'f');
else
    disp('Fictrac already configured for this experiment')
end

%% start fictrac
system('Taskkill/IM cmd.exe'); %terminate any previous fictrac windows

% launch fictrac gui
disp('Launching fictrac...');
fictracStart = 'cd/ & cd /d C:\dev\fictrac\sample & ..\bin\Release\fictrac.exe config_live.txt &';
[~,~] = system(fictracStart);

%select python script to run
switch ftMode
    case 0
        disp('MODE SELECTION: open-loop');
        socket_client = 'socket_client_360_ol'; %select open-loop
    case 1
        disp('MODE SELECTION: closed-loop - frame rate(4)');
        socket_client = 'socket_client_360_cl_mode4'; %select closed-loop, frame rate
    case 2
        disp('MODE SELECTION: closed-loop - frame index(7)');
        socket_client = 'socket_client_360_cl_mode7'; %select closed-loop, frame index
end

% start python script
disp(['Launching ' socket_client '...']);
pythonStart = ['cd/ & cd /d C:\dev\fictrac\scripts & python ' socket_client '.py &'];
[~,~] = system(pythonStart);

disp('Fictrac ready');

end

