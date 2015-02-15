function [datastruct,dataSave,options] = extractMmode(timeStamp,options,datatype)

datatype = lower(datatype);

parFile = sprintf('%s_par_%s.mat', datatype,timeStamp);
binFile = sprintf('%s_SWIF_AData_%s.bin', datatype,timeStamp);
dimsFile = sprintf('%s_SWIF_ADataDims_%s.txt', datatype,timeStamp);

if ~exist(parFile, 'file')
    warning('ARFI parameters file not detected, ARFI Data may not have been saved');
    dataSave = 0;
elseif ~exist(binFile, 'file')
    warning('ARFI data file not detected, ARFI Data may not have been saved');
    dataSave = 0;
elseif ~exist(dimsFile, 'file')
    warning('ARFI Dims file not detected, ARFI Data may not have been saved');
    dataSave = 0;
else
    % Pull out IQ data
    data = readSwif(binFile, dimsFile);
    I = single(data.I);
    Q = single(data.Q);
    clear data
    
    % Load parameters file and assigning new values
    par = load(parFile);
    par.kernelLength = options.dispEst.kernelLength;
    par.interpFactor = options.dispEst.interpFactor;
    
    if (strcmpi(options.dispEst.ref_type,'anchored') && isempty(options.dispEst.ref_idx))
        options.dispEst.ref_idx = par.nref;
    elseif strcmpi(options.dispEst.ref_type,'progressive')
        options.dispEst.ref_idx = -1;
    end
    
    par.ref_type = options.dispEst.ref_type;
    par.ref_idx = options.dispEst.ref_idx;
    par.nreverb = options.dispEst.nreverb;
    
% Carried over from procArfi but not necessary for TTE M-mode ARFI/SWEI data    
%     % Confirm location of push frame in case of DMA-SWIF Buffer Event
%     temp_cc = computeCC(I(:,round(size(I,2)/2),1:par.nref+par.npush+20),round(size(I,1)/2));
%     temp_cc = squeeze(mean(temp_cc,1));
%     temp_cc(find(isnan(temp_cc))) = 0;
%     acq_nref = find(abs(temp_cc)<0.25,1)-1;
%     
%     if acq_nref == par.nref
%         fprintf(1,'Push frame at expected location\n');
%     elseif acq_nref == par.nref-1
%         fprintf(1,'Push frame offset due to DMA-SWIF Buffer Event \npar.nref, par.ensemble will be reduced by 1\n');
%         par.nref = par.nref-1; par.ensemble = par.ensemble-1;
%         I = I(:,:,1:1:par.ensemble); Q = Q(:,:,1:par.ensemble);
%     else
%         warning('Unable to detect location of push frame using correlation coefficients. Check IQ Data')
%     end
   
    % add number of acquisitions and harmonic flag to parameters structure if it isn't there
    if ~isfield(par, 'numAcq'),par.numAcq = 1;end
    if ~isfield(par, 'isHarmonic'), par.isHarmonic = 0;end
    
    % Reshape and reorder the data if we are using multiple acquisitions
    if par.numAcq>1
        I=reshape(I,size(I,1),size(I,2),size(I,3)/par.numAcq,par.numAcq);
        I=reshape(permute(I,[1,2,4,3]),size(I,1),size(I,2)*par.numAcq,size(I,3));
        Q=reshape(Q,size(Q,1),size(Q,2),size(Q,3)/par.numAcq,par.numAcq);
        Q=reshape(permute(Q,[1,2,4,3]),size(Q,1),size(Q,2)*par.numAcq,size(Q,3));
    end
    
    % sum data as needed if we are doing harmonic acquisitions
    if par.isHarmonic
        [I,Q] = genHarmonicSummedData(I,Q,par);
    end
    
    % Compute axial vector
    N = size(I,1)*par.interpFactor;
    axial = (0:N-1)*(par.c/1e3)/(2*par.fs*par.interpFactor);
    
    % Insert up-sampled Raw IQ Data into datastruct (used for tracing borders)
    datastruct.IQ = single(complex(I,Q));
    datastruct.IQaxial = axial(1:par.interpFactor:end);
    
    % Pull out only central Rx line in case of ARFI
    if (strcmpi(datatype,'arfi') && par.nBeams>1 && ~options.dataflow.oneSided)
        I = I(:,ceil(par.nBeams/2):par.nBeams:end,:);
        Q = Q(:,ceil(par.nBeams/2):par.nBeams:end,:);
    elseif (strcmpi(datatype,'arfi') && par.nBeams>1 && options.dataflow.oneSided)
        I = I(:,1:par.nBeams:end,:);
        Q = Q(:,1:par.nBeams:end,:);
    end
    
    % find center frequency (double frequency for harmonic data)
    if par.isHarmonic
        par.fc = par.trackParams.fc*1e6*2; % Hz
    else
        par.fc = par.trackParams.fc*1e6; % Hz
    end
    par.lambda = par.c / par.fc * 1e3; % mm
    
    % calculate depth gate over which to compute displacements
    dof = options.dispEst.DOF_fraction*9*1.540/par.pushFreq*(par.pushFnum)^2;
    start_depth = par.pushFocalDepth - (1/2)*dof;
    end_depth = par.pushFocalDepth + (1/2)*dof;
    if start_depth<axial(1);start_depth = axial(1);end
    if end_depth>axial(end);end_depth = axial(end-1);end
   
    % Compute displacements
    if strcmpi(options.dispEst.ref_type,'anchored')
        fprintf(1,'Computing displacements: Anchored at Frame %d (nref = %d)\nDepth Gate = %2.2f - %2.2f mm\n',par.ref_idx,par.nref,start_depth,end_depth)
    elseif par.ref_idx == -1
        fprintf(1,'Computing displacements: Progressive Depth Gate = %2.2f - %2.2f mm\n',start_depth,end_depth) 
    end
    
    if strcmpi(options.dispEst.method,'Loupas')
        if (strcmpi(options.dispEst.ref_type,'anchored') || strcmpi(options.dispEst.ref_type,'progressive'))
            [dispout, I_up, Q_up] = runLoupas_gated(I, Q, par.interpFactor, par.kernelLength, axial, par, start_depth, end_depth);
            dispout = single(dispout);
            temp = size(dispout,1);
        else
            error('Reference Type not recognized or not supported')
        end
    elseif strcmpi(options.dispEst.method,'Pesavento')
        
        % In the works...
        
