% save the mean features of the wells

%% reset MATLAB workspace

close all;
clear all;

%% get the user input 

rootFolder = uigetdir('Select the Root Folder');

%% navigate in to the folders

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
feature_bank_per_well = [];
feature_bank_per_channel = [];
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
    well_features = [];
    % navigate in to each well folder 
    for j = 1:numel(wells)
        cd(wells{j});
        cd('LFP_features');
        load('lfp_features.mat');
        well_features(j,:) = [mean(features,1) std(features,0,1)];
        feature_bank_per_channel = [feature_bank_per_channel ; features];
        cd ..
        cd ..
    end
    feature_bank_per_well = [feature_bank_per_well ; well_features];
    cd ..
end
save('feature_bank.mat','feature_bank_per_well','feature_bank_per_channel');
disp('Complete!');

