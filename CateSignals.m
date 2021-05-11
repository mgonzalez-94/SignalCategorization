%
% READ ALL TXT FILES
%
% INPUTS:
% FolderDir = dirección del folder a analizar
%   Los archiovs txt deben ser matrices donde cada columna representa una dirección.
%
% OUTPUTS:
%
% %%%%%%%%%%%%%%%%%%
% %%% Mateo G.H. %%%
% %%% 2021/03/17 %%%
% %%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                               %
% Folder:               Level 0 %
% 	- Folder:           Level 1 %
%      	- Folder:       Level 2 %
%      		- Folder    Level 3 %
%                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc, clearvars, close all;
%% INPUT
%%% -----------------------------------------------------------------------
%FolderDir = 'C:\Users\Usuario\Desktop\2021 - 05- 05 - ID Verde\2020-11\02';
FolderDir = '\\idviaserver\IDVIA_TRANSP\Personales\[02] DPTO. ESTRUCTURAS\[01] EQUIPO\JOSE MARIA ALBALADEJO\DesafiosMOP\6Registros\Verde';
Channels  = 1:3;
Scale     = 1/981;
TextFileFormat     = 'csv';
SkipFirstRAndLastC = 1;
DirectoryLevels    = 2;
SaveFigures        = 1;
IncludeInFileName  = 'A';
Fs = 50; % Hz, Sample frequency. If not, then [].
Fr = 5; % Hz, Resample frequency. If not, then [].
%%% Global options
% 'None': do not check,'Any': at least one channel must check,'All': all channels must check
GlobalCheckP25_P75 = 'All';
%% PROCESSING
%%% -----------------------------------------------------------------------
%%% Create Global
Global.FileName    = cell(0); % Column cell, each row is a file
Global.RFall       = cell(0); % Matrix cell, each row is a file, each column is a channel
Global.RFp50       = []; % Matrix, each row is a file, each column is a channel
Global.RFmax       = []; % Matrix, each row is a file, each column is a channel
Global.Wndws       = cell(0); % Matrix cell, each row is a file, each column is a channel
Global.ResampleSig = cell(0); % Matrix cell, each row is a file, each column is a channel
%%% Check current dir
FolderDirOrig = FolderDir;
CurrentDir = pwd;
if DirectoryLevels > 0
    %%% Check current dir and all subdirectories
    FolderDirOrigLength = length(FolderDirOrig);
    cd(FolderDir);
    DirByLevel = dir('**/*');
    cd(CurrentDir);
    DirByLevel = DirByLevel(~ismember({DirByLevel.name},{'.','..'}));
    %%% Get IsDir vector of logicals
    IsDirByLevel = cell2mat({DirByLevel.isdir}');
    DirByLevelFolder = {DirByLevel.folder};
    DirByLevelName   = {DirByLevel.name};
    FolderNames      = strcat(DirByLevelFolder(:),'\',DirByLevelName(:));
    FolderDir = (FolderNames(IsDirByLevel));
    FolderDirLevels = ...
        cell2mat(cellfun(@(CellHandle) sum(ismember(CellHandle(FolderDirOrigLength:end),'\')),FolderDir,'uni',false));
    FolderDir = FolderDir(FolderDirLevels==DirectoryLevels);
else
    FolderDir = {FolderDir};
end
CATE = cell(length(FolderDir),1); % return
for ii = 1:length(FolderDir)
    CATE{ii} = CateAllFiles(FolderDir{ii},Channels,Scale,Fs,Fr,...
        TextFileFormat,SkipFirstRAndLastC,SaveFigures,IncludeInFileName);
    %%% Organize CATE on Global
    LengthChann = length(CATE{ii}.Channel);
    LengthFiles = length(CATE{ii}.Files.Directory);
    Global.ResampleSig(end+1:end+LengthFiles,:) = cell(LengthFiles,LengthChann);
    Global.RFall(end+1:end+LengthFiles,:) = cell(LengthFiles,LengthChann);
    Global.Wndws(end+1:end+LengthFiles,:) = cell(LengthFiles,LengthChann);
    Global.RFmax(end+1:end+LengthFiles,:) = zeros(LengthFiles,LengthChann);
    Global.RFp50(end+1:end+LengthFiles,:) = zeros(LengthFiles,LengthChann);
    %%%
    Global.FileName(end+1:end+LengthFiles,1) = strcat((CATE{ii}.Files.Directory),'\',(CATE{ii}.Files.Name));
    for ii_chan = 1:LengthChann
        %%%
        Global.ResampleSig(end-LengthFiles+1:end,ii_chan) = CATE{ii}.Channel{ii_chan}.ResampleSig(:);
        Global.RFall(end-LengthFiles+1:end,ii_chan) = CATE{ii}.Channel{ii_chan}.RF(:);
        Global.Wndws(end-LengthFiles+1:end,ii_chan) = CATE{ii}.Channel{ii_chan}.Wndws(:);
        %%%
        Global.RFmax(end-LengthFiles+1:end,ii_chan) = ...
            cell2mat(cellfun(@(CellHandle) max([max(CellHandle),0]),CATE{ii}.Channel{ii_chan}.RF(:),'uni',false));
        %%%
        Global.RFp50(end-LengthFiles+1:end,ii_chan) = ...
            cell2mat(cellfun(@(CellHandle) prctile(CellHandle,50),CATE{ii}.Channel{ii_chan}.RF(:),'uni',false));
    end
end
%%% -----------------------------------------------------------------------
%%% Return to Original Folder
cd(FolderDirOrig)
save('Global.mat','Global')
%% Dismiss Files
%%% -----------------------------------------------------------------------
% clear('Global');load('Global.mat');
%%% NAA: 'None','Any','All'
DismFiles.P50gt0.NAA      = 'All';
DismFiles.P25_P75.NAA     = 'All';
DismFiles.MaxP50.NAA      = 'Any';
DismFiles.MaxP50.Treshold = 1.20;
%%% -----------------------------------------------------------------------
[Global.NFiles, Global.NChan] = size(Global.RFp50); 
% DismissThisFiles = false(Global.NFiles,1);
%%% P50gt0
if ~strcmp(DismFiles.P50gt0.NAA,'None')
DismissThisFiles = any(Global.RFp50==0,2);
Global = CleanGlobal(Global,DismissThisFiles,'P50gt0');
end
%%% P25_P75
if ~strcmp(DismFiles.P25_P75.NAA,'None')
    GlobalP25 = prctile(Global.RFp50,25);
    GlobalP75 = prctile(Global.RFp50,75);
    switch DismFiles.P25_P75.NAA
        case 'Any'
            DismissThisFiles = ~any(Global.RFp50>GlobalP25 & Global.RFp50<GlobalP75,2);
        case 'All'
            DismissThisFiles = ~all(Global.RFp50>GlobalP25 & Global.RFp50<GlobalP75,2);
    end
    Global = CleanGlobal(Global,DismissThisFiles,'P25P75');
end
%%% MaxP50
if ~strcmp(DismFiles.MaxP50.NAA,'None')
    switch DismFiles.MaxP50.NAA
        case 'Any'
            DismissThisFiles = ~any(Global.RFmax./Global.RFp50>DismFiles.MaxP50.Treshold,2);
        case 'All'
            DismissThisFiles = ~all(Global.RFmax./Global.RFp50>DismFiles.MaxP50.Treshold,2);
    end
    Global = CleanGlobal(Global,DismissThisFiles,'MaxP50');
end
%%% -----------------------------------------------------------------------
PlotCategAllP50Max_v2(Global.RFmax,Global.RFp50,Global.FileName,SaveFigures)
%%% -----------------------------------------------------------------------
%%% Generate Report
cd(CurrentDir)
MaxZ = 1.5*max(Global.RFmax(:,1));
set(0, 'DefaultFigureVisible', 'off');
MyReport = report('myReport');
web(MyReport)
set(0, 'DefaultFigureVisible', 'on');
%%% ***********************************************************************
%% CleanGlobal
function Global = CleanGlobal(Global,DismissThisFiles,Criteria)
CleanGlobal_ET = tic;
%%%
Global.FileName(DismissThisFiles) = [];
Global.RFall(DismissThisFiles,:)  = [];
Global.RFp50(DismissThisFiles,:)  = [];
Global.RFmax(DismissThisFiles,:)  = [];
Global.Wndws(DismissThisFiles,:)  = [];
Global.ResampleSig(DismissThisFiles,:) = [];
[Global.NFiles, Global.NChan]= size(Global.RFp50);
%%%
disp(['Files dismissed (',Criteria,'): ',num2str(sum(DismissThisFiles(:)),'%.0f')])
Text = 'CleanGlobal:'; Text(20) = ' '; disp([Text,num2str(toc(CleanGlobal_ET),'%.3f')])
end
%% CateAllFiles
function CATE = CateAllFiles(FolderDir,Channels,Scale,Fs,Fr,TextFileFormat,SkipFirstRAndLastC,SaveFigures,IncludeInFileName)
%
% READ ALL TXT FILES BY DIRECTORY
%
% INPUTS:
% FolderDir = dirección del folder a analizar
%   Los archiovs txt deben ser matrices donde cada columna representa una dirección.
%
% OUTPUTS:
%
% %%%%%%%%%%%%%%%%%%
% %%% Mateo G.H. %%%
% %%% 2021/03/17 %%%
% %%%%%%%%%%%%%%%%%%
%%% -----------------------------------------------------------------------
cd(FolderDir);
%%% -----------------------------------------------------------------------
StartTime_ET = tic;
%%% ---
FileFormat  = char(['**/*.',TextFileFormat]); %IncludeInFileName 4309
Files       = dir(FileFormat);
%%% Check inclusion in filename
if ~isempty(IncludeInFileName)
    LengthFileFormat = length(TextFileFormat)+1;
    ExcludeThisFiles = false(length(Files),1);
    for ii = 1:length(Files)
        NameWOExtension = Files(ii).name(1:end-LengthFileFormat);
        ExcludeThisFiles(ii) = ~any(ismember(NameWOExtension,IncludeInFileName));
    end
    Files(ExcludeThisFiles) = [];
end
%%%
FileName    = {Files.name};
FileDir     = {Files.folder};
NumberFiles = length(FileName);
CATE.Files.Name = FileName;
CATE.Files.Directory = FileDir;
%%% ---
for ii = 1:NumberFiles
    %%% ---
    StartTime_LD = tic;
    if SkipFirstRAndLastC==0
        Data = load([FileDir{ii},'\',FileName{ii}])*Scale;
    elseif SkipFirstRAndLastC==1
        Data = readmatrix([FileDir{ii},'\',FileName{ii}])*Scale;
        %Data = dlmread([FileDir{ii},'\',FileName{ii}])*Scale;
        %Data(:,end) = []; Data(1,:) = [];
    end
    Text = 'LoadData:'; Text(20) = ' '; disp([Text,num2str(toc(StartTime_LD),'%.3f')])
    %%% ---
    for jj = 1:length(Channels)
        try
            [CATE.Channel{jj}.RF{ii},~,CATE.Channel{jj}.Wndws{ii},CATE.Channel{jj}.ResampleSig{ii}] = ...
                SignalCateg(Data(:,Channels(jj)),[],Fs,Fr);
            RF.Channel{jj}.Max(ii) = max(CATE.Channel{jj}.RF{ii});
            RF.Channel{jj}.P50(ii) = prctile(CATE.Channel{jj}.RF{ii},50);
        catch ME
            warning(ME.message);
            RF.Channel{jj}.Max(ii) = 0;
            RF.Channel{jj}.P50(ii) = 0;
            %%%
            CATE.Channel{jj}.RF{ii} = 0;
            CATE.Channel{jj}.Wndws{ii} = 0;
            CATE.Channel{jj}.ResampleSig{ii} = 0;
        end
    end
end
%%% -----------------------------------------------------------------------
PlotCategAllP50Max(RF,FileName,FileDir,Channels,SaveFigures);
%%% -----------------------------------------------------------------------
Text = 'Elapse time:'; Text(20) = ' '; disp([Text,num2str(toc(StartTime_ET),'%.3f')])
end
%% SignalCateg
function varargout = SignalCateg(Data,varargin)
%
% Signal categorization
%
% RF = SignalCat(Data) computes the RF in each of 10 windows, where each
%       window has a length of 0.1*size(Data,1).
%
% RF = SignalCat(Data,WindLength) computes de categories of the signal in
%       each window, where each window has a length of WindLength.
%
% [~,IA] = SignalCat(...) computes the IA in each window.
%
% [~,~,Wndws] = SignalCat(...) indicates the first and last point of each
%       window.
%
% [~,~,~,ResampSig] = SignalCat(...) gives the resample signal.
%
% INPUTS:
%   Data: column vector with data to be analyzed in units of (m/s^2).
%   WindLength: analysis window length as number of points.
%   Fs: sample frequency.
%   Fr: resample frequency.
%
% OUTPUTS:
%   RF: range times counts of rainflow analysis.
%   IA: arias intensity.
%   Wndws: the first and last point of each window.
%   ResampSig: resample signal.
%
% %%%%%%%%%%%%%%%%%%
% %%% Mateo G.H. %%%
% %%% 2021/03/11 %%%
% %%%%%%%%%%%%%%%%%%
nargoutchk(1,4)
narginchk(1,4)
%%% ---
StartTime_SC = tic;
%%% -----------------------------------------------------------------------
%%% Number of windows
%%% -----------------------------------------------------------------------
[L1,L2] = size(Data);
WindLength = round(L1/10);
Fs = [];
Fr = [];
if ~isempty(varargin)
    for ii = 1:length(varargin)
        if ~isempty(varargin{ii})
            switch ii
                case 1
                    WindLength = varargin{1};
                case 2
                    Fs = varargin{2};
                case 3
                    Fr = varargin{3};
            end
        end
    end
end
% Obsoleto:
% % % if isempty(varargin)
% % %     WindLength = round(L1/10);
% % % else
% % %     WindLength = varargin{1};
% % % end
Windows = 1:WindLength:L1;
if Windows(end)+WindLength*0.5>L1
    Windows(end) = L1;
else
    Windows(end+1) = L1;
end
%%% -----------------------------------------------------------------------
%%% Rainflow
%%% -----------------------------------------------------------------------
StartTime_SC_RF = tic;
RF = zeros(length(Windows(2:end)),L2);
for ii = 1:L2
    RFData  = rainflow(Data(:,ii)); % T = array2table(RFData,'VariableNames',{'Count','Range','Mean','Start','End'}); disp(T)
    WindMat = Windows(2:end)>=RFData(:,4) & Windows(1:end-1)<=RFData(:,5);
    RCMat   = RFData(:,1).*RFData(:,2)*ones(1,length(Windows)-1).*WindMat;
    RF(:,ii) = sum(RCMat,'omitnan')';
end
% *** Variable Argument Out ***
varargout{1} = RF;
%%% ---
StopTime_SC_RF = toc(StartTime_SC_RF);
%%% -----------------------------------------------------------------------
%%% Arias Intensity
%%% -----------------------------------------------------------------------
StartTime_SC_IA = tic;
if nargout>1
    WindMat = sparse(Windows(1:end-1),1:length(Windows)-1,-1,L1,length(Windows)-1)+...
        sparse(Windows(2:end),1:length(Windows)-1,1,L1,length(Windows)-1);
    IAMat = (pi/(2*9.81))*cumtrapz(Data.^2);
    IA    = (IAMat'*WindMat)';
    % *** Variable Argument Out ***
    varargout{2} = IA;
end
%%% ---
StopTime_SC_IA = toc(StartTime_SC_IA);
%%% -----------------------------------------------------------------------
%%% Windows
%%% -----------------------------------------------------------------------
if nargout>2
    Wndws(1,:) = Windows(1:end-1);
    Wndws(2,:) = Windows(2:end);
    % *** Variable Argument Out ***
    varargout{3} = Wndws;
end
%%% -----------------------------------------------------------------------
%%% Resampled signal
%%% -----------------------------------------------------------------------
if nargout>3
    RS = resample(Data,Fr,Fs);
    % *** Variable Argument Out ***
    varargout{4} = RS;
end
%%% -----------------------------------------------------------------------
%%% Elapsed time
%%% -----------------------------------------------------------------------
Text = 'SignalCateg:'; Text(20) = ' ';    disp([Text,num2str(toc(StartTime_SC),'%.3f')]);
Text = 'SignalCateg.RF:'; Text(20) = ' '; disp([Text,num2str(StopTime_SC_RF,'%.3f')]);
Text = 'SignalCateg.IA:'; Text(20) = ' '; disp([Text,num2str(StopTime_SC_IA,'%.3f')]);
end
%% PlotCateAllP50Max
function PlotCategAllP50Max(RF,FileName,FileDir,Channels,SaveFigures)
%
% PlotCategAllP50Max
%
%
% INPUTS:
%   Channels: 
%   SaveFigures:
%   RF
%
% OUTPUTS:
%   RF: range times counts of rainflow analysis.
%   IA: arias intensity.
%   Wndws: the first and last point of each window.
%   ResampSig: resample signal.
%
% %%%%%%%%%%%%%%%%%%
% %%% Mateo G.H. %%%
% %%% 2021/03/11 %%%
% %%%%%%%%%%%%%%%%%%
GraphProp = GraphicalProperties;
%%% -----------------------------------------------------------------------
for jj =1:length(Channels)
    %%% ---
    wid  = 17;
    hei  = 6;
    Fig  = figure('Units','centimeters','Position',[1 1 wid hei]);
    Ax1 = axes(Fig); %#ok<LAXES>
    Pl1(1) = plot(Ax1,RF.Channel{jj}.P50(:),':','Color',[1,0,0]*0.6,'LineWidth',GraphProp.linewidth,...
        'Marker','d','MarkerSize',6,'MarkerEdgeColor',[1,1,1]*0.3,'MarkerFaceColor',[1,0,0]*0.6); hold on;
    Pl1(2) = plot(Ax1,RF.Channel{jj}.Max(:),':','Color',[0,0,1]*0.6,'LineWidth',GraphProp.linewidth,...
        'Marker','o','MarkerSize',5,'MarkerEdgeColor',[1,1,1]*0.8,'MarkerFaceColor',[0,0,1]*0.6);
    %%% ---
    Ax1.XLim = [1,max([length(RF.Channel{jj}.P50(:)),1.5])];
    Ax1.YLim = [0,1.1*max(RF.Channel{jj}.Max(:))];
    Ax1.Title.String = ['Canal: ',num2str(Channels(jj))];
    Ax1.YLabel.String = 'RF';
    Ax1.XLabel.String = 'Registro';
    %%% ---
    lgn1 = legend({'P50','Max'},'FontSize',GraphProp.Prop.FontSize-1,'Location','best');
    set(lgn1.BoxFace, 'ColorType','truecoloralpha', 'ColorData',uint8(255*[1;1;1;.9]));
    set(Ax1,GraphProp.Prop);
    set(Ax1.XAxis,GraphProp.PropXA);
    set(Ax1.YAxis,GraphProp.PropYA);
    set(Ax1.Title,GraphProp.PropT);
    set(Ax1.XLabel,GraphProp.PropXL);
    set(Ax1.YLabel,GraphProp.PropYL);
    %%% -----------------------------------------------------------------------
    Lpwd = length(pwd);
    %%% ---
    DCursorP50.cursorMode = datacursormode(Fig);
    set(DCursorP50.cursorMode,'UpdateFcn',{@UpdateDataCursorP50,FileName,FileDir,Lpwd});
    DCursorP50.hDatatip = DCursorP50.cursorMode.createDatatip(Pl1(1));
    set(DCursorP50.hDatatip,'Interpreter','none')
    DCursorP50.hDatatip.Position = [Pl1(1).XData(1),Pl1(1).YData(1),0];
    DCursorP50.hDatatip.FontSize = GraphProp.fontsize-1;
    DCursorP50.hDatatip.FontName = GraphProp.fontname;
    DCursorP50.hDatatip.BackgroundColor = ones(1,3).*0.95;
    DCursorP50.hDatatip.MarkerEdgeColor = ones(1,3).*0.2;
    DCursorP50.hDatatip.MarkerFaceColor = [1,1,1]*0.4;
    DCursorP50.hDatatip.EdgeColor =[1 1 1]*0.2;
    DCursorP50.hDatatip.Marker = 'o';
    DCursorP50.hDatatip.MarkerSize = 6;
    DCursorP50.hDatatip.BackgroundAlpha = 0.8;
    DCursorP50.hDatatip.Selected  = 'off';
    DCursorP50.hDatatip.Draggable = 'on';
    %%% Save Figure
    if SaveFigures == 1
        FigureNumber = num2str(get(gcf,'Number'));
        saveas(gcf,FigureNumber,'svg');
    end
end
end
%%
%% PlotCategAllP50Max_v2
function PlotCategAllP50Max_v2(Max,P50,FileName,SaveFigures)
%
% PlotCategAllP50Max
%
%
% INPUTS:
%   Channels: 
%   SaveFigures:
%   RF
%
% OUTPUTS:
%   RF: range times counts of rainflow analysis.
%   IA: arias intensity.
%   Wndws: the first and last point of each window.
%   ResampSig: resample signal.
%
% %%%%%%%%%%%%%%%%%%
% %%% Mateo G.H. %%%
% %%% 2021/03/11 %%%
% %%%%%%%%%%%%%%%%%%
GraphProp = GraphicalProperties;
Channels = size(P50,2);
%%% -----------------------------------------------------------------------
for jj =1:Channels
    %%% ---
    wid  = 17;
    hei  = 6;
    Fig  = figure('Units','centimeters','Position',[1 1 wid hei]);
    Ax1 = axes(Fig); %#ok<LAXES>
    Pl1(1) = plot(Ax1,P50(:,jj),':','Color',[1,0,0]*0.6,'LineWidth',GraphProp.linewidth,...
        'Marker','d','MarkerSize',6,'MarkerEdgeColor',[1,1,1]*0.3,'MarkerFaceColor',[1,0,0]*0.6); hold on;
    Pl1(2) = plot(Ax1,Max(:,jj),':','Color',[0,0,1]*0.6,'LineWidth',GraphProp.linewidth,...
        'Marker','o','MarkerSize',5,'MarkerEdgeColor',[1,1,1]*0.8,'MarkerFaceColor',[0,0,1]*0.6);
    %%% ---
    Ax1.XLim = [1,max([length(P50(:,jj)),1.5])];
    Ax1.YLim = [0,1.1*max(Max(:,jj))];
    Ax1.Title.String = ['Canal: ',num2str(jj)];
    Ax1.YLabel.String = 'RF';
    Ax1.XLabel.String = 'Registro';
    %%% ---
    lgn1 = legend({'P50','Max'},'FontSize',GraphProp.Prop.FontSize-1,'Location','best');
    set(lgn1.BoxFace, 'ColorType','truecoloralpha', 'ColorData',uint8(255*[1;1;1;.9]));
    set(Ax1,GraphProp.Prop);
    set(Ax1.XAxis,GraphProp.PropXA);
    set(Ax1.YAxis,GraphProp.PropYA);
    set(Ax1.Title,GraphProp.PropT);
    set(Ax1.XLabel,GraphProp.PropXL);
    set(Ax1.YLabel,GraphProp.PropYL);
    %%% -----------------------------------------------------------------------
    Lpwd = length(pwd);
    %%% ---
    DCursorP50.cursorMode = datacursormode(Fig);
    set(DCursorP50.cursorMode,'UpdateFcn',{@UpdateDataCursorP50_v2,FileName,Lpwd});
    DCursorP50.hDatatip = DCursorP50.cursorMode.createDatatip(Pl1(1));
    set(DCursorP50.hDatatip,'Interpreter','none')
    DCursorP50.hDatatip.Position = [Pl1(1).XData(1),Pl1(1).YData(1),0];
    DCursorP50.hDatatip.FontSize = GraphProp.fontsize-1;
    DCursorP50.hDatatip.FontName = GraphProp.fontname;
    DCursorP50.hDatatip.BackgroundColor = ones(1,3).*0.95;
    DCursorP50.hDatatip.MarkerEdgeColor = ones(1,3).*0.2;
    DCursorP50.hDatatip.MarkerFaceColor = [1,1,1]*0.4;
    DCursorP50.hDatatip.EdgeColor =[1 1 1]*0.2;
    DCursorP50.hDatatip.Marker = 'o';
    DCursorP50.hDatatip.MarkerSize = 6;
    DCursorP50.hDatatip.BackgroundAlpha = 0.8;
    DCursorP50.hDatatip.Selected  = 'off';
    DCursorP50.hDatatip.Draggable = 'on';
    %%% Save Figure
    if SaveFigures == 1
        FigureNumber = num2str(get(gcf,'Number'));
        saveas(gcf,FigureNumber,'svg');
    end
end
end
%% PlotSignalCateg
% function PlotCategSignal(Data,varargin)
% %
% % PlotSignalCateg(Data,Case)
% %
% % INPUTS:
% %   Data: structure obtained from SignalCateg plot.
% %   Case: analysis window length as number of points.
% %
% % OUTPUTS:
% %
% % %%%%%%%%%%%%%%%%%%
% % %%% Mateo G.H. %%%
% % %%% 2021/03/15 %%%
% % %%%%%%%%%%%%%%%%%%
% nargoutchk(0,0)
% narginchk(1,3)
% %%% -----------------------------------------------------------------------
% %%% Propiedades gráfias
% %%% -----------------------------------------------------------------------
% fontname            = 'Calibri Light';
% fontsize            = 11;
% linewidth           = 1.2;
% Prop.FontName       = fontname;
% Prop.FontSize       = fontsize;
% PropYL.FontName     = fontname;
% PropYL.FontSize     = fontsize;
% PropXL.FontName     = fontname;
% PropXL.FontSize     = fontsize;
% Prop.GridColor      = [1 1 1]*0.6;
% Prop.MinorGridColor = [1 1 1]*0.6;
% Prop.XMinorGrid     = 'on';
% Prop.YMinorGrid     = 'on';
% Prop.XGrid          = 'on';
% Prop.YGrid          = 'on';
% Prop.Box            = 'on';
% PropYA.Color        = [1 1 1]*0;
% PropXA.Color        = [1 1 1]*0;
% PropT.FontName      = fontname;
% PropT.FontSize      = fontsize;
% %%% -----------------------------------------------------------------------
% if isempty(varargin)
%     varargin{1} = 'RF';
% end
% for ii = 1:length(varargin)
%     Case = varargin{ii};
%     switch Case
%         case 'RF'
%             ZData = Data.RF;
%         case 'IA'
%             ZData = Data.IA;
%     end
%     wid  = 17;
%     hei  = 12;
%     Fig  = figure('Units','centimeters','Position',[1 1 wid hei]);
%     Ax1  = axes(Fig); %#ok<LAXES>
%     YData = seconds([Data.Wndws(1,:),Data.Wndws(end)]/Data.fs); YData.Format = 'mm:ss';
%     BarDataLim = [0,0.8]*max(ZData(:));
%     Pl1  = bar3(ZData,0.95);
%     N    = length(Pl1);
%     set(Ax1,GraphProp.Prop);
%     set(Ax1.XAxis,GraphProp.PropXA);
%     set(Ax1.YAxis,GraphProp.PropYA);
%     set(Ax1.Title,GraphProp.PropT);
%     set(Ax1.XLabel,GraphProp.PropXL);
%     set(Ax1.YLabel,GraphProp.PropYL);
%     Ax1.Title.String  = '';
%     Ax1.YLabel.String = '';
%     Ax1.YLabel.String = 'Tiempo (mm:ss)';
%     Ax1.XLabel.String = 'Registro';
%     Ax1.YTick = 0.5:Ax1.YTick(end)+0.5;
%     Ax1.YTickLabel = cellstr(YData);
%     Ax1.XTick = 1:N;
%     %%% ---
%     Ax1.XLim = [0.5,size(ZData,2)+0.5];
%     Ax1.YLim = [0.5,size(ZData,1)+0.5];
%     %%% -----------------------------------------------------------------------
%     Clrs = colormap(Ax1, 'gray');
%     colormap(Ax1, Clrs(end:-1:1,:));
%     Clb = colorbar;
%     caxis(BarDataLim);
%     for kk = 1:N
%         Pl1(kk).CData     = Pl1(kk).ZData;
%         Pl1(kk).FaceColor = 'interp';
%         Pl1(kk).EdgeColor = [1,1,1]*0.7;
%         Pl1(kk).LineWidth = linewidth;
%     end
%     view(-90,90)
%     %%% ---
%     Clb.Location       = 'northoutside';
%     Clb.Label.String   = Case;
%     Clb.Label.FontSize = fontsize;
% end
% end
%% UpdateDataCursorP50
function Text = UpdateDataCursorP50(~,DCursor,FileName,FileDir,Lpwd)
x = DCursor.Position(1);
FileDir  = FileDir{x};
FileName = FileName{x};
if length(FileDir)>Lpwd
    Text = ['.',FileDir(Lpwd+1:end),'\',FileName];
else
    Text = [num2str(x),': ',FileName];
end
end
%% UpdateDataCursorP50_v2
function Text = UpdateDataCursorP50_v2(~,DCursor,FileName,Lpwd)
x = DCursor.Position(1);
FileName = FileName{x};
if length(FileName)>Lpwd
    Text = [num2str(x),': ','.',FileName(Lpwd+1:end)];
else
    Text = [num2str(x),': ',FileName];
end
end
%% GraphicalProperties
function GraphProp = GraphicalProperties
GraphProp.fontname            = 'Calibri Light';
GraphProp.fontsize            = 11;
GraphProp.linewidth           = 1.2;
GraphProp.Prop.FontName       = GraphProp.fontname;
GraphProp.Prop.FontSize       = GraphProp.fontsize;
GraphProp.PropYL.FontName     = GraphProp.fontname;
GraphProp.PropYL.FontSize     = GraphProp.fontsize;
GraphProp.PropXL.FontName     = GraphProp.fontname;
GraphProp.PropXL.FontSize     = GraphProp.fontsize;
GraphProp.Prop.GridColor      = [1 1 1]*0.6;
GraphProp.Prop.MinorGridColor = [1 1 1]*0.6;
GraphProp.Prop.XMinorGrid     = 'on';
GraphProp.Prop.YMinorGrid     = 'on';
GraphProp.Prop.XGrid          = 'on';
GraphProp.Prop.YGrid          = 'on';
GraphProp.Prop.Box            = 'on';
GraphProp.PropYA.Color        = [1 1 1]*0;
GraphProp.PropXA.Color        = [1 1 1]*0;
GraphProp.PropT.FontName      = GraphProp.fontname;
GraphProp.PropT.FontSize      = GraphProp.fontsize;
% set(Ax1,GraphProp.Prop);
% set(Ax1.XAxis,GraphProp.PropXA);
% set(Ax1.YAxis,GraphProp.PropYA);
% set(Ax1.Title,GraphProp.PropT);
% set(Ax1.XLabel,GraphProp.PropXL);
% set(Ax1.YLabel,GraphProp.PropYL);
end