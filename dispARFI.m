function [traced_gate,trace_flag] =  dispARFI(ecgdata,bdata,arfidata,arfidata_mf_pre,arfidata_mf_push,options,par)

[ndepth nacqT ntrackT] = size(arfidata.disp);

edge = [arfidata.axial(1) arfidata.axial(end)];

% Set Gate Parameters
if ~isempty(options.display.gateOffset)
    gate = (par.pushFocalDepth + options.display.gateOffset + [-options.display.gateWidth/2 options.display.gateWidth/2]);
    gate = repmat(gate,[nacqT 1]);
    traced_gate = [];
    trace_flag = 'n';
    
    if (min(gate(:))<arfidata.axial(1) || max(gate(:))>arfidata.axial(end))
        warning('Depth gate requested (%2.2f-%2.2f mm) falls outside the range over which displacements are computed (%2.2f-%2.2f mm)',min(gate(:)),max(gate(:)),arfidata.axial(1),arfidata.axial(end));
    end
    
    for i=1:nacqT
        gate_idx(i,:) = [find(arfidata.axial>gate(i,1),1,'first') find(arfidata.axial<gate(i,2),1,'last')];
    end
end

% Display HQ Bmode Frames
figure
if isunix
    set(gcf,'Position',[203 286 1196 1170])
elseif ispc
    set(gcf,'units','normalized','outerposition',[0 0 1 1])
end

for i=1:size(bdata.bimg,3);
    p1 = subplot('Position',[0.1 0.6 0.3 0.3]);
    imagesc(bdata.blat,bdata.bax,bdata.bimg(:,:,i));
    colormap(gray);axis image; freezeColors;
    title(i);
    hold on
    rectangle('Position',[-7 edge(1) 14 edge(2)-edge(1)],'EdgeColor','b','Linewidth',2)
    if ~isempty(options.display.gateOffset)
        rectangle('Position',[-2 min(gate(:)) 4 options.display.gateWidth],'EdgeColor','g','Linewidth',2)
    end
    hold off
    xlabel('Lateral (mm)','fontsize',16,'fontweight','bold')
    ylabel('Axial (mm)','fontsize',16,'fontweight','bold')
    title(sprintf('HQ B-Mode: Frame %d (t = %1.1f s)',i,bdata.t(i)),'fontsize',16,'fontweight','bold')
    xlim([-25 25]);ylim([max(edge(1)-15,arfidata.IQaxial(1)) min(edge(2)+15,arfidata.IQaxial(end))])
    pause(0.025)
    if i==size(bdata.bimg,3)
        % Display M-mode IQ
        p2 = axes('Position',[0.45 0.3 0.52 1]);
        frame = arfidata.IQ(:,:,1);
        imagesc(linspace(0,range(arfidata.lat(:))*nacqT,size(arfidata.IQ,2)),arfidata.IQaxial,db(frame/max(frame(:))),options.display.IQrange)
        hold on
        plot(linspace(0,range(arfidata.lat(:))*nacqT,nacqT),arfidata.axial(1)*ones(1,nacqT),'b','Linewidth',2)
        plot(linspace(0,range(arfidata.lat(:))*nacqT,nacqT),arfidata.axial(end)*ones(1,nacqT),'b','Linewidth',2)
        if ~isempty(options.display.gateOffset)
            plot(linspace(0,range(arfidata.lat(:))*nacqT,nacqT),gate(:,1),'g','Linewidth',2)
            plot(linspace(0,range(arfidata.lat(:))*nacqT,nacqT),gate(:,2),'g','Linewidth',2)
        end
        hold off
        axis image
        ylabel('Axial (mm)','fontsize',16,'fontweight','bold')
        set(gca,'xTickLabel',[])
        title(sprintf('M-Mode Frames\n Harmonic Tracking = %d',par.isHarmonic),'fontsize',16,'fontweight','bold')
        ylim([max(edge(1)-15,arfidata.IQaxial(1)) min(edge(2)+15,arfidata.IQaxial(end))])
        colormap(gray); freezeColors;
        %         grid on
    end
