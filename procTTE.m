function procTTE(DataDir,fidx,options)

if ~exist('DataDir','var')
    DataDir = pwd;
end

if ~exist('fidx','var')
    fidx = -1;
end

cd(DataDir)

%% Input Parameters
if ~exist('options','var')
    options.dataflow = struct(...
        'realTime',1 ...
        ,'ARFI',1 ...
        ,'SWEI',0 ...
        ,'setID',fidx ...
        ,'saveRes',0 ...
        );
    
    options.dispEst = struct(...
        'method','Loupas'...
        ,'ref_type','independent' ...   % independent/common/progressive - indicates whether "no push" and "push" data sets will have independent references or a common reference, or use a moving reference
        ,'ref_idx',[] ...
        ,'noverlap',5 ...        % DO NOT CHANGE - number of time steps that are common between "no push" and "push" data sets (determined in sequenceParams file)
        ,'interpFactor',5 ...
        ,'kernelLength',4 ...
        ,'ccmode', 0 ...
        );
    
    options.motionFilter = struct(...
        'enable',1 ...
        ,'method','BPF' ... % Polynomial/BPF/Both
        ... % Parameters for Polynomial filter
        ,'order',1 ...
        ,'timeRange',[-inf -0.3 6.6 inf] ...
        ... % Parameters for Bandpass filter
        ,'passBand',[20 1000] ...
        );
end
%% Extract timeStamp
if ispc
    addpath C:\users\vrk4\Documents\GitHub\SC2000\arfiProcCode\
    addpath(genpath('C:\users\vrk4\Documents\GitHub\TTEProcCode'))
elseif isunix
    addpath /emfd/vrk4/GitHub/SC2000/arfiProcCode
    addpath(genpath('/emfd/vrk4/GitHub/TTEProcCode'))
end

list = dir('arfi_par_*'); % get timeStamp based on existance of ARFI par files

if size(list,1)<options.dataflow.setID
    error('Data set index requested greater than number of data sets')
end

% Reading in timestamp for data set
if length(options.dataflow.setID)==14
    timeStamp = options.dataflow.setID;
elseif options.dataflow.setID == -1
    timeStamp = list(end).name(end-17:end-4);
else
    timeStamp = list(options.dataflow.setID).name(end-17:end-4);
end

fprintf('Loading data with timeStamp = %s\n', timeStamp);

%% Extract B-mode Data
fprintf(1,'Extracting B-mode Data...\n');
[bdata,bmodeSave] = extractBmode(timeStamp);

%% Extract ARFI/SWEI Data
fprintf(1,'Extracting ARFI/SWEI Data...\n');
if options.dataflow.ARFI
    [arfidata,arfiSave,options] = extractMmode(timeStamp,options,'ARFI');
    arfi_par = load(sprintf('arfi_par_%s.mat',timeStamp));
    if options.motionFilter.enable
        [arfidata] = motionFilter(arfidata,options,arfi_par);
    end
end

if options.dataflow.SWEI
    [sweidata,sweiSave,options] = extractMmode(timeStamp,options,'SWEI');
    swei_par = load(sprintf('swei_par_%s.mat',timeStamp));
    if options.motionFilter.enable
%         [sweidata] = motionFilter(sweidata,options,swei_par);
    end
end

%%
close all

if options.dataflow.realTime
    dof = 7.22*1.540/arfi_par.pushFreq*(arfi_par.pushFnum)^2;
    edge = (arfi_par.pushFocalDepth + [-dof/2 dof/2])/10;
    
    figure(1)
    set(1,'Position',[10 500 1450 300]);
    for i=1:size(bdata.bimg,3);
        subplot(121)
        imagesc(bdata.blat,bdata.bax,bdata.bimg(:,:,i));
        colormap(gray);axis image;
        title(i);
        hold on
        rectangle('Position',[-1 edge(1) 2 edge(2)-edge(1)],'EdgeColor','b','Linewidth',2)
        hold off
        xlabel('Lateral (cm)')
        ylabel('Axial (cm)')
        title(sprintf('HQ B-Mode: Frame %d (t = %1.1f s)\n',i,bdata.t(i)))
        pause(0.025)
    end
%%
    disp_gate_mm = 2.5;
    offset = 0;
    arange = [0 50];
    
    edge = (arfi_par.pushFocalDepth + offset + [-disp_gate_mm/2 disp_gate_mm/2]);
    edge_idx = [find(arfidata.axial>edge(1),1) find(arfidata.axial>edge(2),1)];
    
    figure(1)
    subplot(122)
    imagesc(arfidata.acqTime,arfidata.axial,abs(db(arfidata.IQ_off(:,:,1))))
    hold on
    plot(arfidata.acqTime,edge(1)*ones(length(arfidata.acqTime)),'b','Linewidth',2)
    plot(arfidata.acqTime,edge(2)*ones(length(arfidata.acqTime)),'b','Linewidth',2)
    hold off
    xlabel('Acquisition Time (s)')
    ylabel('Axial (mm)')
    title(sprintf('M-Mode IQ Frame\n Harmonic Flag = %d',arfi_par.isHarmonic))
    colormap(gray)
    grid on
    
    temp_off = squeeze(mean(arfidata.disp_off(edge_idx(1):edge_idx(2),:,:),1));
    temp_on = squeeze(mean(arfidata.disp_on(edge_idx(1):edge_idx(2),:,:),1));
    
    figure(2)
    set(2,'Position',[10 100 1450 300])
    
    subplot(121)
    imagesc(arfidata.acqTime,arfidata.trackTime,temp_off',arange)
    xlabel('Acquisition Time (s)')
    ylabel('Track Time (ms)')
    title(sprintf('Mean Displacements: No push\n%1.2f - %1.2f mm',edge(1),edge(2)))
    grid on
    
    subplot(122)
    imagesc(arfidata.acqTime,arfidata.trackTime,temp_on',arange)
    xlabel('Acquisition Time (s)')
    ylabel('Track Time (ms)')
    title(sprintf('Mean Displacements: Push\n%1.2f - %1.2f mm',edge(1),edge(2)))
    grid on
    colorbar
    
end

%% 
keyboard

%% Save time stamped results file
if options.dataflow.saveRes
    tic
    resfile = ['res_' timeStamp '.mat'];
    if (options.dataflow.ARFI && options.dataflow.SWEI)
        save(resfile,'bdata','arfidata','sweidata','options','-v7.3');
    elseif (options.dataflow.ARFI && ~options.dataflow.SWEI)
        save(resfile,'bdata','arfidata','options','-v7.3');
    elseif (~options.dataflow.ARFI && options.dataflow.SWEI)
        save(resfile,'bdata','sweidata','options','-v7.3');
    else
        save(resfile,'bdata','options','-v7.3');
    end
    fprintf(1,'Save Time = %2.2fs\n',toc)
end