%         if (strcmpi(options.dispEst.ref_type,'anchored'))
%             [dispout I_up Q_up cc] = runPesavento_gated(I, Q, par.interpFactor, par.kernelLength*2, options.dispEst.searchRegion, axial, par, start_depth, end_depth);
%         elseif (strcmpi(options.dispEst.ref_type,'progressive'))
%             [dispout_all I_all Q_all cc] = runPesaventoFlux(I,Q,res.t,options.displacement.interpFactor,options.displacement.kernelLength*2,options.displacement.searchRegion,axial0, par);
%         end

        else
        error('Displacement estimation method not recognized or not supported')
    end
    
    if options.dispEst.ccmode
        fprintf(1, 'Computing complex correlation coefficients\n');
        fs = par.fs*1e6*par.interpFactor;
        fc = par.fc; % Hz
        if (strcmpi(options.dispEst.ref_type,'anchored') || strcmpi(options.dispEst.ref_type,'progressive'))
            ccout = single(abs(computeCC(complex(I_up,Q_up),round(par.kernelLength*fs/fc),par.ref_idx)));
            ccout(:,:,par.nref+1:par.nref+par.npush+par.nreverb) = nan;
        else
            error('Reference Type not recognized or not supported')
        end
    end
    
    % Remove extra axial samples
    axial = start_depth + axial(1:temp);
    axial = axial + par.kernelLength * par.lambda / 2; % shift axial vector based on 50% of tracking kernel
    datastruct.axial = single(axial);
    
    
    % Insert calculated displacements, cc and IQ data into output structure
    if (strcmpi(options.dispEst.ref_type,'anchored') || strcmpi(options.dispEst.ref_type,'progressive'));
        datastruct.disp = dispout;
        if options.dispEst.ccmode
            datastruct.cc = ccout;
        end
    else
        error('Reference Type not recognized or not supported')
    end

    % Generate time vector
    % time = 0 is the first tracking vector
    [t, txTypeIndex, pushPRF] = genTimeVector(par);
    datastruct.trackTime = single(t);
    par.t = t;
    
    par.txTypeIndex = txTypeIndex;
    par.pushPRF = pushPRF;
    
    % Generate acqTime vector
    datastruct.acqTime = single(0:1/pushPRF:(par.numBeamGroups*par.numAcq-1)/par.pushPRF);
    
    % Generate lateral and axial vectors for SWEI tracking beams
    % Generates lateral extent as a funtion of depth based on the calculated angles for Rx beams
    temp = genLatMatrix(par);
    temp = temp(ceil(par.numBeamGroups*par.nBeams/2)-floor(par.nBeams/2):ceil(par.numBeamGroups*par.nBeams/2)+floor(par.nBeams/2)); % Pulling out the rx angles corresponding to the center beamgroup
    if options.dataflow.oneSided
        temp = temp(2:end);
    end
    [TH R] =  meshgrid(temp,datastruct.axial);
    datastruct.lat = R.*sind(TH) - repmat(par.trackParams.txXyzGridParams.apexMm(3).*cosd(temp'),size(R,1),1).*sind(TH);
    datastruct.ax = R.*cosd(TH);
    %         datastruct.lat = single((abs(par.trackParams.txXyzGridParams.apexMm(3)) + axial)'*tand(temp'));
    
    % Reshape sweidata
    if strcmpi(datatype,'swei')
        datastruct.disp = reshape(datastruct.disp,length(axial),par.nBeams,par.numBeamGroups*par.numAcq,par.ensemble);
        if options.dispEst.ccmode
            datastruct.cc = reshape(datastruct.cc,length(axial),par.nBeams,par.numBeamGroups*par.numAcq,par.ensemble);
        end
    end
        
    % Carried over from procArfi but not necessary for TTE M-mode ARFI/SWEI data
    %     % generate lateral position vector
    %     lat = genLatMatrix(par);
    %
    %     if par.separateFocalZoneAcqs
    %         arfidata = reshape(arfidata, [size(arfidata,1), par.nBeams, par.numBeamGroups*length(par.pushFocalDepth), par.numAcq, size(arfidata,3)]); % reshape into 4-D matrix
    %         if ccmode,cc_coef = reshape(cc_coef, [size(cc_coef,1), par.nBeams, par.numBeamGroups*length(par.pushFocalDepth), par.numAcq, size(cc_coef,3)]);end
    %     else
    %         arfidata = reshape(arfidata, [size(arfidata,1), par.nBeams, par.numBeamGroups, par.numAcq, size(arfidata,3)]); % reshape into 4-D matrix
    %         if ccmode,cc_coef = reshape(cc_coef, [size(cc_coef,1), par.nBeams, par.numBeamGroups, par.numAcq, size(cc_coef,3)]);end
    %     end
    
    %     % collapse to 3D matrix if lat variable is a vector
    %     if sum(size(lat)~=1)==1
    %         arfidata = reshape(arfidata, size(arfidata,1), [], size(arfidata,4), size(arfidata,5));
    %         if ccmode,cc_coef = reshape(cc_coef, size(cc_coef,1), [], size(cc_coef,4), size(cc_coef,5));end
    %         if par.numAcq>1
    %             arfidata = reshape(permute(arfidata, [1 2 4 3]), size(arfidata,1), size(arfidata,2), size(arfidata,4), 1, size(arfidata,3));
    %             if ccmode,cc_coef = reshape(permute(cc_coef, [1 2 4 3]), size(cc_coef,1), size(cc_coef,2), size(cc_coef,4), 1, size(cc_coef,3));end
    %         end
    %     elseif par.numAcq>1
    %         arfidata = permute(arfidata, [1 2 3 5 4]);
    %         if ccmode,cc_coef = permute(cc_coef, [1 2 3 5 4]);end
    %     end
    %     arfidata = squeeze(arfidata);
    %     if ccmode,cc_coef = squeeze(cc_coef);end
    
    %     % change axial and lat to radial and angular for phased and curvilinear array
    %     if max(strcmp(par.probeType,{'curvilinear','phased'}))
    %         radial = axial;
    %         angular = lat;
    %         apex = par.trackParams.txXyzGridParams.apexMm(3);
    %         clear axial lat
    %     end
    
    % Check existing parameters, add proc parameters to parFile
    par = checkParams(par);
    save(parFile,'-struct','par');
    
    %     % Save time stamped results file
    %     resfile = ['res_' timeStamp '.mat'];
    %     if strcmp(par.probeType,'linear')
    %         if bmodeSave
    %             if exist('cc_coef', 'var')
    %                 save(resfile, 'arfidata', 'axial', 'lat', 't', 'cc_coef', 'bimg', 'blat', 'bax', '-v7.3');
    %             else
    %                 save(resfile, 'arfidata', 'axial', 'lat', 't', 'bimg', 'blat', 'bax', '-v7.3');
    %             end
    %         else
    %             if exist('cc_coef', 'var')
    %                 save(resfile, 'arfidata', 'axial', 'lat', 't', 'cc_coef', '-v7.3');
    %             else
    %                 save(resfile, 'arfidata', 'axial', 'lat', 't', '-v7.3');
    %             end
    %         end
    %     elseif max(strcmp(par.probeType,{'curvilinear','phased'}))
    %         if bmodeSave
    %             if exist('cc_coef', 'var')
    %                 save(resfile, 'arfidata', 'radial', 'angular', 'apex', 't', 'cc_coef', 'bimg', 'blat', 'bax', '-v7.3');
    %             else
    %                 save(resfile, 'arfidata', 'radial', 'angular', 'apex', 't', 'bimg', 'blat', 'bax', '-v7.3');
    %             end
    %         else
    %             if exist('cc_coef', 'var')
    %                 save(resfile, 'arfidata', 'radial', 'angular', 'apex', 't', 'cc_coef', '-v7.3');
    %             else
    %                 save(resfile, 'arfidata', 'radial', 'angular', 'apex', 't', '-v7.3');
    %             end
    %         end
    %     else
    %         error('Unknown probe type')
    %     end
    dataSave = 1;
    
end
