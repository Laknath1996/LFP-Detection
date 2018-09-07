function th = autoThreshForLFP(data,fs,multCoeff,winSize)
%% computes the Noise Threshold Level

nSamples = length(data); %T
binWidth = 10*fs; %10 s (Wbin)
noOfBins = ceil(nSamples/binWidth); %T/Wbin
th = zeros(nSamples,1);

nWin = 10; % Nwin
winDur = winSize*1e-3; % now in seconds (Wwin)
winDur_samples = winDur.*fs; % length of samples

%defines the coundaries of the samples

startSample = 1:(round(binWidth/nWin)):binWidth; % take n samples from the signal
endSample = startSample+winDur_samples-1; 

for i = 1:noOfBins
    
    thBlock = 100; %default noise threshold for a block
    dataBlock = data((i-1)*binWidth+1:min([i*binWidth,nSamples])); %define the i th datablock
    
    thsInBlock = 100*ones(nWin,1); %samples taken from the i th block
    for j = 1:nWin
        try
            %compute the noise level for each sample
            thThis = std(dataBlock(startSample(j):endSample(j))); %since you're cutting off the dc frequencies, there shouldn't be an offset --> mean ~= 0
            if thBlock > thThis
                thBlock = thThis; %get the minimum std of a section of the signal as the std of noise
            end
        end
    end
    
    th((i-1)*binWidth+1:i*binWidth) = thBlock; %assign the noise threshold for the time points within the block
end

th = th.*multCoeff; % multiply each threshold by the std multiple
th = th(1:length(data)); %noise threshold