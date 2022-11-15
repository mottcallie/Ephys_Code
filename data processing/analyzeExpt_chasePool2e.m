% analyzeExpt_chase
%
% Analysis Function
% Pulls all processed files from a multiple experiments of the same trial
% type and plots velocity histogram and object tracking
%
% INPUTS
% fileList - selection of interpolated files
% exptName - name of experiment selection
% fwdThresh - forward velocity threshold, + for behavior >, - for behavior <
%
% 06/21/2022 - MC original
%

function analyzeExpt_chasePool2(fileList,exptName,fwdThresh)
%% initialize
disp('STARTING ANALYSES FOR SELECTED EXPERIMENT GROUP...')
close all

cd('D:\Behavior_AOTU019_KiR\interpolated') %jump to interpolated folder

% set file/saving info
filebase = exptName;
if fwdThresh>0 %pull ONLY behavior above threshold
    filebase = [filebase '_thresh'];
elseif fwdThresh<0 %pull ONLY behavior below threshold
    filebase = [filebase '_low'];
end
% folders
mainfolder = 'D:\Behavior_AOTU019_KiR';
dropboxfolder = 'C:\Users\wilson\Dropbox (HMS)\Data\KiRExpt';

% hardcoded y-limits, may need to be adjusted
yfwd = [0 12];
yang = [-50 50];
ysid = [-2 2];

% line widths for plotting
lw1=0.5; %individual trials
lw2=3;   %means
% labels and colors for plotting
plotlabels = {'fwd (mm/s)'; 'ang (deg/s)'; 'side (mm/s)'};
colorlabels = {'#D95319';'#0072BD';'#7E2F8E'};


%% load in and pool all trials from each experiment folder
%initialize
rightSweep_v = [];
leftSweep_v = [];
fullSweep_v = [];
totSelect = length(fileList);

for fs = 1:totSelect
    disp(['Pooling experiment data ' num2str(fs) '/' num2str(totSelect)])

    % load in the summary file
    fileName = [fileList{fs} '_int.mat'];
    load(fileName)
    
    % run data through analysis pipeline of interest
    [mean_vR,mean_vL,pos_lr_sweep] = velocity_v_panelpos2(int_panelps, int_forward,int_angular,int_sideway,int_time,fwdThresh,0);
    [mean_v,pos_f_sweep] = velocity_v_fullsweep2(int_panelps, int_forward,int_angular,int_sideway,int_time,fwdThresh,0);
    
    % pool data
    rightSweep_v(:,fs,1) = mean_vR(:,1); %fwd
    rightSweep_v(:,fs,2) = mean_vR(:,2); %ang
    rightSweep_v(:,fs,3) = mean_vR(:,3); %side

    leftSweep_v(:,fs,1) = mean_vL(:,1); %fwd
    leftSweep_v(:,fs,2) = mean_vL(:,2); %ang
    leftSweep_v(:,fs,3) = mean_vL(:,3); %side

    fullSweep_v(:,fs,1) = mean_v(:,1); %fwd
    fullSweep_v(:,fs,2) = mean_v(:,2); %ang
    fullSweep_v(:,fs,3) = mean_v(:,3); %side

end
%pull experiment time from last trial
expttime = int_time;


%% plot directional velocity across full sweep
disp('Analyzing left/right sweeps...')
cd([mainfolder '\plots'])

% OPTIONAL: account for individual fly bias by subtracing mean(bias)
if 1
    biasAng = mean([rightSweep_v(:,:,2);leftSweep_v(:,:,2)],1);
    rightSweep_v(:,:,2) = rightSweep_v(:,:,2) - biasAng;
    leftSweep_v(:,:,2) = leftSweep_v(:,:,2) - biasAng;
    biasSide = mean([rightSweep_v(:,:,3);leftSweep_v(:,:,3)],1);
    rightSweep_v(:,:,3) = rightSweep_v(:,:,3) - biasSide;
    leftSweep_v(:,:,3) = leftSweep_v(:,:,3) - biasSide;
end

% mean
group_mean_R(:,1) = mean(rightSweep_v(:,:,1),2); %fwd
group_mean_R(:,2) = mean(rightSweep_v(:,:,2),2); %ang
group_mean_R(:,3) = mean(rightSweep_v(:,:,3),2); %side

group_mean_L(:,1) = mean(leftSweep_v(:,:,1),2); %fwd
group_mean_L(:,2) = mean(leftSweep_v(:,:,2),2); %ang
group_mean_L(:,3) = mean(leftSweep_v(:,:,3),2); %side

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

sgtitle(strrep(filebase,'_','/'))
% save plot
plotname = ['summary_leftrightsweep_' filebase '.png'];
saveas(gcf,plotname);
copyfile(plotname, dropboxfolder,'f');

disp('Analyses of left/right sweeps complete.')


%% plot directional velocity vs sweep direction
disp('Analyzing full sweeps...')
cd([mainfolder '\plots'])

% OPTIONAL: account for individual fly bias by subtracing mean(bias)
if 1
    biasAng = mean(fullSweep_v(:,:,2),1);
    fullSweep_v(:,:,2) = fullSweep_v(:,:,2) - biasAng;
    biasSide = mean(fullSweep_v(:,:,3),1);
    fullSweep_v(:,:,3) = fullSweep_v(:,:,3) - biasSide;
end

% mean
group_mean_fL(:,1) = mean(fullSweep_v(:,:,1),2);
group_mean_fL(:,2) = mean(fullSweep_v(:,:,2),2);
group_mean_fL(:,3) = mean(fullSweep_v(:,:,3),2);

% initialize
figure; set(gcf,'Position',[100 100 1500 800])

% set plot variables
sweep_t = expttime(1:length(fullSweep_v(:,:,1)));
p1 = round(min(sweep_t));
p2 = round(max(sweep_t));

for dv = 1:3
    subplot(1,3,dv)
    fx = gca;
   
    % plot bar position
    yyaxis right
    plot(sweep_t,pos_f_sweep,'k','LineWidth',2)
    fx.YAxis(1).Color = 'k';
    fx.YAxis(2).Visible = 'off';

    % add reference lines
    cT = mean(sweep_t);
    xline(cT,'Color','k')
    if dv ~= 1
        yline(0,'Color','k')
    end

    % plot individual trials
    yyaxis left
    for tx=1:size(fullSweep_v(:,:,1),2)
        plot(sweep_t,fullSweep_v(:,tx,dv),'Color', colorlabels{dv},'LineStyle','-.','LineWidth',lw1,'Marker','none');hold on
    end

    % plot velocity mean
    yyaxis left
    plot(sweep_t,group_mean_fL(:,dv),'Color', colorlabels{dv},'LineStyle','-','LineWidth',lw2,'Marker','none'); hold on

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

sgtitle(strrep(filebase,'_','/'))
% save plot
plotname = ['summary_fullsweep_' filebase '.png'];
saveas(gcf,plotname);
copyfile(plotname, dropboxfolder,'f');

disp('Analyses of full sweeps complete.')


%% end
disp('ALL ANALYSES FOR THIS EXPERIMENT ARE COMPLETE.')
end

