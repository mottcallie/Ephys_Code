% analyzeExpt_court
%
% Analysis Function
% Pulls all processed files from a given battery experiments and plots all
% trial types together for quick viewing
%
% INPUTS
% exptfolder - location of processed data files (cd if current)
% skipTrials - specify which trials, if any, to skip
%
% 06/07/22 MC

function analyzeExpt_trialsPlot(exptFolder)

disp('STARTING ANALYSES FOR THIS EXPERIMENT...')
%close all

cd(exptFolder) %jump to correct foler

% pull all file info
allFiles = dir('*pro.mat');

% remove any acclimate trials
skip_idx = find(contains(string({allFiles.name}), 'acclimate','IgnoreCase',true));
allFiles(skip_idx) = []; %remove

% pull expt meta
load('metaDat.mat')
filebase = [exptInfo.dateDir '_' exptInfo.flyDir ];
dropboxfolder = 'C:\Users\wilson\Dropbox (HMS)\Data\Behavior';
%dropboxfolder = 'D:\Dropbox (HMS)\Data\Behavior';


%% load in and pool data

subtypes = 'abcdefghij';
for st = 1:length(subtypes)
    currSubtype = subtypes(st);
    disp(['Pooling experiment data from trial set ' currSubtype])

    figure(st),clf;
    set(gcf,'Position',[100 100 1500 800])

    %initialize
    allVoltage = [];
    allSpikeRate = [];
    allForward = [];
    allSideways = [];
    allAngular = [];
    allPanelPos = [];

    %find subtype trials
    subtypeIdx = find(contains(string({allFiles.name}), [currSubtype '_']));
    et = length(subtypeIdx);

    % pull data by trial type
    for e = 1:et

        currIdx = subtypeIdx(e);

        % load in the file
        trialName = allFiles(currIdx).name;
        load(trialName)

        % pool data
        allVoltage(:,e) = exptData.scaledVoltage;
        allSpikeRate(:,e) = exptData.spikeRate;
        allForward(:,e) = exptData.forwardVelocity;
        allSideways(:,e) = exptData.sidewaysVelocity;
        allAngular(:,e) = exptData.angularVelocity;
        allPanelPos(:,e) = exptData.g4displayXPos;
        expttime = exptData.t;


        % plot one at a time
        if e == 1
            s(1) = subplot(et+1,1,1);
            minPos = nanmin(exptData.g4displayXPos);
            maxPos = nanmax(exptData.g4displayXPos);
            midPos = minPos + (maxPos-minPos)/2; %midline
            plot(exptData.t, exptData.g4displayXPos, 'Color','#77AC30')
            ylim([minPos maxPos])
            yline(midPos,':','Color','k') %line at mideline
            ylabel('Obj');
        end
        s(e+1) = subplot(et+1,1,e+1);
        plot(exptData.t, exptData.scaledVoltage,'k')
        ylabel(['t' num2str(e)])

    end
    xlabel('Time (s)')
    linkaxes(s,'x');

    sgtitle([filebase 'trial set' currSubtype])
    %save
    saveas(gcf,[filebase '_plot_' currSubtype '_summary.png']);


end


%% end
disp('ALL ANALYSES FOR THIS EXPERIMENT ARE COMPLETE.')
end

