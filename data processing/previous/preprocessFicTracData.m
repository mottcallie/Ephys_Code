% preprocessFicTracData.m
%
% Function to take output from preprocessUserDaq.m and extract
%  appropriately fictrac data (x position, y position, heading)
%
% INPUTS:
%   daqData - data collected on DAQ, with fields labeled
%   daqOutput - signal output on DAQ during experiment, with fields labeled
%   daqTime - timing vector for daqData and daqOutput
%   inputParams - input parameters from trial function (e.g. ephysRecording)
%   settings - settings struct from ephysSettings
%s
% OUTPUTS:
%   fictracData - struct of x pos (mm)/sideways vel (mm/s), y pos/forward
%                   vel (mm/s), and angular pos (*)/angular vel (*/s)
%
% Created: MB
% Updated: 04/03/21 - MC
%

function fictracData = preprocessFicTracData(daqData, daqOutput, daqTime, inputParams, settings)

% set ball radius depending on setup
ballRadius = 3.175; %mm, for 1/4" acrylic balls

% set fictrac rate depending on setup
fictrac_rate = 30;

% t/f to view summary plot at the end
plotFicTrac = 0;

%% Stepwise processing of fictrac position data

for ft=1:3
    
    % pull preprocessed fictrac data one at a time
    switch ft
        case 1
            positionVoltage = daqData.ficTracHeading;
        case 2
            positionVoltage = daqData.ficTracIntX;
        case 3
            positionVoltage = daqData.ficTracIntY;
    end
    
    % 1)Tranform signal from voltage to radians for unwrapping
    positionRad = positionVoltage*(2*pi)./10;
    
    % 2)Unwrap
    positionRad_uw = unwrap(positionRad);
    
    % 3)Downsample the position data to match FicTrac's output
    positionRad_uw_ds = resample(positionRad_uw,(fictrac_rate/2),settings.bob.sampRate);
    
    % 4)Smooth the data
    positionRad_uw_ds_sm = smoothdata(positionRad_uw_ds,'rlowess',25);
    
    % 5)Transform to useful systems
    switch ft
        case 1 %degrees for yaw (0-360)
            positionUnit = rad2deg(positionRad_uw_ds_sm);
        case {2, 3} %mm for x/y (0-2pi*r)
            positionUnit = positionRad_uw_ds_sm .* ballRadius;
    end
    
    % 6)Take the derivative
    velocity = gradient(positionUnit).*(fictrac_rate/2);
    
    % 7)Calculate the distribution and take away values that are below 2.5% and above 97.5%
    percentile025 = prctile(velocity,2.5);
    percentile975 = prctile(velocity,97.5);
    boundedVelocity = velocity;
    boundedVelocity(velocity<percentile025 | velocity>percentile975) = NaN;
    
    % 8)Linearly interpolate to replace the NaNs with values.
    [pointsVectorV] = find(~isnan(boundedVelocity));
    valuesVectorV = boundedVelocity(pointsVectorV);
    xiV = 1:length(boundedVelocity);
    
    % load into table
    velocity_interpolated = interp1(pointsVectorV,valuesVectorV,xiV);
    
    % 9)Smooth
    velocity_sm = smoothdata(velocity_interpolated,'rlowess',15);
    
    %% Assign output structure
    switch ft
        case 1
            fictracData.headingPosisition = positionUnit; %heading position in degrees
            fictracData.angularVelocity = velocity_sm; %angular velcoity in degrees/s
        case 2
            fictracData.XPosisition = positionUnit; %x position in mm
            fictracData.sidewaysVelocity = velocity_sm; %sideways velocity in mm/s
        case 3
            fictracData.YPosisition = positionUnit; %y position in mm
            fictracData.forwardVelocity = velocity_sm; %forward velocity in mm/s
    end
    
    %% Fictrac processing visualization plot
    if plotFicTrac
        figure(ft),clf
        set(gcf,'Position',[50 50 800 900])
        
        % set color
        switch ft
            case 1
                c='#D95319';
            case 2
                c='#77AC30';
            case 3
                c='#0072BD';
        end
        
        subplot(8,1,1)
        plot(positionVoltage,'Color',c)
        title('Raw voltage signal');
        ylim([0 10]);
        xlim([0 length(positionVoltage)]);
        set(gca,'xticklabel',{[]})
        
        subplot(8,1,2)
        plot(positionRad,'Color',c)
        title('Signal in radians');
        ylim([0 2*pi]);
        xlim([0 length(positionRad)]);
        set(gca,'xticklabel',{[]})
        
        subplot(8,1,3)
        plot(positionRad_uw,'Color',c)
        title('Unwrapped signal in radians');
        xlim([0 length(positionRad_uw)]);
        set(gca,'xticklabel',{[]})
        
        subplot(8,1,4)
        plot(positionRad_uw_ds,'Color',c)
        title('Downsampled signal in radians');
        xlim([0 length(positionRad_uw_ds)]);
        set(gca,'xticklabel',{[]})
        
        subplot(8,1,5)
        plot(positionRad_uw_ds_sm,'Color',c)
        title('Smoothed position signal');
        xlim([0 length(positionRad_uw_ds_sm)]);
        set(gca,'xticklabel',{[]})
        
        subplot(8,1,6)
        plot(positionUnit,'Color',c)
        title('Smoothed position signal in useful units');
        xlim([0 length(positionUnit)]);
        set(gca,'xticklabel',{[]})
        
        subplot(8,1,7)
        plot(velocity,'Color',c)
        title('Velocity signal');
        xlim([0 length(velocity)]);
        set(gca,'xticklabel',{[]})
        
        subplot(8,1,8)
        plot(velocity_sm,'Color',c)
        title('Smoothed velocity signal');
        ylim([-250 250]);
        xlim([0 length(velocity_sm)]);
        xlabel('Time (frames)');
    end
end


end