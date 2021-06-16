function Text = CateSignalsFreq_UpdateDatatip(hDatatip,DCursor,Output,DataTipProperties)
%
% Text = UpdateDatatip(hDatatip,DCursor,iniMonth,Output,DataTipProperties)
% Da formato al DataTip de los plots.
%
% Inputs:
%   hDatatip: Formato del texto y cuadro del DataTip.
%   DCursor: Posicion asociada al DataTip.
%   iniMonth: Primer mes que contiene informacion.
%   Output: Estructura con la informacion de los archivos.
% Outpus:
%   Output: Estructura con la informacion de los archivos seleccionados.
%
Loc = DCursor.Target.SeriesIndex;
DateTime = Output.DateTime(Loc);
DateTime.Format = 'dd MMMM yyyy';
% Texto mostrado en el DataTip:
Text = [num2str(Loc), ': ',char(DateTime)];
% Se actualiza el formato
set(hDatatip,DataTipProperties);
end