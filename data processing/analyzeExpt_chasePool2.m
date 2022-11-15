% analyzeExpt_chase
%
% Analysis Function
% Pulls all processed files from a multiple experiments of the same trial
% type and plots velocity histogram and object tracking
%
% INPUTS
% exptName - name of experiment selection
% exptType - type of experiment (e.g. electrophysiology, behavior)
% fwdThresh - forward velocity threshold, + for behavior >, - for behavior <
%
% 06/21/2022 - MC original
% 09/07/2022 - MC improved flexibility, added ephys options
% 09/27/2022 - MC set min thresh for including data for "pursuit" block
%

function analyzeExpt_chasePool2(exptName,exptType,fwdThresh)
%% initialize
disp('STARTING ANALYSES FOR SELECTED EXPERIMENT GROUP...')
close all

% set folder names
mainFolder = ['D:\' exptName]; %master folder
cd(mainFolder)
intFolder = [mainFolder '\interpolated']; %folder containing interpolated data
saveFolder = [mainFolder '\summary']; %folder for saving summary data
if ~exist(saveFolder, 'dir')
    mkdir(saveFolder)
end
dropboxFolder = ['C:\Users\wilson\Dropbox (HMS)\Data\' exptName]; %dropbox
cd(intFolder') %jump to interpolated data folder

% set file/saving info
filebase = exptName;
if fwdThresh>0 %pull ONLY behavior above threshold
    filebase = [filebase '_thresh'];
elseif fwdThresh<0 %pull ONLY behavior below threshold
    filebase = [filebase '_low'];
end

% hardcoded y-limits, may need to be adjusted
yfwd = [0 12]; %forward
yang = [-50 50]; %angular
ysid = [-2 2]; %sideways
yspike = [0 10]; %spikerate

% set plotting variables
lw1 = 0.5; %line width for individual experiments
lw2 = 3;   %line width for experiment means
plotlabels = {'fwd (mm/s)'; 'ang (deg/s)'; 'side (mm/s)'}; %velocity names
colorlabels = {'#D95319';'#0072BD';'#7E2F8E'}; %velocity colors

% set forward walking thresholds
highThresh = 5;
lowThresh = 2;
% for pursuit data, set minimum threshold for time spent pursuing
minRun = 30; %sec


%% load in and pool all trials from each experiment folder

% find all files in this directory
% pull all file info
allFiles = dir('*int.mat');

%initialize
all_fwd = [];
all_ang = [];
all_sid = [];
all_spikeR = [];

rightSweep_v = [];
leftSweep_v = [];
fullSweep_v = [];
fullSweep_sr = [];

totFiles = height(allFiles);
%if cell side tracker exists, load 
if isfile('trackLR.mat')
    load('trackLR.mat')
    trackLR=flip(trackLR);
end

for fs = 1:totFiles
    disp(['Pooling experiment data ' num2str(fs) '/' num2str(totFiles)])

    % load in the summary file
    thisFile = allFiles(fs).name;
    load(thisFile)
    
    % to account for L/R tuning, flip L velocities so + is ipsi and - is contra
    if trackLR(fs)==1
        vCorrect = -1;
    else
        vCorrect = 1;
    end
    % pool interpolated data
    all_fwd = [all_fwd int_forward];
    all_ang = [all_ang int_angular.*vCorrect];
    all_sid = [all_sid int_sideway.*vCorrect];

    % run behavioral data analysis pipelines
    [mean_vR,mean_vL,pos_lr_sweep] = velocity_v_panelpos2(int_panelps, int_forward,int_angular,int_sideway,int_time,fwdThresh,0);
    [mean_v,pos_f_sweep] = velocity_v_fullsweep2(int_panelps, int_forward,int_angular,int_sideway,int_time,fwdThresh,0);
    % pool processed data
    rightSweep_v(:,fs,1) = mean_vR(:,1); %fwd
    rightSweep_v(:,fs,2) = mean_vR(:,2); %ang
    rightSweep_v(:,fs,3) = mean_vR(:,3); %side
    leftSweep_v(:,fs,1) = mean_vL(:,1); %fwd
    leftSweep_v(:,fs,2) = mean_vL(:,2); %ang
    leftSweep_v(:,fs,3) = mean_vL(:,3); %side
    fullSweep_v(:,fs,1) = mean_v(:,1); %fwd
    fullSweep_v(:,fs,2) = mean_v(:,2); %ang
    fullSweep_v(:,fs,3) = mean_v(:,3); %side

    % if elecrophsyiology, run spike data analysis pipelines
    if contains(exptType,'physiology')
        % selections required based on input... fix later
        [mean_sr,pos_sweep] = spikerate_v_fullsweep2(int_panelps, int_forward,int_time,int_spikerate,highThresh,lowThresh,minRun,trackLR(fs),0);
        % pool data
        all_spikeR = [all_spikeR int_spikerate];
        fullSweep_sr(:,fs,1) = mean_sr(:,1); %no thresh
        fullSweep_sr(:,fs,2) = mean_sr(:,2); %high thresh
        fullSweep_sr(:,fs,3) = mean_sr(:,3); %low thresh
        fullSweep_sr(:,fs,4) = mean_sr(:,4); %rest
    end

    timespentchasing = (sum(int_forward>highThresh,'all')/length(int_time))*60;
    chaseSelect(fs) = (timespentchasing>minRun);
    timespentwalking = (sum(int_forward>1,'all')/length(int_time))*60;
    walkSelect(fs) = (timespentwalking>minRun);

end
%pull experiment time from last trial
expttime = int_time;


%% plot directional velocity across full sweep
disp('Analyzing left/right sweeps...')
cd(saveFolder)

% OPTIONAL: account for individual fly bias by subtracing mean(bias)
if 1
    biasAng = nanmean([rightSweep_v(:,:,2);leftSweep_v(:,:,2)],1);
    rightSweep_v(:,:,2) = rightSweep_v(:,:,2) - biasAng;
    leftSweep_v(:,:,2) = leftSweep_v(:,:,2) - biasAng;
    biasSide = nanmean([rightSweep_v(:,:,3);leftSweep_v(:,:,3)],1);
    rightSweep_v(:,:,3) = rightSweep_v(:,:,3) - biasSide;
    leftSweep_v(:,:,3) = leftSweep_v(:,:,3) - biasSide;
end

% mean
group_mean_R(:,1) = nanmean(rightSweep_v(:,:,1),2); %fwd
group_mean_R(:,2) = nanmean(rightSweep_v(:,:,2),2); %ang
group_mean_R(:,3) = nanmean(rightSweep_v(:,:,3),2); %side

group_mean_L(:,1) = nanmean(leftSweep_v(:,:,1),2); %fwd
group_mean_L(:,2) = nanmean(leftSweep_v(:,:,2),2); %ang
group_mean_L(:,3) = nanmean(leftSweep_v(:,:,3),2); %side

% initialize
figure; set(gcf,'Position',[100 100 1500 800])

% set plot variables
p1 = round(min(pos_lr_sweep(:,1)));
p2 = round(max(pos_lr_sweep(:,1)));
pm = 0;

for dv = 1:3
    subplot(1,3,dv)
    % plot individual trials
    for tx=1:size(rightSweep_v(:,:,1),2)
        plot(pos_lr_sweep(:,1),rightSweep_v(:,tx,dv),'Color', '#ff0080','LineStyle','-.','LineWidth',lw1);hold on
        plot(pos_lr_sweep(:,2),leftSweep_v(:,tx,dv),'Color', '#0032A0','LineStyle','-.','LineWidth',lw1);hold on
    end

    % plot mean
    plot(pos_lr_sweep(:,1),group_mean_R(:,dv),'Color', '#ff0080','LineWidth',lw2)
    hold on
    plot(pos_lr_sweep(:,2),group_mean_L(:,dv),'Color', '#0032A0','LineWidth',lw2)

    % add reference lines
    xline(pm,'Color','k')
    if dv~=1
        yline(0,'Color','k')
    end

    % adjust axes and labels
    axis tight
    xlim([p1 p2])
    xticks([p1 0 p2])

    switch dv
        case 1
            ylim(yfwd)
        case 2
            ylim(yang)
        case 3
            ylim(ysid)
    end
    ylabel(plotlabels{dv})
    hold off
end
xlabel('panel pos (deg)')

sgtitle(strrep(filebase,'_',' '))
% save plot
plotname = ['summary_leftrightsweep_' filebase '.png'];
saveas(gcf,plotname);
copyfile(plotname, dropboxFolder,'f');

disp('Analyses of left/right sweeps complete.')


%% plot directional velocity vs sweep direction
disp('Analyzing full sweeps...')
cd(saveFolder)

% OPTIONAL: account for individual fly bias by subtracing mean(bias)
if 1
    biasAng = nanmean(fullSweep_v(:,:,2),1);
    fullSweep_v(:,:,2) = fullSweep_v(:,:,2) - biasAng;
    biasSide = nanmean(fullSweep_v(:,:,3),1);
    fullSweep_v(:,:,3) = fullSweep_v(:,:,3) - biasSide;
end

% mean
group_mean_fL(:,1) = nanmean(fullSweep_v(:,:,1),2);
group_mean_fL(:,2) = nanmean(fullSweep_v(:,:,2),2);
group_mean_fL(:,3) = nanmean(fullSweep_v(:,:,3),2);

% initialize
figure; set(gcf,'Position',[100 100 1500 800])

% set plot variables
t = expttime(1:length(fullSweep_v(:,:,1)));
p1 = round(min(t));
p2 = round(max(t));

% estimate behavioral lag using angular velocity
% find left/right angular peaks
aR = find(group_mean_fL(:,2)==max(group_mean_fL(1:(end/2),2)));
aL = find(group_mean_fL(:,2)==min(group_mean_fL((end/2):end,2)));
% find left/right stimulus peaks
sR = find(pos_f_sweep==max(pos_f_sweep));
sL = find(pos_f_sweep==min(pos_f_sweep));
% convert to time, estimate average lag
lag = (((t(aR)-t(sR)) + (t(aL)-t(sL)))/2)*1000;

for dv = 1:3
    subplot(1,3,dv)
    fx = gca;

    % plot bar position
    yyaxis right
    plot(t,pos_f_sweep,'k','LineWidth',2)
    fx.YAxis(1).Color = 'k';
    fx.YAxis(2).Visible = 'off';

    % add reference lines
    cT = mean(t);
    xline(cT,'Color','k')
    if dv ~= 1
        yline(0,'Color','k')
    end

    % plot individual trials
    yyaxis left
    for tx=1:size(fullSweep_v(:,:,1),2)
        plot(t,fullSweep_v(:,tx,dv),'Color', colorlabels{dv},'LineStyle','-.','LineWidth',lw1,'Marker','none');hold on
    end

    % plot velocity mean
    yyaxis left
    plot(t,group_mean_fL(:,dv),'Color', colorlabels{dv},'LineStyle','-','LineWidth',lw2,'Marker','none'); hold on

    % adjust axes
    axis tight
    xlim([p1 p2])
    xticks([p1 p2])

    switch dv
        case 1
            ylim(yfwd)
        case 2
            ylim(yang)
        case 3
            ylim(ysid)
    end
    ylabel(plotlabels{dv})

    hold off
end
xlabel('time (sec.)')

sgtitle([strrep(filebase,'_',' ') ' (' num2str(round(lag)) 'msec. lag)'])
% save plot
plotname = ['summary_fullsweep_' filebase '.png'];
saveas(gcf,plotname);
copyfile(plotname, dropboxFolder,'f');

disp('Analyses of full sweeps complete.')


%% plot spike rate vs sweep direction
if contains(exptType,'physiology')
    disp('Analyzing spike rate vs motion...')
    cd(saveFolder)

    % mean
    group_mean_sr(:,1) = nanmean(fullSweep_sr(:,:,1),2); %no thresh
    group_mean_sr(:,2) = nanmean(fullSweep_sr(:,chaseSelect,2),2); %high thresh
    group_mean_sr(:,3) = nanmean(fullSweep_sr(:,walkSelect,3),2); %low thresh
    group_mean_sr(:,4) = nanmean(fullSweep_sr(:,:,4),2); %rest thresh

    % initialize
    figure; set(gcf,'Position',[100 100 1500 800])
    srplotlabels = {'all (spikes/sec)';
                    ['pursuit >' num2str(highThresh) 'mm/s (spikes/sec)'];
                    ['walking 0-' num2str(lowThresh) 'mm/s (spikes/sec)']
                    'rest = 0mm/s (spikes/sec)'};
    
    % set plot variables
    t = expttime(1:length(fullSweep_sr(:,:,1)));
    p1 = round(min(t));
    p2 = round(max(t));

    % estimate firing anticipation
    % find firing rate peak
    frPk = find(group_mean_sr(:,2)==max(group_mean_sr(:,2)));
    % find stimulus peak
    stPk = find(pos_sweep==max(pos_sweep));
    % convert to time, estimate average lag
    lag = (t(stPk)-t(frPk))*1000;

    for dv = 1:4
        subplot(1,4,dv)
        fs = gca;
        % plot bar position
        yyaxis right
        plot(t,pos_sweep,'k','LineWidth',2)
        fs.YAxis(1).Color = 'k';
        fs.YAxis(2).Visible = 'off';

        % add reference lines
        cT = mean(t);
        xline(cT,'Color','k')
        if dv ~= 1
            yline(0,'Color','k')
        end

        %for pursuit plot, only plot above threshold trials
        ntrials = 1:size(fullSweep_sr(:,:,dv),2);
        if dv==2
            ntrials = ntrials(chaseSelect);
        elseif dv==3
            ntrials = ntrials(walkSelect);
        end

        % plot individual trials
        yyaxis left
        for tx=ntrials
            plot(t,fullSweep_sr(:,tx,dv),'Color', '#77AC30','LineStyle','-.','LineWidth',lw1,'Marker','none');hold on
        end

        % plot spikerate mean
        yyaxis left
        plot(t,group_mean_sr(:,dv),'Color', '#77AC30','LineStyle','-','LineWidth',lw2,'Marker','none'); hold on

        % adjust axes
        axis tight
        xlim([p1 p2])
        xticks([p1 p2])
        ylim(yspike)
        ylabel(srplotlabels{dv})

        hold off
    end
    xlabel('time (sec.)')

    sgtitle([strrep(exptName,'_',' ') ' (' num2str(round(lag)) 'msec. phase anticipation)'])
    % save plot
    plotname = ['summary_spikerate_motion_' exptName '.png'];
    saveas(gcf,plotname);
    copyfile(plotname, dropboxFolder,'f');

    disp('Analyses of spike rates complete.')
end


%% plot spike rate vs directional velocity
if contains(exptType,'physiology')
    disp('Analyzing spike rate vs velocity...')
    cd(saveFolder)

    % run
    spikerate_v_velocity2(all_fwd,all_ang,all_sid,int_time,all_spikeR)

    sgtitle([strrep(exptName,'_',' ') ' all flies summary'])
    % save plot
    plotname = ['summary_spikerate_velocity_' exptName '.png'];
    saveas(gcf,plotname);
    copyfile(plotname, dropboxFolder,'f');

    disp('Analyses of spike rates complete.')
end


%% end
disp('ALL ANALYSES FOR THIS EXPERIMENT ARE COMPLETE.')
end

