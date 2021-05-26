function Text = CateSignals_DataCursor(~,DCursor,FileName,Lpwd)
%
% CateSignals_DataCursor
%
% Created By:
%   Mateo G. H.	(2021/05/25)

x = DCursor.Position(1);
FileName = FileName{x};
if length(FileName)>Lpwd
    Text = [num2str(x),': ','.',FileName(Lpwd+1:end)];
else
    Text = [num2str(x),': ',FileName];
end
end