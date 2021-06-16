function CateSignalsFreq_updatePlot(varargin)
%
% updatePlot(~,indices,Plt3D)
% Quita la visibilidad de los plots no deseados.
%
% Inputs: 
%   indices: Posicion de los archivos seleccionados.
%   Plt3D: Plot de los archivos seleccionados.

ii = varargin{2}.Indices(1);
Plt3D = varargin{3};
if varargin{2}.NewData % Si cambia el logical, se actualiza el plot
    Plt3D(ii).Visible = 'on';
else
    Plt3D(ii).Visible = 'off';
end
Axes  = get(Plt3D(1),'Parent');
YTick = Axes.YTick;
YTick.Format = 'MMM dd';

[~,YTickUniqueInd,~] = unique(cellstr(YTick));
YTickNotUnique = true(length(YTick),1);
YTickNotUnique(YTickUniqueInd) = false;
Axes.YTick(YTickNotUnique) = [];
%%% En caso de querer cambiar el caxis
% MaxZData = varargin{4};
% MaxZData_Ind = cell2mat(varargin{1}.Data(:,2));
% CurrentAxes = Plt3D(1).Parent;
% caxis(CurrentAxes,[0.000,0.75*max(MaxZData(MaxZData_Ind))]);
end