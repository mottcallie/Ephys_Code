% voltage_v_velocity
% function for generating heatmaps of cell voltage vs directional
% velocity
%
% INPUTS:
% poolData - data
% vmchange - 0 to plot raw voltage, 1 to plot change in voltage
% direction - pool across directions 0 or separate 1
%
% UPDATE:   01/03/2022 - MC added median filter
%
function voltage_v_panelpos(poolData,vmchange,direction,trialtitle)

%% reshape

% reshape position trace
posdata = reshape(poolData{6},[],1);

%median filter voltage trace to smooth APs
vmdata_medfilt = medfilt1(poolData{1},200,'truncate');
% reshape voltage trace
if vmchange == 0 %absolute spikerate
    vmdata = reshape(vmdata_medfilt,[],1);
else %change in spikerate
    vmmeans = nanmean(vmdata_medfilt);
    vmdata = reshape((vmdata_medfilt - vmmeans),[],1);
end


%% for plotting regardless of sweep direction

if direction == 0
    
    midpoint =(max(posdata)-min(posdata))/2 + min(posdata);
    i = 1;
    for p = unique(posdata)'
        pos_idx = any(posdata==p,2);
        
        data(i,1) = p - midpoint;
        data(i,2) = nanmean(vmdata(pos_idx)); %mean spikerate
        data(i,3) = nanstd(vmdata(pos_idx)); %standard deviation spikerate
        i = i+1;
    end
    
    %sem
    peaks = findpeaks(posdata,'MinPeakHeight',midpoint);
    ntot = size(peaks,1); %when unidirectional, each point crossed once in each direction
    ntot_bi = ntot*2; %when bidirectional, each point is crossed twice, once in each direction
    data(:,4) = data(:,3)/sqrt(ntot_bi); %divide by number of times said position is presented
    
    p = patch([data(:,1); flipud(data(:,1))],[data(:,2)-data(:,4); flipud(data(:,2)+data(:,4))],'k', 'FaceAlpha',0.1, 'EdgeColor','none');
    p.FaceColor = '#8C4799';
    hold on
    plot(data(:,1),data(:,2),'Color','#8C4799')
    
    xlim([min(data(:,1)) max(data(:,1))])
    xticks([min(data(:,1)) 0 max(data(:,1))])
    xline(0,':','Color','k')
    hold off
    title(trialtitle)
end


%% plot according to sweep direction

if direction == 1
    
    midpoint = (max(posdata)-min(posdata))/2 + min(posdata);
    
    % find peaks
    [~,pk_idx] = findpeaks(posdata,'MinPeakHeight',max(posdata)-1.5);
    [~,pkinv_idx] = findpeaks(-posdata,'MinPeakHeight',max(-posdata)-1.5);
    
    % find how long each pixel is played
    pxchange = ischange(posdata(1:10000));
    pxchange_idx = find(pxchange,2); %first 2
    pxmid = (pxchange_idx(2) - pxchange_idx(1))/2; %midpoint
    % add to pk indices
    pk_idx = pk_idx + pxmid;
    pkinv_idx = pkinv_idx + pxmid;
    
    
    % initialize
    if pk_idx(1) < pkinv_idx(1) %if right first
        sweeptrack = ones(length(posdata),1);
        for k = 1:length(pk_idx)
            leftsweep = pk_idx(k):pkinv_idx(k);
            sweeptrack(leftsweep) = 0;
        end
    elseif pk_idx(1) > pkinv_idx(1) %if left first
        sweeptrack = zeros(length(posdata),1);
        for k = 1:length(pk_idx)
            rightsweep = pkinv_idx(k):pk_idx(k);
            sweeptrack(rightsweep) = 1;
        end
    end
    %pull indices
    right_idx = find(sweeptrack>0);
    left_idx = find(sweeptrack==0);
    
    i = 1;
    for p = unique(posdata)'
        pos_idx = find(posdata==p);
        pos_right = intersect(pos_idx,right_idx);
        pos_left = intersect(pos_idx,left_idx);
        
        data_r(i,1) = p - midpoint;
        data_r(i,2) = nanmean(vmdata(pos_right)); %mean spikerate
        data_r(i,3) = nanstd(vmdata(pos_right)); %standard deviation spikerate
        
        data_l(i,1) = p - midpoint;
        data_l(i,2) = nanmean(vmdata(pos_left)); %mean spikerate
        data_l(i,3) = nanstd(vmdata(pos_left)); %standard deviation spikerate
        i = i+1;
    end
    
    %sem
    ntot = size(pk_idx,1); %when unidirectional, each point crossed once in each direction
    data_r(:,4) = data_r(:,3)/sqrt(ntot); %divide by number of times said position is presented
    data_l(:,4) = data_l(:,3)/sqrt(ntot); %divide by number of times said position is presented
    
    r = patch([data_r(:,1); flipud(data_r(:,1))],[data_r(:,2)-data_r(:,4); flipud(data_r(:,2)+data_r(:,4))], 'r', 'FaceAlpha',0.1, 'EdgeColor','none');
    r.FaceColor = '#ff0080';
    hold on
    plot(data_r(:,1),data_r(:,2),'Color', '#ff0080')
    hold on
    l = patch([data_l(:,1); flipud(data_l(:,1))],[data_l(:,2)-data_l(:,4); flipud(data_l(:,2)+data_l(:,4))], 'b', 'FaceAlpha',0.1, 'EdgeColor','none');
    l.FaceColor = '#0032A0';
    hold on
    plot(data_l(:,1),data_l(:,2),'Color', '#0032A0')
    
    xlim([min(data_l(:,1)) max(data_l(:,1))])
    xticks([min(data_l(:,1)) 0 max(data_l(:,1))])
    xline(0,':','Color','k')
    hold off
    title(trialtitle)
    
    
end


end

