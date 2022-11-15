function [angularPosition,angularVelocity] = process_fictac_data(rawData,NiDaq_rate,fictrac_rate)

%This function takes the raw voltage data coming into the nidaq with
%fictrac info and processes it to obtain the angular position and velocity in
%relevant units

figure('Position',[50 50 800 900]),
subplot(8,1,1)
plot(rawData)
title('Raw voltage signal');
ylim([0 10]);
xlim([0 length(rawData)]);
set(gca,'xticklabel',{[]})

% 1)Tranform signal from voltage to radians for unwrapping
rad_angularPosition = rawData*(2*pi)./10;
subplot(8,1,2)
plot(rad_angularPosition)
title('Signal in radians');
ylim([0 2*pi]);
xlim([0 length(rad_angularPosition)]);
set(gca,'xticklabel',{[]})


% 2)Unwrap
unwrapped_angularPosition = unwrap(rad_angularPosition);
subplot(8,1,3)
plot(unwrapped_angularPosition)
title('Unwrapped signal in radians');
xlim([0 length(unwrapped_angularPosition)]);
set(gca,'xticklabel',{[]})


% 3)Downsample the position data to match FicTrac's output
downsampled_angularPosition = resample(unwrapped_angularPosition,(fictrac_rate/2),NiDaq_rate);
subplot(8,1,4)
plot(downsampled_angularPosition)
title('Downsampled signal in radians');
xlim([0 length(downsampled_angularPosition)]);
set(gca,'xticklabel',{[]})


% 4)Smooth the data
smoothed_angularPosition = smoothdata(downsampled_angularPosition,'rlowess',25);
subplot(8,1,5)
plot(smoothed_angularPosition)
title('Smoothed position signal');
xlim([0 length(smoothed_angularPosition)]);
set(gca,'xticklabel',{[]})


% 5)Transform to useful systems
deg_angularPosition = rad2deg(smoothed_angularPosition);
subplot(8,1,6)
plot(deg_angularPosition)
title('Smoothed position signal in deg');
xlim([0 length(deg_angularPosition)]);
set(gca,'xticklabel',{[]})

% 6)Take the derivative
diff_angularPosition = gradient(deg_angularPosition).*(fictrac_rate/2);
subplot(8,1,7)
plot(diff_angularPosition)
title('Angular velocity signal in deg');
xlim([0 length(diff_angularPosition)]);
set(gca,'xticklabel',{[]})

% 7)Smooth
angularVelocity = smoothdata(diff_angularPosition,'rlowess',15);
subplot(8,1,8)
plot(angularVelocity)
title('Smoothed angular velocity signal in deg');
ylim([-250 250]);
xlim([0 length(angularVelocity)]);
xlabel('Time (frames)');


%% Note: I will usually add 2 steps in between 6) and 7) to remove extreme values. If you want to perform those steps, uncomment the lines below

% % 7)Calculate the distribution and take away values that are below 2.5% and above 97.5%
% percentile25AV = prctile(diff_angularPosition,2.5);
% percentile975AV = prctile(diff_angularPosition,97.5);
% boundedDiffAngularPos = diff_angularPosition;
% boundedDiffAngularPos(diff_angularPosition<percentile25AV | diff_angularPosition>percentile975AV) = NaN;
% 
% % 8)Linearly interpolate to replace the NaNs with values.
% [pointsVectorAV] = find(~isnan(boundedDiffAngularPos));
% valuesVectorAV = boundedDiffAngularPos(pointsVectorAV);
% xiAV = 1:length(boundedDiffAngularPos);
% interpAngVel = interp1(pointsVectorAV,valuesVectorAV,xiAV);
% 
% % 9)Smooth
% angularVelocity = smoothdata(interpAngVel,'rlowess',15);
    
    
end