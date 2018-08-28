% isolate the desired burst + follow up chunk

% define some useful params
Fs = 20000;
follow_up = 2;
decimation_factor = [4,5];

% select the type of data
choice = menu('Select the Type','wildtype','r853q');

% get the start and end points of interest
prompt = {'start time of the chunk','end time of the chunk'};
title = 'Start and End times of the Chunk';
answer = inputdlg(prompt,title);
start_time = str2double(answer{1})*Fs;
end_time = str2double(answer{2})*Fs;

% load the 12 channels
if choice == 1
    load('dataset/wt_A2.mat'); % wild type
end
if choice == 2
    load('dataset/mut_r853q_A1'); % r853q mutation
end
data = double(data);

% get the burst matrix
if strcmp(choice,1)
    load('networkbursts/wt_bursts.mat'); % wild type
end
if strcmp(choice,2)
    load('networkbursts/r853q_bursts.mat'); % r853q mutation
end

% get the netburst end time of the selected chunk
ets = netBursts(:,2);
ix = (start_time < ets) & (ets < end_time);
ix = find(ix);
netburst_endtime = netBursts(max(ix),2);
netburst_starttime = netBursts(max(ix),1);

% leave a follow up time of 5ms from the netburst end time
chunk_end = netburst_endtime + follow_up*Fs;
chunk_start = start_time; %netburst_starttime;

% select only three arbitrary channels
data = data(:,[5,6,8]);

% chunk the signal
data = data(chunk_start:chunk_end,:);
t = chunk_start/Fs:1/Fs:chunk_end/Fs;

% plot the raw sigal and add a line in the end time point of the network burst
f1 = figure;
subplot(3,1,1);plot(t,data(:,1));line([netburst_endtime/Fs netburst_endtime/Fs],get(gca,'YLim'),'Color',[1 0 0]);
line([netburst_starttime/Fs netburst_starttime/Fs],get(gca,'YLim'),'Color',[1 0 0]);grid on;
subplot(3,1,2);plot(t,data(:,2));line([netburst_endtime/Fs netburst_endtime/Fs],get(gca,'YLim'),'Color',[1 0 0]);
line([netburst_starttime/Fs netburst_starttime/Fs],get(gca,'YLim'),'Color',[1 0 0]);grid on;
subplot(3,1,3);plot(t,data(:,3));line([netburst_endtime/Fs netburst_endtime/Fs],get(gca,'YLim'),'Color',[1 0 0]);
line([netburst_starttime/Fs netburst_starttime/Fs],get(gca,'YLim'),'Color',[1 0 0]);grid on;

% filter the selected chunk
Fs_new = Fs/prod(decimation_factor);
data = filter_channels(data,decimation_factor,Fs_new);

t = chunk_start/Fs:1/Fs_new:chunk_end/Fs;
f2 = figure;
subplot(3,1,1);plot(t,data(:,1));line([netburst_endtime/Fs netburst_endtime/Fs],get(gca,'YLim'),'Color',[1 0 0]);
line([netburst_starttime/Fs netburst_starttime/Fs],get(gca,'YLim'),'Color',[1 0 0]);grid on;
subplot(3,1,2);plot(t,data(:,2));line([netburst_endtime/Fs netburst_endtime/Fs],get(gca,'YLim'),'Color',[1 0 0]);
line([netburst_starttime/Fs netburst_starttime/Fs],get(gca,'YLim'),'Color',[1 0 0]);grid on;
subplot(3,1,3);plot(t,data(:,3));line([netburst_endtime/Fs netburst_endtime/Fs],get(gca,'YLim'),'Color',[1 0 0]);
line([netburst_starttime/Fs netburst_starttime/Fs],get(gca,'YLim'),'Color',[1 0 0]);grid on;



















