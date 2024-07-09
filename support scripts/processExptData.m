% processExptData.m
%
% Function to take output from preprocessUserDaq.m and extract
% appropriately scaled and named data ephys(voltage, current,
% scaled out, gain, mode, freq) and g4 display panels (x position)
% and fictrac (x position, y position, heading) and output data (opto or
% current stim)
%
% INPUTS:
%   daqData - data collected on DAQ, with fields labeled
%   daqOutput - signal output on DAQ during experiment, with fields labeled
%   daqTime - timing vector for daqData and daqOutput
%   inputParams - input parameters from trial function (e.g. ephysRecording)
%   settings - settings struct from ephysSettings
%
% OUTPUTS:
%   exptData - struct of appropriately scaled ephys and/or behavior data
%   ephysMeta - struct of ephys metadatam from decoding telegraphed output,
%       trial parameters
%
% Created:  04/03/2021 - MC
%           11/04/2021 - MC removed g3, updated to g4 display
%           11/10/2021 - MC fixed ball width
%           11/15/2021 - MC rotated t, resampled fictrac to match DAQ
%           01/04/2022 - MC fixed resampling error w/fictrac data
%           09/14/2022 - MC g4 data now run through DAC rather than log
%           04/28/2023 - MC exptMeta now stores object size
%

function [exptData, exptMeta] = processExptData(daqData, daqOutput, daqTime, inputParams, settings)

%% meta data

% transfer meta data
exptMeta.exptCond = inputParams.exptCond;
exptMeta.startTimeStamp = inputParams.startTimeStamp;

% if input resistance was calculated for said trial
if isfield(inputParams,'inputResistance')
    exptMeta.inputResistance = inputParams.inputResistance;
end

% time points of recording
exptData.t = daqTime';
ln = length(exptData.t);


%% ephys data
% check if ephys data was collected, if so, process
if contains(inputParams.exptCond,'ephys','IgnoreCase',true)

    % decode telegraphed output
    exptMeta.gain = decodeTelegraphedOutput(daqData.ampGain, 'gain');
    exptMeta.freq = decodeTelegraphedOutput(daqData.ampFreq, 'freq');
    exptMeta.mode = decodeTelegraphedOutput(daqData.ampMode, 'mode');

    % process non-scaled output
    % voltage in mV
    exptData.voltage = settings.Vm.softGain .* daqData.amp10Vm;
    % current in pA
    exptData.current = settings.I.softGain .* daqData.ampI;

    % process scaled output
    switch exptMeta.mode
        case {'Track','V-Clamp'} % voltage clamp, scaled out is current
            % I = alpha * beta mV/pA (1000 is to convert from V to mV)
            exptMeta.softGain = 1000 / ...
                (exptMeta.gain * settings.amp.beta);
            % scaled out is current, in pA
            exptData.scaledCurrent = exptMeta.softGain .* ...
                daqData.ampScaledOut;
            % current clamp, scaled out is voltage
        case {'I=0','I-Clamp','I-Clamp Fast'}
            % V = alpha mV / mV (1000 for V to mV)
            exptMeta.softGain = 1000 / exptMeta.gain;
            % scaled out is voltage, in mV
            exptData.scaledVoltage = exptMeta.softGain .* ...
                daqData.ampScaledOut;
    end
end

%% output data
% check if output (current inj) data was collected, if so, process
if contains(inputParams.exptCond,'inj','IgnoreCase',true)

    % convert from DAQ output back to target current
    exptData.iInj = daqOutput.ampExtCmdIn/settings.VOut.IConvFactor;
end
% check if opto stimulation data was collected, if so, process
if contains(inputParams.exptCond,'stim','IgnoreCase',true)
    exptData.optoStim = daqOutput.optoExtCmd;
end


%% g4 panel data
% check if panels were used, if so, process
if contains(inputParams.exptCond,'g4','IgnoreCase',true)

    % convert from 0-10V AO0 output to 0-360degree mapping
    exptData.g4displayXPos = (daqData.g4panelXPosition./10) *360;

    % if function name provided, store it
    if isfield(inputParams,'function_name')
        exptMeta.func = inputParams.function_name;
    end

    % if object size provided, store it
    if isfield(inputParams,'objectSize')
        obj = inputParams.objectSize;
        if ~isnumeric(obj)
            obj = str2num(obj);
        end
        exptMeta.objSize = obj;
    end

