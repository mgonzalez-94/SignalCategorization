function Fig = CateSignals_PlotAll(Max,P50,FileName,SaveFigures,Channel,ShowDataTip)
%
% CateSignals_PlotAll
%
%
% INPUTS:
%   Channels:
%   SaveFigures:
%   RF
%
% OUTPUTS:
%   RF: range times counts of rainflow analysis.
%   IA: arias intensity.
%   Wndws: the first and last point of each window.
%   ResampSig: resample signal.
%
% Created By:
%   Mateo G. H.	(2021/03/11)
GraphProp = GraphicalProperties;
%%% -----------------------------------------------------------------------
wid  = 17;
hei  = 6;
Fig  = figure('Units','centimeters','Position',[1 1 wid hei],...
    'Color','w','Name','CateSignals_PlotAll');
Ax1 = axes(Fig);
Pl1(1) = plot(Ax1,P50,':','Color',[1,0,0]*0.6,'LineWidth',GraphProp.linewidth,...
    'Marker','d','MarkerSize',6,'MarkerEdgeColor',[1,1,1]*0.3,'MarkerFaceColor',[1,0,0]*0.6); hold on;
Pl1(2) = plot(Ax1,Max,':','Color',[0,0,1]*0.6,'LineWidth',GraphProp.linewidth,...
    'Marker','o','MarkerSize',5,'MarkerEdgeColor',[1,1,1]*0.8,'MarkerFaceColor',[0,0,1]*0.6);
%%% ---
grid on
grid minor
Ax1.XLim = [1,max([length(P50),1.5])];
Ax1.YLim = [0,1.1*max(Max)];
Ax1.Title.String = ['Canal: ',num2str(Channel)];
Ax1.YLabel.String = 'RF';
Ax1.XLabel.String = 'Registro';
%%% ---
lgn1 = legend({'P50','Max'},'FontSize',GraphProp.Prop.FontSize-1,'Location','best');
set(lgn1.BoxFace, 'ColorType','truecoloralpha', 'ColorData',uint8(255*[1;1;1;.9]));
set(Ax1,GraphProp.Prop);
set(Ax1.XAxis,GraphProp.PropXA);
set(Ax1.YAxis,GraphProp.PropYA);
set(Ax1.Title,GraphProp.PropT);
set(Ax1.XLabel,GraphProp.PropXL);
set(Ax1.YLabel,GraphProp.PropYL);
%%% -----------------------------------------------------------------------
Lpwd = length(pwd);
%%% ---
if ShowDataTip==1
    DCursorP50.cursorMode = datacursormode(Fig);
    set(DCursorP50.cursorMode,'UpdateFcn',{@CateSignals_DataCursor,FileName,Lpwd});
    DCursorP50.hDatatip = DCursorP50.cursorMode.createDatatip(Pl1(1));
    set(DCursorP50.hDatatip,'Interpreter','none')
    DCursorP50.hDatatip.Position = [Pl1(1).XData(1),Pl1(1).YData(1),0];
    DCursorP50.hDatatip.FontSize = GraphProp.fontsize-1;
    DCursorP50.hDatatip.FontName = GraphProp.fontname;
    DCursorP50.hDatatip.BackgroundColor = ones(1,3).*0.95;
    DCursorP50.hDatatip.MarkerEdgeColor = ones(1,3).*0.2;
    DCursorP50.hDatatip.MarkerFaceColor = [1,1,1]*0.4;
    DCursorP50.hDatatip.EdgeColor =[1 1 1]*0.2;
    DCursorP50.hDatatip.Marker = 'o';
    DCursorP50.hDatatip.MarkerSize = 6;
    DCursorP50.hDatatip.BackgroundAlpha = 0.8;
    DCursorP50.hDatatip.Selected  = 'off';
    DCursorP50.hDatatip.Draggable = 'on';
end
%%% Save Figure
if SaveFigures == 1
    FigureNumber = num2str(get(gcf,'Number'));
    saveas(gcf,FigureNumber,'svg');
end
end