% spike_v_velocity_scater
% function for generating scatter plot of cell spikerate vs directional velocity
%
% INPUTS:
% allSpikeRate - pooled spikerate data
% allVelocity - pooled directional velocity data
% trialtitle - what to call subplot
%
% 05/24/22 MC
%

function spike_v_velocity_scatter(allSpikeRate,allVelocity,trialtitle)
%% reshape

% reshape data for each pattern type
reshapeSR = reshape(allSpikeRate,[],1);
reshapeVel = reshape(allVelocity,[],1);

% round
reshapeSRr = round(reshapeSR,1);
reshapeVelr = round(reshapeVel,1);

scatter(reshapeVelr,reshapeSRr,5,'.')
lsline

end

