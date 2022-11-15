% spike_v_velocity
% function for generating heatmaps of cell spikerate vs directional
% velocity
%
% INPUTS:
% allSpikeRate - pooled spikerate data
% allForward - pooled forward velocity data
% allTurn - either sideways or angular
% turnSelect - either 1 (sideways) or 2 (angular)
%
% 05/31/2021 MC
%

function spike_v_velocity(allSpikeRate,allForward,allTurn,turnSelect)
%% reshape

% pool traces
ydata = reshape(allForward,[],1);
xdata = reshape(allTurn,[],1);
zdata = reshape(allSpikeRate,[],1);


%% set heatmap variables

% set edges and names based on variables
ybin = 1; %mm bins for forward
yname = 'forward velocity (mm/s)';
switch turnSelect
    case 1 %mm bins for sideways
        xbin = 1;
        xname = 'sideways velocity (mm/s)';
    case 2 %deg bins for angular
        xbin = 30;
        xname = 'angular velocity (deg/s)';
end

% for x edges
xmax = max(xdata) + (xbin - rem(max(xdata),xbin));
xmin = min(xdata) - (xbin + rem(min(xdata),xbin));
xedges = xmin: xbin: xmax;
xticks = xmin + xbin/2: xbin: xmax - xbin/2; %midpoints
% for y edges
ymax = max(ydata) + (ybin - rem(max(ydata),ybin));
ymin = min(ydata) - (ybin + rem(min(ydata),ybin));
yedges = ymin: ybin: ymax;
yticks = ymin + ybin/2: ybin: ymax - ybin/2; %midpoints

% discretize
x_disc = discretize(xdata, xedges, xticks);
y_disc = discretize(ydata, yedges, yticks);

% pool into table
data_tbl = table(x_disc,y_disc,zdata, 'VariableNames', {'x', 'y', 'z'});
% find any nans
nan_idx = any(isnan(table2array(data_tbl)),2); %by row
% remove any nans
data_tbl(nan_idx,:) = [];


%% plot
h = heatmap(data_tbl,'x','y','ColorVariable','z','ColorMethod','mean','CellLabelColor','none');

h.YDisplayData = flipud(h.YDisplayData); %switch so incrementing
grid(h, 'off'); %remove grid

h.XLabel = xname;
h.YLabel = yname;



end

