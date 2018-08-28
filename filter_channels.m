% decimate the given signals in the channel matrix

function data_new = filter_channels(data,decimation_factor,Fs_new)
    num_chan = size(data,2); % get the number of channels
    data_new = [];
    for i = 1:num_chan
        temp = decimate(data(:,i),decimation_factor(1));
        temp = decimate(temp,decimation_factor(2));
        [b,a] = ellip(10,0.01,50,300/Fs_new);
        temp = filter(b,a,temp);
        data_new(:,i) = temp;
    end
    