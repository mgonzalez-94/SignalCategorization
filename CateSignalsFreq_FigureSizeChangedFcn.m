function CateSignalsFreq_FigureSizeChangedFcn(varargin)
%
% Figure_SizeChangedFcn(~,~,UI_Table,TablePanel,Exportar)
% Mantiene la proporcion del boton y la tabla de la interfaz.
%
% Inputs:
%   UI_Table: Tabla de datos
%   TablePanel: Panel que contiene la tabla
%   Exportar: Boton de exportar datos

UI_Table    = varargin{3};
TablePanel  = varargin{4};
Exportar    = varargin{5};
RefreshCLim = varargin{6};
AxesView3D  = varargin{7};
AxesViewYX  = varargin{8};
AxesViewYZ  = varargin{9};
%%% Formato de pixeles para modificar con facilidad -----------------------
TablePanel.Units  = 'pixels';
UI_Table.Units    = 'pixels';
Exportar.Units    = 'pixels';
RefreshCLim.Units = 'pixels';
AxesView3D.Units  = 'pixels';
AxesViewYX.Units  = 'pixels';
AxesViewYZ.Units  = 'pixels';
%%% Se actualiza la posicion del boton con respecto al panel --------------
Exportar.Position = [...
    20,TablePanel.Position(4)-20-Exportar.Position(4),60,20];
%%%
RefreshCLim.Position    = Exportar.Position;
RefreshCLim.Position(1) = 10+sum(Exportar.Position([1,3]));
%%%
AxesView3D.Position = RefreshCLim.Position;
AxesView3D.Position(1) = 10+sum(RefreshCLim.Position([1,3]));
%%%
AxesViewYX.Position = AxesView3D.Position;
AxesViewYX.Position(1) = 10+sum(AxesView3D.Position([1,3]));
%%%
AxesViewYZ.Position    = AxesViewYX.Position;
AxesViewYZ.Position(1) = 10+sum(AxesViewYX.Position([1,3]));
%%% Se actualiza la posicion de la tabla y del panel que la contiene ------
UI_Table.Position = [...
    20 20 TablePanel.Position(3)-20-20 Exportar.Position(2)-20-20];
UI_Table.ColumnWidth{3} = TablePanel.Position(3)-...
    sum(cell2mat(UI_Table.ColumnWidth(1:2)))-20-20;
%%% Formato original para que se puedan actualizar las dimensiones --------
TablePanel.Units  = 'n';
UI_Table.Units    = 'n';
Exportar.Units    = 'n';
RefreshCLim.Units = 'n';
AxesView3D.Units  = 'n';
AxesViewYX.Units  = 'n';
AxesViewYZ.Units  = 'n';
end