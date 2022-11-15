%analyzeKernel.m
% function that returns the linear filter and autocorrelations for 1 fly
%
% INPUTS
% exptfolder - location of all processed data files
%
% OUTPUTS
%
% MODIFIED FROM: HHY
% CREATED: 09/16/2022 MC
%

function [outputArg1,outputArg2] = analyzeKernel(exptFolder)
%% initialize
disp('STARTING KERNEL ANALYSIS FOR SELECTED EXPERIMENT...')
close all

% get experiment file info
cd(exptFolder)              %jump to folder
allFiles = dir('*pro.mat'); %find all processed files
allFiles(find(contains(string({allFiles.name}), 'Acclimate'))) = []; %remove acclimation trials

% set file and folder names for later
paths = split(exptFolder,'\');
filebase = [paths{3} '_' paths{4}]; %experiment name
mainfolder = [paths{1} '\' paths{2}]; %local folder
dropboxfolder = ['C:\Users\wilson\Dropbox (HMS)\Data\' paths{2}]; %dropbox folder

% set sample rate
sampRate=500;


%% load in dataset
disp('Loading in dataset...')

%initialize
allForward = [];
allSideways = [];
allAngular = [];
allSpikeRate = [];

% pull data by trial type
for e = 1:length(allFiles)
    
    % load in the file
    trialName = allFiles(e).name;
    load(trialName)

    % pool velocity data
    allForward(:,e) = exptData.forwardVelocity;
    allSideways(:,e) = exptData.sidewaysVelocity;
    allAngular(:,e) = exptData.angularVelocity;
    % pool spike rate data
    allSpikeRate(:,e) = exptData.spikeRate;

end
%pull timestamps from last trial
expttime = exptData.t;

%% interpolate (downsample) dataset
disp('Interpolating dataset...')

nsp = size(allSpikeRate,1); %rows correspond to number of sample points
rs = 20e3/sampRate; %resample value to convert from 20e3Hz to 1000Hz

% downsample velocity data
int_forward = interp1((1:nsp),allForward,(1:rs:nsp),'linear');
int_angular = interp1((1:nsp),allAngular,(1:rs:nsp),'linear');
int_sideway = interp1((1:nsp),allSideways,(1:rs:nsp),'linear');
% downsample ephys data
int_spikerate = interp1((1:nsp),allSpikeRate,(1:rs:nsp),'linear');
% downsample time data
int_time = interp1((1:nsp),expttime,(1:rs:nsp),'linear');

disp('Dataset loaded and processed.')


% extract kernel
disp('Extracting kernel...')
% kernel parameters
winLen = 1;
cutFreq = 10;
tauFreq = 5;

% pull only data where fly is moving
restIdx = find(int_forward<0.5);
int_forward(restIdx)=NaN;
int_angular(restIdx)=NaN;
int_sideway(restIdx)=NaN;
%int_spikerate=int_spikerate(randperm(length(int_spikerate)),:);
int_spikerate(restIdx)=NaN;

input=reshape(int_spikerate(:,1:10),[],1);
output=reshape(int_forward(:,1:10),[],1);

[kernel, lags, numSeg] = computeWienerKernel(input, output, sampRate, winLen, cutFreq, tauFreq);

plot(lags,kernel)
xline(0)


end