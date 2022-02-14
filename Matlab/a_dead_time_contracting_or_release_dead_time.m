%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Calculating the dead time of activating/deactivating solenoids %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Code written by Adrian Stein
% Data: 12/15/2021

% prerequisites:

% - save the Serial Monitor as .txt files (for activating and deactivating respectively)
% - assign a file name in line 19 & line 20
% - the data has to be truncated before the text ############## Now the button was pushed ############## (including the text)


% info: for the accelerometer "1" is the normalized gravity

clear all; clc; close all;

data_name_activated = '01_activating_solenoid'; % change here
data_name_deactivated = '02_deactivating_solenoid'; % change here

acc_chosen = 0.5; % velocity to trigger that there is a change

data_mat_activated = file_opener(data_name_activated, 1);
data_mat_deactivated = file_opener(data_name_deactivated, 1);

time_index_activated = min(find(data_mat_activated(:,2) > 1+acc_chosen | data_mat_activated(:,2) < 1-acc_chosen));
time_index_deactivated = min(find(data_mat_deactivated(:,2) > 1+acc_chosen | data_mat_deactivated(:,2) < 1-acc_chosen));

figure(1);
subplot(2,1,1); hold on;
plot(data_mat_activated(:,1), data_mat_activated(:,2), 'b');
plot([data_mat_activated(time_index_activated,1) data_mat_activated(time_index_activated,1)], [-5 5],'r--')
xlabel('Time [s]');
ylabel('velocity [deg/s]');
title('activating solenoids');

subplot(2,1,2); hold on;
plot(data_mat_deactivated(:,1), data_mat_deactivated(:,2), 'b');
plot([data_mat_deactivated(time_index_deactivated,1) data_mat_deactivated(time_index_deactivated,1)], [-5 5],'r--')
xlabel('Time [s]');
ylabel('velocity [deg/s]');
title('deactivating solenoids');

% calculate the sampling frequency
for ind = 1:length(data_mat_activated(:,1))-1
    difference_activated(ind) = data_mat_activated(ind+1,1)- data_mat_activated(ind,1);
end
f_sample_activated = 1/mean(difference_activated);

for ind = 1:length(data_mat_deactivated(:,1))-1
    difference_deactivated(ind) = data_mat_deactivated(ind+1,1)- data_mat_deactivated(ind,1);
end
f_sample_deactivated = 1/mean(difference_deactivated);

fprintf(' Sampling rate (activating): %4.4f Hz \n Sampling rate (deactivating): %4.4f Hz\n', f_sample_activated, f_sample_deactivated);
fprintf(' Dead time (activating): %4.4f s \n Dead time (deactivating): %4.4f s \n', data_mat_activated(time_index_activated,1) + 1/f_sample_activated, data_mat_deactivated(time_index_deactivated,1) + 1/f_sample_deactivated);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data_mat = file_opener(data_name, ind_offset)
fid1 = fopen([data_name '.txt'], 'r');
tline = fgetl(fid1);
headers = str2double(strsplit(tline, ','));
datacell = textscan(fid1, '%f %f', 'Delimiter',',', 'CollectOutput', 1);
fclose(fid1);
datavalues = datacell{1};
data = [headers(1:2);datavalues];

time_s = (data(ind_offset:end,1) - data(ind_offset,1))/1000;
vel_degps = data(ind_offset:end, 2);
data_mat = [time_s vel_degps];
end