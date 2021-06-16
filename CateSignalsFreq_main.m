clc, clearvars, close all force;
%%%%%%%%%%%%%%%%%% --------------------------------------------------------
%%% Repository %%%
%%%%%%%%%%%%%%%%%%
warning('off')
addpath('C:\Users\Mateo\Google Drive\01 Trabajo\GIT\CateSignals')
addpath('C:\Users\Mateo\Google Drive\01 Trabajo\GIT')
addpath('C:\Users\Usuario\Google Drive\01 Trabajo\GIT\CateSignals')
addpath('C:\Users\Usuario\Google Drive\01 Trabajo\GIT')
warning('on')
%%%%%%%%%%%%%%%%%%%%% -----------------------------------------------------
%%% Assign Inputs %%%
%%%%%%%%%%%%%%%%%%%%%
%%% Search Options
SearchOpt.WorkingFolder   = 'C:\Users\Usuario\Google Drive\01 Trabajo\01 Idvia\2021 - 02 - 10 - Desafios MOP\01-Desarrollo\2021 - 06 - 15 - CateSignals\MuestraDatosVerde';
SearchOpt.DirectoryLevels = 0;
SearchOpt.FileNameFormat = 'Registro_YYYYMMDD';
%%% Signal Properties
SignalProp.Channels = 2;     % Canal para representar la FFT
SignalProp.Fs       = 50;    % Frecuencia de muestreo
%%% Visualizacions
ViewProp.plt = 1; % 1 se hace plot, 0, no se hace
ViewProp.pltWidth = 15;
ViewProp.pltHeight = 10;
ViewProp.GUI = 1; % 1 se hace GUI, 0, no se hace
ViewProp.GUIWidth = 35;
ViewProp.GUIHeight = 19;
%%%%%%%%%%%%%%%%%%%%% -----------------------------------------------------
%%% Call Function %%%
%%%%%%%%%%%%%%%%%%%%%
Output = CateSignalsFreq(...
    SearchOpt,...
    SignalProp,...
    ViewProp);
