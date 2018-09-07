% author : ashwin de silva
% isolate the desired burst + follow up chunk

clear all;
close all;

% define some useful params
Fs = 20000;
%follow_up = 2;
%decimation_factor = [4,5];

% select the type of data
choice = menu('Select the Type','wildtype','r853q');

type = menu('Select the analisys','raw signals','filtered  signals','frequency profiles','fft','Time-Frequncy Analysis');

% get the start and end points of interest
prompt = {'start time of the chunk','end time of the chunk','desired channels (3)','decimation factors','follow up time','cutoff','channels for individula analysis'};
title = 'Start and End times of the Chunk';
defaultans = {'140','145','1,2,3,4,5,6,7,8,9,10,12','4,5','2','300','5'};
answer = inputdlg(prompt,title,1,defaultans);
start_time = str2double(answer{1})*Fs;
end_time = str2double(answer{2})*Fs;
chans = str2double(strsplit(char(answer{3}),','));
decimation_factor = str2double(strsplit(char(answer{4}),','));
follow_up = str2double(answer{5});
cf = str2double(strsplit(char(answer{6}),','));
channel = str2double(answer{7});

% load the 12 channels
if choice == 1
    load('dataset/wt_A2.mat'); % wild type
end
if choice == 2
    load('dataset/mut_r853q_A1.mat'); % r853q mutation
end
data = double(data);

% get the burst matrix
if choice == 1
    load('networkbursts/wt_bursts.mat'); % wild type
end
if choice == 2
    load('networkbursts/r853q_bursts.mat'); % r853q mutation
end

% get the latest netburst end time of the selected chunk
ets = netBursts(:,2);
ix = (start_time < ets) & (ets < end_time);
ix = find(ix);
netburst_endtime = netBursts(max(ix),2);
netburst_starttime = netBursts(max(ix),1);

% leave a follow up time of 5ms from the netburst end time
chunk_end = netburst_endtime + follow_up*Fs;
chunk_start = start_time; %netburst_starttime;

% select the number channels arbitrary channels
data = data(:,chans);

% chunk the signal
data = data(chunk_start:chunk_end,:);
tr = chunk_start/Fs:1/Fs:chunk_end/Fs;
raw = data;

% plot the raw sigal and add a line in the end time point of the network burst
if type == 1
    f1 = figure;
    for i = 1:numel(chans)
        subplot(numel(chans),1,numel(chans)+1-i);plot(tr,data(:,chans(i)));set(gca,'YLim',[-5000,5000]);line([netburst_endtime/Fs netburst_endtime/Fs],get(gca,'YLim'),'Color',[1 0 0]);
        line([netburst_starttime/Fs netburst_starttime/Fs],get(gca,'YLim'),'Color',[1 0 0]);grid on;
    end
end
% subplot(3,1,1);plot(tr,data(:,1));line([netburst_endtime/Fs netburst_endtime/Fs],get(gca,'YLim'),'Color',[1 0 0]);
% line([netburst_starttime/Fs netburst_starttime/Fs],get(gca,'YLim'),'Color',[1 0 0]);grid on;
% subplot(3,1,2);plot(tr,data(:,2));line([netburst_endtime/Fs netburst_endtime/Fs],get(gca,'YLim'),'Color',[1 0 0]);
% line([netburst_starttime/Fs netburst_starttime/Fs],get(gca,'YLim'),'Color',[1 0 0]);grid on;
% subplot(3,1,3);plot(tr,data(:,3));line([netburst_endtime/Fs netburst_endtime/Fs],get(gca,'YLim'),'Color',[1 0 0]);
% line([netburst_starttime/Fs netburst_starttime/Fs],get(gca,'YLim'),'Color',[1 0 0]);grid on;

% filter the selected chunk
if type == 2
    Fs_new = Fs/prod(decimation_factor);
    data = filter_channels(data,decimation_factor,Fs_new,cf);

    t = chunk_start/Fs:1/Fs_new:chunk_end/Fs;
    f2 = figure;
    for i = 1:numel(chans)
        subplot(numel(chans),1,numel(chans)+1-i);plot(t,data(:,chans(i)));%set(gca,'YLim',[-5000,5000]);
        line([netburst_endtime/Fs netburst_endtime/Fs],get(gca,'YLim'),'Color',[1 0 0]);
        line([netburst_starttime/Fs netburst_starttime/Fs],get(gca,'YLim'),'Color',[1 0 0]);grid on;
    end
end
        
