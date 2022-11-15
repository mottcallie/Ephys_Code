% vm_v_panelpos
% function for generating summary plot of membrane potential v panel position
%
% INPUTS:
% allPanelPos - panel data
% allVoltage - voltage data
% trialtitle - what to call subplot
%
% ORIGINAL: 05/25/2022 - MC
%

function vm_v_panelpos(allPanelPos,allVoltage,trialtitle)

%% reshape

% reshape data for each pattern type
reshapePos = reshape(allPanelPos,[],1);
reshapeVm = reshape(allVoltage,[],1);

%% find left/right sweeps

% find peaks
[~,pk_idx] = findpeaks(reshapePos,'MinPeakHeight',max(reshapePos)-5);
[~,pkinv_idx] = findpeaks(-reshapePos,'MinPeakHeight',max(-reshapePos)-5);
midpoint = (max(reshapePos)-min(reshapePos))/2 + min(reshapePos);

% find how long each pixel is played
pxchange = ischange(reshapePos(1:10000));
pxchange_idx = find(pxchange,2); %first 2
pxmid = (pxchange_idx(2) - pxchange_idx(1))/2; %midpoint
% add to pk indices
pk_idx = pk_idx + pxmid;
pkinv_idx = pkinv_idx + pxmid;
if length(pkinv_idx)<length(pk_idx)
    pkinv_idx(end+1) = length(reshapePos); %until end
end

% find each sweep
if pk_idx(1) < pkinv_idx(1) %if right first
    pk_dist = pkinv_idx(1) - pk_idx(1);
    sweeptrack = zeros(length(reshapePos),1);
    for k = 1:length(pk_idx)
        rightsweep = pk_idx(k)-pk_dist: pk_idx(k);
        rightsweep = rightsweep(rightsweep>0);
        sweeptrack(rightsweep) = 1;
        
        leftsweep = pk_idx(k):pkinv_idx(k);
        sweeptrack(leftsweep) = -1;

        if k == 1
            righttrials_v{k} = reshapeVm(1:pk_idx(k));
            lefttrials_v{k} = reshapeVm(pk_idx(k):pkinv_idx(k));
            righttrials_pos{k} = reshapePos(1:pk_idx(k))- midpoint;
            lefttrials_pos{k} = reshapePos(pk_idx(k):pkinv_idx(k))- midpoint;
        elseif k == length(pk_idx)
            righttrials_v{k} = reshapeVm(pk_idx(k)-pk_dist:pk_idx(k));
            lefttrials_v{k} = reshapeVm(pk_idx(k):pkinv_idx(k));
            righttrials_pos{k} = reshapePos(pk_idx(k)-pk_dist:pk_idx(k))- midpoint;
            lefttrials_pos{k} = reshapePos(pk_idx(k):pkinv_idx(k))- midpoint;
        else
            righttrials_v{k} = reshapeVm(pk_idx(k)-pk_dist:pk_idx(k));
            lefttrials_v{k} = reshapeVm(pk_idx(k):pkinv_idx(k));
            righttrials_pos{k} = reshapePos(pk_idx(k)-pk_dist:pk_idx(k))- midpoint;
            lefttrials_pos{k} = reshapePos(pk_idx(k):pkinv_idx(k))- midpoint;
        end
        
%         if k>length(pkinv_idx)
%             leftsweep = pk_idx(k):length(reshapePos); %to end
%             sweeptrack(leftsweep) = 0;
%         else
%             leftsweep = pk_idx(k):pkinv_idx(k);
%             sweeptrack(leftsweep) = 0;
%         end
    end
elseif pk_idx(1) > pkinv_idx(1) %if left first
    sweeptrack = zeros(length(reshapePos),1);
    for k = 1:length(pk_idx)
        rightsweep = pkinv_idx(k):pk_idx(k);
        sweeptrack(rightsweep) = 1;
    end
end
%pull indices
right_idx = find(sweeptrack>0);
left_idx = find(sweeptrack<0);


%% pull data according to sweep direction

% for each panel position, pull mean and stdev for left/right sweeps
i = 1; %counter
for p = unique(reshapePos)'
    pos_idx = find(reshapePos==p);
    pos_right = intersect(pos_idx,right_idx);
    pos_left = intersect(pos_idx,left_idx);
    
    data_r(i,1) = p - midpoint;
    data_r(i,2) = nanmean(reshapeVm(pos_right)); %mean spikerate
    data_r(i,3) = nanstd(reshapeVm(pos_right)); %standard deviation spikerate
    
    data_l(i,1) = p - midpoint;
    data_l(i,2) = nanmean(reshapeVm(pos_left)); %mean spikerate
    data_l(i,3) = nanstd(reshapeVm(pos_left)); %standard deviation spikerate
    i = i+1;
end

% calculate sem from stdev
ntot = size(pk_idx,1); %when unidirectional, each point crossed once in each direction
data_r(:,4) = data_r(:,3)/sqrt(ntot); %divide by number of times said position is presented
data_l(:,4) = data_l(:,3)/sqrt(ntot); %divide by number of times said position is presented


%% plot

% plot right trials
% for t = 1:length(righttrials_v)
%     patchline(righttrials_pos{t},righttrials_v{t},'edgecolor','#ff0080','edgealpha',0.6);
%     hold on
% end
% 
% % plot left trials
% for t = 1:length(lefttrials_v)
%     patchline(lefttrials_pos{t},lefttrials_v{t},'edgecolor','#0032A0','edgealpha',0.6);
%     hold on
% end

% plot sem
r = patch([data_r(:,1); flipud(data_r(:,1))],[data_r(:,2)-data_r(:,4); flipud(data_r(:,2)+data_r(:,4))], 'r', 'FaceAlpha',0.2, 'EdgeColor','none');
r.FaceColor = '#ff0080';
hold on
l = patch([data_l(:,1); flipud(data_l(:,1))],[data_l(:,2)-data_l(:,4); flipud(data_l(:,2)+data_l(:,4))], 'b', 'FaceAlpha',0.2, 'EdgeColor','none');
l.FaceColor = '#0032A0';
hold on

% plot means
plot(data_r(:,1),data_r(:,2),'Color', '#ff0080')
hold on
plot(data_l(:,1),data_l(:,2),'Color', '#0032A0')

xlim([min(data_l(:,1)) max(data_l(:,1))])
xticks([min(data_l(:,1)) 0 max(data_l(:,1))])
xline(0,':','Color','k')
hold off
title(strrep(trialtitle,'_',' '))


end

