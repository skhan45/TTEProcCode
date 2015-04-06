function runTTE_raw(DataDir,stream,fidx)

close all

% TTE Wrapper for Raw Data

if ~exist('DataDir','var')
    DataDir = pwd;
end
if ~exist('stream','var')
    stream = 'RT';
end
if ~exist('fidx','var')
    fidx = -1;
end

% Sanity Checks
[status, hostname] = system('hostname');
hostname = deblank(hostname);
if (strcmpi(stream,'cluster') && strcmpi(hostname,'patcuda1'))
    stream = 'review'; 
    str = sprintf('Cluster mode not supported on %s. Reverting to review mode\n',hostname);
    warning(str)
end
clear status hostname
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Inputs to procTTE
options.dataflow = struct(...
    'stream', stream ... % RT (realTime) || review || cluster 
    ,'display', 0 ...
    ,'ecg_test', 0 ...
    ,'ARFI', 0 ...
    ,'SWEI', 1 ...
    ,'oneSided', 1 ...
    ,'setID',fidx ...
    ,'saveRes', 0 ...
    );
options.dispEst = struct(...
    'method','Loupas'...
    ,'ref_type','Progressive' ...   % anchored || progressive
    ,'ref_idx',[] ...
    ,'nreverb', 2 ...         % Not having the correct nreverb could mess up displacements when using progressive ref_type
    ,'interpFactor', 5 ...
    ,'kernelLength', 10 ... % 10 -> 2.4 mm (Fundamental) 1.9 mm (Harmonic)
    ,'DOF_fraction', 2 ... % Fraction of Depth of Field (around focus) to compute displacements for. DOF = 9*lambda*F_num^2
    ,'ccmode', 1 ...
    );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Inputs to dispTTE
options.motionFilter = struct(...
    'enable', 1 ...
    ,'method','Both' ... % Polynomial || LPF || Both
    ... % Parameters for Polynomial filter
    ,'order', 2 ...
    ,'timeRange_push', [-1.5 -1 4.5 5] ... % [-1.5 -1 4.5 5]
    ,'pre_offset', -6.5 ... % [-6.5]
    ... % Parameters for Bandpass filter
    ,'LPF_Cutoff', 1000 ...
    );
options.motionFilter.timeRange_pre = options.motionFilter.timeRange_push + options.motionFilter.pre_offset;

options.display = struct(...
    'theme', 'dark' ... % light/dark
    ,'IQrange',[-35 0] ...
    ,'gateWidth', 10 ...
    ,'gateOffset', 0 ...
    ,'n_pts', 5 ...
    ,'medfilt',[5 0.25] ... % median filter parameters - [axial (mm) acqTime (s)]
    ,'cc_filt', 1 ...
    ,'cc_thresh', 0.99 ...
    ... % ARFI Display Parameters
    ,'disprange',[-5 15] ...
    ,'autoRange', 1 ...
    ,'normalize', 0 ...
    ,'t_disp_push', 0.6 ...
    ,'extras', 0 ... % [-1] - Suppress all extra plots || [0] - Asks for User Input on which plots to display
    ... % SWEI Display Parameters
    ,'velrange',[ ] ...
    ,'axial_scan',0 ...
    ,'sw_movie',0 ...
    ,'dvt_plots',0 ...
    ,'sw_display','disp' ... % Display displacements ('disp') or velocity ('vel') data
    );
options.display.t_disp_pre = options.motionFilter.timeRange_pre(1) + (options.display.t_disp_push - options.motionFilter.timeRange_push(1));

options.calcSWS = struct(...
    'enable',0 ...
    ,'method','LinReg' ... LinReg/ LatSum
    ,'metric', 'TTP' ...
    ,'r2_threshold',0.5 ...
    ,'SWSrange',[0 7] ...
    );

% Check input settings
switch options.dataflow.stream
    
    case 'RT' % realTime
        fprintf(1,'\n%%%%%%%%%%%%%%%%%%%%%% Real Time %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
        options.dataflow.display = 1; fprintf(1,'\nDisplay: On');
        options.dataflow.ecg_test = 0; fprintf(1,'\nECG Test: Off');
        options.dataflow.ARFI = 1; options.dataflow.SWEI = 0; fprintf(1,'\nARFI: On / SWEI: Off');
        options.dataflow.saveRes = 0; fprintf(1,'\nSaveRes: Off');
        options.dispEst.DOF_fraction = 2; fprintf(1,'\nDOF Fraction  = 2');
        options.display.extras = -1; fprintf(1,'\nExtras: Off [-1]');
        options.display.gateWidth = 20; fprintf(1,'\nGate Width = %d mm',options.display.gateWidth);
        fprintf(1,'\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'); fprintf(1,'\n\n');
        
    case 'review'
        fprintf(1,'\n%%%%%%%%%%%%%%%%%%%%%% Review %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
        options.dataflow.display = 1; fprintf(1,'\nDisplay: On');
        options.dataflow.ecg_test = 0; fprintf(1,'\nECG Test: Off');
        options.dataflow.saveRes = 0; fprintf(1,'\nSaveRes: Off');
        options.dispEst.DOF_fraction = 2; fprintf(1,'\nDOF Fraction  = 2');
        options.display.extras = 0; fprintf(1,'\nExtras: On [0]');
        options.display.gateWidth = 10; fprintf(1,'\nGate Width = %d mm',options.display.gateWidth);
        fprintf(1,'\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'); fprintf(1,'\n\n');
        
    case 'cluster'
        fprintf(1,'\n%%%%%%%%%%%%%%%%%%%%%% Cluster %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
        options.dataflow.display = 0; fprintf(1,'\nDisplay: Off');
        options.dataflow.ecg_test = 0; fprintf(1,'\nECG Test: Off');
        options.dataflow.ARFI = 1; options.dataflow.SWEI = 1; fprintf(1,'\nARFI: On / SWEI: On');
        options.dispEst.DOF_fraction = 5; fprintf(1,'\nDOF Fraction  = 5');
        options.dataflow.saveRes = 1; fprintf(1,'\nSaveRes: On');
        options.display.extras = -1; fprintf(1,'\nExtras: Off [-1]');
        fprintf(1,'\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'); fprintf(1,'\n\n');
                
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Function Call
procTTE(DataDir,fidx,options)

clear
clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%