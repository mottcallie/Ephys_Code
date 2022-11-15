% schmittTrigger
% implements a shmitt trigger and pulls indices accordingly. once x exceeds
% high threshold, trigger will remain active until x falls below low
% threshold
%
% INPUT
% xdata - dataset to apply trigger against
% highT - high threshold to cross in order to be active
% lowT - low threshold to cross in order to be inactive
%
% 08/05/2022 MC - created
%

function triggerIdx = schmittTrigger(xdata,highT,lowT)
% initialize
[x,n] = size(xdata);
triggerIdx = zeros(x,n);

for e = 1:n
    highIdx = xdata(:,e)>=highT;
    lowIdx = xdata(:,e)>=lowT;

    triggerIdx(:,e) = highIdx; %initialize w/all high points
    trig=0; %set trigger off
    for i=1:x
        % turn trigger ON if above HIGH
        if highIdx(i)==1
            trig=1;
        end
        % if above LOW add point
        if lowIdx(i)==1
            if trig==1
                triggerIdx(i,e)=1;
            end
            % else, turn trigger OFF if below LOW
        else
            trig=0;
        end
    end

end