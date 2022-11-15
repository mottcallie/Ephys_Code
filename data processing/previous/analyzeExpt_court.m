% analyzeExpt_court
%
% Analysis Function
% Pulls all processed files from a given courtship pursuit experiment in
% order to analyze the data
%
% INPUTS
% exptfolder - location of processed data files (cd if current)
% skipTrials - specify which trials, if any, to skip
%
% 05/24/22 MC

function analyzeExpt_court(exptFolder,skipTrials)

disp('STARTING ANALYSES FOR THIS EXPERIMENT...')
%close all

cd(exptFolder) %jump to correct foler

% pull all file info
allFiles = dir('*pro.mat');

% remove any acclimate trials
skip_idx = find(contains(string({allFiles.name}), 'acclimate'));
allFiles(skip_idx) = []; %remove
% remove skipped trials
if skipTrials
    for s = skipTrials
        skip_idx = find(contains(string({allFiles.name}), sprintf('trial%02d',s)));
        allFiles(skip_idx) = []; %remove
    end
end

% pull expt meta
load('metaDat.mat')
filebase = [exptInfo.dateDir '_' exptInfo.flyDir ];
dropboxfolder = 'C:\Users\wilson\Dropbox (HMS)\Data\Behavior';
%dropboxfolder = 'D:\Dropbox (HMS)\Data\Behavior';


%% load in and pool data
disp('Pooling experiment data...')

%initialize
allVoltage = [];
allSpikeRate = [];
allForward = [];
allSideways = [];
allAngular = [];
allPanelPos = [];

% pull data by trial type
for e = 1:length(allFiles)

    % load in the file
    trialName = allFiles(e).name;
    load(trialName)

    % pool data
    allVoltage(:,e) = exptData.scaledCurrent;
    allSpikeRate(:,e) = exptData.spikeRate;

    allForward(:,e) = exptData.forwardVelocity;
    allSideways(:,e) = exptData.sidewaysVelocity;
    allAngular(:,e) = exptData.angularVelocity;

    allPanelPos(:,e) = exptData.g4displayXPos;

end
%pull experiment time from last trial
expttime = exptData.t;

disp('Data pooled.')


%% plot each directional velocity histogram
disp('Plotting directional velocity histograms')
figure(1)
set(gcf,'Position',[100 100 1500 800])

nbins = 50;

subplot(3,1,1)
fwdmax = 12;
fwdedge = 0.5:0.5:fwdmax;
histogram(allForward(:,:),fwdedge,'FaceColor','#D95319','Normalization','probability')
xlim([0 fwdmax])
xlabel('forward velocity distribution (mm/s)')

subplot(3,1,2)
sidemax = 2.5;
sidedge = 0.1:0.1:sidemax;
histogram(abs(allSideways(:,:)),sidedge,'FaceColor','#7E2F8E','Normalization','probability')
xlim([0 sidemax])
xlabel('sideways velocity distribution (mm/s)')

subplot(3,1,3)
angmax = 180;
angedge = 4:6:angmax;
histogram(abs(allAngular(:,:)),angedge,'FaceColor','#0072BD','Normalization','probability')
xlim([0 angmax])
xlabel('angular velocity distribution (deg/s)')

sgtitle([strrep(filebase,'_',' ') ' - velocity histogram'])
%save
vvp_filebase1 = [filebase '_plot_velocityhistogram.png'];
saveas(gcf,vvp_filebase1);


%% velocity vs obj position
disp('Analyzing directional velocity vs object position...')

figure(2),clf;
set(gcf,'Position',[100 100 900 400])

% forward row 1
vo1(1) = subplot(1,3,1);
velocity_v_panelpos(allPanelPos,allForward,[])
ylabel('fwd vel (mm/s)')

% sideways row 2
vo1(2) = subplot(1,3,2);
velocity_v_panelpos(allPanelPos,allSideways,[])
ylabel('side vel (mm/s)')
xlabel('panel pos (deg)')

% angular row 3
vo1(3) = subplot(1,3,3);
velocity_v_panelpos(allPanelPos,allAngular,[])
ylabel('ang vel (deg/s)')

sgtitle([strrep(filebase,'_',' ') ' - velocity v sweep direction'])
linkaxes(vo1,'x');
%save
vvpt_filebase2 = [filebase '_plot_velocityvspanel.png'];
saveas(gcf,vvpt_filebase2);
disp('Analyses of directional velocity vs object position complete.')


disp('Analyzing directional velocity vs object position for fwd-velocity>0...')
figure(3),clf;
set(gcf,'Position',[100 100 900 400])

% remove points below threshold
thresh = 0.5;
allForward_thresh = allForward;
allForward_thresh(allForward<thresh) = NaN;
allSideways_thresh = allSideways;
allSideways_thresh(allForward<thresh) = NaN;
allAngular_thresh = allAngular;
allAngular_thresh(allForward<thresh) = NaN;

% forward row 1
vo2(1) = subplot(1,3,1);
velocity_v_panelpos(allPanelPos,allForward_thresh,[])
ylabel('fwd vel (mm/s)')