end

% Trace out center of depth gate
if (isfield(arfidata,'traced_gate') && isempty(options.display.gateOffset))
    gate = arfidata.traced_gate;
    hold on
    l1 = plot(linspace(0,range(arfidata.lat(:))*nacqT,nacqT),gate(:,1),'g','Linewidth',2);
    l2 = plot(linspace(0,range(arfidata.lat(:))*nacqT,nacqT),gate(:,2),'g','Linewidth',2);
    r1 = rectangle('Position',[-2 min(gate(:)) 4 max(gate(:))-min(gate(:))],'EdgeColor','g','LineStyle','--','Linewidth',2,'Parent',p1);
    trace_flag = input('Previously traced gate exists, do you want to retrace the gate? (y/n) [n]: ','s');
    if ~strcmpi(trace_flag,'y')
        trace_flag = 'n';
    else
        delete(l1,l2,r1)
    end
elseif (~isfield(arfidata,'traced_gate') && isempty(options.display.gateOffset))
    trace_flag = 'y';
end    
if ((isempty(options.display.gateOffset) && ~isfield(arfidata,'traced_gate')) || strcmpi(trace_flag,'y'))
    hold on
    fprintf(1,'Ready to trace gate (GateWidth = %2.1f mm)...\n',options.display.gateWidth)
    for i=1:nacqT
        [x,y] = ginput(1);
        mark(i) = plot(x,y,'yo','MarkerSize',10);
        gate(i,:) = (y + [-options.display.gateWidth/2 options.display.gateWidth/2]);
        clear x y
    end
    delete(mark)
    plot(linspace(0,range(arfidata.lat(:))*nacqT,nacqT),gate(:,1),'g','Linewidth',2)
    plot(linspace(0,range(arfidata.lat(:))*nacqT,nacqT),gate(:,2),'g','Linewidth',2)
    rectangle('Position',[-2 min(gate(:)) 4 max(gate(:))-min(gate(:))],'EdgeColor','g','LineStyle','--','Linewidth',2,'Parent',p1)
    fprintf(1,'Gate Traced.\n')
elseif ((isempty(options.display.gateOffset) && ~isfield(arfidata,'traced_gate')) && strcmpi(trace,'n'))
    gate = arfidata.traced_gate;
    hold on
    plot(linspace(0,range(arfidata.lat(:))*nacqT,nacqT),gate(:,1),'g','Linewidth',2)
    plot(linspace(0,range(arfidata.lat(:))*nacqT,nacqT),gate(:,2),'g','Linewidth',2)
    rectangle('Position',[-2 min(gate(:)) 4 max(gate(:))-min(gate(:))],'EdgeColor','g','LineStyle','--','Linewidth',2,'Parent',p1)
end

traced_gate = gate;

if (min(gate(:))<arfidata.axial(1) || max(gate(:))>arfidata.axial(end))
    warning('Depth gate requested (%2.2f-%2.2f mm) falls outside the range over which displacements are computed (%2.2f-%2.2f mm)',min(gate(:)),max(gate(:)),arfidata.axial(1),arfidata.axial(end));
end

for i=1:nacqT
    gate_idx(i,:) = [find(arfidata.axial>gate(i,1),1,'first') find(arfidata.axial<gate(i,2),1,'last')];
end


% NaN out push reverb frames
arfidata = interpPushReverb(arfidata,options,par,'nan'); % NaN out push and reverb frames
if options.motionFilter.enable
    arfidata_mf_pre = interpPushReverb(arfidata_mf_pre,options,par,'nan'); % NaN out push and reverb frames
    arfidata_mf_push = interpPushReverb(arfidata_mf_push,options,par,'nan'); % NaN out push and reverb frames
end

% Coorelation mask filter
if options.display.cc_filt
    mask = arfidata.cc>options.display.cc_thresh;
end

% Indices corresponding to median filter parameters
nax = double(ceil(options.display.medfilt(1)/(arfidata.axial(2) - arfidata.axial(1))));
nt = double(ceil(options.display.medfilt(2)/(arfidata.acqTime(2) - arfidata.acqTime(1))));
cmap = colormap(hot);
cmap(end,:) = [0.5 0.5 0.5];

