% interpolateSpikeRate.m
%
% Analysis function
% Finds the time point indices for each action potential peak and then
% calculates the instantaneous spike rate
%
% INPUTS:
%   settings - struct of ephys setup settings, from ephysSettings()
%   exptData - processed experiment data
%   pk_prominence - find peaks that drop by at least this much on either side
%   plotAnnotated - 0 or 1, optional plot at the end
%
% OUTPUTS:
%   pk_v - voltage of spike peaks
%   pk_t - times at which spike peak occured
%   spike_rate - interpolated spike rate vector
%
% CREATED:  11/15/2021 - MC
%           12/07/2021 - MC made compatible for either iclamp and vclamp
%           12/09/2021 - added condition for <2 spikes (interp fails)
%

function  [pk_v,pk_t,spike_rate] = interpolateSpikeRate(settings,exptData, pkProminence, plotAnnotated)

% pull trace and time
if isfield(exptData,'scaledVoltage') %iclamp
    ylbl = 'voltage (mV)';
    spikeTrace = exptData.scaledVoltage;
    inv = 1; %do not invert
elseif isfield(exptData,'scaledCurrent') %vclamp
    ylbl = 'current (pA)';
    spikeTrace = exptData.scaledCurrent;
    inv = -1; %invert
end
t = exptData.t;

% find spike peaks
% note: this method only works for neurons with big, prominent spikes
[pk_v,pk_t] = findpeaks((spikeTrace .* inv),settings.bob.sampRate,...
    'MinPeakProminence',pkProminence,'MinPeakDistance',0.005);
pk_v = pk_v * inv;

% calculate interspike interval (difference between points)
interspike = gradient(pk_t);
% calculate spikes per second (inverse)
spikespersec = 1./interspike;

% interpolate spike rate based on spike times
if length(pk_t)<2
    %not enough points to interpolate, will crash
    spike_rate = zeros(1,length(t));
else
    spike_rate = interp1(pk_t, spikespersec,t);
end

% plot
if plotAnnotated
    figure(5); clf;
    set(gcf,'Position',[100 100 1200 500])
    subplot(3,1,1:2);
    plot(t,spikeTrace,'k',pk_t,pk_v,'.','MarkerEdgeColor','#D95319')
    ylabel(ylbl)
    subplot(3,1,3);
    plot(t,spike_rate,'color','#D95319')
    ylabel('spikes/sec')
    xlabel('time (sec.)')
end
end

