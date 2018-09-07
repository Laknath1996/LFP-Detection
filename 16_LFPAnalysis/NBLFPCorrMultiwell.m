function [burstSizes,lfpAmps,burstDurs,lfpDurs,burstAmps,delays,sizeAmpCorr,ampAmpCorr,durAmpCorr,burstCoinPerc,lfpCoinPerc]=NBLFPCorrMultiwell(rootFolder,fs,burstStr)
%sizeAmpCorr,leadPerc,burstCoinPerc,lfpCoinPerc,lfpPeakLagSPerc,lfpPeakLagEPerc,meanLFPPeak,burstSizes

colormap jet

cd(rootFolder);

clear lfpAll;


path = pwd;

%load the burst detection files
list = dir(burstStr);
fileName = list(1).name;
cd(fileName);
list = dir('*NetworkBurstDetectionFiles*');
cd(list(1).name);

list = dir('NetworkBurstDetection*.mat');

load(list(1).name);

cd ..
cd ..

%load the lfp files
list = dir('*LFP_files*');
cd(list(1).name);
list = dir('*LFP_data.mat*');
load(list(1).name);

chans = getMultiwell12Channels();

lfpStartsEnds = [];

for i=1:length(chans)   
     if channelMat(i,3)<channelMat(i,21) %if depRate<hypRate - hypAmp is the bigger amp
       lfpStartsEnds = [lfpStartsEnds;[depHypMat{i,11},depHypMat{i,12},depHypMat{i,5}',depHypMat{i,6}',depHypMat{i,7}]];   
     else
       lfpStartsEnds = [lfpStartsEnds;[depHypMat{i,9},depHypMat{i,10},depHypMat{i,1}',depHypMat{i,2}',depHypMat{i,3}]]; 
     end 
end

 lfpBurstInfo = [];
 noOfLFPs = 0;

 
for j=1:size(netBursts,1) 
    
        %find lfps that overlap a NB
            inds = find((netBursts(j,1)/fs<lfpStartsEnds(:,1) & netBursts(j,2)/fs>lfpStartsEnds(:,1)) | (netBursts(j,1)/fs>lfpStartsEnds(:,1) & netBursts(j,1)/fs<lfpStartsEnds(:,2)));
            if ~isempty(inds) && length(inds)>2
                
                    lfpsTemp = lfpStartsEnds(inds,:);
                    lfpsTemp = lfpsTemp(lfpsTemp(:,5)>prctile(lfpsTemp(:,5),10) & lfpsTemp(:,5)<prctile(lfpsTemp(:,5),90),:);
                if size(lfpsTemp,1)==1
                    lfpAvg = lfpsTemp;
                else
                    lfpAvg = mean(lfpsTemp);
                end
               
                try
               lfpBurstInfo = [lfpBurstInfo;[netBursts(j,1)/fs-lfpAvg(1),lfpAvg(1:2),lfpAvg(3),lfpAvg(4),...
                   lfpAvg(5),netBursts(j,9),netBursts(j,4),netBursts(j,6)]];
                catch
                    disp('');
                end
               
               noOfLFPs = noOfLFPs + 1;
                %1-delay, 2-lfp start and 3-end,4-lfp position,
                %5-lfp value, 6-lfp duration,7-burst size,8-burst duration,
                %9- sum of spikes of burst
                %if multiple lfps are inside the burst only the first one is considered
               % disp(sprintf('%d %d %d %d',burstCell(j,1),burstCell(j,2),lfpStartsEnds(inds(1),3),lfpStartsEnds(inds(1),1)));
            end
       
 end
    
   
   
   noOfBursts = size(netBursts,1);
   
sizeAmpCorr = corrcoef(lfpBurstInfo(:,5),lfpBurstInfo(:,7));
sizeAmpCorr = sizeAmpCorr(1,2);
ampAmpCorr = corrcoef(lfpBurstInfo(:,5),lfpBurstInfo(:,9));
ampAmpCorr = ampAmpCorr(1,2);
durAmpCorr = corrcoef(lfpBurstInfo(:,5),lfpBurstInfo(:,8));
durAmpCorr = durAmpCorr(1,2);

% sizeAmpCorr = corrcoef(lfpBurstInfo(:,5),lfpBurstInfo(:,7));
% sizeAmpCorr = sizeAmpCorr(1,2);
  
burstCoinPerc = 100*noOfLFPs/noOfBursts;
lfpCoinPerc = 100*noOfLFPs/noOfLFPs;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
burstSizes = lfpBurstInfo(:,7);
lfpAmps = lfpBurstInfo(:,5);
burstDurs = lfpBurstInfo(:,8);
lfpDurs = lfpBurstInfo(:,6);
burstAmps = lfpBurstInfo(:,9);
delays = lfpBurstInfo(:,1);



