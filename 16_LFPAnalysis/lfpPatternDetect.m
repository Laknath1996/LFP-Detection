function [lfpMat,f,meanDist,lfpNNMat] = lfpPatternDetect(fs,rootFolder)

% answer = inputdlg({'fs (Hz)'},'Plot Parameters',1,{'10000'}); 
% fs = str2double(answer{1});

scrsz = get(0,'ScreenSize');
channels = getMEA60Channels();

%%Get the upper root folder
% rootFolder = uigetdir(pwd,'Select the root folder');
cd(rootFolder);


list = dir('*');
cd(list(3).name);


%load the lfp files
list = dir('*LFPInfo*');
cd(list(1).name);
list = dir('*LFPInfo.mat*');
load(list(1).name);

chans = getMEA60Channels();
lfpAll = [];

for i=1:length(lfpInfo)
    lfpMat = lfpInfo{i};
    if ~isempty(lfpMat)
        lfpAll = [lfpAll;[i*ones(size(lfpMat,1),1),lfpMat(:,1)]];
    end
end

lfpAll = sortrows(lfpAll,2);
lfpTimes = lfpAll(:,2);


lfpTimes = lfpAll(:,2);
ili = diff(sort(lfpTimes));
bins = logspace(log10(fs/1000),log10(max(ili)),100);
counts = histc(ili,bins);
counts = smooth(counts,'lowess');
thresh = otsu(bins,counts);
f = figure();
plot(bins./fs,counts);
hold on
plot(thresh./fs,0,'*r');
set(gca,'xscale','log');
%set(gca,'yscale','log');
close(f);

%gather lfps into groups
lfpGroupEnds = find(ili>thresh);

lfpMat = [];
lfpNNMat = [];

for i=1:length(lfpGroupEnds)
    if i==1
        group = lfpAll(1:lfpGroupEnds(i));
    else
        group = lfpAll(lfpGroupEnds(i-1)+1:lfpGroupEnds(i),:);
    end
    
    if size(group,1)>9
        %remove repeat occurances in the same channel
        chansFound = [];
        
        count = 1;
        while count<=size(group,1)
            if nnz(ismember(group(count,1),chansFound))==0
                chansFound = [chansFound,group(count,1)];
                count =count+1;
            else
                group(count,:)=[];
            end
        end
        
        lfpMatRow = zeros(1,60);
        lfpMatRow(:) = NaN;
        
        lfpNNMatRow = zeros(1,60);
        lfpNNMatRow(:) = NaN;
        
        for j=1:size(group,1)
            lfpMatRow(group(j,1)) = (group(j,2)-min(group(:,2)))./(max(group(:,2))-min(group(:,2)));
            lfpNNMatRow(group(j,1)) = group(j,2);
        end
        
        lfpMat = [lfpMat;lfpMatRow];
        lfpNNMat = [lfpNNMat;lfpNNMatRow];
    end
end

count = 1;
while count<=size(lfpMat,2)
    if nnz(isnan(lfpMat(:,count)))==size(lfpMat,1)
        lfpMat(:,count) = [];
    else
        count= count+1;
    end
end

count = 1;
while count<=size(lfpNNMat,2)
    if nnz(isnan(lfpNNMat(:,count)))==size(lfpNNMat,1)
        lfpNNMat(:,count) = [];
    else
        count= count+1;
    end
end

lfpMat(isnan(lfpMat)) = 1;
f2 = figure();
distances = pdist(lfpMat);
meanDist = mean(distances);
links = linkage(distances);
[h,T,outperm] = dendrogram(links,size(lfpMat,1));
lfpMat = lfpMat(outperm,:);
close(f2);

f = figure();
imagesc(1-rot90(lfpMat,2));
cb = colorbar;
ticks = get(cb,'YTickLabel');
set(cb,'YTickLabel',flipud(ticks)); %0 means 0 delay now.
ylabel('LFP Groups');
xlabel('Channels');
title(rootFolder);





