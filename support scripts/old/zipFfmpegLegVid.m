% zipFfmpgLegVid.m
%
% Function given trial with leg video, generates .mp4 file from individual
%  tiffs and zip file of same tiffs for that trial.
% Called by preprocessLegVidFiles(). Does not stand alone. 
%
% INPUTS:
%   inputParams - metadata about trial, loaded from saved data
%   scriptsPath - full path to where scripts are saved
%   cellDirPath - full path to where to put zip file
%   rawLegVidPath - full path to raw leg videos folder
%   flyName - name of fly (e.g. fly01)
%   cellName - name of cell (e.g. cell01)
%   trialName - name of trial (e.g. trial01)
%
% OUTPUTS:
%   none, but generates .mp4 and .zip files. Also prints to screen status
%     updates
%
% CREATED: 7/16/20 - code was part of preprocessLegVidFiles(). Break out
%
% UPDATED:
%   7/16/20 - HHY
%   7/29/20 - HHY - fix bugs where not all variables passed from preprocess
%
function zipFfmpegLegVid(inputParams, scriptsPath, cellDirPath, ...
    rawLegVidPath, flyName, cellName, trialName)

    % some constants
    PATH_7ZIP = 'C:\Program Files\7-Zip\7z.exe';

    % current number of frames grabbed same as start index
    %  for new video with zero indexing
    startFrame = inputParams.startLegVidNum;
    % total number of frames grabbed for this trial
    totFrames = inputParams.endLegVidNum - ...
        inputParams.startLegVidNum;
    frameRate = inputParams.legCamFrameRate;

    % zip file name and path
    legVidZipFname = [flyName '_' ...
        cellName '_' trialName '_legVid.zip'];
    legVidZipPath = [cellDirPath filesep legVidZipFname];

    % generate filelist file for images to put in zip file
    filelistFname = [flyName '_' ...
        cellName '_' trialName '_filelist.txt'];
    filelistPath = [scriptsPath filesep filelistFname];
    filelistFID = fopen(filelistPath, 'w');

    % loop over all frame numbers to include, write to file
    for r = startFrame:(startFrame + totFrames - 1)
        fprintf(filelistFID, '%s%slegVid-%d.tiff\n', ...
            rawLegVidPath, filesep, r);
    end

    % close file
    fclose(filelistFID);

    % generate powershell script file for zipping
    zipScriptFname = [flyName '_' ...
        cellName '_' trialName '_zipScript.ps1'];
    zipScriptPath = [scriptsPath filesep zipScriptFname];
    zipScriptFID = fopen(zipScriptPath, 'w');

%                     % add this zip script path to cell array of them
%                     % (for writing to batch file later)
%                     allZipScriptPaths = {allZipScriptPaths{:} ...
%                         zipScriptPath};

    % write constant portions of script
    fprintf(zipScriptFID, '$7zipPath = "%s"\n', PATH_7ZIP);
    fprintf(zipScriptFID, 'Set-Alias 7zip $7zipPath\n');

    % write variable portions of script: zip file path, 
    %  filelist path
    fprintf(zipScriptFID, '$Target = "%s"\n', ...
        legVidZipPath); % target is zip file
    fprintf(zipScriptFID, '$Source = "@%s"\n', filelistPath);

    % write line to actually do zipping
    fprintf(zipScriptFID, '7zip a $Target $Source');

    % close file
    fclose(zipScriptFID);

    % file name for leg vid mp4
    legVidFName = [flyName '_' ...
        cellName '_' trialName ...
        '_legVid.mp4'];
    legVidPath = [cellDirPath filesep legVidFName];

    % generate command for creating ffmpeg video
    vidCmd = ...
        sprintf('ffmpeg -f image2 -r %.2f -start_number %d -i %s%slegVid-%%d.tiff -vframes %d -pix_fmt yuv420p -r %.2f -b:v 17000k -c:v libx264 %s', ...
        frameRate, startFrame, rawLegVidPath, filesep, ...
        totFrames, frameRate, legVidPath);
    % run command for creating ffmpeg video
    setenv("PATH",getenv("PATH") + ";C:\Program Files\ffmpeg\bin");
    createVidStatus = system(vidCmd);

    % display whether video file generated successfully
    if ~(createVidStatus)
        fprintf('%s created successfully! \n', legVidFName);
    else
        fprintf('Error creating %s. \n', legVidFName);
    end

    % generate command for calling powershell script for
    %  zipping
    setenv("PATH",getenv("PATH") + ";C:\Windows\System32\WindowsPowerShell\v1.0")
    zipCmd = ...
        sprintf('Powershell -NoProfile -ExecutionPolicy Bypass -Command "%s" \n', ...
        zipScriptPath);
    % run command to zip files
    zipStatus = system(zipCmd);

    % display whether zipping happened successfully
    if ~(zipStatus)
        fprintf('%s zipped succesfully!\n', ...
            [flyName '_' cellName '_'...
            trialName]);
    else
        fprintf('Error zipping %s.\n', ...
            [flyName '_' cellName '_'...
            trialName]);
    end
end