%Author : Dulini Mendis
%Anotated by : Ashwin de Silva

function LFPOverlay()

rootFolder = uigetdir(pwd,'Select root folder');%select the folder with the signals

%% Get params from user

PopupPrompt  = {'Sampling frequency (Hz)','Window size for LFP detection (ms)','Low pass filter cutoff (Hz)','Std multiple for LFP detection','MIn threshold for LFP magnitude (uV)'};
PopupTitle   = 'Connectivity Maps - Mutual Information';
PopupLines   = 1;
PopupDefault = {'10000','200','5','10','2'};

answer = inputdlg(PopupPrompt,PopupTitle,PopupLines,PopupDefault,'on');
fs = str2double(answer{1}); %Sampling frequency
winSize = str2double(answer{2}); %Window size for LFP detection
cutoff= str2double(answer{3}); %Low pass filter cutoff
multCoeff = str2double(answer{4}); %Std multiple for LFP detection
thresh = str2double(answer{5}); %MIn threshold for LFP magnitude 


colormap jet

%% Get the filenames in to a list

cd(rootFolder);


list = dir('*');

count = 1;

while count<=length(list)
    if list(count).isdir == 0
        list(count) = [];
    else
        count=count+1;
    end
end

cd(list(3).name);

path = pwd;

list = dir('*MAT_files*');
cd(list(1).name);
list = dir('*');
cd(list(3).name);

list = dir('*.mat');

channelMat = [];
scrsz = get(0,'ScreenSize');
fShapes =figure('Position',[1+10 scrsz(1)+100 scrsz(3)-150 scrsz(4)-200]);

%% Analyze each file


for j=1:length(list)
    load(list(j).name); %load the signal
    data = data(fs*150:end); %select the datastream only after 2.5 minutes
    [b, a] = butter(2, cutoff/(0.5*fs), 'low'); %low pass filter
    data = (filter(b, a, data)); %filter the data
    data = data - nanmean(data); %center the signal
    
    %Get noise threshold
    th = autoThreshForLFP(data,fs,multCoeff,winSize);
    
    %extract LFP positions
    
    %record the points that are above or below both computed threshold for
    %repsective window and the minimum LFP magnitude threshold
    lfpDep = data<-th & data<-thresh; 
    lfpHyp = data>th & data>thresh;
    
    signalDep = data;
    signalDep(~lfpDep)=0; %nullify the signal where there are no negative depolarizations
    signalHyp = data;
    signalHyp(~lfpHyp)=0; %nullify the signal where there are no positive depolarizations
    
    [depVals,depPos] = findpeaks(abs(signalDep),'minpeakdistance',fs/2); %detect the negative polarization peaks (within 500ms)
    [hypVals,hypPos] = findpeaks(abs(signalHyp),'minpeakdistance',fs/2); %detect the positive polarization peaks (within 500ms)
    
    inds = depVals<prctile(depVals,50)/2; %choose only the negative polarization peaks which are less than half of the 50th percentile
    depVals(inds) = []; 
    depPos(inds) = [];
    
    inds = hypVals<prctile(hypVals,50)/2; %choose only the negative polarization peaks which are more than half of the 50th percentile
    hypVals(inds) = [];
    hypPos(inds) = [];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    chanNo = getChanNo(list(j).name); 
    ind = getSubplotIndexMEA60(chanNo);
    subplot(8,8,ind);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    xlim([-fs/4,fs/2]./10);
    hold on
    
    
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
                    lfpShapeMat = [lfpShapeMat;[data(depPos(k)-fs/4:depPos(k)+fs/2)]']; % might not include first or last lfp if not enough padding is available to fill the mat row
                    plot([-fs/4:fs/2]./10,lfpShapeMat(end,:),'Color',getColormapVal(k,length(depVals))); %padding is done
                end
            end
        end
        
        %if the primary pattern is potentiation
        if mean(depVals)<mean(hypVals)
            for k=1:length(hypVals)
                try
                    lfpShapeMat = [lfpShapeMat;[data(hypPos(k)-fs/4:hypPos(k)+fs/2)]']; % might not include first or last lfp if not enough padding is available to fill the mat row
                    plot([-fs/4:fs/2]./10,lfpShapeMat(end,:),'Color',getColormapVal(k,length(hypVals))); %padding is done
                end
            end
        end
    end
    
     
    f = figure();
    plot([1:length(data)]./fs,data);
    hold on
    plot([1:length(data)]./fs,signalDep,'r');
    plot(depPos./fs,-depVals,'*g');
    plot(hypPos./fs,hypVals,'*g');
    
    depIntervals =diff(depPos); %get the LFP negative polarization intervals
    hypIntervals =diff(hypPos); %get the LFP positive polarization intervals
    close(f);
    
end

cd(path);
mkdir('LFPWaveShapes');
cd('LFPWaveShapes');
saveas(fShapes,strcat('LFP waveforms - ',folderName));
saveas(fShapes,strcat('LFP waveforms - ',folderName,'.jpg'));
save('LFPWaveShapes','lfpShapeMat');
close(fShapes);