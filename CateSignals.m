function CateSignals(varargin)
%
% CateSignals
%
% INPUTS:
%   WorkingFolder = dirección del folder a analizar
%       Los archiovs txt deben ser matrices donde cada columna representa
%       una dirección.
%
% OUTPUTS:
%
% Created By:
%   Mateo G. H.	(2021/03/17)
%
% Modified By:
%   Jose M. A.	(2021/05/24)
%   Mateo G. H. (2021/05/26)
%   Mateo G. H. (2021/06/15)
global WorkingFolder Count_Folder CateSignals_Results Signals
%%%%%%%%%%%%%%%%%%%%% -----------------------------------------------------
%%% Assign Inputs %%%
%%%%%%%%%%%%%%%%%%%%%
%%% Search options --------------------------------------------------------
SearchOpt         = varargin{1};
WorkingFolder     = SearchOpt.Folder;
TextFileFormat    = SearchOpt.TextFileFormat;
DirectoryLevels   = SearchOpt.DirectoryLevels;
IncludeInFileName = SearchOpt.IncludeInFileName;
%%% Signal properties -----------------------------------------------------
SignalProp = varargin{2};
Channels   = SignalProp.Channels;
Scale      = SignalProp.Scale;
Fs         = SignalProp.Fs;
%%% Signal processing -----------------------------------------------------
SignalProc = varargin{3};
%%% Report properties -----------------------------------------------------
ReportProp      = varargin{4};
SaveFigures     = ReportProp.SaveFigures;
GenerateReport  = ReportProp.GenerateReport;
Report_PDF_HTML = ReportProp.Style;
%%% Dismiss Files Options -------------------------------------------------
DismFiles = varargin{5};
%%% Waitbar ---------------------------------------------------------------
WaitBarLogical = logical(varargin{6});
%%%%%%%%%%%%%%%%%%%%%%%%%%% -----------------------------------------------
%%% Get Working Folders %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
MainWorkingFolder = WorkingFolder;
MainFolder = pwd;
if DirectoryLevels > 0
    %%% Check current dir and all subdirectories
    FolderDirOrigLength = length(MainWorkingFolder);
    cd(WorkingFolder);
    DirByLevel = dir('**/*');
    cd(MainFolder);
    DirByLevel = DirByLevel(~ismember({DirByLevel.name},{'.','..'}));
    %%% Get IsDir vector of logicals
    IsDirByLevel = cell2mat({DirByLevel.isdir}');
    DirByLevelFolder = {DirByLevel.folder};
    DirByLevelName   = {DirByLevel.name};
    FolderNames      = strcat(DirByLevelFolder(:),'\',DirByLevelName(:));
    WorkingFolder = (FolderNames(IsDirByLevel));
    FolderDirLevels = ...
        cell2mat(cellfun(@(CellHandle) sum(ismember(CellHandle(FolderDirOrigLength:end),'\')),WorkingFolder,'uni',false));
    WorkingFolder = WorkingFolder(FolderDirLevels==DirectoryLevels);
else
    WorkingFolder = {WorkingFolder};
end
NumFolderDir = length(WorkingFolder);
%%%%%%%%%%%%%%% -----------------------------------------------------------
%%% Waitbar %%%
%%%%%%%%%%%%%%%
if WaitBarLogical
    WaitBar = WaitBarFcn([]);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ------------------------------------------
%%% Cate. Each WorkingFolder %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for Count_Folder = 1:NumFolderDir
    %%%%%%%%%%%%%%% -------------------------------------------------------
    %%% Waitbar %%%
    %%%%%%%%%%%%%%%
    if WaitBarLogical
        WaitBar.CurrFolderDir = Count_Folder;
        WaitBar.NumFolderDir = NumFolderDir;
    else
        WaitBar = [];
    end
    %%%%%%%%%%%%%%%%%%%% --------------------------------------------------
    %%% CateAllFiles %%%
    %%%%%%%%%%%%%%%%%%%%
    CATE = CateAllFiles(WorkingFolder{Count_Folder},Channels,Scale,Fs,...
        TextFileFormat,SaveFigures,IncludeInFileName,SignalProc,WaitBar);
    %%% Create New Global -------------------------------------------------
    Global = CreateNewGlobal();
    %%% Organize CATE on Global -------------------------------------------
    LengthChann = length(CATE.Channel);
    LengthFiles = length(CATE.Files.Directory);
    Global.Signal(end+1:end+LengthFiles,:) = cell(LengthFiles,LengthChann);
    Global.RFall(end+1:end+LengthFiles,:) = cell(LengthFiles,LengthChann);
    Global.Wndws(end+1:end+LengthFiles,:) = cell(LengthFiles,LengthChann);
    Global.RFmax(end+1:end+LengthFiles,:) = zeros(LengthFiles,LengthChann);
    Global.RFp50(end+1:end+LengthFiles,:) = zeros(LengthFiles,LengthChann);
    Global.DismissByProcessing(end+1:end+LengthFiles,:) = CATE.DismissByProcessing;
    %%%
    Global.FileName(end+1:end+LengthFiles,1) = strcat((CATE.Files.Directory),'\',(CATE.Files.Name));
    for ii_chan = 1:LengthChann
        %%%
        Global.Signal(end-LengthFiles+1:end,ii_chan) = CATE.Channel{ii_chan}.Signal(:);
        Global.RFall(end-LengthFiles+1:end,ii_chan) = CATE.Channel{ii_chan}.RF(:);
        Global.Wndws(end-LengthFiles+1:end,ii_chan) = CATE.Channel{ii_chan}.Wndws(:);
        %%%
        Global.RFmax(end-LengthFiles+1:end,ii_chan) = ...
            cell2mat(cellfun(@(CellHandle) max([max(CellHandle),0]),CATE.Channel{ii_chan}.RF(:),'uni',false));
        %%%
        Global.RFp50(end-LengthFiles+1:end,ii_chan) = ...
            cell2mat(cellfun(@(CellHandle) prctile(CellHandle,50),CATE.Channel{ii_chan}.RF(:),'uni',false));
    end
    %%%%%%%%%%%%%%%%%%%%% -------------------------------------------------
    %%% Dismiss Files %%%
    %%%%%%%%%%%%%%%%%%%%%
    %%% Not processed data and less than five minutes files are eliminated
    Global = CleanGlobal(Global,logical(Global.DismissByProcessing),'Processing');
    %%%
    [Global.NFiles, Global.NChan] = size(Global.RFp50);
    %%% P50gt0
    if ~strcmp(DismFiles.P50gt0.NAA,'None')
        switch DismFiles.P50gt0.NAA
            case 'Any'
                DismissThisFiles = any(Global.RFp50==0,2);
            case 'All'
                DismissThisFiles = all(Global.RFp50==0,2);
        end
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
    if Global.NFiles>0
        DismFiles.MaxP50.Number = ceil(0.01+4*log10(Global.NFiles));
    else
        DismFiles.MaxP50.Number = 0;
    end
    if ~strcmp(DismFiles.MaxP50.NAA,'None')
        KeepThisFiles = false(Global.NFiles,Global.NChan);
        GlobalRatio = Global.RFmax./Global.RFp50;
        [~,BestFiles] = sort(GlobalRatio,1,'descend');
        BestFiles = BestFiles(1:DismFiles.MaxP50.Number,:);
        if ~isempty(DismFiles.MaxP50.Channels)
            BestFiles = BestFiles(:,DismFiles.MaxP50.Channels);
        end
        BestFiles = unique(BestFiles);
        KeepThisFiles(BestFiles,:) = true;
        DismissThisFiles = ~any(KeepThisFiles,2);
        Global = CleanGlobal(Global,DismissThisFiles,'MaxP50');
    end
    %%%%%%%%%%%%%%%%%%%%%% ------------------------------------------------
    %%% Export Results %%%
    %%%%%%%%%%%%%%%%%%%%%%
    if Global.NFiles~=0 % At least one file meet the given criteria
        %%% Save global and plot
        cd(WorkingFolder{Count_Folder})
        try
            CateSignals_Results = rmfield(Global,'Signal');
            Signals = Global.Signal;
        catch
            CateSignals_Results = Global;
        end
        save('CateSignals_Results.mat','CateSignals_Results')
        for Channel_i = 1:Global.NChan
            CateSignals_PlotAll(...
                Global.RFmax(:,Channel_i),...
                Global.RFp50(:,Channel_i),...
                Global.FileName,SaveFigures,Channel_i,...
                1);
        end
        %%% Generate Report
        if GenerateReport
            set(0, 'DefaultFigureVisible', 'off');
            if strcmp(Report_PDF_HTML,'HTML')
                report('CateSignals_Report_HTML',['-o',WorkingFolder{Count_Folder},'\CateSignals_Report.html']);
            elseif strcmp(Report_PDF_HTML,'PDF')
                report('CateSignals_Report_PDF',['-o',WorkingFolder{Count_Folder},'\CateSignals_Report.pdf']);
            else
                warning('El tipo de reporte indicado no es correcto, las opciones son ''HTML'', ''PDF''.');
            end
            set(0, 'DefaultFigureVisible', 'on');
        end
    else
        warning([newline,'No file meets the given criteria.',newline])
    end
    %%% Return to folder
    cd(MainFolder)
end
end
%% CreateNewGlobal
function Global = CreateNewGlobal()
%
% Global = CreateNewGlobal()
%
% Created By:
%   Mateo G. H.	(2021/05/25)
Global.FileName    = cell(0); % Column cell, each row is a file
Global.RFall       = cell(0); % Matrix cell, each row is a file, each column is a channel
Global.RFp50       = []; % Matrix, each row is a file, each column is a channel
Global.RFmax       = []; % Matrix, each row is a file, each column is a channel
Global.Wndws       = cell(0); % Matrix cell, each row is a file, each column is a channel
Global.Signal      = cell(0); % Matrix cell, each row is a file, each column is a channel
Global.DismissByProcessing = []; % Indica si el archivo se ha podido preprocesar.
end
%% CleanGlobal
function Global = CleanGlobal(Global,DismissThisFiles,Criteria)
%
% Global = CleanGlobal(Global,DismissThisFiles,Criteria)
%
% Created By:
%   Mateo G. H.	(2021/03/17)
CleanGlobal_ET = tic;
%%%
Global.FileName(DismissThisFiles) = [];
Global.RFall(DismissThisFiles,:)  = [];
Global.RFp50(DismissThisFiles,:)  = [];
Global.RFmax(DismissThisFiles,:)  = [];
Global.Wndws(DismissThisFiles,:)  = [];
Global.Signal(DismissThisFiles,:) = [];
[Global.NFiles, Global.NChan]= size(Global.RFp50);
%%%
disp(['Files dismissed (',Criteria,'): ',num2str(sum(DismissThisFiles(:)),'%.0f')])
Text = 'CleanGlobal:'; Text(20) = ' '; disp([Text,num2str(toc(CleanGlobal_ET),'%.3f')])
end
%% CateAllFiles
function CATE = CateAllFiles(varargin)
%
% CateAllFiles
%
%   WorkingFolder
%   Channels
%   Scale
%   Fs
%   TextFileFormat
%   SaveFigures
%   IncludeInFileName
%   SignalProcessing
%   WaitBar
%
% INPUTS:
% WorkingFolder = dirección del folder a analizar
%   Los archiovs txt deben ser matrices donde cada columna representa una dirección.
%
% OUTPUTS:
%
% Created By:
%   Mateo G. H.	(2021/03/17)

%%% -----------------------------------------------------------------------
WorkingFolder = varargin{1};
Channels = varargin{2};
Scale = varargin{3};
Fs = varargin{4};
TextFileFormat = varargin{5};
SaveFigures = varargin{6};
IncludeInFileName = varargin{7};
SignalProcessing = varargin{8};
WaitBar = varargin{9};
%%% -----------------------------------------------------------------------
cd(WorkingFolder);
%%% -----------------------------------------------------------------------
StartTime_ET = tic;
%%% ---
FileFormat = char(['**/*.',TextFileFormat]);
Files      = dir(FileFormat);
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
CATE.DismissByProcessing = false(NumberFiles,1);
%%% ---
for ii = 1:NumberFiles
    %%% ---
    if ~isempty(WaitBar)
        WaitBar = WaitBarFcn(WaitBar.Handle,WaitBar.Tic,WaitBar.CurrFolderDir,WaitBar.NumFolderDir,FileName{ii},ii/NumberFiles);
    end
    %%% ---
    StartTime_LD = tic;
    Data = readmatrix([FileDir{ii},'\',FileName{ii}])*Scale;
    try
        Data = SignalProcessingFcn(Data,...
            SignalProcessing.trend,...
            SignalProcessing.ts,...
            SignalProcessing.ffi,...
            SignalProcessing.fff,...
            Fs);
        if size(Data,1)<Fs*5*60 % Los archivos de menos de 5 min se borran.
            CATE.DismissByProcessing(ii,1)=1;
        end
    catch
        CATE.DismissByProcessing(ii,1)=1;
    end
    Text = 'LoadData:'; Text(20) = ' '; disp([Text,num2str(toc(StartTime_LD),'%.3f')])
    %%% ---
    for jj = 1:length(Channels)
        try
            [CATE.Channel{jj}.RF{ii},~,CATE.Channel{jj}.Wndws{ii},CATE.Channel{jj}.Signal{ii}] = ...
                getRF(Data(:,Channels(jj)));
            RF.Channel{jj}.Max(ii) = max(CATE.Channel{jj}.RF{ii});
            RF.Channel{jj}.P50(ii) = prctile(CATE.Channel{jj}.RF{ii},50);
        catch ME
            warning(ME.message);
            RF.Channel{jj}.Max(ii) = 0;
            RF.Channel{jj}.P50(ii) = 0;
            %%%
            CATE.Channel{jj}.RF{ii} = 0;
            CATE.Channel{jj}.Wndws{ii} = 0;
            CATE.Channel{jj}.Signal{ii} = 0;
        end
    end
end
%%% -----------------------------------------------------------------------
for Channel_i = 1:length(RF.Channel)
    CateSignals_PlotAll(...
        RF.Channel{Channel_i}.Max(:),...
        RF.Channel{Channel_i}.P50(:),...
        FileName,...
        SaveFigures,...
        Channel_i,...
        1);
end
%%% -----------------------------------------------------------------------
Text = 'Elapse time:'; Text(20) = ' '; disp([Text,num2str(toc(StartTime_ET),'%.3f')])
end
%% getRF
function varargout = getRF(Data,varargin)
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
%
% OUTPUTS:
%   RF: range times counts of rainflow analysis.
%   IA: arias intensity.
%   Wndws: the first and last point of each window.
%   ResampSig: resample signal.
%
% Created By:
%   Mateo G. H.	(2021/03/11)

% nargoutchk(1,4)
% narginchk(1,2)
%%% ---
StartTime_SC = tic;
%%% -----------------------------------------------------------------------
%%% Number of windows
%%% -----------------------------------------------------------------------
[L1,L2] = size(Data);
WindLength = floor(L1/10);
if ~isempty(varargin)
    WindLength = varargin{1};
end
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
%%% Signal
%%% -----------------------------------------------------------------------
if nargout>3
    varargout{4} = Data;
end

%%% -----------------------------------------------------------------------
%%% Elapsed time
%%% -----------------------------------------------------------------------
Text = 'getRF:'; Text(20) = ' ';    disp([Text,num2str(toc(StartTime_SC),'%.3f')]);
Text = 'getRF.RF:'; Text(20) = ' '; disp([Text,num2str(StopTime_SC_RF,'%.3f')]);
Text = 'getRF.IA:'; Text(20) = ' '; disp([Text,num2str(StopTime_SC_IA,'%.3f')]);
end
%% SignalProcessingFcn
function Data = SignalProcessingFcn(y,trend,ts,ffi,fff,fs)
%
% Data = SignalProcessingFcn(y,trend,ts,ffi,fff,fs)
%
% INPUTS:
%
%   y: señales iniciales (antes de ser procesadas y remuestreadas).
%   trend: valor lógico (1:true, 0:false) para realizar detrend.
%   ts: duración del suavizado inicial y final de la señal (eliminar ruido
%       cuando la excitación es nula).
%   ffi: frecuencia de corte del filtro pasa alto.
%   fff: frecuencia de corte del filtro pasa bajo.
%   fs: frecuencia de muestreo, en caso de ser diferente de 0 y menor a la
%       del vector ti, se hará remuestreo.
%
% Created By:
%   Mateo G. H. (2021/05/25)
%
% Modified BY:
%   Jose M. A.	(2021/05/24)
%   Mateo G. H. (2021/05/25)

%%%%%%%%%%%%%%%%%%% -------------------------------------------------------
%%% Time Vector %%%
%%%%%%%%%%%%%%%%%%%
t = round((0:(length(y(:,1))-1))'/fs,10);
%%%%%%%%%%%%%%% -----------------------------------------------------------
%%% Detrend %%%
%%%%%%%%%%%%%%%
if trend==1
    y = detrend(y);
end
%%%%%%%%%%%%%% ------------------------------------------------------------
%%% Smooth %%%
%%%%%%%%%%%%%%
if ~isempty(ts)
    if ts>0 && length(t)>fs*ts/2
        S = ones(length(t),1);
        S(1:fs*ts/2-1) = (1-cos(2*pi*(1/ts)*t(1:fs*ts/2-1)))/2;
        S(end-(fs*ts/2-1):end) = (1+cos(2*pi*(1/ts)*t(1:fs*ts/2)))/2;
        S([1,end]) = [0;0];
        S = S*ones(size(y(1,:)));
        y = S.*y;
    elseif ts>0
        y([1,end],:) = 0;
    end
end
%%%%%%%%%%%%%% ------------------------------------------------------------
%%% Filter %%%
%%%%%%%%%%%%%%
if ffi~=0	%%% High
    fc      = min([ffi,0.99*fs/2]); % (Hz)
    [z,p,k] = butter(6,fc/(fs/2),'high');
    sos     = zp2sos(z,p,k);
    y       = filtfilt(sos,1,y); % fvtool(sos,'Analysis','freq')
end
if fff~=0	%%% Low
    if fff>0.4*fs
        fff = min([0.4*fs,fff]); % (Hz)
        warning('La frecuencia de corte fff se ha modificado: fff=0.4*fs')
    end
    fc    = min([fff,0.99*fs/2]); % (Hz)
    [B,A] = butter(6,fc/(fs/2),'low');
    y     = filtfilt(B,A,y); % fvtool(B,A)
end
Data=y;
end
%% WaiBarFcn
function WaitBar = WaitBarFcn(varargin)
%
% WaitBar = WaitBarFcn(varargin)
%
% INPUTS:
%
%   WaitBar.Handle
%   WaitBar.Tic
%   CurrFolderDir
%   NumFolderDir
%   FileName
%   Progress
%
% OUTPUTS:
%   WaitBar
%
% Created By:
%   Mateo G. H. (2021/05/25)

%%% -----------------------------------------------------------------------
if nargin >1
    WaitBar.Handle = varargin{1};
    WaitBar.Tic = varargin{2};
    WaitBar.CurrFolderDir = varargin{3};
    WaitBar.NumFolderDir = varargin{4};
    FileName = varargin{5};
    Progress = varargin{6};
    MSG = ['Folder: ',num2str(WaitBar.CurrFolderDir,'%.0f'),'/',num2str(WaitBar.NumFolderDir,'%.0f'),', '];
    MSG = [MSG,'File: ',FileName];
    MSG = char([MSG,', Elapsed time (s): ',num2str(toc(WaitBar.Tic),'%.0f')]);
    WaitBar.Handle = waitbar(Progress,WaitBar.Handle,MSG);
else
    MSG = 'Please wait...';
    WaitBar.Handle = waitbar(0,MSG);
    WaitBar.Tic = tic;
    %%% Handle properties -------------------------------------------------
    GraphProp = GraphicalProperties;
    h = findall(WaitBar.Handle);
    for ii = 1:length(h)
        try
            set(h(ii),'Units','n')
        catch
        end
    end
    WaitBar.Handle.Units = 'centimeters';
    WaitBar.Handle.Position(3) = 15;
    WaitBar.Handle.Children.Title.Interpreter = 'none';
    set(WaitBar.Handle.Children,GraphProp.Prop);
    set(WaitBar.Handle.Children.XAxis,GraphProp.PropXA);
    set(WaitBar.Handle.Children.YAxis,GraphProp.PropYA);
    set(WaitBar.Handle.Children.Title,GraphProp.PropT);
    set(WaitBar.Handle.Children.XLabel,GraphProp.PropXL);
    set(WaitBar.Handle.Children.YLabel,GraphProp.PropYL);
end
%%% -----------------------------------------------------------------------
end