% Display M-mode ARFI
if options.motionFilter.enable
    
    if strcmpi(options.display.t_disp_pre,'max')
        [pk idx] = max(arfidata_mf_pre.disp(:,:,1:par.nref),[],3);
        idx_pre = round(median(idx)); % to get a single representative number through all depth
        pre = medfilt2(double(pk),[nax nt]);
        % figure out way to cc_filt these properly
        clear pk idx
    else
        idx_pre = find(arfidata.trackTime>options.display.t_disp_pre,1);
        pre = medfilt2(double(arfidata_mf_pre.disp(:,:,idx_pre)),[nax nt]);
        if options.display.cc_filt; pre(mask(:,:,idx_pre)==0) = inf; end
        idx_pre = repmat(idx_pre,[1 size(pre,2)]);
    end
    
    if strcmpi(options.display.t_disp_push,'max')
        [pk idx] = max(arfidata_mf_push.disp(:,:,par.nref:end),[],3);
        idx_push = par.nref -1 + round(median(idx)); % to get a single representative number through all depth
        push = medfilt2(double(pk),[nax nt]);
        % figure out way to cc_filt these properly
        clear pk idx
    else
        idx_push = find(arfidata.trackTime>options.display.t_disp_push,1);
        push = medfilt2(double(arfidata_mf_push.disp(:,:,idx_push)),[nax nt]);
        if options.display.cc_filt; push(mask(:,:,idx_push)==0) = inf; end
        idx_push = repmat(idx_push,[1 size(push,2)]);
    end
    
    rng = options.display.disprange;
    
    if options.display.normalize
        m1 = 1/range(pre(:)); b1 = 1 - max(pre(:))/range(pre(:));
        m2 = 1/range(push(:)); b2 = 1 - max(push(:))/range(push(:));
        pre = m1.*pre + b1; push = m2.*push + b2;
        rng = [0 1];
    end
        
    p3 = axes('Position',[0.5 0.53 0.4 0.1]);
    imagesc(arfidata.acqTime,arfidata.axial,pre,rng);
    hold on
    plot(arfidata.acqTime,gate(:,1),'g','Linewidth',2)
    plot(arfidata.acqTime,gate(:,2),'g','Linewidth',2)
    cp3 = copyobj(p3,gcf);
    set(cp3,'box','on','linewidth',3,'xcolor','y','ycolor','y','xticklabel',[],'yticklabel',[]);
    ylabel('Axial (mm)','Parent',p3,'fontsize',16,'fontweight','bold')
    if strcmpi(options.display.t_disp_pre,'max')
        title(sprintf('ARFI Displacements over DOF at t_m_a_x (pre push)'),'parent',p3,'fontsize',16,'fontweight','bold')
    else
        title(sprintf('ARFI Displacements over DOF at t = %2.2f ms (pre push)',arfidata.trackTime(idx_pre(1))),'parent',p3,'fontsize',16,'fontweight','bold')
    end
    p4 = axes('Position',[0.5 0.37 0.4 0.1]);
    imagesc(arfidata.acqTime,arfidata.axial,push,rng);
    hold on
    plot(arfidata.acqTime,gate(:,1),'g','Linewidth',2)
    plot(arfidata.acqTime,gate(:,2),'g','Linewidth',2)
    cp4 = copyobj(p4,gcf);
    set(cp4,'box','on','linewidth',3,'xcolor','g','ycolor','g','xticklabel',[],'yticklabel',[]);
    cb = colorbar;
    set(cb,'Position',[0.91 0.37 0.0187/2 0.26])
    if options.display.normalize
        ylabel(cb,'Normalized Displacement','fontsize',16,'fontweight','bold')
    else
        ylabel(cb,'Displacement (\mum)','fontsize',16,'fontweight','bold')
    end
    ylabel('Axial (mm)','parent',p4,'fontsize',16,'fontweight','bold')
    if strcmpi(options.display.t_disp_pre,'max')
        title(sprintf('ARFI Displacements over DOF at t_m_a_x (at push)'),'parent',p4,'fontsize',16,'fontweight','bold')
    else
        title(sprintf('ARFI Displacements over DOF at t = %2.2f ms (at push)',arfidata.trackTime(idx_push(1))),'parent',p4,'fontsize',16,'fontweight','bold')
    end
    colormap(cmap)
    set(cb,'yLim',[options.display.disprange]+[0 -1])    
