function Output = CateSignalsFreq(varargin)
%%%%%%%%%%%%%%%%%%%%% -----------------------------------------------------
%%% Assign Inputs %%%
%%%%%%%%%%%%%%%%%%%%%
%%% Search options --------------------------------------------------------
SearchOpt       = varargin{1};
WorkingFolder   = SearchOpt.WorkingFolder;
DirectoryLevels = SearchOpt.DirectoryLevels;
FileNameFormat  = SearchOpt.FileNameFormat;
%%%
[~,FormatYearLocation] = ismember('YYYY',FileNameFormat);
FormatYearLocation = FormatYearLocation(1);
%%%
[~,FormatMonthLocation] = ismember('MM',FileNameFormat);
FormatMonthLocation = FormatMonthLocation(1);
%%%
[~,FormatDayLocation] = ismember('DD',FileNameFormat);
FormatDayLocation = FormatDayLocation(1);
%%% Signal properties -----------------------------------------------------
SignalProp = varargin{2};
Channels   = SignalProp.Channels;
Fs         = SignalProp.Fs;
%%% GUI Properties --------------------------------------------------------
ViewProp = varargin{3};

%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Recorrer carpetas %%%
%%%%%%%%%%%%%%%%%%%%%%%%%
MainWorkingFolder = WorkingFolder;
MainFolder = pwd;
if DirectoryLevels > 0
    % Busqueda de subdirectorios en el directorio principal
    FolderDirOrigLength = length(MainWorkingFolder);
    cd(WorkingFolder);
    DirByLevel = dir('**/*');
    cd(MainFolder);
    DirByLevel = DirByLevel(~ismember({DirByLevel.name},{'.','..'}));
    % Vector IsDir de logicos
    IsDirByLevel     = cell2mat({DirByLevel.isdir}');
    DirByLevelFolder = {DirByLevel.folder};
    DirByLevelName   = {DirByLevel.name};
    FolderNames      = strcat(DirByLevelFolder(:),'\',DirByLevelName(:));
    WorkingFolder    = (FolderNames(IsDirByLevel));
    FolderDirLevels = ...
        cell2mat(cellfun(@(CellHandle) sum(ismember(CellHandle(...
        FolderDirOrigLength:end),'\')),WorkingFolder,'uni',false));
    WorkingFolder = WorkingFolder(FolderDirLevels==DirectoryLevels);
    if isempty(WorkingFolder)
        WorkingFolder = {MainWorkingFolder};
    end
else
    WorkingFolder = {WorkingFolder};
end

%%%%%%%%%%%%%%%%%%%%%%%% --------------------------------------------------
%%% Lectura de datos %%%
%%%%%%%%%%%%%%%%%%%%%%%%
NumFolderDir = length(WorkingFolder);
Output   = {};
FileName = '\CateSignals_Results.mat';
countFile = 0;
for countFolder = 1:NumFolderDir
    try % Por si hay dias sin datos validos por algun motivo
        % Lectura de datos
        Folder = WorkingFolder{countFolder};
        Location = strcat(Folder,FileName);
        Global = load(Location);
        Global = Global.CateSignals_Results;
        % Seleccion del mejor entre los seleccionados en CateSignals
        for countFileName = 1:size(Global.FileName,1)
            %%%
            countFile = countFile+1;
            %%% Get Date from FileName ------------------------------------
            FileName = Global.FileName{countFileName};
            FileName(1:length(Folder)+1) = [];
            %%% Year (YYYY)
            Year = FileName(FormatYearLocation:FormatYearLocation+3);
            Output.Year{countFile} = str2double(Year);
            %%% Month (MM)
            Month = FileName(FormatMonthLocation:FormatMonthLocation+1);
            Output.Month{countFile} = str2double(Month);
            %%% Day (DD)
            Day = FileName(FormatDayLocation:FormatDayLocation+1);
            Output.Day{countFile}   = str2double(Day);
            %%% DateTime
            Output.DateTime(countFile) = datetime(...
                [Year,Month,Day],...
                'InputFormat','yyyyMMdd'...
                );
            %%%
            Output.DayFile{countFile}  = countFileName;
            Output.FileName{countFile} = Global.FileName{countFileName};
            Data = readmatrix(Output.FileName{countFile});
            % Vector de tiempos para SigPro
            t = (0:size(Data,1)-1)./Fs; % (s)
            Data = [t(:),Data]; %#ok<AGROW>
            % Ventana alrededor del pico maximo del registro
            [~,loc] = sort(Data(:,Channels+1),1,'descend');
            loc = loc(1:25,:);
            Wndw = [loc(end)-1000,loc(end)+1000];
            SignOut = SigPro(...
                Data(:,1),... % ti
                Data(:,Channels+1)./1000,... % yi
                40,... % fs
                Wndw,... % Wndw
                1,... % Trend
                2,... % ts
                0.2,... % ffi
                30,... % fff
                '',... % plotts
                0,... % plotfft
                0,... % plotpsd
                0,... % plotspt
                0);...% plotpwl
                Output.FFT{countFile} = SignOut.Y;
            Output.frec{countFile} = SignOut.f;
        end
    catch
        disp([newline,'No se encontró nada en:',newline,WorkingFolder{countFolder},newline])
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ---------------------------------------
%%% Organizar Valores Repetidos %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[~,~,DateTimeRepetitions] = unique(Output.DateTime);
for countRepeated = 1:length(Output.DateTime)
    Repetitions = DateTimeRepetitions(countRepeated)==DateTimeRepetitions;
    RepeSum = sum(Repetitions);
    if RepeSum>1
        Repetitions(1:countRepeated) = false;
        Output.DateTime(Repetitions) = Output.DateTime(Repetitions)+1/RepeSum;
    end
end
%%% -----------------------------------------------------------------------
cd(MainFolder)
Output.TotalFiles = size(Output.frec,2); % Total de archivos almacenados
Output.FilesPerDay = max(cell2mat(Output.DayFile)); % Maximos archivos/dia
% Se guarda la fecha con formato adecuado para la tabla:
Output.fecha = Output.DateTime(:);
Output.fecha.Format = 'dd MMMM yyyy';
Output.fecha = cellstr(Output.fecha);
% Output.fecha = strcat(...
%     Output.fecha,...
%     {' '},...
%     cellstr(num2str((1:Output.TotalFiles)','(%.0f)'))...
%     );
Output.visible = num2cell(true(Output.TotalFiles,1));
save('OriginalOutput','Output');
%%%%%%%%%%%%%%%%%%%%%% ----------------------------------------------------
%%% Representacion %%%
%%%%%%%%%%%%%%%%%%%%%%
if ViewProp.plt
    GraphProp = GraphicalProperties;
    Fig = figure('Units','centimeters',...
        'Position',[1 1 ViewProp.pltWidth ViewProp.pltHeight]);
    Ax1 = axes(Fig);
    CateSignalsFreq_PlotFFT(Fig, Ax1, GraphProp, Output);
end
%%%%%%%%%%%%%%%% ----------------------------------------------------------
%%% Interfaz %%%
%%%%%%%%%%%%%%%%
if ViewProp.GUI
    % Representacion
    uifig = figure('Units','centimeters',...
        'Position',[1 1 ViewProp.GUIWidth ViewProp.GUIHeight],...
        'Color','w');
    %%%%%%%%%%%%%%%%%%%%
    %%% Panel: Tabla %%%
    %%%%%%%%%%%%%%%%%%%%
    TablePanel = uipanel(uifig,...
        'Units','n',...
        'BackgroundColor','w',...
        'Position',[0.05,0.025,0.90,0.35]);
    AxesPanel = uipanel(uifig,...
        'Units','n',...
        'BackgroundColor','w',...
        'Position',[0.05,0.40,0.90,0.575]);
    Axes = axes(AxesPanel);
    Axes.OuterPosition = [0 0 1 1];
    GraphProp = GraphicalProperties;
    [Plt3D,Plt3D_MaxZData] = CateSignalsFreq_PlotFFT(uifig, Axes, GraphProp, Output);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Cambiar unidades previo a creación %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    TablePanel.Units = 'pixels';
    %%%%%%%%%%%%%%%%
    %%% Exportar %%%
    %%%%%%%%%%%%%%%%
    Exportar = uicontrol('Parent',TablePanel,'String','Exportar');
    Exportar.Callback = {@CateSignalsFreq_Exportar, Plt3D, Output};
    Exportar.Units = 'pixels';
    Exportar.Position = [20,20,60,20];
    Exportar.Position(2) = TablePanel.Position(4)-20-Exportar.Position(4);
    %%%%%%%%%%%%%%%%%%%
    %%% RefreshCLim %%%
    %%%%%%%%%%%%%%%%%%%
    RefreshCLim = uicontrol('Parent',TablePanel,'String','CLim');
    RefreshCLim.Callback = {@CateSignalsFreq_RefreshCLim, Plt3D, Output};
    RefreshCLim.Units = 'pixels';
    RefreshCLim.Position = Exportar.Position;
    RefreshCLim.Position(1) = 10+sum(Exportar.Position([1,3]));
    %%%%%%%%%%%%%%%%%%%
    %%% AxesView3D %%%
    %%%%%%%%%%%%%%%%%%%
    AxesView3D = uicontrol('Parent',TablePanel,'String','3D');
    AxesView3D.Callback = {@CateSignalsFreq_AxesView3D, Plt3D, Output};
    AxesView3D.Units = 'pixels';
    AxesView3D.Position = RefreshCLim.Position;
    AxesView3D.Position(1) = 10+sum(RefreshCLim.Position([1,3]));
    %%%%%%%%%%%%%%%%%%
    %%% AxesViewYX %%%
    %%%%%%%%%%%%%%%%%%
    AxesViewYX = uicontrol('Parent',TablePanel,'String','f vs Fecha');
    AxesViewYX.Callback = {@CateSignalsFreq_AxesViewYX, Plt3D, Output};
    AxesViewYX.Units = 'pixels';
    AxesViewYX.Position = AxesView3D.Position;
    AxesViewYX.Position(1) = 10+sum(AxesView3D.Position([1,3]));
    %%%%%%%%%%%%%%%%%%
    %%% AxesViewYZ %%%
    %%%%%%%%%%%%%%%%%%
    AxesViewYZ = uicontrol('Parent',TablePanel,'String','f vs |Y(f)|');
    AxesViewYZ.Callback = {@CateSignalsFreq_AxesViewYZ, Plt3D, Output};
    AxesViewYZ.Units = 'pixels';
    AxesViewYZ.Position = AxesViewYX.Position;
    AxesViewYZ.Position(1) = 10+sum(AxesViewYX.Position([1,3]));
    %%%%%%%%%%%%%
    %%% Tabla %%%
    %%%%%%%%%%%%%
    UI_Table = uitable(TablePanel);
    UI_Table.Data = [Output.fecha(:),Output.visible(:),Output.FileName(:)];
    UI_Table.ColumnEditable = true;
    UI_Table.Units = 'pixels';
    UI_Table.ColumnName={'Fecha','Visible','Ruta del archivo'};
    UI_Table.CellEditCallback = {@CateSignalsFreq_updatePlot,Plt3D,Plt3D_MaxZData};
    UI_Table.Position = [20 20 TablePanel.Position(3)-20-20 ...
        Exportar.Position(2)-20-20];
    UI_Table.ColumnWidth = {100,75,550};
    UI_Table.ColumnWidth{3} = TablePanel.Position(3)-...
        sum(cell2mat(UI_Table.ColumnWidth(1:2)))-20-20;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Cambiar unidades al finalizar creación %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    TablePanel.Units  = 'n';
    Exportar.Units    = 'n';
    RefreshCLim.Units = 'n';
    UI_Table.Units    = 'n';
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Figure SizeChangedFcn %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    uifig.SizeChangedFcn = {...
        @CateSignalsFreq_FigureSizeChangedFcn,...
        UI_Table,...
        TablePanel,...
        Exportar,...
        RefreshCLim,...
        AxesView3D,...
        AxesViewYX,...
        AxesViewYZ};
end
end
