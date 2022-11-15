% one script to re-process them all

exptFolders = {...
    'D:\2021_11_11\fly01\cell01',...
    'D:\2021_11_22\fly01\cell01',...
    'D:\2021_12_06\fly01\cell01\court sweep',...
    'D:\2021_12_08\fly01\cell01',...
    'D:\2021_12_09\fly01\cell02'};

for e = 1:length(exptFolders)
    reprocessExpt(exptFolders{e})
    analyzeExpt_court(exptFolders{e}, 0)
    
    disp(['Experiment ' num2str(e) ' re-processed and re-analyzed'])
end

close all