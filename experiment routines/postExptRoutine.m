% postExptRoutine.m
%
% Function that (1) calls fx to preprocess raw DAQ data into useable
%  variables, (2) calls fx to process each ephys and behavior variables to
%  ensure that each has been properly converted/scaled, and (3) calls fx to
%  plot data based on the experiment conducted.
%
% INPUTS:
%   inputParams - input parameters from trial function (e.g. ephysRecording)
%   rawData - raw signal input from DAQ during experiment
%   rawOutput - raw signal output to DAQ (current inject) during experiment 
%   settings - settings struct from ephysSettings
%
% Original: 04/02/2021 - MC
% Updated:  11/12/2021 - MC added pro to filename for easier calling
%           07/31/2025 - MC moved firing rate convolution to processExptData
%


function [exptData] = postExptRoutine(inputParams, rawData, rawOutput, settings)
    %% initialize
    % setup directories
    currentFolder = cd;
    processFolder = [currentFolder '_processed'];
    if ~exist(processFolder, 'dir')
        mkdir(processFolder)
        % move meta file over
        copyfile('metaDat.mat', processFolder,'f');
    end
    cd(processFolder);


    %% Processes raw data
    disp('Processing data...');
    % process raw daq data
    [daqData, daqOutput, daqTime] = preprocessUserDaq(inputParams, rawData, rawOutput, settings);
    % process daq data based on respective experiments
    [exptData, exptMeta] = processExptData(daqData, daqOutput, daqTime, inputParams, settings);

    % save processed trial data
    save([inputParams.filename '_pro.mat'], 'exptData', 'exptMeta', '-v7.3');
    disp('Processed data saved!');
    

    %% Plot processesed data
    disp('Plotting data...');
    % plot based on experiment type
    plotExpt(exptData,exptMeta)
    sgtitle(strrep(inputParams.filename,'_',' '))

    % save plot of trial data
    saveas(gcf,[inputParams.filename '_plot.png']);
    disp('Plotted data saved!');
    cd(currentFolder)


end