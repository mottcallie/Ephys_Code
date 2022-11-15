% analyzeExpt_optomotor
%
% Analysis Function
% Pulls all processed files from a given optomotor assay
%
% INPUTS
% exptfolder - location of processed data files (cd if current)
% folderName - name of folder for saving files
%
% 10/22/2022 - MC adapted from chase analysis

function analyzeExpt_optomotor(exptFolder,folderName)
%% initialize
disp('STARTING ANALYSES FOR SELECTED EXPERIMENT...')
close all

cd(exptFolder) %jump to correct folder
% pull all file info
allFiles = dir('*pro.mat');
% remove any acclimate trials
allFiles(find(contains(string({allFiles.name}), 'Acclimate'))) = [];

% pull expt meta
load('metaDat.mat')

% set filename info and create necessary directories
filebase = [exptInfo.dateDir '_' exptInfo.flyDir ];
mainfolder = ['D:\' folderName];
cd(mainfolder)

intFolder = [mainfolder '\interpolated']; %for saving interpolated data
if ~exist(intFolder, 'dir')
    mkdir(intFolder)
end
plotFolder = [mainfolder '\plot']; %for saving plots
if ~exist(plotFolder, 'dir')
    mkdir(plotFolder)
end
dropboxFolder = ['C:\Users\wilson\Dropbox (HMS)\Data\' folderName]; %for saving data to dropbox
if ~exist(dropboxFolder, 'dir')
    mkdir(dropboxFolder)
end


%% load in dataset
disp('Loading in dataset...')
cd(exptFolder)

%initialize
allForward = [];
allSideways = [];
allAngular = [];
allPanelPos = [];
allSpikeRate = [];

% pull data by trial type
for e = 1:length(allFiles)
    
    % load in the file
    trialName = allFiles(e).name;
    load(trialName)

    % pool display data
    allPanelPos(:,e) = exptData.g4displayXPos;
    % pool velocity data
    allForward(:,e) = exptData.forwardVelocity;
    allSideways(:,e) = exptData.sidewaysVelocity;
    allAngular(:,e) = exptData.angularVelocity;
    % if ephys, pool spike rate data
    if contains(exptMeta.exptCond,'Ephys')
        allSpikeRate(:,e) = exptData.spikeRate;
    end

end
%pull timestamps from last trial
expttime = exptData.t;


%% interpolate (downsample) dataset
% optional, but dramatically increases analysis time
disp('Interpolating dataset...')
cd(intFolder)

nsp = size(allPanelPos,1); %rows correspond to number of sample points

% find pixel dwell time
px_change = find(ischange(allPanelPos(:,1))); %find when pixels change position
px_dwell = round(median(px_change(2:end)-px_change(1:end-1))); %find how long each pixel lasts

% downsample panel data to 1px position per data point
int_panelps_pre = interp1((1:nsp),allPanelPos,(1:px_dwell:nsp),'nearest');
midpoint = min(int_panelps_pre(10:end,1)) + (max(int_panelps_pre(10:end,1))-min(int_panelps_pre(1000:end,1)))/2;
int_panelps = int_panelps_pre-midpoint; %center to midpoint

% downsample velocity data
int_forward = interp1((1:nsp),allForward,(1:px_dwell:nsp),'linear');
int_angular = interp1((1:nsp),allAngular,(1:px_dwell:nsp),'linear');
int_sideway = interp1((1:nsp),allSideways,(1:px_dwell:nsp),'linear');
% downsample time data
int_time = interp1((1:nsp),expttime,(1:px_dwell:nsp),'linear');

% if ephys, downsample spikerate data
if contains(exptMeta.exptCond,'Ephys')
    int_spikerate = interp1((1:nsp),allSpikeRate,(1:px_dwell:nsp),'linear');

    % save interpolated dataset w/ephys
    save([filebase '_int.mat'], 'int_panelps', 'int_forward','int_angular','int_sideway','int_spikerate','int_time','-v7.3');
else
    % save interpolated dataset w/o ephys
    save([filebase '_int.mat'], 'int_panelps', 'int_forward','int_angular','int_sideway','int_time','-v7.3');
end

disp('Dataset processed and saved.')

%% plot directional velocity across full sweep
disp('Analyzing behavior during rotational sweeps...')
cd(plotFolder)

% run analysis pipeline w/o threshold
[~,~,~] = velocity_v_optomotor(int_panelps, int_forward,int_angular,int_sideway,int_time,chaseThreshold,optPlot);
sgtitle([strrep(filebase,'_','/') ' all'])
% save plot
plotname = ['fullsweep_all_' filebase '.png'];
saveas(gcf,plotname);
%copyfile(plotname, dropboxFolder,'f');

disp('Analyses of behavior during rotational sweeps complete.')


%% end
disp('ALL ANALYSES FOR THIS EXPERIMENT ARE COMPLETE.')
end