else
    
    if strcmpi(options.display.t_disp_pre,'max')
        [pk idx] = max(arfidata.disp(:,:,1:par.nref),[],3);
        idx_pre = round(median(idx)); % to get a single representative number through all depth
        pre = medfilt2(double(pk),[nax nt]);
        % figure out way to cc_filt these properly
        clear pk idx
    else
        idx_pre = find(arfidata.trackTime>options.display.t_disp_pre,1);
        pre = medfilt2(double(arfidata.disp(:,:,idx_pre)),[nax nt]);
        if options.display.cc_filt; pre(mask(:,:,idx_pre)==0) = inf; end
        idx_pre = repmat(idx_pre,[1 size(pre,2)]);
    end
    
    if strcmpi(options.display.t_disp_push,'max')
        [pk idx] = max(arfidata.disp(:,:,par.nref:end),[],3);
        idx_push = par.nref -1 + round(median(idx)); % to get a single representative number through all depth
        push = medfilt2(double(pk),[nax nt]);
        % figure out way to cc_filt these properly
        clear pk idx
    else
        idx_push = find(arfidata.trackTime>options.display.t_disp_push,1);
        push = medfilt2(double(arfidata.disp(:,:,idx_push)),[nax nt]);
        if options.display.cc_filt; push(mask(:,:,idx_push)==0) = inf; end
        idx_push = repmat(idx_push,[1 size(push,2)]);
    end
    
    rng = options.display.disprange;
    
    if options.display.normalize
        m1 = 1/range(pre(:)); b1 = max(pre(:))/range(pre(:));
        m2 = 1/range(push(:)); b2 = max(push(:))/range(push(:));
        pre = m1.*pre + b1; push = m2.*push + b2;
        rng = [0 1];
    end
    
    p3 = axes('Position',[0.5 0.53 0.4 0.1]);
    imagesc(arfidata.acqTime,arfidata.axial,pre,rng);
    hold on
    plot(arfidata.acqTime,gate(:,1),'g','Linewidth',2)
    plot(arfidata.acqTime,gate(:,2),'g','Linewidth',2)
    cp3 = copyobj(p3,gcf);
    set(cp3,'box','on','linewidth',3,'xcolor','y','ycolor','y','xticklabel',[],'yticklabel',[]);
    ylabel('Axial (mm)','Parent',p3,'fontsize',16,'fontweight','bold')
    if strcmpi(options.display.t_disp_pre,'max')
        title(sprintf('ARFI Displacements over DOF at t_m_a_x (pre push)',arfidata.trackTime(idx_pre(1))),'parent',p3,'fontsize',16,'fontweight','bold')
    else
        title(sprintf('ARFI Displacements over DOF at t = %2.2f ms (pre push)',arfidata.trackTime(idx_pre(1))),'parent',p3,'fontsize',16,'fontweight','bold')
    end
    p4 = axes('Position',[0.5 0.37 0.4 0.1]);
    imagesc(arfidata.acqTime,arfidata.axial,push,rng);
    hold on
    plot(arfidata.acqTime,gate(:,1),'g','Linewidth',2)
    plot(arfidata.acqTime,gate(:,2),'g','Linewidth',2)
    cp4 = copyobj(p4,gcf);
    set(cp4,'box','on','linewidth',3,'xcolor','g','ycolor','g','xticklabel',[],'yticklabel',[]);
    cb = colorbar;
    set(cb,'Position',[0.91 0.37 0.0187/2 0.26])
    if options.display.normalize
        ylabel(cb,'Normalized Displacement','fontsize',16,'fontweight','bold')
    else
        ylabel(cb,'Displacement (\mum)','fontsize',16,'fontweight','bold')
    end
    ylabel('Axial (mm)','parent',p4,'fontsize',16,'fontweight','bold')
    if strcmpi(options.display.t_disp_pre,'max')
        title(sprintf('ARFI Displacements over DOF at t_m_a_x (at push)',arfidata.trackTime(idx_push(1))),'parent',p4,'fontsize',16,'fontweight','bold')
    else
        title(sprintf('ARFI Displacements over DOF at t = %2.2f ms (at push)',arfidata.trackTime(idx_push(1))),'parent',p4,'fontsize',16,'fontweight','bold')
    end
    colormap(cmap)
    set(cb,'yLim',[options.display.disprange]+[0 -1])
