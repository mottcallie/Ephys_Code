% extractMoveCondKernels.m
%
% Function that takes in data conditioned on whether the fly was moving or
%  not (from the function moveCondPairData() and returns the kernels and
%  autocorrelations only during the time period where the fly was moving. 
% Similar to extractKernels() but starts with trials already selected, data
%  already resampled to 100 Hz, and NaNs present.
%
% NOTE: code works but with current movement conditioned data, the bouts
%  are too short to extract meaningful kernels
%
% INPUT:
%   condPairData - struct array of movement conditioned data, 1 element per
%     fly, with fields:
%       img - struct with fields of dF/F for left, right, sum, diff (only
%           those that exist for that fly
%       fictrac - struct with fields of behavioral variables: fwdVel,
%           yawVel, slideVel, yawSpd, totSpd
%       flyID - flyID for which fly contributed that data
%   kernelParams - struct of kernel parameters
%       winLen - length of window, in seconds that averages are computed 
%           over
%       cutFreq - cutoff frequency (f_cut) in attenuation applied to
%           frequency domain filter, a la Nagel and Wilson 2011. Set to 0 
%           with tauFreq if no attenuation desired.
%       tauFreq - f_tau in attenuation applied to frequency domain filter, 
%           a la Nagel and Wilson 2011. Set to 0 with cutFreq if no 
%           attenuation desired.
%       sampRate - sampling rate to convert dF/F and FicTrac data to, and
%           to calculate kernel at
%       fwdKernelBW - full bandwidth of Slepian window filter applied to
%           forward kernels post-hoc
%       revKernelBW - full bandwidth of Slepian window filter applied to
%           reverse kernels post-hoc
%   autoCorrParams - struct of autocorrelation parameters
%       maxLag - maximum lag for autocorrelation, in seconds
%
% OUTPUT:
%   kernels - struct with all the kernel data
%       fFwdVel, fYawVel, fYawSpd, fTotSpd, fSlideVel, rFwdVel, rYawVel,
%           rYawSpd, rTotSpd, rSlideVel
%       for each of the above fields: fields left, right, sum, diff
%       for each of the above fields: allKernels (fly x kernelLen matrix),
%           flyID (fly x 1 vector, corresponding dimensions to kernel),
%           meanKernel (1 x kernelLen vector), sem (1 x kernelLen vector),
%           numFlies (number of flies), varExpl (variance explained, fly 
%           x 1 vector)
%   kernelParams - struct of kernel parameters (as input, but adds)
%       t - kernel times in sec
%   autoCorrParams - struct of kernel parameters (as input, but adds)
%       sampRate - sampling rate autocorrelation was computed at, is equal
%           to kernelParams.sampRate
%       lags - autocorrelation times in sec
%   autoCorr - struct with all of the autocorrelation data
%       imgLeft, imgRight, imgSum, imgDiff, FwdVel, YawVel, SlideVel,
%           YawSpd, TotSpd
%       for each of the above fields: allAutoCorr, flyID, meanAutoCorr,
%           sem, numFlies
%
% CREATED: 9/26/19 - HHY
%
% UPDATED: 9/26/19 - HHY
%
function [kernels, kernelParams, autoCorrParams, autoCorr] = ...
    extractMoveCondKernels(condPairData, kernelParams, autoCorrParams)

    % names of behavioral variables
    behVars = {'FwdVel', 'SlideVel', 'YawVel', 'YawSpd','TotSpd'};
    
    % set autocorrelation sampling rate to same as kernel sampling rate
    autoCorrParams.sampRate = kernelParams.sampRate;
    
    % preallocate
    flyIDs = extractfield(condPairData, 'flyID');
    numFlies = length(flyIDs);
    kernelLen = (kernelParams.sampRate * 2*kernelParams.winLen) - 1;
    % max lag of autocorrelation, in samples
    autoCorrMaxLagSamp = (autoCorrParams.maxLag * autoCorrParams.sampRate);
    % length of autocorrelation is 1 more than max lag
    autoCorrLen = autoCorrMaxLagSamp + 1;
    
    % struct structure for left, right, sum, diff fields
    oneCellStrct.allKernels = zeros(numFlies, kernelLen);
    oneCellStrct.flyID = zeros(numFlies, 1);
    oneCellStrct.meanKernel = zeros(1, kernelLen);
    oneCellStrct.sem = zeros(1, kernelLen);
    oneCellStrct.numFlies = numFlies;
    oneCellStrct.varExpl = zeros(numFlies, 1);
    
    % use oneCellStrct to compose struct for 1 kernel condition
    oneKernelCondStrct.left = oneCellStrct;
    oneKernelCondStrct.right = oneCellStrct;
    oneKernelCondStrct.sum = oneCellStrct;
    oneKernelCondStrct.diff = oneCellStrct;
    
    % use oneKernelCondStrct to compose full kernels struct
    kernels.fFwdVel = oneKernelCondStrct;
    kernels.fYawVel = oneKernelCondStrct;
    kernels.fSlideVel = oneKernelCondStrct;
    kernels.fYawSpd = oneKernelCondStrct;
    kernels.fTotSpd = oneKernelCondStrct;
    kernels.rFwdVel = oneKernelCondStrct;
    kernels.rYawVel = oneKernelCondStrct;
    kernels.rSlideVel = oneKernelCondStrct;
    kernels.rYawSpd = oneKernelCondStrct;
    kernels.rTotSpd = oneKernelCondStrct;
    
    oneVarACStrct.allAutoCorr = zeros(numFlies, autoCorrLen);
    oneVarACStrct.flyID = zeros(numFlies, 1);
    oneVarACStrct.meanAutoCorr = zeros(1, autoCorrLen);
    oneVarACStrct.sem = zeros(1, autoCorrLen);
    oneVarACStrct.numFlies = numFlies;
    
    autoCorr.left = oneVarACStrct;
    autoCorr.right = oneVarACStrct;
    autoCorr.sum = oneVarACStrct;
    autoCorr.diff = oneVarACStrct;
    autoCorr.FwdVel = oneVarACStrct;
    autoCorr.YawVel = oneVarACStrct;
    autoCorr.SlideVel = oneVarACStrct;
    autoCorr.YawSpd = oneVarACStrct;
    autoCorr.TotSpd = oneVarACStrct;
    
    % loop through all flies
    for i = 1:numFlies
        curFlyID = flyIDs(i);
        
        cellFieldNames = fieldnames(oneKernelCondStrct);
                    
        % get moving FicTrac data
        FwdVel = condPairData(i).fictrac.move.fwdVel;
        SlideVel = condPairData(i).fictrac.move.slideVel;
        YawVel = condPairData(i).fictrac.move.yawAngVel;
        YawSpd = condPairData(i).fictrac.move.yawAngSpd;
        TotSpd = condPairData(i).fictrac.move.totAngSpd;
        
        % loop through all behavioral variables
        for j = 1:length(behVars)
            
            % forward and reverse kernel names
            fKernName = ['f' behVars{j}];
            rKernName = ['r' behVars{j}];

            % loop through all img (left, right, sum, diff)
            for k = 1:length(cellFieldNames)
                imgDat = condPairData(i).img.(cellFieldNames{k});
                imgDat(condPairData(i).moveLog) = nan;

                % if this fly has this img type, compute kernel
                if any(~isnan(imgDat))
                    % compute forward kernel
                    [tempKern, lags, numSeg] = computeWienerKernel(...
                        eval(behVars{k}), imgDat, kernelParams.sampRate, ...
                        kernelParams.winLen, kernelParams.cutFreq, ...
                        kernelParams.tauFreq);
                    % data went into this kernel
                    if (numSeg > 0)
                        kernels.(fKernName).(cellFieldNames{k}).allKernels(i,:) = ...
                            slepianWinFilter(tempKern, ...
                            kernelParams.fwdKernelBW, ...
                            kernelParams.sampRate);
                        predResp = computeLinearPrediction(...
                            kernels.(fKernName).(cellFieldNames{k}).allKernels(i,:),...
                            eval(behVars{k}));
                        [kernels.(fKernName).(cellFieldNames{k}).varExpl(i),...
                            ~] = computeVarianceExplained(imgDat, predResp, ...
                            'poly1');
                        kernels.(fKernName).(cellFieldNames{k}).flyID(i) = curFlyID;
                    else % data didn't go into this kernel (likely, bouts too short)
                        % set all values to NaN
                        kernels.(fKernName).(cellFieldNames{k}).allKernels(i,:) = nan;
                        kernels.(fKernName).(cellFieldNames{k}).flyID(i) = nan;
                        kernels.(fKernName).(cellFieldNames{k}).allKernels(i,:) = nan;
                        kernels.(fKernName).(cellFieldNames{k}).varExpl(i) = nan;   
                    end

                    % compute reverse kernel
                    [tempKern, ~, numSeg] = computeWienerKernel(...
                        imgDat, eval(behVars{k}),  kernelParams.sampRate, ...
                        kernelParams.winLen,kernelParams.cutFreq, ...
                        kernelParams.tauFreq);
                    % data went into this kernel
                    if (numSeg > 0)
                        kernels.(rKernName).(cellFieldNames{k}).allKernels(i,:) = ...
                            slepianWinFilter(tempKern, kernelParams.revKernelBW, ...
                            kernelParams.sampRate);
                        predResp = computeLinearPrediction(...
                            kernels.(rKernName).(cellFieldNames{k}).allKernels(i,:),...
                            imgDat);
                        [kernels.(rKernName).(cellFieldNames{k}).varExpl(i),...
                            ~] = computeVarianceExplained(...
                            eval(behVars{k}), predResp,'poly1');  
                        kernels.(rKernName).(cellFieldNames{k}).flyID(i) = curFlyID;
                    else % data didn't go into this kernel
                        % set all values to NaN
                        kernels.(rKernName).(cellFieldNames{k}).allKernels(i,:) = nan;
                        kernels.(rKernName).(cellFieldNames{k}).flyID(i) = nan;
                        kernels.(rKernName).(cellFieldNames{k}).allKernels(i,:) = nan;
                        kernels.(rKernName).(cellFieldNames{k}).varExpl(i) = nan; 
                    end

                else % if this fly doesn't have this img type
                    % set all values to NaN
                    kernels.(fKernName).(cellFieldNames{k}).allKernels(i,:) = nan;
                    kernels.(fKernName).(cellFieldNames{k}).flyID(i) = nan;
                    kernels.(fKernName).(cellFieldNames{k}).allKernels(i,:) = nan;
                    kernels.(fKernName).(cellFieldNames{k}).varExpl(i) = nan;
                    kernels.(rKernName).(cellFieldNames{k}).allKernels(i,:) = nan;
                    kernels.(rKernName).(cellFieldNames{k}).flyID(i) = nan;
                    kernels.(rKernName).(cellFieldNames{k}).allKernels(i,:) = nan;
                    kernels.(rKernName).(cellFieldNames{k}).varExpl(i) = nan;    
                end
            end
        end
        
        % loop through and compute behavioral autocorrelations for
        %  this fly
        for j = 1:length(behVars)
            [autoCorr.(behVars{j}).allAutoCorr(i,:),...
                autoCorrLags] = normAutoCorrWNan(eval(behVars{j}),...
                autoCorrMaxLagSamp);
            autoCorr.(behVars{k}).flyID(i) = curFlyID;
        end

        % loop through and compute imaging autocorrelations for
        %  this fly
        for j = 1:length(cellFieldNames)
            imgDat = condPairData(i).img.(cellFieldNames{j});
            imgDat(condPairData(i).moveLog) = nan;
            
            % if fly has this imaging type, compute autocorr
            if any(~isnan(imgDat))
                [autoCorr.(cellFieldNames{j}).allAutoCorr(i,:),...
                    autoCorrLags] = normAutoCorrWNan(...
                    imgDat, autoCorrMaxLagSamp);
                autoCorr.(cellFieldNames{j}).flyID(i) = curFlyID;
            else % trial doesn't have this img type, set values to nan
                autoCorr.(cellFieldNames{j}).allAutoCorr(i,:) = nan;
                autoCorr.(cellFieldNames{j}).flyID(i) = nan;
            end
        end
        
    end
    
    % clean up kernels matrix, compute mean, sem
    kFN = fieldnames(kernels);
    for i = 1:length(kFN)
        % loop through all img/cells
        cFN = fieldnames(kernels.fFwdVel);
        for j = 1:length(cFN)
            % remove all nans
%             kernels.(kFN{i}).(cFN{j}).allKernels(...
%                 isnan(kernels.(kFN{i}).(cFN{j}).allKernels)) = [];
            
            % need to loop when using matrix
            delRows = [];
            for k = 1:size(kernels.(kFN{i}).(cFN{j}).allKernels,1)
                if (isnan(kernels.(kFN{i}).(cFN{j}).allKernels(k,1)))
                    delRows = [delRows k];
                end
            end
            kernels.(kFN{i}).(cFN{j}).allKernels(delRows, :) = [];
            
            kernels.(kFN{i}).(cFN{j}).flyID(...
                isnan(kernels.(kFN{i}).(cFN{j}).flyID)) = [];
            kernels.(kFN{i}).(cFN{j}).varExpl(...
                isnan(kernels.(kFN{i}).(cFN{j}).varExpl)) = [];
            
            % compute mean
            kernels.(kFN{i}).(cFN{j}).meanKernel = mean(...
                kernels.(kFN{i}).(cFN{j}).allKernels, 1);
            % get number of flies
            kernels.(kFN{i}).(cFN{j}).numFlies = length(...
                kernels.(kFN{i}).(cFN{j}).flyID);
            % get standard error of the mean
            kernels.(kFN{i}).(cFN{j}).sem = std(...
                kernels.(kFN{i}).(cFN{j}).allKernels, [], 1) ./ ...
                sqrt(kernels.(kFN{i}).(cFN{j}).numFlies);
            
        end
    end    
    
    % clean up autoCorr, compute mean, sem
    % loop through all fields of autoCorr
    acFN = fieldnames(autoCorr);
    for i = 1:length(acFN)
        % remove NaNs from autocorrelations
        delRows = [];
        for k = 1:size(autoCorr.(acFN{i}).allAutoCorr, 1)
            if (isnan(autoCorr.(acFN{i}).allAutoCorr(k,1)))
                delRows = [delRows k];
            end
        end
        autoCorr.(acFN{i}).allAutoCorr(delRows, :) = [];
        
        % remove NaNs from flyID
        autoCorr.(acFN{i}).flyID(...
            isnan(autoCorr.(acFN{i}).flyID)) = [];
        
        % compute mean
        autoCorr.(acFN{i}).meanAutoCorr = mean(...
            autoCorr.(acFN{i}).allAutoCorr, 1);
        % get number of flies
        autoCorr.(acFN{i}).numFlies = length(autoCorr.(acFN{i}).flyID);
        % sem
        autoCorr.(acFN{i}).sem = ...
            std(autoCorr.(acFN{i}).allAutoCorr, [], 1) ./ ...
            sqrt(autoCorr.(acFN{i}).numFlies);
    end

    
    % save kernelsParams.t
    kernelParams.t = lags;
    
    % save autoCorrParams.lags
    autoCorrParams.lags = autoCorrLags ./ autoCorrParams.sampRate;
end