%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Comparing experiments to simulation for activated solenoids (pushing) %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Code written by Adrian Stein
% Data: 12/15/2021


% prerequisites:

% - save the in a .txt file
% - assign a file name in line 19
% - the beginning data has to be truncated at the correct instant 
%   -> use ind_offset in line 20


clear all; close all; clc;

data_name = '04_Receiver_pump_turned_on'; % change here
ind_offset = 242; % change here (index to truncate the data from the front)
angle_init_deg = -30; % change here (because you were holding the payload at -25°)

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
alpha_rad_sim = angle_init_deg/360*2*pi; % because you hold the pendulum at -25° initial condition
vel_radps_sim = data_mat(1,2)/360*2*pi; % angular velocity initial condition comes from the measured data

% assuming angle_off = 0° and vel_off = 0°/s
global angle_off vel_off;
angle_off = 0/360*2*pi; % in rad
vel_off = 0/360*2*pi; % in rad/s

bit_offset = 0;
[time_s_vec_sim_0, alpha_rad_vec_sim_0, vel_radps_vec_sim_0] = simualtion(zeta, L_activated_sim, L_deactivated_sim, g, n, ...
    time_s_sim, alpha_rad_sim, vel_radps_sim, time_s_real, bit_offset);

% assuming angle_off = 10° and vel_off = 10°/s
angle_off = 10/360*2*pi; % in rad
vel_off = 10/360*2*pi; % in rad/s

bit_offset = 1;
[time_s_vec_sim_10, alpha_rad_vec_sim_10, vel_radps_vec_sim_10] = simualtion(zeta, L_activated_sim, L_deactivated_sim, g, n, ...
    time_s_sim, alpha_rad_sim, vel_radps_sim, time_s_real, bit_offset);

figure(1); hold on;
plot(time_s_real, data_mat(:,2), 'b', 'Linewidth',2);
plot(time_s_vec_sim_0, vel_radps_vec_sim_0/(2*pi)*360,'r', 'Linewidth',2);
plot(time_s_vec_sim_10, vel_radps_vec_sim_10/(2*pi)*360,'g', 'Linewidth',2);
xlabel('Time [s]');
ylabel('Velocity [deg/s]');
xlim([0 20]); xticks([0 2 4 6 8 10 12 14 16 18 20]);
ylim([-350 350]); yticks([-300 -200 -100 0 100 200 300]);
grid on;
box on;
legend('real (with solenoid)','simulated (angle_{off} = 0 deg) and angle_vel_{off}=0)', 'simulated (angle_{off} = 10 deg and angle_vel_{off}=10)')

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

function [time_s_sim, alpha_deg_sim, vel_degps_sim] = simualtion(zeta, L_activated_sim, L_deactivated_sim, g, n, time_s_sim, alpha_deg_sim, vel_degps_sim, time_s_real, bit_offset)

start = 1;
for i=1:n
    if start == 1
        y0(1) = alpha_deg_sim; % phi in rad
        y0(2) = vel_degps_sim; % phi_dot in rad/s
        L_var = L_deactivated_sim; % start in with a deactivated solenoid mode
        start = 0; % set start-bit to 0, so it never enters this case again
    elseif abs(xx(end,1)) < abs(xx(end,2)) % we are at phi = 0 (lowest point) (assumption: phi is way smaller than phi_dot)
        y0(1) = xx(end,1); % phi in rad
        y0(2) = (L_deactivated_sim/L_activated_sim)^2*xx(end,2); % as an approximate for small perturbations around phi = 0; % phi in rad/s
        alpha_deg_sim = [alpha_deg_sim xx(:,1)']; % stack angle vector
        vel_degps_sim = [vel_degps_sim xx(:,2)']; % stack angular velocity vector
        time_s_sim = [time_s_sim tt'+time_s_sim(end)]; % stack time vector
        L_var = L_activated_sim; % new length is the activated rod length
    else % we are at phi_dot = 0 (max. displacement) (assumption: phi_dot is way smaller than phi)
        y0(1) = xx(end,1); % phi in rad
        y0(2) = xx(end,2); % phi in rad/s
        alpha_deg_sim = [alpha_deg_sim xx(:,1)']; % stack angle vector
        vel_degps_sim = [vel_degps_sim xx(:,2)']; % stack angular velocity vector
        time_s_sim = [time_s_sim tt'+time_s_sim(end)]; % stack time vector
        L_var = L_deactivated_sim; % new length is the deactivated rod length
    end
    
    if bit_offset == 1
        ode_opt = odeset('Events',@yzero_offset,'RelTol',1e-10,'AbsTol',1e-10);
    else
        ode_opt = odeset('Events',@yzero_0,'RelTol',1e-10,'AbsTol',1e-10);
    end
    
    [tt, xx] = ode45(@(t,y)odefct(y,g,L_var,zeta),time_s_real,y0,ode_opt); % start with squatted position
end

end

function dxdt = odefct(x,g,L,zeta)
x1_dot = x(2);
x2_dot = -zeta*x(2) - g/L*sin(x(1));
dxdt = [x1_dot; x2_dot];
end

function [value,isterminal,direction] = yzero_0(~,y)
% Locate the time when the value is zero
value =[y(1), y(2)];
isterminal = [1,1];
direction = [0,0];
end

function [value,isterminal,direction] = yzero_offset(~,y)
% Locate the time when the value is zero
global angle_off;
global vel_off;

% trigger too early (condition: angle_off > 0)
if y(2) > 0 % velocity > 0 ?
    angle = y(1) + angle_off; % trigger when the angle is still negative
elseif y(2) < 0 % velocity < 0 ?
    angle = y(1) - angle_off; % trigger when the angle is still positive
else
    angle = 99; % any number (never trigger)
end

% trigger too late (condition: vel_off > 0)
if y(1) > 0 % angle > 0 ?
    velocity = y(2) + vel_off; % trigger when the velocity is negative
elseif y(1) < 0 % angle < 0 ?
    velocity = y(2) - vel_off; % trigger when the velocity is positive
else
    velocity = 99; % any number (never trigger)
end

value =[angle, velocity];
isterminal = [1,1];
direction = [0,0];
end