%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Impact of Low pass filter %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Code written by Adrian Stein
% Data: 01/19/2022

clear all; close all; clc;

data_name = '03_Receiver_attenuate_turned_on'; % change here
ind_offset = 1; % change here (index to truncate the data from the front)
angle_init_deg = -90; % change here (because you were holding the payload at -90°)

data_mat = file_opener(data_name, ind_offset);

% simulation
% from system identification (c_get_zeta_and_L.m)
zeta = 0.05; % change here (identified zeta from c_get_zeta_and_L.m)
L_deactivated_sim = 0.6815; % change here (identified rod length from c_get_zeta_and_L.m)
stroke_m = 0.016; % measured stroke length with vernier caliper in [m] (change here)

L_activated_sim =  L_deactivated_sim - stroke_m; 

g = 9.8; % gravitational acceleration
n = 50; % how often the ode45 should be called
time_s_sim = 0; % initialize time vector for stacking
time_s_real = data_mat(:,1); % use same time vector as the measured data
vel_radps_sim = data_mat(:,2); % filtered angular velocity in [deg/s]

vel_filtered = vel_radps_sim;
vel_raw_n(1) = 0;
for ind=2:length(vel_filtered)
    vel_raw_n(ind) = (vel_filtered(ind)- 0.7627*vel_filtered(ind-1))/0.2373; % from vel_filtered_n = 0.7627 * vel_filtered_n1 + 0.2373 * vel_raw_n;
end

figure(1)
plot(time_s_real, vel_raw_n, 'r'); hold on;
plot(time_s_real, vel_filtered, 'b')
legend('raw', 'filtered')
xlabel('Time [s]');
ylabel('Velocity [deg/s]');


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

