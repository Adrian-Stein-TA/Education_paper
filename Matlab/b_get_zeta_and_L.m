%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Identifying damping and the rod length %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Code written by Adrian Stein
% Data: 12/15/2021


% prerequisites:

% - save the in a .txt file
% - assign a file name in line 19
% - the beginning data has to be truncated at the correct instant 
%   -> use ind_offset in line 20


clear all; clc; close all;

data_name = '03_Receiver_attenuate_turned_off'; % change here
ind_offset = 17; % change here (index to truncate the data from the front)
angle_init_deg = -90; % change here (because you were holding the payload at -90°)

data_mat = file_opener(data_name, ind_offset);

g = 9.81; % gravitational acceleration
stroke_m = 0.016; % measured stroke length with vernier caliper in [m] (maybe needs to be changed)
max_tries = 5; % maximal number of tries for fmincon optimizer
LB = [0.01, 0.1]; % lower bound; [c, L]
UB = [0.1, 1]; % upper bound; [c, L]
error_tolerance = 1e8; % maximal allowed error between measured and estimated data (maybe needs to be changed)
ode_opt = odeset('RelTol',1e-10,'AbsTol',1e-10);

% Optimizer
[paropt, error, counter_tries] = data_fit(data_mat,g,error_tolerance,max_tries,LB,UB,angle_init_deg,ode_opt);

% Ode-simulation with optimized values
xinit = [angle_init_deg/360*2*pi; data_mat(1,2)/360*2*pi]; % initial conditions (angle = -90°; angular velocity from the measured data)
[time_s_sim, data_mat_sim] = ode45(@(tx,x)inside(x,g,paropt(1),paropt(2)),data_mat(:,1),xinit,ode_opt);

figure(1); hold on;
plot(data_mat(:,1), data_mat(:,2), 'b');
plot(time_s_sim, data_mat_sim(:,2)/(2*pi)*360, 'r--');
xlabel('Time [s]');
ylabel('Velocity [deg/s]');
xlim([0 20]); xticks([0 2 4 6 8 10 12 14 16 18 20]);
ylim([-350 350]); yticks([-300 -200 -100 0 100 200 300]);
legend('measured','approximated');
grid on;
box on;

fprintf('Damping coefficient is: %4.4f\n', paropt(1));
fprintf('Length (off) is: %4.4f\n', paropt(2));
fprintf('Length (on) is: %4.4f\n', paropt(2)-stroke_m);
fprintf('Natural frequency (off): %4.4f rad/s\n', sqrt(g/paropt(2)));
fprintf('Natural frequency (on): %4.4f rad/s\n', sqrt(g/(paropt(2)-stroke_m)));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data_mat = file_opener(data_name, ind_offset)
fid1 = fopen([data_name '.txt'], 'r');
tline = fgetl(fid1);
headers = str2double(strsplit(tline, ','));
datacell = textscan(fid1, '%f %f %f', 'Delimiter',',', 'CollectOutput', 1);
fclose(fid1);
datavalues = datacell{1};
data = [headers(1:3);datavalues];

time_s = (data(ind_offset:end,1) - data(ind_offset,1))/1000;
vel_degps = data(ind_offset:end, 2);
data_mat = [time_s vel_degps];
end

function [paropt, error, counter_tries] = data_fit(data_mat,g,error_tolerance,max_tries,LB,UB,angle_init_deg,ode_opt)
error = 1e10; % any large number 
counter_first = 1; % to ensure we go once through the loop with the "good" initial guess
counter_tries = 0; % make random guesses for c and the rod length
x0 = [0.05; 0.68]; % c; L
while error > error_tolerance && counter_tries < max_tries
    options = optimoptions('fmincon','display','off','Algorithm','interior-point','MaxFunctionEvaluations',1e5);
    
    if counter_first == 0 % to randomly guess initial conditions
        x0 = [(UB(1)-LB(1))*rand(1)+LB(1), (UB(2)-LB(2))*rand(1)+LB(2)]; % [c, L]
    end
    counter_first = 0;
    
    [paropt,error] = fmincon(@fcost,x0,[],[],[],[],LB,UB,[],options,data_mat,g,angle_init_deg,ode_opt);
    counter_tries = counter_tries + 1; % counting up the tries
end
end

function f = fcost(par,data_mat,g,angle_init_deg,ode_opt)
c = par(1);
L = par(2);
xinit = [angle_init_deg/360*2*pi; data_mat(1,2)/360*2*pi];
[time_s_sim, data_mat_sim] = ode45(@(tx,x)inside(x,g,c,L),data_mat(:,1),xinit,ode_opt);

f = sum((data_mat(:,2) - data_mat_sim(:,2)/(2*pi)*360).^2); % least square error
end

function dxdt = inside(x,g,c,L)
x1_dot = x(2);
x2_dot = -c*x(2) - g/L*sin(x(1));
dxdt = [x1_dot; x2_dot];
end
