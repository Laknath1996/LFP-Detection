% decimate the given signals in the channel matrix

function data_new = filter_channels(data,decimation_factor,Fs_new,cf)
    num_chan = size(data,2); % get the number of channels
    data_new = [];
    for i = 1:num_chan
        temp = data(:,i);
        j = 1;
        while j <= numel(decimation_factor) 
            temp = decimate(temp,decimation_factor(j));
            j = j + 1;
        end
        [b,a] = ellip(10,0.01,50,cf/(0.5*Fs_new));
        temp = filter(b,a,temp);
        data_new(:,i) = temp;
    end
    