directory = uigetdir;

grey=[0.4,0.4,0.4];
sigsize=size(sig);
lengthSig=sigsize(1);
for donor=1:sigsize(3)
    if max(sig(200:lengthSig, 1, donor))<1200||max(sig(200:lengthSig, 2, donor))<1200||max(sig(200:lengthSig, 3, donor))<1200
    else    
        for channel=1:3
            sig_median(:,channel,donor)=sig(:,channel,donor)-median(sig(:,channel,donor));
        end
        fig=figure('Visible','off');
        plot((1:lengthSig)/33,sig_median(1:lengthSig,1,donor),'g',...
             (1:lengthSig)/33,sig_median(1:lengthSig,2,donor),'r',...
             (1:lengthSig)/33,sig_median(1:lengthSig,3,donor),'b');
        hold all;
    %    plot(1:2000,sig_median(1:2000,4,donor),'Color',grey);
        title(num2str(donor));
        axis([0,lengthSig/33, 0 ,6000]);
        
        width = 24;
        height = 12;
        
        set(gcf,'paperunits','centimeters')
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf,'papersize',[width,height])
        set(gcf,'paperposition',[0,0,width,height])
        set(gcf, 'renderer', 'painters');
        set(gca,'FontSize', 16);
        
        xlabel('Time (Seconds)', 'FontSize', 18);
        ylabel('Absolute Intensity', 'FontSize', 18);
        
        filename=strcat('trace_',num2str(donor),'.eps');
        filename=fullfile(directory,filename);
        print (fig,'-depsc2',filename);
    end
end