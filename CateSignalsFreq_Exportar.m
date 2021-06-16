function CateSignalsFreq_Exportar(varargin)
%
% ExportarCallback(~,~,Plt3D,Output)
% Guarda la nueva estructura con los archivos seleccionados como validos.
%
% Inputs: 
%   Plt3D: Plot de los archivos seleccionados.
%   Output: Estructura con los datos de los archivos.

Plt3D = varargin{3};
Output = varargin{4};
DismissThisFiles=true(size(Plt3D));

for ii = 1:length(Plt3D)
    if Plt3D(ii).Visible == 'on'
        DismissThisFiles(ii) = false; %Si esta visible, no se elimina
    else
        DismissThisFiles(ii) = true;
    end
end

NewOutput = CateSignalsFreq_CleanGlobal(Output,DismissThisFiles); % Elimina los archivos
save('EditedOutput','NewOutput');
assignin('base','NewOutput',NewOutput) % Se guarda la variable nueva
end