% subplot(3,1,1);plot(t,data(:,1));line([netburst_endtime/Fs netburst_endtime/Fs],get(gca,'YLim'),'Color',[1 0 0]);
% line([netburst_starttime/Fs netburst_starttime/Fs],get(gca,'YLim'),'Color',[1 0 0]);grid on;
% subplot(3,1,2);plot(t,data(:,2));line([netburst_endtime/Fs netburst_endtime/Fs],get(gca,'YLim'),'Color',[1 0 0]);
% line([netburst_starttime/Fs netburst_starttime/Fs],get(gca,'YLim'),'Color',[1 0 0]);grid on;
% subplot(3,1,3);plot(t,data(:,3));line([netburst_endtime/Fs netburst_endtime/Fs],get(gca,'YLim'),'Color',[1 0 0]);
% line([netburst_starttime/Fs netburst_starttime/Fs],get(gca,'YLim'),'Color',[1 0 0]);grid on;

%frequency profiling (100, 100-200, 200-300)
if type == 3
    f3 = figure;
    Fs_new = Fs/prod(decimation_factor);
    t = chunk_start/Fs:1/Fs_new:chunk_end/Fs;
    
    subplot(5,1,1);plot(tr,raw(:,channel));%set(gca,'YLim',[-5000,5000]);
    line([netburst_endtime/Fs netburst_endtime/Fs],get(gca,'YLim'),'Color',[1 0 0]);
    line([netburst_starttime/Fs netburst_starttime/Fs],get(gca,'YLim'),'Color',[1 0 0]);grid on; % raw signal

    data = filter_channels(raw(:,channel),decimation_factor,Fs_new,100);
    subplot(5,1,2);plot(t,data);%set(gca,'YLim',[-5000,5000]);
    line([netburst_endtime/Fs netburst_endtime/Fs],get(gca,'YLim'),'Color',[1 0 0]);
    line([netburst_starttime/Fs netburst_starttime/Fs],get(gca,'YLim'),'Color',[1 0 0]);grid on;%title('100Hz LPF Signal'); % 100 lpf

    data = filter_channels(raw(:,channel),decimation_factor,Fs_new,[100,200]);
    subplot(5,1,3);plot(t,data);%set(gca,'YLim',[-5000,5000]);
    line([netburst_endtime/Fs netburst_endtime/Fs],get(gca,'YLim'),'Color',[1 0 0]);
    line([netburst_starttime/Fs netburst_starttime/Fs],get(gca,'YLim'),'Color',[1 0 0]);grid on;%title('100Hz - 200Hz BPF Signal'); % 100-200 bpf

    data = filter_channels(raw(:,channel),decimation_factor,Fs_new,[200,300]);
    subplot(5,1,4);plot(t,data);%set(gca,'YLim',[-5000,5000]);
    line([netburst_endtime/Fs netburst_endtime/Fs],get(gca,'YLim'),'Color',[1 0 0]);
    line([netburst_starttime/Fs netburst_starttime/Fs],get(gca,'YLim'),'Color',[1 0 0]);grid on;%title('200Hz - 300Hz BPF Signal'); % 200-300 bpf

    [b,a] = ellip(10,0.01,50,300/(0.5*Fs),'high');
    data = filter(b,a,raw(:,channel));
    subplot(5,1,5);plot(tr,data);%set(gca,'YLim',[-5000,5000]);
    line([netburst_endtime/Fs netburst_endtime/Fs],get(gca,'YLim'),'Color',[1 0 0]);
    line([netburst_starttime/Fs netburst_starttime/Fs],get(gca,'YLim'),'Color',[1 0 0]);grid on;%title('300Hz HPF Signal'); % 300 hpf
end

% fft of the burst region
if type == 4
    f4 = figure;
    data = raw(:,channel);
    L = numel(data);
    NFFT = 2^nextpow2(L); % Next power of 2 from length of y
    Y = fft(data,NFFT)/L;
    f = Fs/2*linspace(0,1,NFFT/2+1);

    % Plot single-sided amplitude spectrum.
    plot(f,2*abs(Y(1:NFFT/2+1))) 
    %title('Single-Sided Amplitude Spectrum of y(t)')
    xlabel('Frequency (Hz)')
    ylabel('|Y(f)|')
end

if type == 5
    Fs_new = Fs/prod(decimation_factor);
    data = filter_channels(raw(:,channel),decimation_factor,Fs_new,300);
    spectrogram(data,100,98,128,Fs_new,'yaxis');
    
end

    
disp('Input Parameters => ');
disp(['start time : ',num2str(start_time)]);
disp(['end time : ',num2str(end_time)]);
disp(['channels : ',num2str(chans)]);
disp(['decimation factor : ',num2str(decimation_factor)]);
disp(['decimated sampling frequency : ', Fs_new]);
disp(['follow up time (s) : ',num2str(follow_up)]);
disp(['cutoff frequency (Hz) : ',num2str(cf)]);
disp(['Channel for individual analysis : ',num2str(channel)]);




















