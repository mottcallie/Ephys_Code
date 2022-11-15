% plotEphysFicTrac.m
%
% Function that generates a simple summary plot containing all relevant
% data acquired during a given trial. For ephys only, plots only ephys. For
% fictrac and ephys, plots both behavior and ephys, etc.
%
% INPUTS:
%   exptData - processed data, can contain ephys, fictrac, and/or output
%   exptMeta - processed ephys meta
%
%
% OUTPUTS:
%
% Original: 04/05/2021 - MC
%           11/04/2021 - MC removed g3 and added g4

function [] = plotExpt(exptData,exptMeta)
    
    % reset counters
    s = 0;
    n = 0;
    

    % set number of sublots based on number of expt variables
    if contains(exptMeta.exptCond,'ephys','IgnoreCase',true)
        s=s+1; %for plotting scaled output
    end
    if contains(exptMeta.exptCond,'inj','IgnoreCase',true)
        s=s+1; %for plotting current injection
    end
    if contains(exptMeta.exptCond,'g4','IgnoreCase',true)
        if std(exptData.g4displayXPos) %and only if not stationary
            s=s+1; %for plotting panels
        end
    end
    if contains(exptMeta.exptCond,'fictrac','IgnoreCase',true)
        s=s+3; %for plotting directional velocity
    end
    
    % set plot height based on number of expt variables
    if s>2
        plotHeight = 750;
    else
        plotHeight = 400;
    end
    
    % generate figure
    figure(1); clf;
    set(gcf,'Position',[100 100 1500 plotHeight])
    lw = 1;
    
    
    %% plot ephys
    if contains(exptMeta.exptCond,'ephys','IgnoreCase',true)
        n = n+1; % advance counter
        
        switch exptMeta.mode
            % voltage clamp, scaled out is current
            case {'Track','V-Clamp'}
                ex(n) = subplot(s,1,n);
                plot(exptData.t, exptData.scaledCurrent, 'k')
                y(n) = ylabel('Current (pA)');
                axis tight

            % current clamp, scaled out is voltage
            case {'I=0','I-Clamp','I-Clamp Fast'}
                ex(n) = subplot(s,1,n);
                plot(exptData.t, exptData.scaledVoltage, 'k')
                y(n) = ylabel('Voltage (mV)');
                axis tight

        end
    end

    
    %% plot output variable
    if contains(exptMeta.exptCond,'inj','IgnoreCase',true)
        n = n+1; % update counter
        
        ex(n) = subplot(s,1,n);
        plot(exptData.t, exptData.iInj, 'k')
        y(n) = ylabel('I-Inj (pA)');
        axis tight

    end
    
    %% plot panel display
    if contains(exptMeta.exptCond,'g4','IgnoreCase',true)
        if std(exptData.g4displayXPos) %and only if not stationary
            n = n+1; % update counter
            
            minPos = nanmin(exptData.g4displayXPos);
            maxPos = nanmax(exptData.g4displayXPos);
            midPos = minPos + (maxPos-minPos)/2; %midline
            
            ex(n) = subplot(s,1,n);
            p = plot(exptData.t, exptData.g4displayXPos, 'Color','#77AC30','LineWidth',lw);
            p.YData(abs(diff(p.YData))>180) = nan;
            y(n) = ylabel('Object (deg)');
            axis tight
            
            yline(midPos,':','Color','k') %line at mideline
            
        end
    end
    
    
    %% plot directional velocities (3)
    if contains(exptMeta.exptCond,'fictrac','IgnoreCase',true)
        n = n+1; % update counter
        
        ex(n) = subplot(s,1,n);
        plot(exptData.t, exptData.angularVelocity, 'Color','#0072BD','LineWidth',lw)
        y(n) = ylabel('Angular (deg/s)');
        yline(0,':','Color','k')
        axis tight
        % if fly doesnt walk, set ylim above just baseline noise
        angMax = max(abs(exptData.angularVelocity));
        if angMax < 20
            ylim([-20 20])
        else
            ylim([-angMax angMax])
        end
        n = n+1; % update counter
        
        ex(n) = subplot(s,1,n);
        plot(exptData.t, exptData.sidewaysVelocity, 'Color','#7E2F8E','LineWidth',lw)
        y(n) = ylabel('Sideways (mm/s)');
        yline(0,':','Color','k')
        axis tight
        % if fly doesnt walk, set ylim above just baseline noise
        sidMax = max(abs(exptData.sidewaysVelocity));
        if sidMax < 1
            ylim([-1 1])
        else
            ylim([-sidMax sidMax])
        end
        n = n+1; % update counter
        
        ex(n) = subplot(s,1,n);
        plot(exptData.t, exptData.forwardVelocity, 'Color','#D95319','LineWidth',lw)
        yline(0,':','Color','k')
        y(n) = ylabel('Forward (mm/s)');
        axis tight
        % if fly doesnt walk, set ylim above just baseline noise
        fwdMax = exptData.forwardVelocity;
        if max(fwdMax) < 2
            ylim([min(exptData.forwardVelocity) 2])
        end
        
    end
    
    %% add opto stim line if needed
    if contains(exptMeta.exptCond,'opto','IgnoreCase',true)
        optoend = find(ischange(exptData.optoStim));
        oc = "#A2142F"; %set color
        if ~isempty(optoend)
            for ol=1:s
                subplot(s,1,ol)
                xline(exptData.t(1),'Color',oc,'LineWidth',lw)
                xline(exptData.t(optoend),'Color',oc,'LineWidth',lw)
            end
        end
    end
    %% add label
    % add at label at the end, regardless of the number of subplots
    xlabel('Time (s)')
    linkaxes(ex,'x');
    for yn = 1:n
        y(yn).Position(1) = -15;
    end
end

