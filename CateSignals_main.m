%%% -----------------------------------------------------------------------
clc, clearvars, close all force;
global WorkingFolder Count_Folder CateSignals_Results Signals %#ok<NUSED>
%%%%%%%%%%%%%%%%%% --------------------------------------------------------
%%% Repository %%%
%%%%%%%%%%%%%%%%%%
warning('off')
addpath('C:\Users\Mateo\Google Drive\01 Trabajo\GIT\CateSignals')
addpath('C:\Users\Usuario\Google Drive\01 Trabajo\GIT\CateSignals')
warning('on')
%%%%%%%%%%%%%%%%%%%%% -----------------------------------------------------
%%% Assign Inputs %%%
%%%%%%%%%%%%%%%%%%%%%
%%% Search options --------------------------------------------------------
SearchOpt.Folder = '\\idviaserver\IDVIA_TRANSP\Personales\[02] DPTO. ESTRUCTURAS\[02] PROYECTOS\[03] DESAFIO_MOP_2021\000_Puente_Ejemplo_Verde\[00]_DATOS_VERDE\Raya_2020\2020-03';
SearchOpt.TextFileFormat    = 'csv';
SearchOpt.DirectoryLevels   = 0;
SearchOpt.IncludeInFileName = 'A';
%%% Signal properties -----------------------------------------------------
SignalProp.Channels = 1:3;
SignalProp.Scale    = 1/981;
SignalProp.Fs       = 50;
%%% Signal processing -----------------------------------------------------
SignalProc.ts  = 1;
SignalProc.ffi = 0.1;
SignalProc.fff = 20;
SignalProc.trend = 1;
%%% Report properties -----------------------------------------------------
ReportProp.SaveFigures    = 0;
ReportProp.GenerateReport = 1;
ReportProp.Style          = 'HTML'; % Seleecionar entre 'PDF' o 'HTML'
%%% Dismiss Files Options -------------------------------------------------
% 'None': no incluir criterio
% 'Any': si alguna dirección no cumple, elimina archivo.
% 'All': si ninguna dirección cumple, elimina archivo.
DismFiles.P50gt0.NAA  = 'Any';
DismFiles.P25_P75.NAA = 'Any';
DismFiles.MaxP50.NAA  = 'All';
% Canales a evaluar el criterio MaxP50
DismFiles.MaxP50.Channels = [];
%%% Waitbar ---------------------------------------------------------------
% 0: *no* graficar barra de progreso.
% 1: graficar barra de progreso.
PlotWaitbar = 1;
%%% -----------------------------------------------------------------------
CateSignals(...
    SearchOpt,...
    SignalProp,...
    SignalProc,...
    ReportProp,...
    DismFiles,...
    PlotWaitbar);
