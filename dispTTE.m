<<<<<<< HEAD
function dispTTE(ecgdata,bdata,arfidata,arfi_par,sweidata,swei_par,options,timeStamp)

%% Default Input Parameters
if ~isfield(options,'motionFilter')
    options.motionFilter = struct(...
        'enable', 1 ...
        ,'method','Both' ... % Polynomial/LPF/Both
        ... % Parameters for Polynomial filter
        ,'order', 1 ...
        ,'timeRange_push',[-1.5 -1 4.5 5] ...
        ,'pre_offset', -6.5 ...
        ... % Parameters for Bandpass filter
        ,'LPF_Cutoff', 750 ...
        );
    options.motionFilter.timeRange_pre = options.motionFilter.timeRange_push + options.motionFilter.pre_offset;
end

if ~isfield(options,'display')
    options.display = struct(...
        'IQrange',[-40 0] ...
        ,'gateWidth', 2.5 ...
        ,'gateOffset', 0 ...
        ,'n_pts', 5 ...
        ,'medfilt',[1 0.15] ... % median filter parameters - [axial (mm) acqTime (s)]
        ,'cc_filt', 1 ...
        ,'cc_thresh', 0.995 ...
        ... % ARFI Display Parameters
        ,'disprange',[ ] ...
        ,'normalize', 0 ...
        ,'t_disp_push', 0.5 ...
        ,'extras', 0 ...
        ... % SWEI Display Parameters
        ,'velrange',[-5 15] ...
        ,'axial_scan',0 ...
        ,'sw_movie',0 ...
        ,'dvt_plots',0 ...
        ,'sw_display','disp' ... % Display displacements ('disp') or velocity ('vel') data
        );
    options.display.t_disp_pre = options.motionFilter.timeRange_pre(1) + (options.display.t_disp_push - options.motionFilter.timeRange_push(1));
end

if ~isfield(options,'calcSWS')
    options.calcSWS = struct(...
        'enable',0 ...
        ,'method','LinReg' ... LinReg/ LatSum
        ,'metric', 'TTP' ...
        ,'r2_threshold',0.5 ...
        ,'SWSrange',[0 7] ...
        );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Process and Display
if options.dataflow.ARFI
    if options.motionFilter.enable
        arfidata_mf_pre = motionFilter(arfidata,options,arfi_par,'pre');
        arfidata_mf_push = motionFilter(arfidata,options,arfi_par,'push');
    else
        arfidata_mf_pre = [];
        arfidata_mf_push = [];
    end
    [arfidata.traced_gate] = dispARFI(ecgdata,bdata,arfidata,arfidata_mf_pre,arfidata_mf_push,options,arfi_par);
end

if options.dataflow.SWEI
    if options.motionFilter.enable
        sweidata_mf_pre = motionFilter(sweidata,options,swei_par,'pre');
        sweidata_mf_push = motionFilter(sweidata,options,swei_par,'push');
    else
        sweidata_mf_pre = [];
        sweidata_mf_push = [];
    end
    [sweidata.traced_gate] = dispSWEI(ecgdata,bdata,sweidata,sweidata_mf_pre,sweidata_mf_push,options,swei_par);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save time stamped results file

if options.dataflow.ARFI
    if ~isempty(arfidata.traced_gate)
        options.dataflow.saveRes = 1;
        fprintf(1,'Detected Traced Gate. Saving ARFI Res file...\n');
        tic
        resfile = ['res_arfi_' timeStamp '.mat'];
        save(resfile,'bdata','ecgdata','arfidata','options','-v7.3');
        fprintf(1,'Save Time for ARFI = %2.2fs\n',toc)
    end
end

if options.dataflow.SWEI
    if ~isempty(sweidata.traced_gate)
        options.dataflow.saveRes = 1;
        fprintf(1,'Detected Traced Gate. Saving SWEI Res file...\n');
        tic
        resfile = ['res_swei_' timeStamp '.mat'];
        save(resfile,'bdata','ecgdata','sweidata','options','-v7.3');
        fprintf(1,'Save Time for SWEI = %2.2fs\n',toc)
    end
end

