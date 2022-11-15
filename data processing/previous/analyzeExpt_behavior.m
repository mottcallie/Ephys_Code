% analyzeExpt_behavior
%
% Analysis Function
% Pulls all processed files from a given behavior pursuit experiment in
% order to analyze the data
%
% INPUTS
% exptfolder - location of processed data files (cd if current)
% skipTrials - specify which trials, if any, to skip
%
% 12/21/2021 - MC original
%

function analyzeExpt_behavior(exptFolder, skipTrials)

disp('STARTING ANALYSES FOR THIS EXPERIMENT...')
close all

cd(exptFolder) %jump to correct foler
[~, ~, settings] = ephysSettings();% load settings

% pull all file info
allFiles = dir('*pro.mat');
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
disp('Pooling experiment data by trial type...')

%initialize
switch dispInfo.change
    case 'pattern'
        plotNames = dispInfo.pattNames;
    case 'function'
        plotNames = dispInfo.funcNames;
    case ' both'
        plotNames = dispInfo.fullNames;
end
allDispNames = dispInfo.fullNames;
nPat = length(allDispNames);
allPanelPos = cell(1,nPat);
allForward = cell(1,nPat);
allSideways = cell(1,nPat);
allAngular = cell(1,nPat);
expttime = cell(1,nPat);

% pull data by trial type
for e = 1:length(allFiles)
    
    % load in the file
    trialName = allFiles(e).name;
    load(trialName)
    
    % find last complete sweep (within 1px/1.5degrees of max)
    [~,pk_idx] = findpeaks(exptData.g4displayXPos,'MinPeakHeight',max(exptData.g4displayXPos)-1.5);
    [~,pkinv_idx] = findpeaks(-exptData.g4displayXPos,'MinPeakHeight',max(-exptData.g4displayXPos)-1.5);
    pk_last = max([pk_idx ;pkinv_idx])+1000; %buffer of 2 samples (500hz) to ensure peak is registered
    % set range to exclude partial sweeps
    if pk_last < length(exptData.g4displayXPos)
        t = 1:pk_last;
    else
        t = 1:length(exptData.g4displayXPos);
    end
    
    % pull pattern name index
    for n = 1:length(allDispNames)
        trial_idx(n) = contains(trialName,allDispNames{n});
    end
    patIdx = find(trial_idx);
    % find next available data entry column
    nextIdx = size(allForward{patIdx},2)+1;
    
    % pool data
    allPanelPos{patIdx}(:,nextIdx) = exptData.g4displayXPos(t);
    allForward{patIdx}(:,nextIdx) = exptData.forwardVelocity(t);
    allSideways{patIdx}(:,nextIdx) = exptData.sidewaysVelocity(t);
    allAngular{patIdx}(:,nextIdx) = exptData.angularVelocity(t);
    
    expttime{patIdx}(:,nextIdx) = exptData.t(t);
    
end
    
disp('Data pooled.')


%% plot individual trials by pattern type
disp('Plotting individual trials of each pattern type')

% for each pattern type
for tr = 1:nPat
    figure(tr),clf;
    set(gcf,'Position',[100 100 1500 800])
    
    totTrials = size(allAngular{tr},2);
    
    % plot object position
    subplot(totTrials+1,1,1);
    
    minPos = nanmin(allPanelPos{tr},[],'all');
    maxPos = nanmax(allPanelPos{tr},[],'all');
    midPos = minPos + (maxPos-minPos)/2; %midline
    xrange = [0 ceil(max(expttime{tr}(:,1)))];
    
    plot(expttime{tr}(:,1), allPanelPos{tr}(:,1), 'Color','#77AC30')
    xlim(xrange)
    ylim([minPos maxPos])
    yline(midPos,':','Color','k') %line at mideline
    ylabel('obj pos (deg)');
    
    % find changes in sweep direction
    [~,pk_idx] = findpeaks(allPanelPos{tr}(:,1),'MinPeakHeight',max(allPanelPos{tr}(:,1))-1.5);
    [~,pkinv_idx] = findpeaks(-allPanelPos{tr}(:,1),'MinPeakHeight',max(-allPanelPos{tr}(:,1))-1.5);
        
    % plot angular velocity trials
    for r = 1:totTrials
        subplot(totTrials+1,1,r+1);
        plot(expttime{tr}(:,r), allAngular{tr}(:,r), 'Color','#0072BD')
        
        xlim(xrange)
        for rp = expttime{tr}(pk_idx,1)'
            xline(rp,':','Color','#ff0080') %line at right peaks
        end
        for lp = expttime{tr}(pkinv_idx,1)'
            xline(lp,':','Color','#0032A0') %line at left peaks
        end
        
        angMax = ceil(max(abs(allAngular{tr}),[],'all'));
        ylim([-angMax angMax])
        ylabel(['trial ' num2str(r)])
        yline(0,':','Color','k') %line at mideline
    end
    xlabel('time(sec.)')
    
    sgtitle([strrep(filebase,'_',' ') ' - ' '(' num2str(tr) ') ' strrep(allDispNames{tr},'_',' ') ': angular velocity trials'])
    %save
    atrial_filebase = [filebase '_' allDispNames{tr} '_plot_atrials.png'];
    saveas(gcf,atrial_filebase);
    copyfile(atrial_filebase, dropboxfolder,'f');
    disp(['Pattern ' num2str(tr) ' trials complete.'])
