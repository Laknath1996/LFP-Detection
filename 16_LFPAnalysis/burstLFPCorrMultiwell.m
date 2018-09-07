function [burstSizes,lfpAmps,burstDurs,lfpDurs,burstAmps,delays,sizeAmpCorr,ampAmpCorr,durAmpCorr,burstCoinPerc,lfpCoinPerc]=burstLFPCorrMultiwell(rootFolder,fs,burstStr)
%sizeAmpCorr,leadPerc,burstCoinPerc,lfpCoinPerc,lfpPeakLagSPerc,lfpPeakLagEPerc,meanLFPPeak,burstSizes

colormap jet

cd(rootFolder);

clear lfpAll;


path = pwd;

%load the burst detection files
list = dir(burstStr);
fileName = list(1).name;
cd(fileName);
list = dir('*BurstDetectionFiles');
cd(list(1).name);

list = dir('*burst_detection*.mat');

load(list(1).name);

cd ..
cd ..

%load the lfp files
list = dir('*LFP_files*');
cd(list(1).name);
list = dir('*LFP_data.mat*');
load(list(1).name);

chans = getMultiwell12Channels();

%% Initilaize figure
scrsz = get(0,'ScreenSize');
f = figure('Position',[1+100 scrsz(1)+100 scrsz(3)-700 scrsz(4)-200]);
ylim([0,13]);
hold on

for i=1:length(chans)
    burstCell = full(burst_detection_cell{chans(i)});
    if ~isempty(burstCell)
        for k=1:size(burstCell,1)-1
            x = [burstCell(k,1),burstCell(k,2)]/fs;
            y = [i i];
            line(x,y,'lineWidth',2);
        end
    end
    
 
   if channelMat(i,3)<channelMat(i,21) %if depAmp<hypAmp - hypAmp is the bigger amp
           lfpStartsEnds = [depHypMat{i,11},depHypMat{i,12}];   
   else
       lfpStartsEnds = [depHypMat{i,9},depHypMat{i,10}]; 
   end   

    if ~isempty(lfpStartsEnds)
        plot(lfpStartsEnds(:,1),(i+0.2).*ones(size(lfpStartsEnds,1),1),'.g');
        plot(lfpStartsEnds(:,2),(i+0.2).*ones(size(lfpStartsEnds,1),1),'.r');
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
    
     if channelMat(i,3)<channelMat(i,21) %if depAmp<hypAmp - hypAmp is the bigger amp
           lfpStartsEnds = [depHypMat{i,11},depHypMat{i,12},depHypMat{i,5}',depHypMat{i,6}',depHypMat{i,7}];   
     else
       lfpStartsEnds = [depHypMat{i,9},depHypMat{i,10},depHypMat{i,1}',depHypMat{i,2}',depHypMat{i,3}]; 
     end 
    
    lfpBurstInfo = [];
    
    if ~isempty(burstCell) && ~isempty(lfpStartsEnds)
        %find lfps that preceed a burst, find the time lead, the lfp peak time, the lfp amplitude,  and
        %burst size, delay in lfp peak after burst start, delay in lfp peak
        %after burst end
        for j=1:size(lfpStartsEnds,1)
            inds = find(burstCell(:,1)/fs>lfpStartsEnds(j,1) & burstCell(:,1)/fs<lfpStartsEnds(j,2));
            if ~isempty(inds)
                if numel(inds)>1
                    burstSize = sum(burstCell(inds,3)); %if multiple bursts are inside the lfp, the burst size is taken as the summation of all bursts that are inside
                else
                    burstSize = burstCell(inds,3);
                end
                lfpBurstInfo = [lfpBurstInfo;[i,burstCell(inds(1),1)/fs-lfpStartsEnds(j,1),lfpStartsEnds(j,1:2),lfpStartsEnds(j,1),lfpStartsEnds(j,2),lfpStartsEnds(j,2)-lfpStartsEnds(j,1),...
                    burstSize,burstCell(inds(1),4),burstCell(inds(1),7)]];
                %1-channel,2-delay, 3-lfp start and 4-end,5-lfp position,
                %6-lfp value, 7-lfp duration,8-burst size,9-burst duration,
                %10- sum of spikes of burst
                %disp(sprintf('%d %d %d %d',burstCell(inds(1),1),burstCell(inds(1),2),lfpStartsEnds(j,3),lfpStartsEnds(j,1)));
            end
        end       
        
        %find lfps that suceed a burst, find the time lag, the lfp peak time,the lfp amplitude and
        %burst size
         for j=1:size(burstCell,1)-1
            inds = find(burstCell(j,1)/fs<lfpStartsEnds(:,1) & burstCell(j,2)/fs>lfpStartsEnds(:,1));
            if ~isempty(inds)
               lfpBurstInfo = [lfpBurstInfo;[i,burstCell(j,1)-lfpStartsEnds(inds(1),1),lfpStartsEnds(inds(1),1:2),lfpStartsEnds(inds(1),1),lfpStartsEnds(inds(1),2),...
                   lfpStartsEnds(inds(1),2)-lfpStartsEnds(inds(1),1),burstCell(j,3),burstCell(j,4),burstCell(j,7)]];
                %if multiple lfps are inside the burst only the first one is considered
               % disp(sprintf('%d %d %d %d',burstCell(j,1),burstCell(j,2),lfpStartsEnds(inds(1),3),lfpStartsEnds(inds(1),1)));
            end
         end        
    end
    
 
    
   
   lfpAll = [lfpAll;lfpBurstInfo];
   noOfBursts = noOfBursts + size(burstCell,1)-1;
   noOfLFPs = noOfLFPs + size(lfpStartsEnds,1);
end

sizeAmpCorr = corrcoef(lfpAll(:,6),lfpAll(:,8));
sizeAmpCorr = sizeAmpCorr(1,2);
ampAmpCorr = corrcoef(lfpAll(:,6),lfpAll(:,10));
ampAmpCorr = ampAmpCorr(1,2);
durAmpCorr = corrcoef(lfpAll(:,6),lfpAll(:,9));
durAmpCorr = durAmpCorr(1,2);

leadPerc = 100*length(find(lfpAll(:,2)>0))/size(lfpAll,1);
burstCoinPerc = 100*size(lfpAll,1)/noOfBursts;
lfpCoinPerc = 100*size(lfpAll,1)/noOfLFPs;
%lfpPeakLagSPerc = 100*length(find(lfpAll(:,6)>0))/size(lfpAll,1);
%lfpPeakLagEPerc = 100*length(find(lfpAll(:,7)>0))/size(lfpAll,1);
meanLFPPeak = nanmean(lfpAll(:,6));
burstSizes = lfpAll(:,8);
burstSizes = burstSizes(burstSizes<prctile(burstSizes,90));
burstSizes = nanmean(burstSizes);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
burstSizes = lfpAll(:,8);
lfpAmps = lfpAll(:,6);
burstDurs = lfpAll(:,9);
lfpDurs = lfpAll(:,7);
burstAmps = lfpAll(:,10);
delays = lfpAll(:,2);

close(f);