end

%% python jump data
% check if a python script was used to jump the bar position
if contains(inputParams.exptCond,'jumps','IgnoreCase',true)
    % clean up and store
    exptData.pythonJumpTrig = round(daqData.pythonJumpTrig);
end

%% behavior data
% check if behavior data was collected, if so, process
if contains(inputParams.exptCond,'fictrac','IgnoreCase',true)

    %note:
    %X is forward
    %Y is side-to-side (roll)
    %heading is angular (yaw)

    fictrac_rate = 50; %set fictrac acquisition rate
    ballRadius = 9/2; %set ball radius in mm

    % pull preprocessed fictrac data in order to processes together
    positionVoltage = [daqData.ficTracHeading, daqData.ficTracIntX,...
        daqData.ficTracIntY];

    % 1)Tranform signal from voltage to radians for unwrapping
    positionRad = positionVoltage*(2*pi)./10;

    % 2)Unwrap
    positionRad_uw = unwrap(positionRad);

    % 3)Downsample the position data to match FicTrac's output
    positionRad_uw_ds = resample(positionRad_uw,(fictrac_rate/2),settings.bob.sampRate);

    % 4)Smooth the data
    positionRad_uw_ds_sm = smoothdata(positionRad_uw_ds,'rlowess',25);

    % 5)Transform to useful systems
    positionUnit(:,1) = rad2deg(positionRad_uw_ds_sm(:,1)); %degrees for yaw (0-360)
    positionUnit(:,2:3) = positionRad_uw_ds_sm(:,2:3) .* ballRadius; %mm for x/y (0-2pi*r)

    % 6)Take the derivative (must be done one at a time)
    velocity(:,1) = gradient(positionUnit(:,1)).*(fictrac_rate/2);
    velocity(:,2) = gradient(positionUnit(:,2)).*(fictrac_rate/2);
    velocity(:,3) = gradient(positionUnit(:,3)).*(fictrac_rate/2);

    % 7)OPTIONAL: Smooth again
    velocity_sm = smoothdata(velocity,'rlowess',15);

    % 8)Resample to match DAQ
    % add caps to avoid end resampling error
    cap = 10;
    velocity_sm_cap = [repmat(velocity_sm(1,:),cap,1); velocity_sm; repmat(velocity_sm(end,:),cap,1)];
    position_sm_cap = [repmat(positionUnit(1,:),cap,1); positionUnit; repmat(positionUnit(end,:),cap,1)];
    % resample
    velocity_rs_cap = resample(velocity_sm_cap,settings.bob.sampRate,(50/2),3,10);
    positionUnit_rs_cap = resample(position_sm_cap,settings.bob.sampRate,(50/2),3,10);
    % remove caps
    rsFactor = cap * settings.bob.sampRate/(50/2);
    velocity_rs = velocity_rs_cap;
    velocity_rs(1:rsFactor,:) = [];
    velocity_rs(end-rsFactor+1:end,:) = [];
    positionUnit_rs = positionUnit_rs_cap;
    positionUnit_rs(1:rsFactor,:) = [];
    positionUnit_rs(end-rsFactor+1:end,:) = [];


    %Assign output structure
    exptData.headingPosition = positionUnit_rs(1:ln,1); %heading position in degrees
    exptData.angularVelocity = velocity_rs(1:ln,1); %angular velcoity in degrees/s

    exptData.XPosition = positionUnit_rs(1:ln,2); %x position in mm
    exptData.forwardVelocity = velocity_rs(1:ln,2); %forward velocity in mm/s

    exptData.YPosition = positionUnit_rs(1:ln,3); %y position in mm
    exptData.sidewaysVelocity = velocity_rs(1:ln,3); %sideways velocity in mm/s

end


%% leg data
% check if leg video was collected, if so, process
if contains(inputParams.exptCond,'legvid','IgnoreCase',true)
    exptData.legCamFramesIn = daqData.legCamFrames;
    exptData.legCamFrameStartTrig = daqOutput.legCamFrameStartTrig;
end
end