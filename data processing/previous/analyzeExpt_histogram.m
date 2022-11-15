% analyzeExpt_histogram
%
% Analysis Function
% Pulls all processed files from a given experiment and plots velocity
% histogram
%
% INPUTS
% exptfolder - location of processed data files (cd if current)
%
% 04/04/2022 - MC original
%

function analyzeExpt_histogram(exptFolder)

disp('STARTING ANALYSES FOR THIS EXPERIMENT...')
%close all

cd(exptFolder) %jump to correct foler

% pull all file info
allFiles = dir('*pro.mat');
% remove any acclimate trials
skip_idx = find(contains(string({allFiles.name}), 'Acclimate'));
allFiles(skip_idx) = []; %remove

% pull expt meta
load('metaDat.mat')
filebase = [exptInfo.dateDir '_' exptInfo.flyDir ];
dropboxfolder = 'C:\Users\wilson\Dropbox (HMS)\Data\Behavior';
%dropboxfolder = 'D:\Dropbox (HMS)\Data\Behavior';


%% load in and pool data
disp('Pooling experiment data...')

%initialize
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
fwdmax = 20;
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
copyfile(vvp_filebase1, dropboxfolder,'f');


%% velocity vs obj position
disp('Analyzing directional velocity vs object position...')

figure(2),clf;
set(gcf,'Position',[100 100 900 400])

% forward row 1
subplot(1,3,1)
velocity_v_panelpos(allPanelPos,allForward,[])
ylabel('fwd vel (mm/s)')

% sideways row 2
subplot(1,3,2)
velocity_v_panelpos(allPanelPos,allSideways,[])
ylabel('side vel (mm/s)')
xlabel('panel pos (deg)')

% angular row 3
subplot(1,3,3)
velocity_v_panelpos(allPanelPos,allAngular,[])
ylabel('ang vel (deg/s)')

sgtitle([strrep(filebase,'_',' ') ' - velocity v sweep direction'])
%save
vvpt_filebase2 = [filebase '_plot_velocityvspanel.png'];
saveas(gcf,vvpt_filebase2);
copyfile(vvpt_filebase2, dropboxfolder,'f');

disp('Analyses of directional velocity vs object position complete.')


%% velocity vs obj position
disp('Analyzing directional velocity vs object position for fwd-velocity>0...')

figure(3),clf;
set(gcf,'Position',[100 100 900 400])

% remove points below threshold
thresh = 4;
allForward_thresh = allForward;
allForward_thresh(allForward<thresh) = NaN;
allSideways_thresh = allSideways;
allSideways_thresh(allForward<thresh) = NaN;
allAngular_thresh = allAngular;
allAngular_thresh(allForward<thresh) = NaN;

% forward row 1
subplot(1,3,1)
velocity_v_panelpos(allPanelPos,allForward_thresh,[])
ylabel('fwd vel (mm/s)')

% sideways row 2
subplot(1,3,2)
velocity_v_panelpos(allPanelPos,allSideways_thresh,[])
ylabel('side vel (mm/s)')
xlabel('panel pos (deg)')

% angular row 3
subplot(1,3,3)
velocity_v_panelpos(allPanelPos,allAngular_thresh,[])
ylabel('ang vel (deg/s)')

sgtitle([strrep(filebase,'_',' ') ' - velocity v sweep direction (fwd>0)'])
%save
vvpt_filebase = [filebase '_plot_velocityvspanel_thresh.png'];
saveas(gcf,vvpt_filebase);
copyfile(vvpt_filebase, dropboxfolder,'f');

disp('Analyses of directional velocity vs object position for fwd-velocity>0 complete.')


%% end
disp('ALL ANALYSES FOR THIS EXPERIMENT ARE COMPLETE.')
end