end

% for each pattern type
for tr = 1:nPat
    figure(tr),clf;
    set(gcf,'Position',[100 100 1500 800])
    
    totTrials = size(allSideways{tr},2);
    
    % plot object position
    subplot(totTrials+1,1,1);
    
    minPos = nanmin(allPanelPos{tr},[],'all');
    maxPos = nanmax(allPanelPos{tr},[],'all');
    midPos = minPos + (maxPos-minPos)/2; %midline
    xrange = [0 ceil(max(expttime{tr}(:,1)))];
    
    plot(expttime{tr}(:,1), allPanelPos{tr}(:,1), 'Color','#77AC30')
    xlim(xrange)
    ylim([minPos maxPos])
    yline(midPos,':','Color','k') %line at mideline
    ylabel('obj pos (deg)');
    
    % find changes in sweep direction
    [~,pk_idx] = findpeaks(allPanelPos{tr}(:,1),'MinPeakHeight',max(allPanelPos{tr}(:,1))-1.5);
    [~,pkinv_idx] = findpeaks(-allPanelPos{tr}(:,1),'MinPeakHeight',max(-allPanelPos{tr}(:,1))-1.5);
        
    % plot angular velocity trials
    for r = 1:totTrials
        subplot(totTrials+1,1,r+1);
        plot(expttime{tr}(:,r), allSideways{tr}(:,r), 'Color','#7E2F8E')
        
        xlim(xrange)
        for rp = expttime{tr}(pk_idx,1)'
            xline(rp,':','Color','#ff0080') %line at right peaks
        end
        for lp = expttime{tr}(pkinv_idx,1)'
            xline(lp,':','Color','#0032A0') %line at left peaks
        end
        
        sidMax = ceil(max(abs(allSideways{tr}),[],'all'));
        ylim([-sidMax sidMax])
        ylabel(['trial ' num2str(r)])
        yline(0,':','Color','k') %line at mideline
    end
    xlabel('time(sec.)')
    
    sgtitle([strrep(filebase,'_',' ') ' - ' '(' num2str(tr) ') ' strrep(allDispNames{tr},'_',' ') ': sidewyas velocity trials'])
    %save
    strial_filebase = [filebase '_' allDispNames{tr} '_plot_strials.png'];
    saveas(gcf,strial_filebase);
    copyfile(strial_filebase, dropboxfolder,'f');
    disp(['Pattern ' num2str(tr) ' trials complete.'])
end

disp('Summary of each pattern type plotted and saved')


%% plot summary by pattern type
disp('Plotting summary of each pattern type')

