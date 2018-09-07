function [sizeAmpCorr,leadPerc,burstCoinPerc,lfpCoinPerc,lfpPeakLagSPerc,lfpPeakLagEPerc,meanLFPPeak,burstSizes]=burstLFPCorr(rootFolder,fs,burstStr)

% rootFolder = uigetdir(pwd,'Select root folder');
% 
% %get params from user
% PopupPrompt  = {'Sampling frequency (Hz)','Burst Detection String'};
% PopupTitle   = 'LFP Burst Correlations';
% PopupLines   = 1;
% PopupDefault = {'10000','*BurstDetectionMAT_5-TC*'};
% %----------------------------------- PARAMETER CONVERSION
% answer = inputdlg(PopupPrompt,PopupTitle,PopupLines,PopupDefault,'on');
% fs = str2double(answer{1});
% burstStr = answer{2};

colormap jet

cd(rootFolder);

clear lfpAll;

% list = dir('*');

% count = 1;
% 
% while count<=length(list)
%     if list(count).isdir == 0
%         list(count) = [];
%     else
%         count=count+1;
%     end
% end
% 
% cd(list(3).name);

path = pwd;

%load the burst detection files
list = dir(burstStr);
fileName = list(1).name;
cd(fileName);
list = dir('*BurstDetectionFiles');
cd(list(1).name);

list = dir('*burst_detection_*.mat');

load(list(1).name);

cd ..
cd ..

%load the lfp files
list = dir('*LFPInfo*');
cd(list(1).name);
list = dir('*LFPInfo.mat*');
load(list(1).name);

chans = getMEA60Channels();

%% Initilaize figure
scrsz = get(0,'ScreenSize');
f = figure('Position',[1+100 scrsz(1)+100 scrsz(3)-200 scrsz(4)-200]);
ylim([0,60]);
hold on

for i=1:length(chans)
    burstCell = burst_detection_cell{chans(i)};
    
    if ~isempty(burstCell)
        burstCell = burstCell(burstCell(:,3)>10,1:end-1); %ONLY TAKE BURSTS THAT ARE LARGER THAN 10 SPIKES TO AVOID GETTING STIM ATREFACTS
        for k=1:size(burstCell,1)-1
            x = [burstCell(k,1),burstCell(k,2)]/fs;
            y = [i i];
            line(x,y,'lineWidth',2);
        end
    end
    
    lfpStartsEnds = lfpInfo{i};
    if ~isempty(lfpStartsEnds)
        plot(lfpStartsEnds(:,3)./fs,(i+0.2).*ones(size(lfpStartsEnds,1),1),'.g');
        plot(lfpStartsEnds(:,4)./fs,(i+0.2).*ones(size(lfpStartsEnds,1),1),'.r');
        plot(lfpStartsEnds(:,1)./fs,(i+0.2).*ones(size(lfpStartsEnds,1),1),'.k');
    end
end

close(f);


 f = figure();
 hold on
 
 lfpAll = [];
 noOfBursts = 0;
 noOfLFPs = 0;
 