=======
function dispTTE(ecgdata,bdata,arfidata,arfi_par,sweidata,swei_par,options,timeStamp)

%% Default Input Parameters
if ~isfield(options,'motionFilter')
    options.motionFilter = struct(...
        'enable', 1 ...
        ,'method','Both' ... % Polynomial/LPF/Both
        ... % Parameters for Polynomial filter
        ,'order', 1 ...
        ,'timeRange_push',[-1.5 -1 4.5 5] ...
        ,'pre_offset', -6.5 ...
        ... % Parameters for Bandpass filter
        ,'LPF_Cutoff', 750 ...
        );
    options.motionFilter.timeRange_pre = options.motionFilter.timeRange_push + options.motionFilter.pre_offset;
end

if ~isfield(options,'display')
    options.display = struct(...
        'IQrange',[-40 0] ...
        ,'gateWidth', 2.5 ...
        ,'gateOffset', 0 ...
        ,'n_pts', 5 ...
        ,'medfilt',[1 0.15] ... % median filter parameters - [axial (mm) acqTime (s)]
        ,'cc_filt', 1 ...
        ,'cc_thresh', 0.995 ...
        ... % ARFI Display Parameters
        ,'disprange',[ ] ...
        ,'normalize', 0 ...
        ,'t_disp_push', 0.5 ...
        ,'extras', 0 ...
        ... % SWEI Display Parameters
        ,'velrange',[-5 15] ...
        ,'axial_scan',0 ...
        ,'sw_movie',0 ...
        ,'dvt_plots',0 ...
        ,'sw_display','disp' ... % Display displacements ('disp') or velocity ('vel') data
        );
    options.display.t_disp_pre = options.motionFilter.timeRange_pre(1) + (options.display.t_disp_push - options.motionFilter.timeRange_push(1));
end

if ~isfield(options,'calcSWS')
    options.calcSWS = struct(...
        'enable',0 ...
        ,'method','LinReg' ... LinReg/ LatSum
        ,'metric', 'TTP' ...
        ,'r2_threshold',0.5 ...
        ,'SWSrange',[0 7] ...
        );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Process and Display
if options.dataflow.ARFI
    if options.motionFilter.enable
        arfidata_mf_pre = motionFilter(arfidata,options,arfi_par,'pre');
        arfidata_mf_push = motionFilter(arfidata,options,arfi_par,'push');
    else
        arfidata_mf_pre = [];
        arfidata_mf_push = [];
    end
    [arfidata.traced_gate] = dispARFI(ecgdata,bdata,arfidata,arfidata_mf_pre,arfidata_mf_push,options,arfi_par);
end

if options.dataflow.SWEI
    if options.motionFilter.enable
        sweidata_mf_pre = motionFilter(sweidata,options,swei_par,'pre');
        sweidata_mf_push = motionFilter(sweidata,options,swei_par,'push');
    else
        sweidata_mf_pre = [];
        sweidata_mf_push = [];
    end
    [sweidata.traced_gate] = dispSWEI(ecgdata,bdata,sweidata,sweidata_mf_pre,sweidata_mf_push,options,swei_par);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save time stamped results file

if options.dataflow.ARFI
    if ~isempty(arfidata.traced_gate)
        options.dataflow.saveRes = 1;
        fprintf(1,'Detected Traced Gate. Saving ARFI Res file...\n');
        tic
        resfile = ['res_arfi_' timeStamp '.mat'];
        save(resfile,'bdata','ecgdata','arfidata','options','-v7.3');
        fprintf(1,'Save Time for ARFI = %2.2fs\n',toc)
    end
end

if options.dataflow.SWEI
    if ~isempty(sweidata.traced_gate)
        options.dataflow.saveRes = 1;
        fprintf(1,'Detected Traced Gate. Saving SWEI Res file...\n');
        tic
        resfile = ['res_swei_' timeStamp '.mat'];
        save(resfile,'bdata','ecgdata','sweidata','options','-v7.3');
        fprintf(1,'Save Time for SWEI = %2.2fs\n',toc)
    end
end

>>>>>>> afa77557451dedcbdaaf013db29dc3d36822037b
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%