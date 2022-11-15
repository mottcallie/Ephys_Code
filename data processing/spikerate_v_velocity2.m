% spikerate_v_velocity2
% analysis function for generating a summary plot of spike rate versus
% directional velocity as heatmaps
%
% OUTPUTS:
%
% INPUTS:
% int_panelps - downsampled panel positions
% int_forward - downsampled forward velocities
% int_forward - downsampled forward velocities
% int_angular - downsampled angular velocities
% int_sideway - downsampled sideways velocities
% int_spikerate - downsampled spikerate
% int_time - downsampled trial time
%
% ORIGINAL: 06/24/2022 - MC
%

function spikerate_v_velocity2(int_forward,int_angular,int_sideway,int_time,int_spikerate)
%% reshape and discretize the data set
% reshape each to single column
rsp_forward = reshape(int_forward,[],1);
rsp_angular = reshape(int_angular,[],1);
rsp_sideway = reshape(int_sideway,[],1);
rsp_spikerate = reshape(int_spikerate,[],1);

% discretize each variable
fs = 1; %bin size
f_max = round(max(rsp_forward),0); %max
f_edge = -fs/2:fs:f_max+fs/2; %bin edges
f_bins = 0:fs:f_max; %bin labels (center)
disc_forward=discretize(rsp_forward,f_edge,f_bins);

as = 40; %bin size
a_max = round(max([rsp_angular -rsp_angular],[],'all'),-1); %max
a_edge = -a_max-as/2:as:a_max+as/2; %bin edges
a_bins = -a_max:as:a_max; %bin labels (center)
disc_angular=discretize(rsp_angular,a_edge,a_bins);

ss = 0.4; %bin size
s_max = round(max([rsp_sideway -rsp_sideway],[],'all'),0); %max
s_edge = -s_max-ss/2:ss:s_max+ss/2; %bin edges
s_bins = -s_max:ss:s_max; %bin labels (center)
disc_sideway=discretize(rsp_sideway,s_edge,s_bins);

rs = 1; %bin size
r_max = round(max(rsp_spikerate),-1); %max
r_edge = -rs/2:rs:r_max+rs/2; %bin edges
r_bins = 0:rs:r_max; %bin labels (center)
disc_spikerate=discretize(rsp_spikerate,r_edge,r_bins);

% compile data and remove NaN values
trialData_pre = [disc_spikerate disc_forward disc_angular disc_sideway];
[rNan, ~] = find(isnan(trialData_pre));
trialData_pre(rNan,:)=[];

% convert to table
colNames = {'SpikeRate','Forward','Angular','Sideway'};
trialData = array2table(trialData_pre,'VariableNames',colNames);

% plot
% initialize
figure; set(gcf,'Position',[100 100 1500 500])

subplot(1,2,1)
h(1) = heatmap(trialData,'Angular','Forward','ColorVariable','SpikeRate');
h(1).YDisplayData = flipud(h(1).YDisplayData);
h(1).CellLabelColor = 'None';
h(1).GridVisible = 'off';

subplot(1,2,2)
h(2) = heatmap(trialData,'Sideway','Forward','ColorVariable','SpikeRate');
h(2).YDisplayData = flipud(h(2).YDisplayData);
h(2).CellLabelColor = 'None';
h(2).GridVisible = 'off';


end

