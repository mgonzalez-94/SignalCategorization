function varargout = CateSignalsFreq_PlotFFT(Fig, Ax1, GraphProp, Output)
%
% Plt3D = PlotFFT(Fig, Ax1, GraphProp, Output)
% Representacion 3D en scatter de las FFT de los registros de Output.
%
% Inputs:
%   Fig: Figura en la que se hace la representacion.
%   Ax1: Ejes de la Figura.
%   GraphProp: Propiedades de la representacion.
%   Output: Estructura con la informacion de los archivos.
% Outpus:
%   Plt3D: Scatter con toda la informacion del plot almacenada.
%
%

% Propiedades del scatter
ScatterGraphicalProp.MarkerEdgeColor = 'flat';
ScatterGraphicalProp.MarkerFaceColor = [1,1,1]*0.6;
ScatterGraphicalProp.LineWidth  = 2;
ScatterGraphicalProp_MarkerSize = 4;
% Inicializacion de las variables del scatter
Plt3D = scatter3(0,0,0);
MaxFFT = zeros(Output.TotalFiles,1);
MaxFFT_Ind = true(Output.TotalFiles,1);
for ii = 1:Output.TotalFiles
    XData = Output.frec{ii};
    YData = repmat(Output.DateTime(ii),length(XData),1);%ones(size(Output.frec{ii}))*day(ii);
    ZData = abs(Output.FFT{ii});
    Plt3D(ii) = scatter3(Ax1,...
        XData,YData,ZData,...
        ZData*0+ScatterGraphicalProp_MarkerSize,...
        ZData);
    set(Plt3D(ii),ScatterGraphicalProp);
    hold(Ax1,'on');
    % Valor maximo en Z
    MaxFFT(ii) = max(ZData);
end
% 50% más alto con el mismo color
caxis([0.000,0.50*max(MaxFFT(MaxFFT_Ind))])
%%% -------------------------------------------------------------------
Ax1.XLabel.String = 'X';
Ax1.YLabel.String = 'Y';
Ax1.ZLabel.String = 'Z';
colormap('parula');
Ax1.Color = 'none';
Ax1.View = [-30,80];
%%% -------------------------------------------------------------------
set(Ax1,GraphProp.Prop);
set(Ax1.XAxis,GraphProp.PropXA);
set(Ax1.YAxis,GraphProp.PropYA);
set(Ax1.Title,GraphProp.PropT);
set(Ax1.XLabel,GraphProp.PropXL);
set(Ax1.YLabel,GraphProp.PropYL);
set(Ax1.ZLabel,GraphProp.PropYL);
Ax1.YLabel.String = 'Dia del registro';
Ax1.XLabel.String = 'Frecuencia (Hz)';
Ax1.ZLabel.String = '|Y(f)|';
Ax1.Title.String = 'Evolución de la FFT en el tiempo';
Ax1.XMinorGrid='on';
Ax1.YMinorGrid='on';
Ax1.ZMinorGrid='on';
%%% -------------------------------------------------------------------
DataTipProperties.FontSize = GraphProp.fontsize-1;
DataTipProperties.FontName = GraphProp.fontname;
DataTipProperties.BackgroundColor = ones(1,3).*0.95;
DataTipProperties.MarkerEdgeColor = ones(1,3).*0.2;
DataTipProperties.MarkerFaceColor = [1,1,1]*0.4;
DataTipProperties.EdgeColor =[1 1 1]*0.2;
DataTipProperties.Marker = 'o';
DataTipProperties.MarkerSize = 6;
DataTipProperties.BackgroundAlpha = 0.8;
DataTipProperties.Selected  = 'off';
DataTipProperties.Draggable = 'on';
DataTipProperties.Interpreter = 'none';
%%% -------------------------------------------------------------------
DCursor.cursorMode = datacursormode(Fig);
set(DCursor.cursorMode,'UpdateFcn',{...
    @CateSignalsFreq_UpdateDatatip,...
    Output,...
    DataTipProperties});
DCursor.hDatatip = DCursor.cursorMode.createDatatip(Plt3D(1));
set(DCursor.hDatatip,'Interpreter','none')
DCursor.hDatatip.Position(1) = Plt3D(1).XData(1);
DCursor.hDatatip.Position(2) = datenum(Plt3D(1).YData(1));
DCursor.hDatatip.Position(3) = Plt3D(1).ZData(1); %#ok<STRNU>
%%% -------------------------------------------------------------------
% set(DCursor.hDatatip,DataTipProperties);
%%% Set Outputs %%% -------------------------------------------------------
if nargout>0
    varargout{1} = Plt3D; %#ok<*AGROW>
end
if nargout>1
    varargout{2} = MaxFFT;
end
end
