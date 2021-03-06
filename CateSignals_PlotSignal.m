function Fig = CateSignals_PlotSignal(ZData,TData,MaxZ,Wndws,Fs,File,Channel)
%
% PlotCategSignalReport(ZData,TData,MaxZ,Wndws,Fs,File)
%
% INPUTS:
%   ZData: RF.
%   MaxZ: MaxZ.
%   Wndws: structure obtained from SignalCateg plot.
%   Fs: sample frequency.
%
% OUTPUTS:
%
% Created By:
%   Mateo G. H.	(2021/05/25)

%%% -----------------------------------------------------------------------
%%% Propiedades gráfias
%%% -----------------------------------------------------------------------
GraphProp = GraphicalProperties;
%%% -----------------------------------------------------------------------
wid  = 15;
hei  = 4;
Fig  = figure('Units','centimeters','Position',[1 1 wid hei],'Color','w');
Ax1  = axes(Fig);%axes(Fig);
Ax1.PositionConstraint = 'innerposition';
Ax1.PlotBoxAspectRatioMode = 'manual';
YData = seconds([Wndws(1,:),Wndws(end)]/Fs); YData.Format = 'mm:ss';
BarDataLim = [0,1]*max(MaxZ);%[0,0.8]*max(ZData(:));
Pl1  = bar3(Ax1,ZData,0.95);
N    = length(Pl1);
set(Ax1,GraphProp.Prop);
set(Ax1.XAxis,GraphProp.PropXA);
set(Ax1.YAxis,GraphProp.PropYA);
set(Ax1.Title,GraphProp.PropT);
set(Ax1.XLabel,GraphProp.PropXL);
set(Ax1.YLabel,GraphProp.PropYL);
Ax1.Title.String  = ['Canal: ',num2str(Channel,'%.0f')];
Ax1.YLabel.String = '';
Ax1.YLabel.String = 'Tiempo (mm:ss)';
%Ax1.XLabel.String = num2str(File,'%.0f');
Ax1.YTick = 0.5:Ax1.YTick(end)+0.5;
Ax1.YTickLabel = cellstr(YData);
Ax1.XTick = 1:N;
Ax1.XTickLabel = cellstr(num2str(File));
%%% ---
Ax1.XLim = [0.5,size(ZData,2)+0.5];
Ax1.YLim = [0.5,size(ZData,1)+0.5];
%%% -----------------------------------------------------------------------
Clrs = colormap(Ax1, 'gray');
colormap(Ax1, Clrs(end:-1:1,:));
Clb = colorbar;
caxis(BarDataLim);
for kk = 1:N
    Pl1(kk).CData     = Pl1(kk).ZData;
    Pl1(kk).FaceColor = 'interp';
    Pl1(kk).EdgeColor = [1,1,1]*0.7;
    Pl1(kk).LineWidth = GraphProp.linewidth;
end
view(-90,90)
%%% ---
% Clb.Location       = 'northoutside';
% Clb.Label.String   = num2str(File,'%.0f');
% Clb.Label.FontSize = GraphProp.fontsize;
Clb.Position(1)    = 10;
%%% -----------------------------------------------------------------------
set(Ax1,'Units','pixels')
Ax2 = axes(Fig);
Pl2 = plot(TData,'Color',[0, 1, 0]);
Pl2.LineWidth = GraphProp.linewidth;
Ax2.XLim = [1,length(TData)];
Ax2.Title.String  = '';
Ax2.XLabel.String = '';
Ax2.YLabel.String = '';
Ax2.XAxis.Visible = 'off';
Ax2.YAxis.Visible = 'off';
Ax2.XTick = [];
Ax2.YTick = [];
Ax2.Visible = 'off';
Ax2.Color = 'none';
Ax2.Position([2,4]) = [0.41,0.22];
Ax2.Position([1,3]) = [0.135,0.765];
end