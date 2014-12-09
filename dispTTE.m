function dispTTE(ecgdata,bdata,arfidata,arfi_par,sweidata,swei_par,options,timeStamp)

% Process Raw Displacements and Display

options.motionFilter = struct(...
    'enable',0 ...
    ,'method','Both' ... % Polynomial/LPF/Both
    ... % Parameters for Polynomial filter
    ,'order',1 ...
    ,'timeRange_push',[-1.5 -1 5.5 6] ...
    ... % Parameters for Bandpass filter
    ,'LPF_Cutoff',1000 ...
    );
options.motionFilter.timeRange_pre = options.motionFilter.timeRange_push - 7;

options.display = struct(...
    'IQrange',[-40 0] ...
    ,'gateWidth', 5 ...
    ,'gateOffset',[] ...
    ,'n_pts', 5 ...
    ,'medfilt',[1 0.15] ... % median filter parameters - [axial (mm) acqTime (s)]
    ,'cc_filt',1 ...
    ,'cc_thresh', 0.995 ...
    ... % ARFI Display Parameters
    ,'disprange',[-5 35] ...
    ,'normalize',0 ...
    ,'t_disp_push',0.5 ...
    ,'extras',0 ...
    ... % SWEI Display Parameters
    ,'velrange',[-5 10] ...
    ,'axial_scan',0 ...
    ,'sw_movie',0 ...
    ,'dvt_plots',0 ...
    ,'sw_display','disp' ... % Display displacements ('disp') or velocity ('vel') data
    );
options.display.t_disp_pre = options.motionFilter.timeRange_pre(1) + (options.display.t_disp_push - options.motionFilter.timeRange_push(1));

options.calcSWS = struct(...
    'enable',1 ...
    ,'method','LinReg' ... LinReg/ LatSum
    ,'metric', 'TTP' ...
    ,'r2_threshold',0.5 ...
    ,'SWSrange',[0 7] ...
    );
 
if options.dataflow.ARFI
    if options.motionFilter.enable
        arfidata_mf_pre = motionFilter(arfidata,options,arfi_par,'pre');
        arfidata_mf_push = motionFilter(arfidata,options,arfi_par,'push');
    else
        arfidata_mf_pre = [];
        arfidata_mf_push = [];
    end
    [arfidata.traced_gate,arfi_trace_flag] = dispARFI(ecgdata,bdata,arfidata,arfidata_mf_pre,arfidata_mf_push,options,arfi_par);
end

if options.dataflow.SWEI
    if options.motionFilter.enable
        sweidata_mf_pre = motionFilter(sweidata,options,swei_par,'pre');
        sweidata_mf_push = motionFilter(sweidata,options,swei_par,'push');
    else
        sweidata_mf_pre = [];
        sweidata_mf_push = [];
    end
    dispSWEI(ecgdata,bdata,sweidata,sweidata_mf_pre,sweidata_mf_push,options,swei_par);
end

% Save time stamped results file
if (options.dataflow.saveRes && ~exist(['res_',timeStamp,'.mat'],'file'))
    options.dataflow.saveRes = 1;
    fprintf(1,'Saving Res file...\n');
    tic
    resfile = ['res_' timeStamp '.mat'];
    save(resfile,'bdata','ecgdata','arfidata','sweidata','options','-v7.3');
    fprintf(1,'Save Time = %2.2fs\n',toc)
elseif (~strcmpi(arfi_trace_flag,'n') && ~isempty(arfidata.traced_gate))
    options.dataflow.saveRes = 1;
    fprintf(1,'Detected Traced Gate. Saving Res file...\n');
    tic
    resfile = ['res_' timeStamp '.mat'];
    save(resfile,'bdata','ecgdata','arfidata','sweidata','options','-v7.3');
    fprintf(1,'Save Time = %2.2fs\n',toc)
end