% for each pattern type
for tr = 1:nPat
    figure(tr),clf;
    set(gcf,'Position',[100 100 1500 800])
    
    % plot object position
    subplot(4,1,1);
    
    minPos = nanmin(allPanelPos{tr},[],'all');
    maxPos = nanmax(allPanelPos{tr},[],'all');
    midPos = minPos + (maxPos-minPos)/2; %midline
    xrange = [0 ceil(max(expttime{tr}(:,1)))];
    
    plot(expttime{tr}(:,1), allPanelPos{tr}(:,1), 'Color','#77AC30')
    xlim(xrange)
    ylim([minPos maxPos])
    yline(midPos,':','Color','k') %line at mideline
    ylabel('obj pos (deg)');
    
    % plot forward velocity trials
    subplot(4,1,2); 
    for r = 1:size(allForward{tr},2)
        plot(expttime{tr}(:,r), allForward{tr}(:,r), 'Color','#D95319')
        hold on
    end
    hold off
    xlim(xrange)
    ylabel('fwd vel (mm/s)')

    % plot sideways velocity trials
    subplot(4,1,3); 
    for r = 1:size(allSideways{tr},2)
        plot(expttime{tr}(:,r), allSideways{tr}(:,r), 'Color','#7E2F8E')
        hold on
    end
    hold off
    xlim(xrange)
    sidMax = ceil(max(abs(allSideways{tr}),[],'all'));
    ylim([-sidMax sidMax])
    ylabel('side vel (mm/s)')
    
    % plot angular velocity trials
    subplot(4,1,4); 
    for r = 1:size(allAngular{tr},2)
        plot(expttime{tr}(:,r), allAngular{tr}(:,r), 'Color','#0072BD')
        hold on
    end
    hold off
    xlim(xrange)
    angMax = ceil(max(abs(allAngular{tr}),[],'all'));
    ylim([-angMax angMax])
    ylabel('ang vel (deg/s)')
    
    sgtitle([strrep(filebase,'_',' ') ' - ' '(' num2str(tr) ') ' strrep(allDispNames{tr},'_',' ')])
    %save
    sum_filebase = [filebase '_' allDispNames{tr} '_plot_summary.png'];
    saveas(gcf,sum_filebase);
    copyfile(sum_filebase, dropboxfolder,'f');
    disp(['Pattern ' num2str(tr) ' summary complete.'])
end

disp('Summary of each pattern type plotted and saved')