end

if isempty(ecgdata)
    xlabel('Acquisition Time (s)','fontsize',16,'fontweight','bold')
end

% NaN out displacements filtered out by cc_thresh
pre(pre==inf) = nan;
push(push==inf) = nan;
arfidata.disp(mask==0) = nan;
if options.motionFilter.enable
    arfidata_mf_pre.disp(mask==0) = nan;
    arfidata_mf_push.disp(mask==0) = nan;
end

% Compute axially averaged Pre and Push Traces
for i=1:nacqT
    pre_trace(i) = nanmean(pre(gate_idx(i,1):gate_idx(i,2),i));
    push_trace(i) = nanmean(push(gate_idx(i,1):gate_idx(i,2),i));
end

% Incorporate ECG Data into this figure
if ~isempty(ecgdata)
    samples = zeros(1,nacqT);
    for i=1:nacqT
        samples(i) = ecgdata.arfi(find(ecgdata.arfi(:,1)>arfidata.acqTime(i),1,'first'),2);
    end
    ecgdata.arfi(:,2) = ecgdata.arfi(:,2)/max(ecgdata.arfi(:,2));
    
    h1 = axes('Position',[0.5 0.1 0.4 0.2]);
    plot(ecgdata.arfi(:,1),ecgdata.arfi(:,2),'Linewidth',2);
    hold on
    plot(arfidata.acqTime,samples,'kx','MarkerSize',8)
    pt = plot(arfidata.acqTime(1),samples(1),'ro','Parent',h1,'Markersize',10,'Markerfacecolor','r');
    hold off
    grid on
    title('ECG Trace','fontsize',16,'fontweight','bold')
    xlabel('Acquisition Time (s)','fontsize',16,'fontweight','bold')
    axis tight
    hold(h1)
end

h2 = axes('Position',[0.05 0.15 0.4 0.3]);
set(h2,'Color',[0.5 0.5 0.5]);

if (options.motionFilter.enable && (strcmpi(options.motionFilter.method,'Polynomial') || strcmpi(options.motionFilter.method,'Both')))
    rng = options.display.disprange*1.5;
else
    rng = [-100 100];
end

% Calculate indices for disp. vs. time plots
for i=1:nacqT
    idx(i,:) = ceil(linspace(gate_idx(i,1),gate_idx(i,2),options.display.n_pts));
end

