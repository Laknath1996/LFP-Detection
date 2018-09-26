function features = getLfpFeatures(data)
    %% global variables
    
    global fs
    global winSize
    global cutoff
    global multCoeff
    global thresh
    decimation_factor = [5,5,5];
    
    %% wavelet analysis
    
    % decimate data
    temp = data;
    j = 1;
    Fs_new = fs/prod(decimation_factor);
    while j <= numel(decimation_factor) 
        temp = decimate(temp,decimation_factor(j));
        j = j + 1;
    end
    wt = modwt(temp,5,'db4'); % get the level decomposition
    
    % compute the features
    ED = sum(wt.^2, 2)./size(wt,2); % energy of each level
    ENT = -sum((wt.^2).*log(wt.^2),2); % entropy of each level
    stdev = sqrt(sum((wt - mean(wt,2)).^2,2)./size(wt,2)); % standard deviation for each level
    
    %% LFP shape analysis
    
    % low pass filter the signal
    [b, a] = butter(2, cutoff/(0.5*fs), 'low'); %low pass filter
    data = (filter(b, a, data)); %filter the data
    data = data - nanmean(data); %center the signal
    
    %Get noise threshold
    th = autoThreshForLFP(data,fs,multCoeff,winSize);
    
    %extract LFP positions
    
    %record the points that are above or below both computed threshold for
    %repsective window and the minimum LFP magnitude threshold
    lfpDep = data<-th' & data<-thresh; 
    lfpHyp = data>th' & data>thresh;
    
    signalDep = data;
    signalDep(~lfpDep)=0; %nullify the signal where there are no negative depolarizations
    signalHyp = data;
    signalHyp(~lfpHyp)=0; %nullify the signal where there are no positive depolarizations
    
    [depVals,depPos] = findpeaks(abs(signalDep),'minpeakdistance',fs/2); %detect the negative polarization peaks (within 500ms)
    [hypVals,hypPos] = findpeaks(abs(signalHyp),'minpeakdistance',fs/2); %detect the positive polarization peaks (within 500ms)
    
    inds = depVals<prctile(depVals,70)/2; %choose only the negative polarization peaks which are less than half of the 50th percentile
    depVals(inds) = []; 
    depPos(inds) = [];
    
    inds = hypVals<prctile(hypVals,70)/2; %choose only the negative polarization peaks which are more than half of the 50th percentile
    hypVals(inds) = [];
    hypPos(inds) = [];
    
     if ~isempty(hypVals) || ~isempty(depVals)

        if isempty(hypVals)
            hypVals = 0;
            hypPos = 0;
        end
        if isempty(depVals)
            depVals = 0;
            depPos = 0;
        end

        lfpShapeMat = [];

        %if the primary pattern is depression 
        if mean(depVals)>=mean(hypVals)
            for k=1:length(depVals)
                try
                    lfpShapeMat = [lfpShapeMat;[data(depPos(k)-fs/4:depPos(k)+fs/2)]]; % save the LFP shape
                end
            end
        end

        %if the primary pattern is potentiation
        if mean(depVals)<mean(hypVals)
            for k=1:length(hypVals)
                try
                    lfpShapeMat = [lfpShapeMat;[data(hypPos(k)-fs/4:hypPos(k)+fs/2)]]; % save the LFP shape
                end
            end
        end
     end
    
    % computer the polarization intervals
    depIntervals =diff(depPos); %get the LFP negative polarization intervals
    hypIntervals =diff(hypPos); %get the LFP positive polarization intervals
    
   % compute the features
    meanHypAmps = mean(hypVals);
    meanDepAmps = mean(depVals);
    meanHypIntervals = mean(hypIntervals)/fs; % in seconds
    meanDepIntervals = mean(depIntervals)/fs; % in seconds
    meanHypDurations = sum(signalHyp > 0)/(fs*numel(hypVals)); % in seconds
    meanDepDurations = sum(signalDep < 0)/(fs*numel(depVals)); % in seconds
    hypRate = numel(hypVals)/(numel(data)/fs);
    depRate = numel(depVals)/(numel(data)/fs);
    
    features = [ED' ENT' stdev' meanHypAmps meanDepAmps meanHypIntervals meanDepIntervals meanHypDurations meanDepDurations hypRate depRate];
    
end
    
    
