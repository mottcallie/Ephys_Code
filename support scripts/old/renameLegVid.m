% renameLegVid.m
%
% Function that renames all leg video tiff files by generating and calling
%  Powershell script. 
% Assumes leg video tiff files are named legVid_dateTime_#.tiff.
%
% INPUTS:
%   rawLegVidPath - full path to rawLegVid folder
%   scriptsPath - full path to folder to save scripts
%   flyName - name of fly (e.g. fly01)
%   cellName - name of cell (e.g. cell01)
%
% OUTPUTS:
%   renameStatus - status of renaming, returns 0 for success and 1 for
%     failure
%
% CREATED:
%   7/16/20 - same code as was in preprocessLegVidFiles, now broken out
%       into separate function
%
% UPDATED:
%   7/16/20 - HHY
%

function renameStatus = renameLegVid(rawLegVidPath, scriptsPath, ...
    flyName, cellName) 

    % get present working directory
    curDir = pwd;
    
    % go to rawLegVid folder (necessary for Powershell script call to work)
    cd(rawLegVidPath)

    % generate Powershell script to rename legVid files
    renameScriptFname = [flyName '_' cellName '_legVidRenameScript.ps1'];
    renameScriptPath = [scriptsPath filesep renameScriptFname];
    renameScriptFID = fopen(renameScriptPath, 'w');

    % write command to go to right folder
    fprintf(renameScriptFID, 'cd "%s"\n', rawLegVidPath);
    % write rename command
    fprintf(renameScriptFID, ...
        'get-childitem legVid* | rename-item -newname{[string] ($_.name).substring(21) -replace "-", "legVid-"}');

    % close file
    fclose(renameScriptFID);

    disp('Renaming leg vid images');

    % call script to do renaming              
    renameCmd = sprintf(...
        'Powershell -NoProfile -ExecutionPolicy Bypass -Command "%s"', ...
        renameScriptPath);
    renameStatus = system(renameCmd);

    if ~(renameStatus)
        disp('Leg vid images renamed successfully!');
    else
        disp('Error renaming leg vid images');
        return; % end function here; this is a problem
    end
    
    % return to original directory
    cd(curDir);
end