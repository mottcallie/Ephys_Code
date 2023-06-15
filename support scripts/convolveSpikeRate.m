% convolveSpikeRate.m
%
% Analysis function
% Detects spikes and then applies a convolution kernel to calculate the
% spike rate
%
% INPUTS:
%   settings - struct of ephys setup settings, from ephysSettings()
%   exptData - processed experiment data
%
% OUTPUTS:
%   pk_v - voltage of spike peaks
%   pk_r - raster of spikes
%   spikeRate - convolved spike rate
%
% CREATED:  12/14/2021 MC
%

function  [pk_v,pk_r,spikeRate] = convolveSpikeRate(settings,exptData,ktype)

%% pull trace and time

% pull time and sample rate
t = exptData.t;
sr = settings.bob.sampRate;

% pull voltage or current trace
if isfield(exptData,'scaledVoltage') %iclamp
    % set findpeak variables
    minProm = 4;
    maxWidth = 1e-2 * sr;
    minDistance = 1.5e-3 * sr;
    minWidth = 0.3e-3 * sr;
    
    ylbl = 'voltage (mV)';
    spikeTrace = exptData.scaledVoltage;
    inv = 1; %do not invert
elseif isfield(exptData,'scaledCurrent') %vclamp
    % set findpeak variables
    minProm = 6;
    maxWidth = .09e-2 * sr;
    minDistance = 1.5e-3 * sr;
    minWidth = 0.3e-3 * sr;
    
    ylbl = 'current (pA)';
    spikeTrace = exptData.scaledCurrent;
    inv = -1; %invert
end


%% detect spikes

% find peaks
[pk_v,pk_i] = findpeaks((spikeTrace .* inv),...
    'MinPeakProminence', minProm,...
    'MinPeakWidth', minWidth,...
    'MaxPeakWidth', maxWidth,...
    'MinPeakDistance', minDistance);
pk_v = pk_v * inv;

% create raster
pk_r = zeros(length(t),1);
pk_r(pk_i) = 1;


%% convolve to find spike rate

switch ktype
    case 'causal'
        % create kernel
        tau = 60000; %increase to increase smoothing
        tc = 0:(tau*10);
        kernel = 0.5 * exp(-tc./tau);
%         plot(t(tc+1),kernel) %preview kernel
%         trapz(t(tc+1),kernel)
        
        % convolve spikerate
        spikeRate = zeros(1,length(spikeTrace)); %initialize
        for p = 1:length(pk_i)
            pk_idx = pk_i(p) + tc;
            if max(pk_idx) > length(spikeRate) %if kernel runs over
                pk_idx = pk_idx(pk_idx<=length(spikeRate));
            end
            spikeRate(1,pk_idx) = spikeRate(1,pk_idx) + kernel(1:length(pk_idx));
        end
        
    case 'gaussian'
        
        % create kernel
        sigma = 2000;
        %sigma = 4000; %increase to increase smoothing
        tc = -(sigma*10):(sigma*10);
        kernel = gaussmf(tc,[sigma 0]);
        %plot(kernel) %preview kernel
        trapz(tc,kernel)./sr;
        
        spikeRate = conv(pk_r,kernel,'same');

end



%% plot
if 1
    figure(10); clf;
    set(gcf,'Position',[100 100 1200 500])
    sr(1) = subplot(3,1,1:2);
    plot(t,spikeTrace,'k',t(pk_i),pk_v,'.','MarkerEdgeColor','#D95319')
    ylabel(ylbl)

    sr(2) = subplot(3,1,3);
    plot(t,spikeRate,'color','#D95319')
    ylabel('spikes/sec')
    xlabel('time (sec.)')

    linkaxes(sr,'x')
end
end

