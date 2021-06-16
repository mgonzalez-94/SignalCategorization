function Output = CateSignalsFreq_CleanGlobal(Output,DismissThisFiles)
%
% Output = CleanGlobal(Output,DismissThisFiles)
% Elimina los archivos no deseados de la estructura.
%
% Inputs: 
%   DismissThisFiles: Vector de logicos que indica archivos a eliminar.
%   Output: Estructura con la informacion de los archivos.
% Outpus:
%   Output: Estructura con la informacion de los archivos seleccionados.
%
%
Output.Year(DismissThisFiles)       = [];
Output.Month(DismissThisFiles)      = [];
Output.Day(DismissThisFiles)        = [];
Output.DateTime(DismissThisFiles)   = [];
Output.DayFile(DismissThisFiles)    = [];
Output.FileName(DismissThisFiles)   = [];
Output.FFT(DismissThisFiles)        = [];
Output.frec(DismissThisFiles)       = [];
Output.TotalFiles                   = size(Output.Day,2);
Output.FilesPerDay                  = size(Output.Day,2);
Output.fecha(DismissThisFiles)      = [];
Output.visible(DismissThisFiles)    = [];
end