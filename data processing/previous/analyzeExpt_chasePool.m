% analyzeExpt_chase
%
% Analysis Function
% Pulls all processed files from a multiple experiments of the same trial
% type and plots velocity histogram and object tracking
%
% INPUTS
% folderList - folders to choose from
% folderSelect - selection of which folders to actually process
% exptName - name of experiment selection
%
% 04/04/2022 - MC original
% 06/19/2022 - MC converted to pool function
%

function analyzeExpt_chasePool(folderList,folderSelect,exptName)
%% load in and pool all trials from each experiment folder
disp('STARTING ANALYSES FOR SELECTED EXPERIMENT')

mainfolder = 'D:\Behavior_AOTU019_KiR';
dropboxfolder = 'C:\Users\wilson\Dropbox (HMS)\Data\Behavior';

%initialize
allForward = [];
allSideways = [];
allAngular = [];
allPanelPos = [];
totSelect = length(folderSelect);

for fs = 1:totSelect
    disp(['Pooling experiment data ' num2str(fs) '/' num2str(totSelect)])

    cd(folderList{folderSelect(fs)}) %jump to correct foler

    % pull all file info
    allFiles = dir('*pro.mat');
    % remove any acclimate trials
    skip_idx = find(contains(string({allFiles.name}), 'Acclimate'));
    allFiles(skip_idx) = []; %remove

    % pull data by trial type
    for e = 1:length(allFiles)

        % load in the file
        trialName = allFiles(e).name;
        load(trialName)

        % pool data
        allForward(:,end+1) = exptData.forwardVelocity;
        allSideways(:,end+1) = exptData.sidewaysVelocity;
        allAngular(:,end+1) = exptData.angularVelocity;
        allPanelPos(:,end+1) = exptData.g4displayXPos;

    end
end
%pull experiment time from last trial
expttime = exptData.t;

%set forward velocity threshold
thresh = 5;

disp('Data pooled.')


%% plot each directional velocity histogram
cd(mainfolder)
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
sidemax = 3;
sidedge = 0.1:0.1:sidemax;
histogram(abs(allSideways(:,:)),sidedge,'FaceColor','#7E2F8E','Normalization','probability')
xlim([0 sidemax])
xlabel('sideways velocity distribution (mm/s)')

subplot(3,1,3)
angmax = 200;
angedge = 4:6:angmax;
histogram(abs(allAngular(:,:)),angedge,'FaceColor','#0072BD','Normalization','probability')
xlim([0 angmax])
xlabel('angular velocity distribution (deg/s)')

sgtitle([strrep(exptName,'_',' ') ' - velocity histogram'])
%save
vvp_filebase1 = [exptName '_plot_velocityhistogram.png'];
saveas(gcf,vvp_filebase1);
copyfile(vvp_filebase1, dropboxfolder,'f');


%% velocity vs obj position
disp('Analyzing directional velocity vs object position...')

figure(2),clf;
set(gcf,'Position',[100 100 900 400])

% forward row 1
subplot(1,3,1)
velocity_v_panelpos(allPanelPos,allForward,'fwd')
ylabel('fwd vel (mm/s)')

% sideways row 2
subplot(1,3,2)
velocity_v_panelpos(allPanelPos,allSideways,'side')
ylabel('side vel (mm/s)')
xlabel('panel pos (deg)')

% angular row 3
subplot(1,3,3)
velocity_v_panelpos(allPanelPos,allAngular,'ang')
ylabel('ang vel (deg/s)')

sgtitle([strrep(exptName,'_',' ') ' - velocity v sweep direction'])
%save
vvpt_filebase2 = [exptName '_plot_velocityvspanel.png'];
saveas(gcf,vvpt_filebase2);
copyfile(vvpt_filebase2, dropboxfolder,'f');

disp('Analyses of directional velocity vs object position complete.')


%% velocity vs obj position
disp(['Analyzing directional velocity vs object position for fwd >' num2str(thresh) 'mm/s...'])

figure(3),clf;
set(gcf,'Position',[100 100 900 400])

% remove points below threshold
allForward_thresh = allForward;
allForward_thresh(allForward<thresh) = NaN;
allSideways_thresh = allSideways;
allSideways_thresh(allForward<thresh) = NaN;
allAngular_thresh = allAngular;
allAngular_thresh(allForward<thresh) = NaN;

% forward row 1
subplot(1,3,1)
velocity_v_panelpos(allPanelPos,allForward_thresh,'fwd')
ylabel('fwd vel (mm/s)')

% sideways row 2
subplot(1,3,2)
velocity_v_panelpos(allPanelPos,allSideways_thresh,'side')
ylabel('side vel (mm/s)')
xlabel('panel pos (deg)')

% angular row 3
subplot(1,3,3)
velocity_v_panelpos(allPanelPos,allAngular_thresh,'ang')
ylabel('ang vel (deg/s)')

sgtitle([strrep(exptName,'_',' ') ' - velocity v sweep direction (fwd>' num2str(thresh) ')'])
%save
vvpt_filebase = [exptName '_plot_velocityvspanel_thresh.png'];
saveas(gcf,vvpt_filebase);
copyfile(vvpt_filebase, dropboxfolder,'f');

disp(['Analyses of directional velocity vs object position for fwd >' num2str(thresh) 'mm/s complete.'])


%% end
disp('ALL ANALYSES FOR THIS EXPERIMENT ARE COMPLETE.')
end

