function [t, arfidata] = filtArfiData_TTE(axial, t, arfidata, nref, par, cutoffFreq, type, axFiltKer);
% function [t arfidata] = filtArfiData(axial, t, arfidata, cutoffFreq, axFiltKer, stdCutoff);
%
% this function is designed to work with a single acquisition (numAcq=1)
% if multiple acquisitions were performed, feed them in one at a time
%
% if nargin<4,cutoffFreq = [20 1000];end % filter cutoff frequencies (Hz)
% if nargin<5,axFiltKer = 0.5;end % axial filter length (mm)
% if nargin<6,stdCutoff = 10;end % cutoff in microns for the minimum standard deviation for push/reverb time steps

if nargin<6,cutoffFreq = [20 1000];end % filter cutoff frequencies (Hz)
if nargin<7,type = 'LPF';end % filter cutoff frequencies (Hz)
if nargin<8,axFiltKer = 1;end % axial filter length (mm)
% if nargin<7,stdCutoff = 10;end % cutoff in microns for the minimum standard deviation for push/reverb time steps


% determine push and reverb time steps, then remove them


% if ndims(arfidata)==3
%     out = squeeze(max(std(arfidata,0,2),[],1));
%     stem(out)
%     ts = out<stdCutoff; % valid time steps
% elseif ndims(arfidata)==4
%     out = squeeze(max(max(std(arfidata,0,3),[],1),[],2));
%     ts = out<stdCutoff; % valid time steps
% end

ts = true(1,size(arfidata,3))';
% ts(nref+(1:par.npush+2)) = false;

% Set up filtering parameters
dt = median(diff(t));
if (t(end)-t(end-1))>10*dt,ts(end)=0;end
% fprintf(1, 'Removing time step:\t%d\n', find(ts==0));
t = t(ts);t = round(t*1e4)/1e4; % numerical tolerance issues
tn = t; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% tn = t(1):dt:t(end);tn = round(tn*1e4)/1e4; % numerical tolerance issues
fs = 1./dt*1e3;
if strcmpi(type,'BPF') [B,A] = butter(3, cutoffFreq./(fs/2)); end % pass between cutoff
if strcmpi(type,'LPF') [B,A] = butter(3, cutoffFreq(2)./(fs/2),'low'); end % filter beyond cutoff

B = double(B); A = double(A);
n = max(1,round(axFiltKer./mean(diff(axial)))); % axial filter (minimum 1 sample)

% interpolate and filter the data
arfidata = reshape(arfidata, size(arfidata,1), [], size(arfidata,ndims(arfidata)));
arfidata = arfidata(:,:,ts);

% tstart = tic;
% arfidata = medfilt1(double(arfidata), double(n), [], 1); % axial filter
% fprintf(1, 'Axial median filter complete in %0.2f seconds\n', toc(tstart));

tstart = tic;
arfidata = temporalFilter(arfidata, t, tn, B, A); % interpolate and filter in time
fprintf(1, 'Temporal filter complete in %0.2f seconds\n', toc(tstart));
arfidata = single(arfidata);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This may be required when using PBF with ARFI Data

% Not Required after moving to a LPF as opposed to a BPF
% % Adding back lost DC component (values hard coded for TTE sequences)
% base = mean(arfidata(:,:,1:nref),3);
% base = repmat(base,[1 1 size(arfidata,3)]);
% arfidata = arfidata - base;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

t = tn;

end

function data = temporalFilter(arfidata, t, tn, B, A)
% interpolate and filter
D = size(arfidata);
arfidata = reshape(arfidata, [], D(end));
data = arfidata;
% data = interp1(t(:), arfidata', tn(:), 'spline')';
D(end) = length(tn);
data = single(filtfilt(B,A,double(data)'))';
data = reshape(data,D);
end