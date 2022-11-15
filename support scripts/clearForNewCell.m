% clearForNewCell.m
%
% Function to clear persistent and global variables used in runEphysExpt()
%  so that a new cell starts fresh
%
% CREATED: 3/11/20 - HHY
%
% UPDATED: 
%   3/11/20 - HHY
%   3/22/20 - HHY added global variable firstLegVidTrial

function clearForNewCell()

    clear runEphysExpt % has persistent variables cellDirPath, trialNum
    clear collectData % has persistent variable whichInScan
    % restart binary for whether leg vid has been intialized
    clear global firstLegVidTrial   
end