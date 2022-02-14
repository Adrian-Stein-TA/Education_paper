%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Low-Pass filter and derivation for difference equation %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Code written by Adrian Stein
% Data: 12/15/2021


% prerequisites:

% - assign the correct cut off frequency in line 18

clear all; close all; clc;

fs = 116; % in Hz
ts = 1/fs; % in s

omega_cutoff_Hz = 5; % cut-off frequency in Hz

% continuous
s = tf('s');
TF_lowpass_c = omega_cutoff_Hz*2*pi/(s + omega_cutoff_Hz*2*pi);

% discrete
z = tf('z',ts);
TF_lowpass_d = c2d(TF_lowpass_c, ts)

figure(1);
opts1=bodeoptions('cstprefs');
opts1.PhaseVisible = 'off';
opts1.XLim={[10^-1 10^3]};
opts1.YLim={[-30 0]};
Mag=subplot(2,1,1); bodeplot(TF_lowpass_c,opts1); grid on;
hold on;
title('Lowpass');

set(xlabel(''),'visible','off');
opts2=bodeoptions('cstprefs');
opts2.MagVisible = 'off';
opts2.XLim={[10^-1 10^3]};
opts2.YLim={[-90 0]};
Phase=subplot(2,1,2); bodeplot(TF_lowpass_c,opts2); grid on; title('');
hold on;

plot([omega_cutoff_Hz*2*pi omega_cutoff_Hz*2*pi],[-90 0],'r');
plot([3.7939 3.7939],[-90 0],'g');
plot([3.8393 3.8393],[-90 0],'k');
legend('Low pass','cut off','omega_{n,off}','omega_{n,on}')

