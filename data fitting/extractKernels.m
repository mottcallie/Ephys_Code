% extractKernels.m
%
% Function that takes in metaDat struct of selected trials and returns 
%  linear filters and autocorrelations, 1 per fly. Also returns mean and
%  standard error of the mean.
%
% INPUT:
%   selMetaDat - metaDat struct with only trials that will be incorporated
%       in this analysis
%   pdPath - full path to pData directory
%   kernelParams - struct of kernel parameters
%       winLen - length of window, in seconds that averages are computed 
%           over
%       cutFreq - cutoff frequency (f_cut) in attenuation applied to
%           frequency domain filter, a la Nagel and Wilson 2011. Set to 0 
%           with tauFreq if no attenuation desired.
%       tauFreq - f_tau in attenuation applied to frequency domain filter, 
%           a la Nagel and Wilson 2011. Set to 0 with cutFreq if no 
%           attenuation desired.
%       sampRate - sampling rate to convert activity and FicTrac data to,
%           and to calculate kernel at
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
%   exptNames - cell array of experiment names that went into this data
%
% CREATED: 8/28/19 - HHY
%
% UPDATED: 
%   8/28/2019 - HHY
%   9/04/2019 - HHY added computation of autocorrelations
%   9/16/2022 - MC

function [kernels, autoCorr, exptNames, kernelParams, autoCorrParams] = extractKernels(selMetaDat, pdPath, kernelParams, autoCorrParams)

    curDir = pwd;
    cd(pdPath);
    
    % names of all pData files
    pDataFiles = dir(pdPath);
    pDataFileNames = extractfield(pDataFiles, 'name');
    
    % experiment names
    exptNames = selMetaDat.ExperimentName;
    
    % set autocorrelation sampling rate to same as kernel sampling rate
    autoCorrParams.sampRate = kernelParams.sampRate;

    % preallocate
    flyIDs = unique(selMetaDat.FlyID);
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

    % loop through all selected flies
    for i = 1:numFlies
        curFlyID = flyIDs(i);
        
        % which trials in selMetaDat belong to this fly
        whichInd = find(selMetaDat.FlyID == curFlyID);
        
        % number of trials that belong to this fly
        numTrials = length(whichInd);
        
        % preallocate 
        % valid time vector, used to compute contribution of each trial to 
        %  fly's total
        oneCellTrialStrct.validTime = zeros(numTrials,1);
        % matrix for all trial kernels
        oneCellTrialStrct.allTrialKernels = zeros(numTrials, kernelLen);
        % vector for variance explained
        oneCellTrialStrct.allTrialVarExpl = zeros(numTrials,1);
        
        oneCellCondStrct.left = oneCellTrialStrct;
        oneCellCondStrct.right = oneCellTrialStrct;
        oneCellCondStrct.sum = oneCellTrialStrct;
        oneCellCondStrct.diff = oneCellTrialStrct;
        
        oneFlyKernel.fFwdVel = oneCellCondStrct;
        oneFlyKernel.fYawVel = oneCellCondStrct;
        oneFlyKernel.fSlideVel = oneCellCondStrct;
        oneFlyKernel.fYawSpd = oneCellCondStrct;
        oneFlyKernel.fTotSpd = oneCellCondStrct;
        oneFlyKernel.rFwdVel = oneCellCondStrct;
        oneFlyKernel.rYawVel = oneCellCondStrct;
        oneFlyKernel.rSlideVel = oneCellCondStrct;
        oneFlyKernel.rYawSpd = oneCellCondStrct;
        oneFlyKernel.rTotSpd = oneCellCondStrct;
        
        % preallocate for autocorrelation
        oneTrialACStrct.validTime = zeros(numTrials,1);
        oneTrialACStrct.allTrialAutoCorr = zeros(numTrials, autoCorrLen);
        
        oneFlyAutoCorr.left = oneTrialACStrct;
        oneFlyAutoCorr.right = oneTrialACStrct;
        oneFlyAutoCorr.sum = oneTrialACStrct;
        oneFlyAutoCorr.diff = oneTrialACStrct;
        oneFlyAutoCorr.FwdVel = oneTrialACStrct;
        oneFlyAutoCorr.YawVel = oneTrialACStrct;
        oneFlyAutoCorr.SlideVel = oneTrialACStrct;
        oneFlyAutoCorr.YawSpd = oneTrialACStrct;
        oneFlyAutoCorr.TotSpd = oneTrialACStrct;
        
        % loop through all trials for this fly
        for j = 1:numTrials
            % load relevant pData for this file
            curExptName = selMetaDat.ExperimentName{whichInd(j)};
            pDataName = [curExptName '_pData.mat'];
            
            % check that pData file exists
            hasPDat = sum(strcmp(pDataFileNames, pDataName));
            if (hasPDat)
                % load pData
                load(pDataName, 'fictrac', 'img');
                
                % turn FicTrac values to NaNs where it dropped
                
                % hack to delete zeros from dropInd, bug in when it was
                %  computed -- FIX
                fictrac.dropInd(fictrac.dropInd < 1) = [];
                
                fictrac.fwdVel(fictrac.dropInd) = nan;
                fictrac.slideVel(fictrac.dropInd) = nan;
                fictrac.yawAngVel(fictrac.dropInd) = nan;
                fictrac.yawAngSpd(fictrac.dropInd) = nan;
                fictrac.totAngSpd(fictrac.dropInd) = nan;
                
                % convert dF/F data and FicTrac data to same timescale
                newT = img.t(1):(1/kernelParams.sampRate):img.t(end);
                % linear interpolation of fictrac data
                FwdVel = interp1(fictrac.t, fictrac.fwdVel', newT);
                SlideVel = interp1(fictrac.t, fictrac.slideVel', newT);
                YawVel = interp1(fictrac.t, fictrac.yawAngVel', newT);
                YawSpd = interp1(fictrac.t, fictrac.yawAngSpd', newT);
                TotSpd = interp1(fictrac.t, fictrac.totAngSpd', newT);
                
                % names of behavioral variables
                behVars = {'FwdVel', 'SlideVel', 'YawVel', 'YawSpd',...
                    'TotSpd'};
                
                % linear interpolation of dF/F data
                dffFieldNames = fieldnames(img.filtDFF);
                for k = 1:length(dffFieldNames)
                    dffRS.(dffFieldNames{k}) = interp1(img.t, ...
                        img.filtDFF.(dffFieldNames{k})', newT);
                end
                
                % loop through and compute all kernels for this trial
                % loop through all behavioral variables
                for k = 1:length(behVars)
                    cellFieldNames = fieldnames(oneFlyKernel.fFwdVel);
 
                    fKernName = ['f' behVars{k}];
                    rKernName = ['r' behVars{k}];
                    
                    % loop through all img (left, right, sum, diff)
                    for l = 1:length(cellFieldNames)

                        % if this trial has this img type
                        if (sum(strcmpi(dffFieldNames, cellFieldNames{l}))) 
                            
                            % compute forward kernel
                            [tempKern, lags, numSeg] = computeWienerKernel(...
                                eval(behVars{k}), ...
                                dffRS.(cellFieldNames{l}), ...
                                kernelParams.sampRate, ...
                                kernelParams.winLen,...
                                kernelParams.cutFreq, ...
                                kernelParams.tauFreq);
                            oneFlyKernel.(fKernName).(cellFieldNames{l}).validTime(j) = ...
                                numSeg;
                            oneFlyKernel.(fKernName).(cellFieldNames{l}).allTrialKernels(j,:) = ...
                                slepianWinFilter(tempKern, ...
                                kernelParams.fwdKernelBW, ...
                                kernelParams.sampRate);
                            predResp = computeLinearPrediction(...
                                oneFlyKernel.(fKernName).(cellFieldNames{l}).allTrialKernels(j,:),...
                                eval(behVars{k}));
                            [oneFlyKernel.(fKernName).(cellFieldNames{l}).allTrialVarExpl(j),...
                                ~] = computeVarianceExplained(...
                                dffRS.(cellFieldNames{l}), predResp, ...
                                'poly1');
                            
                            % compute reverse kernel
                            [tempKern, ~, numSeg] = computeWienerKernel(...
                                dffRS.(cellFieldNames{l}), ...
                                eval(behVars{k}), ...
                                kernelParams.sampRate, ...
                                kernelParams.winLen,...
                                kernelParams.cutFreq, ...
                                kernelParams.tauFreq);
                            oneFlyKernel.(rKernName).(cellFieldNames{l}).validTime(j) = ...
                                numSeg;
                            oneFlyKernel.(rKernName).(cellFieldNames{l}).allTrialKernels(j,:) = ...
                                slepianWinFilter(tempKern, ...
                                kernelParams.revKernelBW, ...
                                kernelParams.sampRate);
                            predResp = computeLinearPrediction(...
                                oneFlyKernel.(rKernName).(cellFieldNames{l}).allTrialKernels(j,:),...
                                dffRS.(cellFieldNames{l}));
                            [oneFlyKernel.(rKernName).(cellFieldNames{l}).allTrialVarExpl(j),...
                                ~] = computeVarianceExplained(...
                                eval(behVars{k}), predResp, ...
                                'poly1');  

                        else % if this trial doesn't have this img type
                            % set all values to nan
                            oneFlyKernel.(fKernName).(cellFieldNames{l}).validTime(j) = nan;
                            oneFlyKernel.(fKernName).(cellFieldNames{l}).allTrialKernels(j,:) = nan;
                            oneFlyKernel.(fKernName).(cellFieldNames{l}).allTrialVarExpl(j) = nan;
                            oneFlyKernel.(rKernName).(cellFieldNames{l}).validTime(j) = nan;
                            oneFlyKernel.(rKernName).(cellFieldNames{l}).allTrialKernels(j,:) = nan;
                            oneFlyKernel.(rKernName).(cellFieldNames{l}).allTrialVarExpl(j) = nan;
                        end
                    end    
                end
                
                % loop through and compute behavioral autocorrelations for
                %  this trial
                for k = 1:length(behVars)
                    [oneFlyAutoCorr.(behVars{k}).allTrialAutoCorr(j,:),...
                        autoCorrLags] = normAutoCorrWNan(eval(behVars{k}),...
                        autoCorrMaxLagSamp);
                    % valid time, number of non NaN elements
                    oneFlyAutoCorr.(behVars{k}).validTime(j) = ...
                        sum(~isnan(eval(behVars{k})));
                end
                
                % loop through and compute imaging autocorrelations for
                %  this trial
                imgFieldNames = {'left', 'right', 'sum', 'diff'};
                for k = 1:length(imgFieldNames)
                    % if trial has this imaging type, compute autocorr
                    if (sum(strcmpi(dffFieldNames, imgFieldNames{k}))) 
                        [oneFlyAutoCorr.(imgFieldNames{k}).allTrialAutoCorr(j,:),...
                            autoCorrLags] = normAutoCorrWNan(...
                            dffRS.(imgFieldNames{k}), autoCorrMaxLagSamp);
                        oneFlyAutoCorr.(imgFieldNames{k}).validTime(j) = ...
                            length(dffRS.(imgFieldNames{k}));
                    else % trial doesn't have this img type, set values to nan
                        oneFlyAutoCorr.(imgFieldNames{k}).allTrialAutoCorr(j,:) = nan;
                        oneFlyAutoCorr.(imgFieldNames{k}).validTime(j) = nan;
                    end
                        
                end
                

                
            else % if pData file doesn't exist
                fprintf('%s does not exist \n', pDataName);
                
                cellKernelNames = fieldnames(oneFlyKernel);
                trialCellNames = fieldnames(oneCellCondStrct);
                
                % for kernels, convert that trial to NaN values
                for k = 1:length(cellKernelNames)
                    for l = 1:length(trialCellNames)
                        oneFlyKernel.(cellKernelNames{k}).(trialCellNames{l}).validTime(j) = nan;
                        oneFlyKernel.(cellKernelNames{k}).(trialCellNames{l}).allTrialKernels(j,:) = nan;
                        oneFlyKernel.(cellKernelNames{k}).(trialCellNames{l}).allTrialVarExpl(j,:) = nan;
                    end
                end
                
                acNames = fieldnames(oneFlyAutoCorr);
                % for autocorrelations, convert that trial to NaN values
                for k = 1:length(acNames)
                    oneFlyAutoCorr.(acNames{k}).validTime(j) = nan;
                    oneFlyAutoCorr.(acNames{k}).allTrialAutoCorr(j,:) = nan;
                end
            end  
        end
        
        % get average kernel for fly
        ofkFN = fieldnames(oneFlyKernel);
        % loop through all kernel types
        for m = 1:length(ofkFN)
            occFN = fieldnames(oneFlyKernel.fFwdVel);
            % loop through all img cond/cells
            for n = 1:length(occFN)
                validTime = oneFlyKernel.(ofkFN{m}).(occFN{n}).validTime(...
                    ~isnan(oneFlyKernel.(ofkFN{m}).(occFN{n}).validTime));
                
                % check that this condition has any trials
                if ~isempty(validTime)
                    weighting = validTime ./ (sum(validTime));

                    % remove NaNs
                    oneFlyKernel.(ofkFN{m}).(occFN{n}).allTrialKernels(...
                        isnan(oneFlyKernel.(ofkFN{m}).(occFN{n}).allTrialKernels)) = []; 
                    oneFlyKernel.(ofkFN{m}).(occFN{n}).allTrialVarExpl(...
                        isnan(oneFlyKernel.(ofkFN{m}).(occFN{n}).allTrialVarExpl)) = [];

                    % weight kernel
                    weightTrialKernels = ...
                        oneFlyKernel.(ofkFN{m}).(occFN{n}).allTrialKernels .* ...
                        weighting;
                    % sum to get weighted average kernel
                    thisKernel = sum(weightTrialKernels, 1);
                    
                    % weight variance explained
                    weightVarExpl = ...
                        oneFlyKernel.(ofkFN{m}).(occFN{n}).allTrialVarExpl .* ...
                        weighting;
                    % sum to get weighted average variance explained
                    thisVarExpl = sum(weightVarExpl);
                    
                    % this fly's ID
                    thisFlyID = curFlyID;
                else
                    thisKernel = NaN(1,kernelLen);
                    thisVarExpl = nan;
                    thisFlyID = nan;
                end
                
                % save into main struct
                kernels.(ofkFN{m}).(occFN{n}).allKernels(i,:) = thisKernel;
                kernels.(ofkFN{m}).(occFN{n}).flyID(i) = thisFlyID;
                kernels.(ofkFN{m}).(occFN{n}).varExpl(i) = thisVarExpl;    
            end
        end
        
        % get average autocorrelation for fly
        ofacFN = fieldnames(oneFlyAutoCorr);
        % loop through all fields, separate autocorrelations
        for m = 1:length(ofacFN)
            validTime = oneFlyAutoCorr.(ofacFN{m}).validTime(...
                ~isnan(oneFlyAutoCorr.(ofacFN{m}).validTime));
            
            % check that this condition has any trials
            if ~isempty(validTime)
                weighting = validTime ./ (sum(validTime));
                
                % remove NaNs
                oneFlyAutoCorr.(ofacFN{m}).allTrialAutoCorr(...
                    isnan(...
                    oneFlyAutoCorr.(ofacFN{m}).allTrialAutoCorr)) = []; 
                
                % weight autocorrelation
                weightTrialAutoCorr = ...
                    oneFlyAutoCorr.(ofacFN{m}).allTrialAutoCorr .* ...
                    weighting;
                % sum to get weighted average autocorrelation
                thisAutoCorr = sum(weightTrialAutoCorr,1);
                
                % this fly's ID
                thisFlyID = curFlyID;
            else % if no trials
                thisAutoCorr = NaN(1,autoCorrLen);
                thisFlyID = nan;
            end
            
            % save into main struct
            autoCorr.(ofacFN{m}).allAutoCorr(i,:) = thisAutoCorr;
            autoCorr.(ofacFN{m}).flyID(i) = thisFlyID;
        end
        
    end
    
    % save kernels into kernels struct
    % loop through all fields of kernels
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
    
    % save autocorrelations into autoCorr struct
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
    
    cd(curDir);
end