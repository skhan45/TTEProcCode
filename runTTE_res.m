function runTTE_res(DataDir,type,fidx) 
    % Type - ARFI or SWEI

close all

% Add Paths
if ispc
    addpath(genpath('C:\Users\vrk4\Documents\GiHub\SC2000\arfiProcCode\'))
    addpath(genpath('C:\Users\vrk4\Documents\GitHub\TTEProcCode'))
elseif isunix
    addpath(genpath('/emfd/vrk4/GitHub/SC2000/arfiProcCode'))
    addpath(genpath('/emfd/vrk4/GitHub/TTEProcCode'))
end

if ~exist('DataDir','var')
    DataDir = pwd;
end
if ~exist('type','var')
    type = 'ARFI';
    str = sprintf('Type not specified. Defaulting to ARFI');
    warning(str);
end
if ~exist('fidx','var')
    fidx = 1;
end

if ~exist(fullfile(DataDir,'res'),'dir')
    error('res directory does not exist')
end

list = dir(strcat('arfi_par_*'));
if size(list,1)<fidx
    error('Data set index requested greater than number of data sets')
end

if fidx == -1
    timeStamp = list(end).name(end-17:end-4);
    fprintf('Loading data with timeStamp = %s (Set # %d of %d)\n', timeStamp,size(list,1),size(list,1));
else
    timeStamp = list(fidx).name(end-17:end-4);
    fprintf('Loading data with timeStamp = %s (Set # %d of %d)\n', timeStamp,fidx,size(list,1));
end

cd(fullfile(DataDir,'res'))
if exist(strcat('res_',lower(type),'_',timeStamp,'.mat'),'file')
    load(strcat('res_',lower(type),'_',timeStamp,'.mat'));
    cd ..
else
    cd ..
    error('res file for requested data set does not exist')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Inputs to dispTTE
options.motionFilter = struct(...
    'enable', 1 ...
    ,'method','Both' ... % Polynomial/LPF/Both
    ... % Parameters for Polynomial filter
    ,'order', 2 ...
    ,'timeRange_push',[-1.5 -1 4.5 5] ...
    ,'pre_offset', -6.5 ...
    ... % Parameters for Bandpass filter
    ,'LPF_Cutoff', 1000 ...
    );
options.motionFilter.timeRange_pre = options.motionFilter.timeRange_push + options.motionFilter.pre_offset;

options.display = struct(...
    'theme', 'light' ... % light/dark
    ,'IQrange',[-40 0] ...
    ,'gateWidth', 10 ...
    ,'gateOffset', 0 ...
    ,'n_pts', 5 ...
    ,'medfilt',[2.5 0.25] ... % median filter parameters - [axial (mm) acqTime (s)]
    ,'cc_filt', 1 ...
    ,'cc_thresh', 0.99...
    ... % ARFI Display Parameters
    ,'dispRange',[-5 15] ...
    ,'autoRange', 1 ...
    ,'normalize', 0 ...
    ,'t_disp_push', 0.6 ...
    ,'extras', 0 ... % [-1] - Suppress all extra plots; [0,1] - Asks for User Input on which plots to display
    ... % SWEI Display Parameters
    ,'velrange',[-3 3] ...
    ,'axial_scan',0 ...
    ,'sw_movie',0 ...
    ,'dvt_plots',1 ...
    ,'sw_display','disp' ... % Display displacements ('disp') or velocity ('vel') data
    );
options.display.t_disp_pre = options.motionFilter.timeRange_pre(1) + (options.display.t_disp_push - options.motionFilter.timeRange_push(1));
if ~options.motionFilter.enable
    options.display.dispRange = [-300 300]; options.autoRange = 0;
    fprintf(1,'Motion Filter is disabled:\nExanding displacement range to [%d %d], Turning autorange off\n',options.display.disprange(1),options.display.disprange(2));
end
options.calcSWS = struct(...
    'enable',0 ...
    ,'method','LinReg' ... LinReg/ LatSum
    ,'metric', 'TTP' ...
    ,'r2_threshold',0.5 ...
    ,'SWSrange',[0 7] ...
    );

switch type
    case 'ARFI'
        options.dataflow.ARFI = 1;
        options.dataflow.SWEI = 0;
        sweidata = []; swei_par = [];
    case 'SWEI'
        options.dataflow.ARFI = 0;
        options.dataflow.SWEI = 1;
        arfidata = []; arfi_par = [];
end

eval(strcat(lower(type),'_par = load(strcat(lower(type),''_par_'',timeStamp));'));
dispTTE(ecgdata,bdata,arfidata,arfi_par,sweidata,swei_par,options,timeStamp);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