% filename = 'test.gif';
for i=1:nacqT
    cla(h2)
    if ~isempty(ecgdata)
        set(pt,'Visible','off')
        set(h1,'Color',[0.5 0.5 0.5]);
    end
    if options.motionFilter.enable
        plot(arfidata.trackTime(1:par.nref),squeeze(arfidata_mf_pre.disp(idx(i,:),i,1:par.nref)),'.--','Parent',h2)
        hold on
        plot(arfidata.trackTime(par.nref+1:end),squeeze(arfidata_mf_push.disp(idx(i,:),i,par.nref+1:end)),'.--','Parent',h2)
        set(h2,'Color',[0.5 0.5 0.5]);
        ylim(h2,rng)
    else
        plot(arfidata.trackTime,squeeze(arfidata.disp(idx(i,:),i,:)),'.--','Parent',h2)
        set(h2,'Color',[0.5 0.5 0.5]);
        ylim(h2,rng)
    end
    hold on
    plot(arfidata.trackTime(idx_pre(i))*ones(1,10),linspace(-300,300,10),'y','linewidth',2,'Parent',h2)
    plot(arfidata.trackTime(idx_push(i))*ones(1,10),linspace(-300,300,10),'g','linewidth',2,'Parent',h2)
    title(sprintf('ARFI Displacement Profiles (within Depth Gate)\nPush # %d (t = %2.2f s)\nMotion Filter = %s',i,arfidata.acqTime(i),options.motionFilter.method*options.motionFilter.enable),'fontsize',16,'fontweight','bold','Parent',h2)
    if i==1
        xlabel('Track Time (ms)','fontsize',16,'fontweight','bold')
        ylabel('Displacement (\mum)','fontsize',16,'fontweight','bold')
        xlim([arfidata.trackTime(1) arfidata.trackTime(end)])
        grid on
    end
    if ~isempty(ecgdata)
        pt = plot(arfidata.acqTime(i),samples(i),'ro','Parent',h1,'Markersize',10,'Markerfacecolor','r');
    end
    
    %     frame = getframe(1);
    %     im = frame2im(frame);
    %     [imind,cm] = rgb2ind(im,256);
    %     if i == 1;
    %         imwrite(imind,cm,filename,'gif', 'Loopcount',inf,'DelayTime',0.1);
    %     else
    %         imwrite(imind,cm,filename,'gif','WriteMode','append','DelayTime',0.1);
    %
    %     end
    if options.display.IQtraces
    temp = db(squeeze(arfidata.IQ(:,1+(i-1)*par.nBeams,:)));
    temp(:,par.nref+1:par.nref+par.npush+par.nreverb) = nan;
    offset = 5;
    figure(101);
    if isunix
        set(101,'Position',[1203 390 1916 767])
    elseif ispc
        set(101,'units','normalized','outerposition',[0 0 1 1])
    end
    hh=subplot(121);cla(hh);
    for j=1:ntrackT;plot(arfidata.IQaxial,offset*(j-1)-temp(:,j)');hold on;end;view(90,90);
    hold on;plot(gate(1)*ones(1,100),linspace(-offset*10,offset*ntrackT,100),'g','linewidth',3);plot(gate(2)*ones(1,100),linspace(-offset*10,offset*ntrackT,100),'g','linewidth',3)
    xlim(edge);title(sprintf('Raw IQ: %d (t = %2.2f s)',i,arfidata.acqTime(i)),'fontsize',16,'fontweight','bold');
    set(hh,'Color',[0.5 0.5 0.5]);
    xlabel('Axial (mm)','fontsize',16,'fontweight','bold');ylabel('Tracks','fontsize',16,'fontweight','bold');set(gca,'YTickLabel',[])
    
    subplot(122);imagesc(arfidata.trackTime,arfidata.axial,squeeze(arfidata.cc(:,i,:)),[options.display.cc_thresh 1]);colorbar;
    title(sprintf('%s Correlation Coefficients',options.dispEst.ref_type),'fontsize',16,'fontweight','bold');grid on;colormap(jet)
    hold on;plot(linspace(-8,8,100),gate(1)*ones(1,100),'g','linewidth',3);plot(linspace(-8,8,100),gate(2)*ones(1,100),'g','linewidth',3)
    xlabel('Track Time (ms)','fontsize',16,'fontweight','bold');ylabel('Axial (mm)','fontsize',16,'fontweight','bold')
    end
    pause
end

cla(h2);
plot(arfidata.acqTime,pre_trace,'y.--','Parent',h2);hold all;plot(arfidata.acqTime,push_trace,'gx--','Parent',h2);
set(h2,'Color',[0.5 0.5 0.5]);
xlabel('Acquisition Time (s)','fontsize',16,'fontweight','bold','Parent',h2); 
title(sprintf('Axially Averaged ARFI Displacements\n(within Depth Gate)'),'fontsize',16,'fontweight','bold','Parent',h2)
axis(h2,'tight')
