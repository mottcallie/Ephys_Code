% collectData.m
%
% Function to collect data from DAQ background acquisition into global
%  variable daqData. 
% Persistent variable whichInScan helps keep track of index
%  into daqData across calls to collectData
% Based off collectData() from Clandinin lab 2P-stim-code
%
% INPUTS:
%   src - as required by listener, session input argument
%   event - as required by listener, event input argument; has Data,
%       TimeStamps, and TriggerTime properties
%
% OUTPUTS:
%   none, but modifies global variable daqData and persistent variable 
%       whichInScan
%
% CREATED: 3/12/20 - HHY
%
% UPDATED:
%   3/12/20 - HHY
%

function collectData(src, event)
    % whichInScan keeps track of which scan for indexing into array
    persistent whichInScan
    global daqData % need to specify here to use global variable
    
    % initialize whichInScan on first run through
    if isempty(whichInScan)
        whichInScan = 1;
    end
    
    lengthData = length(event.Data); % length of new data
    
    % save data into daqData global variable, across all channels
    daqData(whichInScan:(whichInScan + lengthData - 1), :) = ...
        event.Data;
    
    % update whichInScan (start index of next batch of data
    whichInScan = whichInScan + lengthData;
end