%make sure everything is closed
function shutitdown
        Panel_com('stop_display');
        Panel_com('all_off');
        disconnectHost;
        
        system('Taskkill/IM cmd.exe');
        disp('Fictrac terminated')
end