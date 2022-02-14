%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Comparing experiments of deactivated and activated solenoids %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Code written by Adrian Stein
% Data: 12/15/2021


% prerequisites: 

% - save the in a .txt file
% - assign a file name in line 18 & line 20
% - the data has to be truncated at the correct instant 
%   -> use ind_offset in line 19 & 21

clear all; clc; close all;

data_name_activated = '03_Receiver_attenuate_turned_on'; % change here
ind_offset_activated = 1; % change here (index to truncate the data from the front)
data_name_deactivated = '03_Receiver_attenuate_turned_off'; % change here
ind_offset_deactivated = 17; % change here (index to truncate the data from the front)

data_mat_activated = file_opener(data_name_activated, ind_offset_activated);
data_mat_deactivated = file_opener(data_name_deactivated, ind_offset_deactivated);

figure(1); 
hold on;
plot(data_mat_activated(:,1), data_mat_activated(:,2), 'b');
plot(data_mat_deactivated(:,1), data_mat_deactivated(:,2), 'k');
xlabel('Time [s]');
ylabel('Velocity [deg/s]');
xlim([0 20]); xticks([0 2 4 6 8 10 12 14 16 18 20]);
ylim([-350 350]); yticks([-300 -200 -100 0 100 200 300]);
legend('activated solenoids','deactivated solenoids');
grid on;
box on;

% calculate the sampling frequency
for ind = 1:length(data_mat_activated(:,1))-1
    difference_activated(ind) = data_mat_activated(ind+1,1) - data_mat_activated(ind,1);
end
f_sample_activated = 1/mean(difference_activated);

for ind = 1:length(data_mat_deactivated(:,1))-1
    difference_deactivated(ind) = data_mat_deactivated(ind+1,1) - data_mat_deactivated(ind,1);
end
f_sample_deactivated = 1/mean(difference_deactivated);

fprintf(' Sampling rate (without solenoid): %4.2f Hz \n Sampling rate (with solenoid): %4.2f Hz\n', f_sample_activated, f_sample_deactivated);


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