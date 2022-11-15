function  plotPatchCheck(checkInputR,checkVm,checkSR)
% pull trial N
trials = 1:length(checkInputR);

% plot input resistance and baseline membrane potential
figure(2); clf;
set(gcf,'Position',[100 100 700 400]);

s(1) = subplot(3,1,1);
scatter(trials,checkInputR,'filled','MarkerFaceColor','#0072BD')
ylabel('IR (MOhm)')

s(2) = subplot(3,1,2);
scatter(trials,checkSR,'filled','MarkerFaceColor','#D95319')
ylabel('spikes/sec')

s(3) = subplot(3,1,3);
scatter(trials,checkVm,'filled','MarkerFaceColor','#A2142F')
ylabel('Vm (mV)')

sgtitle('patch status')
linkaxes(s,'x')


% save data
save('patchcheck.mat', 'checkInputR','checkVm','checkSR','-v7.3');
% save plot
saveas(gcf,'patchcheck_scatterplot.png');
end