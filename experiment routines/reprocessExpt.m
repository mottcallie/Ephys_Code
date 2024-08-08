% reprocessExpt
% Function that pulls all raw files from a given experiment and
% re-processes them. To be used if for whatever reason one needs to change
% the post-experiment routine and apply changes across multiple files.
%
% INPUTS
% exptfolder - location of raw data files
%
% ORIGINAL  11/11/2021 MC
%

function reprocessExpt(exptFolder)

% load ephys settings
[~, ~, settings] = ephysSettings();

disp('Re-processing data...')
% pull all raw files from the experiment folder of interest
cd(exptFolder)
close all
rawFiles = dir('*raw.mat');
rawFiles(contains(string({rawFiles.name}), 'Acclimate')) = [];
rawFiles(contains(string({rawFiles.name}), 'acclimate')) = [];

% for each raw file
for e = 1:length(rawFiles)
    % ensure folder is correct
    cd(exptFolder)
    % load in the file
    load(rawFiles(e).name)
    
    % re-run post experiment routine
    [~] = postExptRoutine(inputParams, rawData, rawOutput, settings);
    
end

copyfile('metaDat.mat', [exptFolder '_processed'],'f');

disp('Data re-processed successfully')
end