% sideways row 2
vo2(2) = subplot(1,3,2);
velocity_v_panelpos(allPanelPos,allSideways_thresh,[])
ylabel('side vel (mm/s)')
xlabel('panel pos (deg)')

% angular row 3
vo2(3) = subplot(1,3,3);
velocity_v_panelpos(allPanelPos,allAngular_thresh,[])
ylabel('ang vel (deg/s)')

sgtitle([strrep(filebase,'_',' ') ' - velocity v sweep direction (fwd>0)'])
linkaxes(vo2,'x')
%save
vvpt_filebase = [filebase '_plot_velocityvspanel_thresh.png'];
saveas(gcf,vvpt_filebase);
disp('Analyses of directional velocity vs object position for fwd-velocity>0 complete.')


%% cell acivity vs obj position
disp('Analyzing cell activity vs object position...')

figure(4),clf;
set(gcf,'Position',[100 100 700 400])

% spikerate vs object position
ao(1) = subplot(1,2,1);
% remove trials with low/no spiking
minSR = 1; %spikes/sec
srIdx = mean(allSpikeRate)>minSR;
% run analysis
spike_v_panelpos(allPanelPos(:,srIdx),allSpikeRate(:,srIdx),[])
ylabel('spikerate (spike/sec)')

% membrane potential vs object position
ao(2) = subplot(1,2,2);
% run analysis
vm_v_panelpos(allPanelPos,allVoltage,[])
ylabel('voltage (mV)')

sgtitle([strrep(filebase,'_',' ') ' - cell activity v sweep direction'])
linkaxes(ao,'x')

%save
vvpt_filebase2 = [filebase '_plot_activityvspanel.png'];
saveas(gcf,vvpt_filebase2);
disp('Analyses of cell activity vs object position complete.')


%% cell acivity vs obj position, scatter plot
disp('Analyzing cell activity vs directional velocity via scatter...')

figure(4),clf;
set(gcf,'Position',[100 100 900 400])

av(1) = subplot(1,3,1);
spike_v_velocity_scatter(allSpikeRate,allForward,[])
ylabel('spikerate (spike/sec)')
xlabel('fwd vel (mm/s)')

av(2) = subplot(1,3,2);
spike_v_velocity_scatter(allSpikeRate,allAngular,[])
xlabel('ang vel (deg/s)')

av(3) = subplot(1,3,3);
spike_v_velocity_scatter(allSpikeRate,allSideways,[])
xlabel('side vel (mm/s)')

sgtitle([strrep(filebase,'_',' ') ' - cell activity v directional velocity'])
linkaxes(av,'y')

%save
avv_filebase = [filebase '_scatter_activityvsvelocity.png'];
saveas(gcf,avv_filebase);

% calculate change in firing rate
columnMeansSR = mean(allSpikeRate); %calculate column means
columnMeansSR_ext = repmat(columnMeansSR,length(allSpikeRate),1); %extend
allSpikeRate_d = allSpikeRate - columnMeansSR_ext; %subtract to get difference

figure(5),clf;
set(gcf,'Position',[100 100 900 400])

av2(1) = subplot(1,3,1);
spike_v_velocity_scatter(allSpikeRate_d,allForward,[])
ylabel('spikerate (spike/sec)')
xlabel('fwd vel (mm/s)')

av2(2) = subplot(1,3,2);
spike_v_velocity_scatter(allSpikeRate_d,allAngular,[])
xlabel('ang vel (deg/s)')

av2(3) = subplot(1,3,3);
spike_v_velocity_scatter(allSpikeRate_d,allSideways,[])
xlabel('side vel (mm/s)')

sgtitle([strrep(filebase,'_',' ') ' - firing change v directional velocity'])
linkaxes(av2,'y')

%save
avv2_filebase = [filebase '_scatter_dactivityvsvelocity.png'];
saveas(gcf,avv2_filebase);
disp('Analyses of cell activity vs directional velocity via scatter complete.')



%% cell acivity vs obj position, heatmap plot
disp('Analyzing cell activity vs directional velocity via heatmap...')

figure(6),clf;
set(gcf,'Position',[100 100 1000 500])

av(1) = subplot(1,2,1);
spike_v_velocity(allSpikeRate,allForward,allSideways,1)

av(2) = subplot(1,2,2);
spike_v_velocity(allSpikeRate,allForward,allAngular,2)

sgtitle([strrep(filebase,'_',' ') ' - cell activity v directional velocity'])

%save
avv_filebase = [filebase '_heat_activityvsvelocity.png'];
saveas(gcf,avv_filebase);

figure(7),clf;
set(gcf,'Position',[100 100 1000 500])

av(1) = subplot(1,2,1);
spike_v_velocity(allSpikeRate_d,allForward,allSideways,1)

av(2) = subplot(1,2,2);
spike_v_velocity(allSpikeRate_d,allForward,allAngular,2)

sgtitle([strrep(filebase,'_',' ') ' - firing change v directional velocity'])

%save
avv_filebase = [filebase '_heat_dactivityvsvelocity.png'];
saveas(gcf,avv_filebase);


%% end
disp('ALL ANALYSES FOR THIS EXPERIMENT ARE COMPLETE.')
end

