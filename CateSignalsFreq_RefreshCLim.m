function CateSignalsFreq_RefreshCLim(varargin)
disp('CateSignalsFreq_RefreshCLim')
Axes = varargin{3}.Parent;
Axes.CLim = Axes.ZLim.*[0,0.75];
end