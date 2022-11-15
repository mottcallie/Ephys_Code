function saveEPSPlot(filename)
% load in file
load(filename)
plotname = erase(filename,'_pro.mat');

disp('Plotting data...');
% plot based on experiment type
plotExpt(exptData,exptMeta)
sgtitle(strrep(plotname,'_',' '))


% save plot of trial data
saveas(gcf,[plotname '_epsc'],'epsc');
disp('Plotted data saved as EPS!');
end