for i=1:length(chans)
    burstCell = burst_detection_cell{chans(i)};
    lfpStartsEnds = lfpInfo{i};
    
    if ~isempty(lfpStartsEnds)
    durs = lfpStartsEnds(:,4)-lfpStartsEnds(:,3);
    inds = find(durs<prctile(durs,90));
    lfpStartsEnds = lfpStartsEnds(inds,:);
    diffs = lfpStartsEnds(2:end,3)-lfpStartsEnds(1:end-1,4);
    inds = find(diffs<=0);
    lfpStartsEnds(inds,:) = [];
    end
    
    lfpBurstInfo = [];
    
    if ~isempty(burstCell) && ~isempty(lfpStartsEnds)
        burstCell = burstCell(burstCell(:,3)>10,1:end-1); %ONLY TAKE BURSTS THAT ARE LARGER THAN 10 SPIKES TO AVOID GETTING STIM ATREFACTS
        
        %find lfps that preceed a burst, find the time lead, the lfp peak time, the lfp amplitude,  and
        %burst size, delay in lfp peak after burst start, delay in lfp peak
        %after burst end
        for j=1:size(lfpStartsEnds,1)
            inds = find(burstCell(:,1)>lfpStartsEnds(j,3) & burstCell(:,1)<lfpStartsEnds(j,4));
            if ~isempty(inds)
                if numel(inds)>1
                    burstSize = sum(burstCell(inds,3)); %if multiple bursts are inside the lfp, the burs isze is taken as the summation of all bursts that are inside
                else
                    burstSize = burstCell(inds,3);
                end
                lfpBurstInfo = [lfpBurstInfo;[i,burstCell(inds(1),1)-lfpStartsEnds(j,3),lfpStartsEnds(j,1:2),burstSize,lfpStartsEnds(j,1)-burstCell(inds(1),1),lfpStartsEnds(j,1)-burstCell(inds(1),2)]];
                disp(sprintf('%d %d %d %d',burstCell(inds(1),1),burstCell(inds(1),2),lfpStartsEnds(j,3),lfpStartsEnds(j,1)));
            end
        end       
        
        %find lfps that suceed a burst, find the time lag, the lfp peak time,the lfp amplitude and
        %burst size
         for j=1:size(burstCell,1)-1
            inds = find(burstCell(j,1)<lfpStartsEnds(:,3) & burstCell(j,2)>lfpStartsEnds(:,3));
            if ~isempty(inds) %lfpInfo columns: channel no in 1-60, delay from lfp start to burst start, lfpPeakPos, lfpPeakVal, burstSize, delay from burst start to lfp Peak, delay from burst end to lfp peak
                lfpBurstInfo = [lfpBurstInfo;[i,burstCell(j,1)-lfpStartsEnds(inds(1),3),lfpStartsEnds(inds(1),1:2),burstCell(j,3),lfpStartsEnds(inds(1),1)-burstCell(j,1),lfpStartsEnds(inds(1),1)-burstCell(j,2)]];
                %if multiple lfps are inside the burst only the first one is considered
                disp(sprintf('%d %d %d %d',burstCell(j,1),burstCell(j,2),lfpStartsEnds(inds(1),3),lfpStartsEnds(inds(1),1)));
            end
         end        
    end
    
   if ~isempty(lfpBurstInfo)
         [~,inds] = unique(lfpBurstInfo(:,3));
    lfpBurstInfo = lfpBurstInfo(inds,:);
    plot(lfpBurstInfo(:,4),lfpBurstInfo(:,5),'+','Color',getColormapVal(i,60));
   end
    
   try
   disp(i); 
   disp(nanmean(lfpBurstInfo(:,4)));
   end
   lfpAll = [lfpAll;lfpBurstInfo];
   noOfBursts = noOfBursts + size(burstCell,1)-1;
   noOfLFPs = noOfLFPs + size(lfpStartsEnds,1);
end

sizeAmpCorr = corrcoef(lfpAll(:,4),lfpAll(:,5));
sizeAmpCorr = sizeAmpCorr(1,2);
leadPerc = 100*length(find(lfpAll(:,2)>0))/size(lfpAll,1);
burstCoinPerc = 100*size(lfpAll,1)/noOfBursts;
lfpCoinPerc = 100*size(lfpAll,1)/noOfLFPs;
lfpPeakLagSPerc = 100*length(find(lfpAll(:,6)>0))/size(lfpAll,1);
lfpPeakLagEPerc = 100*length(find(lfpAll(:,7)>0))/size(lfpAll,1);
meanLFPPeak = nanmean(lfpAll(:,4));
burstSizes = lfpAll(:,5);
burstSizes = burstSizes(burstSizes<prctile(burstSizes,90));
burstSizes = nanmean(burstSizes);

close(f);