%% plot object-velocity correlation by pattern type
% disp('Plotting object-velocity correlation of each pattern type')
% % set sliding window for calculating binned correlation
% slidingWindow = 4 * 20000; %frames, 20000 = 1 sec
% 
% % for each pattern type
% for tr = 1:nPat
%     figure(tr),clf;
%     set(gcf,'Position',[100 100 1500 800])
%     
%     totTrials = size(allAngular{tr},2);
%     
%     % plot object position
%     subplot(totTrials+1,1,1);
%     
%     minPos = min(allPanelPos{tr},[],'all');
%     maxPos = max(allPanelPos{tr},[],'all');
%     midPos = minPos + (maxPos-minPos)/2; %midline
%     xrange = [0 ceil(max(expttime))];
%     
%     plot(expttime, allPanelPos{tr}(:,1), 'Color','#77AC30')
%     xlim(xrange)
%     ylim([minPos maxPos])
%     yline(midPos,':','Color','k') %line at mideline
%     ylabel('obj pos (deg)');
%     
%     % find changes in sweep direction
% %     [~,pk_idx] = findpeaks(allPanelPos{tr}(:,1),'MinPeakHeight',max(allPanelPos{tr}(:,1))-1.5);
% %     [~,pkinv_idx] = findpeaks(-allPanelPos{tr}(:,1),'MinPeakHeight',max(-allPanelPos{tr}(:,1))-1.5);
% %     
% %     pk_times = sort([time(pk_idx) ; time(pkinv_idx)]');
%     
%     % plot angular velocity trials
%     for r = 1:totTrials
%         subplot(totTrials+1,1,r+1);
%         
%         nWin = floor(length(allPanelPos{tr}(:,r))/slidingWindow); %number of windows
%         trackingIdx = zeros(1,length(allAngular{tr}(:,r))); %initialize
%         fidelity = zeros(1,nWin); %initialize
%         timeWin = zeros(1,nWin); %initialize
%         vigor = zeros(1,length(allAngular{tr}(:,r))); %initialize
%         
%         % calculate tracking fidelity (sliding correlation)
%         for w = 0:nWin-1
%             currWin = 1 + (slidingWindow * w):slidingWindow + (slidingWindow * w);
%             fidelity(w+1) = corr(allPanelPos{tr}(currWin,r),allAngular{tr}(currWin,r));
%             timeWin(w+1) = median(expttime(currWin));
%         end
%         fidelity_int = interp1(timeWin,fidelity,expttime);
%         % calculate tracking vigor (velocity in direction of object)
%         objectOnRight = find(allPanelPos{tr}(:,r)>midPos);
%         for rIdx = 1:length(objectOnRight)
%             i = objectOnRight(rIdx);
%             if allAngular{tr}(i,r)>0
%                 vigor(i) = allAngular{tr}(i,r);
%             end
%         end
%         objectOnLeft = find(allPanelPos{tr}(:,r)<midPos);
%         for lIdx = 1:length(objectOnLeft)
%             i = objectOnLeft(lIdx);
%             if allAngular{tr}(i,r)<0
%                 vigor(i) = allAngular{tr}(i,r) * -1; % invert
%             end
%         end
%         vigor_norm = vigor/max(vigor); %normalize
%         
%         % compute tracking index from product of both
%         trackingIdx = fidelity_int .* vigor_norm';
%         
%         plot(expttime,trackingIdx, 'Color','#A2142F')
%         
%         xlim(xrange)
%         ylabel(['trial ' num2str(r)])
%         yline(0,':','Color','k') %line at mideline
%     end
%     xlabel('time(sec.)')
%     
%     sgtitle([strrep(filebase,'_',' ') ' - ' strrep(allDispNames{tr},'_',' ') ': sliding correlation'])
%     %save
%     corr_filebase = [filebase '_' allDispNames{tr} '_plot_corr.png'];
%     saveas(gcf,corr_filebase);
%     copyfile(corr_filebase, dropboxfolder,'f');
%     disp(['Pattern ' num2str(tr) ' trials complete.'])
% end
% 
% disp('Object-velocity correlation of each pattern type plotted and saved')


%% velocity vs obj position
disp('Analyzing directional velocity vs object position...')

figure(nPat+1),clf;
set(gcf,'Position',[100 100 300*nPat 900])

for vo = 1:nPat
    % forward row 1
    subplot(3,nPat,vo)
    velocity_v_panelpos(allPanelPos{vo},allForward{vo},plotNames{vo})
    if vo == 1
        ylabel('fwd vel (mm/s)')
    end
    
    % sideways row 2
    subplot(3,nPat,nPat+vo)
    velocity_v_panelpos(allPanelPos{vo},allSideways{vo},[])
    if vo == 1
        ylabel('side vel (mm/s)')
    end
    
    % angular row 3
    subplot(3,nPat,2*nPat+vo)
    velocity_v_panelpos(allPanelPos{vo},allAngular{vo},[])
    if vo == 1
        ylabel('ang vel (deg/s)')
    end

end
xlabel('panel pos (deg)')
sgtitle([strrep(filebase,'_',' ') ' - velocity v sweep direction'])
%save
vvp_filebase = [filebase '_plot_velocityvspanel.png'];
saveas(gcf,vvp_filebase);
copyfile(vvp_filebase, dropboxfolder,'f');

disp('Analyses of directional velocity vs object position complete.')


%% velocity vs obj position
disp('Analyzing directional velocity vs object position for fwd-velocity>0...')

figure(nPat+2),clf;
set(gcf,'Position',[100 100 300*nPat 900])

for vo = 1:nPat
    
    % remove points below threshold
    thresh = 1;
    allForward_thresh = allForward{vo};
    allForward_thresh(allForward{vo}<thresh) = NaN;
    allSideways_thresh = allSideways{vo};
    allSideways_thresh(allForward{vo}<thresh) = NaN;
    allAngular_thresh = allAngular{vo};
    allAngular_thresh(allForward{vo}<thresh) = NaN;
    
    % forward row 1
    subplot(3,nPat,vo)
    velocity_v_panelpos(allPanelPos{vo},allForward_thresh,plotNames{vo})
    if vo == 1
        ylabel('fwd vel (mm/s)')
    end
    
    % sideways row 2
    subplot(3,nPat,nPat+vo)
    velocity_v_panelpos(allPanelPos{vo},allSideways_thresh,[])
    if vo == 1
        ylabel('side vel (mm/s)')
    end
    
    % angular row 3
    subplot(3,nPat,2*nPat+vo)
    velocity_v_panelpos(allPanelPos{vo},allAngular_thresh,[])
    if vo == 1
        ylabel('ang vel (deg/s)')
    end

end
xlabel('panel pos (deg)')
sgtitle([strrep(filebase,'_',' ') ' - velocity v sweep direction (fwd>0)'])
%save
vvpt_filebase = [filebase '_plot_velocityvspanel_thresh.png'];
saveas(gcf,vvpt_filebase);
copyfile(vvpt_filebase, dropboxfolder,'f');

disp('Analyses of directional velocity vs object position for fwd-velocity>0 complete.')


%% end
disp('ALL ANALYSES FOR THIS EXPERIMENT ARE COMPLETE.')
end

