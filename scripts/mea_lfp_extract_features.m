% Extract features from Low Frequency Content

%% Reset MATLAB workspace

clear all;
close all;

%% Get params from user

rootFolder = uigetdir(pwd,'Select root folder'); %select the folder with the signals

PopupPrompt  = {'Sampling frequency (Hz)','Window size for LFP detection (ms)','Low pass filter cutoff (Hz)','Std multiple for LFP detection','MIn threshold for LFP magnitude (uV)'};
PopupTitle   = 'Parameters for LFP feature Extraction';
PopupLines   = 1;
PopupDefault = {'20000','200','5','10','2'};

global fs
global winSize
global cutoff
global multCoeff
global thresh

answer = inputdlg(PopupPrompt,PopupTitle,PopupLines,PopupDefault,'on');
fs = str2double(answer{1}); %Sampling frequency
winSize = str2double(answer{2}); %Window size for LFP detection
cutoff= str2double(answer{3}); %Low pass filter cutoff
multCoeff = str2double(answer{4}); %Std multiple for LFP detection
thresh = str2double(answer{5}); %MIn threshold for LFP magnitude 

%% Navigate to folders

cd(rootFolder);
list = dir('*');
% take out the non folders
count = 1;
while count<=length(list)
    if list(count).isdir == 0
        list(count) = [];
    else
        count=count+1;
    end
end
recordings = {};
for i = 1:numel(list)
    recordings{i} = list(i).name;
end
recordings = recordings(3:end);

% navigate in to each recording folder
for i = 1:numel(recordings)
    disp(sprintf('Accessing LFP features from...%s',recordings{i}));
    cd(recordings{i});
    well_list = dir('*');
    count = 1;
    while count<=length(well_list)
        if well_list(count).isdir == 0
            well_list(count) = [];
        else
            count=count+1;
        end
    end
    wells = {};
    for ii = 1:numel(well_list)
        wells{ii} = well_list(ii).name;
    end
    wells = wells(3:end);
    % navigate in to each well folder 
    for j = 1:numel(wells)
        disp(sprintf('Extracting LFP features from %s...',wells{j}));
        cd(wells{j});
        cd('Mat_files');
        chan_list = dir('*.mat');
        chans = {};
        for jj = 1:numel(chan_list)
            chans{jj} = chan_list(jj).name;
        end
        features = zeros(12,26);
        for k = 1:numel(chans)
            load(chans{k});
            features(k,:) = getLfpFeatures(data);
        end
        cd ..
        mkdir('LFP_features');
        cd('LFP_features');
        save('lfp_features.mat','features');
        cd ..
        cd ..
    end
end
disp('Complete!');


    


